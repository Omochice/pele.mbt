// A seeded differential fuzzer: mutates each diagram's golden sources the way pele's own oracle
// tests do, renders every mutation with pele's dist bundle and with the wasm plugin under every
// golden profile and under random option variations, and reports where the two disagree.
//
// Usage: node scripts/fuzz.mjs [--seed n] [--count n] [--variations n] [--jobs n] [--out file.json] [--no-shrink] [diagram ...]
// Build the plugin first with `moon build --target wasm --release`.
// PELE_ROOT points at a built pele checkout when vendor/pele is not initialized.
//
// `count` sources are drawn per diagram, and each is rendered under every profile of
// golden/manifest.json and under `variations` random option sets, so a run makes
// count * (profiles + variations) comparisons per diagram.
// Everything random is drawn in the main thread before any work is handed out, so a seed gives
// the same cases and the same report whatever --jobs is.
// For each kind of mismatch, the first case is shrunk: options that do not matter are reset to the
// default profile, then chunks of the source are deleted while the same kind of mismatch remains.

import { existsSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { availableParallelism } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { isDeepStrictEqual, parseArgs } from 'node:util';
import { Worker, isMainThread, parentPort, workerData } from 'node:worker_threads';
import { TYPST_CALL_DEPTH } from './call-depth.mjs';
import { loadPlugin } from './plugin-host.mjs';
import { peleOptions } from './plugin-options.mjs';

// The goldens were rendered under UTC, and gantt floors its ticks to local midnight.
process.env.TZ = 'UTC';

const self = fileURLToPath(import.meta.url);
const root = join(dirname(self), '..');
const peleRoot = process.env.PELE_ROOT ?? join(root, 'vendor/pele');
const goldenDir = join(root, 'golden');
const wasmPath = join(root, '_build/wasm/release/build/plugin/plugin.wasm');
const { render, detectType } = await import(join(peleRoot, 'dist/pele.js'));

// pele reports a stack overflow as "nested too deeply", so its outcome depends on the stack it runs on.
// The goldens come from node's main thread, whose V8 stack is 984 KiB, and a worker loses 192 KiB of
// its thread stack to V8's buffer, so this gives the workers the main thread's limit.
const WORKER_STACK_MB = (984 + 192) / 1024;

// Port of random and mutator in vendor/pele/tests/support/corpus.ts, kept to the same draws so that
// a seed yields the sequence pele's tests would.
function random(seed) {
  let state = seed >>> 0;
  return () => {
    state = (Math.imul(state, 1664525) + 1013904223) >>> 0;
    return state / 4294967296;
  };
}

const pickWith = (rnd) => (list) => list[Math.floor(rnd() * list.length)];

function mutator(corpus, fragments, rnd) {
  const pick = pickWith(rnd);
  return () => {
    let s = pick(corpus);
    const edits = 1 + Math.floor(rnd() * 3);
    for (let k = 0; k < edits; k++) {
      const pos = Math.floor(rnd() * (s.length + 1));
      const r = rnd();
      if (r < 0.35) {
        s = s.slice(0, pos) + pick(fragments) + s.slice(pos);
      } else if (r < 0.6) {
        s = s.slice(0, pos) + s.slice(pos + 1 + Math.floor(rnd() * 3));
      } else if (r < 0.75) {
        const other = pick(corpus);
        const from = Math.floor(rnd() * other.length);
        s = s.slice(0, pos) + other.slice(from, from + Math.floor(rnd() * 20)) + s.slice(pos);
      } else if (r < 0.9) {
        s = s.slice(0, pos) + s.slice(pos, pos + Math.floor(rnd() * 6)) + s.slice(pos);
      } else {
        s = s.slice(0, pos) + pick(fragments) + s.slice(pos + 1);
      }
    }
    return s;
  };
}

function peleOutcome(source, json) {
  try {
    const r = render(source, peleOptions(json));
    return { svg: r.svg, width: r.width, height: r.height, links: r.links, type: r.type, mermaidType: r.mermaidType };
  } catch (e) {
    return {
      error: {
        name: e?.name === 'PeleError' ? 'PeleError' : (e?.constructor?.name ?? typeof e),
        code: e?.code ?? null,
        message: String(e?.message ?? e),
        type: e?.type ?? null,
        mermaidType: e?.mermaidType ?? null,
      },
    };
  }
}

function pluginOutcome(call, source, json) {
  try {
    const { code, result } = call(Buffer.from(source), Buffer.from(JSON.stringify(json)));
    const parsed = JSON.parse(result);
    if ((code === 1) !== (parsed.error !== undefined)) return { broken: `status ${code} with ${parsed.error ? 'an error' : 'a result'}` };
    return parsed;
  } catch (error) {
    if (error instanceof WebAssembly.RuntimeError) return { trap: error.message };
    return { broken: `${error?.constructor?.name}: ${error?.message}` };
  }
}

// Quoted text and numbers vary with the source, so they are blanked to let one bug make one kind.
const shape = (message) => message.replace(/"[^"]*"/g, '"…"').replace(/'[^']*'/g, "'…'").replace(/\d+(\.\d+)?/g, 'N').slice(0, 90);
const describeError = (e) => `${e.name === 'PeleError' ? '' : `${e.name} `}${e.code ?? '-'}: ${shape(e.message)}`;

function excerpt(text, at) {
  return JSON.stringify(text.slice(Math.max(0, at - 40), at + 60));
}

function firstDifference(expected, actual) {
  let i = 0;
  while (i < expected.length && i < actual.length && expected[i] === actual[i]) i++;
  return i;
}

// Where in the SVG the first difference falls: an attribute of an element, or text content.
function svgPlace(svg, at) {
  const open = svg.lastIndexOf('<', at);
  if (open < 0) return 'prologue';
  const tag = /^<\/?([\w:-]+)/.exec(svg.slice(open))?.[1] ?? '?';
  const close = svg.indexOf('>', open);
  if (close >= 0 && close < at) return `text in <${tag}>`;
  const attribute = /\s([\w:-]+)=["'][^"']*$/.exec(svg.slice(open, at))?.[1];
  return attribute ? `<${tag} ${attribute}>` : `<${tag}>`;
}

/**
 * Compares the two outcomes of one case.
 * @returns {{ kind: string, detail: string } | null} null when they agree
 */
function classify(expected, actual) {
  if (actual.trap !== undefined) return { kind: `trap: ${shape(actual.trap)}`, detail: actual.trap };
  if (actual.broken !== undefined) return { kind: `broken response: ${actual.broken}`, detail: actual.broken };
  if (expected.error && actual.error) {
    if (isDeepStrictEqual(expected.error, actual.error)) return null;
    return {
      kind: `error differs: pele ${describeError(expected.error)} / plugin ${describeError(actual.error)}`,
      detail: `pele ${JSON.stringify(expected.error)}, plugin ${JSON.stringify(actual.error)}`,
    };
  }
  if (expected.error) return { kind: `plugin renders where pele throws ${describeError(expected.error)}`, detail: expected.error.message };
  if (actual.error) return { kind: `plugin throws ${describeError(actual.error)}`, detail: actual.error.message };
  for (const key of ['type', 'mermaidType']) {
    if (expected[key] !== actual[key]) return { kind: `${key} differs`, detail: `pele ${expected[key]}, plugin ${actual[key]}` };
  }
  if (expected.svg !== actual.svg) {
    const at = firstDifference(expected.svg, String(actual.svg));
    return { kind: `svg differs at ${svgPlace(expected.svg, at)}`, detail: `at ${at}: pele ${excerpt(expected.svg, at)}, plugin ${excerpt(String(actual.svg), at)}` };
  }
  for (const key of ['width', 'height', 'links']) {
    if (!isDeepStrictEqual(expected[key], actual[key])) {
      return { kind: `${key} differs`, detail: `pele ${JSON.stringify(expected[key])}, plugin ${JSON.stringify(actual[key])}` };
    }
  }
  return null;
}

// Deletes runs of `parts`, from half their number down to one, while `keeps` holds.
function shrinkParts(parts, keeps, budget) {
  let size = Math.max(1, parts.length >> 1);
  while (budget.left > 0) {
    let changed = false;
    for (let i = 0; i < parts.length && budget.left > 0; ) {
      const candidate = parts.slice(0, i).concat(parts.slice(i + size));
      budget.left--;
      if (keeps(candidate.join(''))) {
        parts = candidate;
        changed = true;
      } else {
        i += size;
      }
    }
    if (size > 1) size = Math.max(1, size >> 1);
    else if (!changed) break;
  }
  return parts.join('');
}

function shrink(check, source, json, kind, defaults) {
  const same = (s, o) => check(s, o)?.kind === kind;
  let options = { ...json };
  // Options first, so that the source is shrunk under the options it is reported with.
  for (const key of Object.keys(options)) {
    if (isDeepStrictEqual(options[key], defaults[key])) continue;
    const candidate = { ...options };
    if (Object.hasOwn(defaults, key)) candidate[key] = defaults[key];
    else delete candidate[key];
    if (same(source, candidate)) options = candidate;
  }
  const budget = { left: 3000 };
  const keeps = (s) => same(s, options);
  let text = shrinkParts(source.split(/(?<=\n)/), keeps, budget);
  text = shrinkParts([...text], keeps, budget);
  return { source: text, options, detail: check(text, options)?.detail ?? '' };
}

function serveWorker() {
  const { call } = loadPlugin(wasmPath, { callDepthLimit: TYPST_CALL_DEPTH });
  const compare = (source, json) => {
    const expected = peleOutcome(source, json);
    return { rendered: expected.error === undefined, mismatch: classify(expected, pluginOutcome(call, source, json)) };
  };
  const check = (source, json) => compare(source, json).mismatch;
  parentPort.on('message', (message) => {
    if (message.cases) {
      parentPort.postMessage({ results: message.cases.map(({ id, source, options }) => ({ id, ...compare(source, options) })) });
    } else {
      const { id, source, options, kind, defaults } = message.shrink;
      parentPort.postMessage({ shrunk: { id, ...shrink(check, source, options, kind, defaults) } });
    }
  });
}

// The string literals of a test file whose source text passes `accept`, with their escapes evaluated.
// Spreads such as `...COMMON` are not literals, so they are skipped.
function* stringLiterals(src, accept = () => true) {
  for (const m of src.matchAll(/`((?:[^`\\]|\\.)*)`|'((?:[^'\\\n]|\\.)*)'|"((?:[^"\\\n]|\\.)*)"/g)) {
    const raw = m[1] ?? m[2] ?? m[3];
    if (!accept(raw)) continue;
    try {
      yield new Function('return `' + raw.replace(/`/g, '\\`').replace(/\$\{/g, '\\${') + '`')();
    } catch {
      continue;
    }
  }
}

function literalsOfBlocks(file, opening) {
  const text = readFileSync(file, 'utf8');
  const found = [];
  for (const block of text.matchAll(new RegExp(`${opening}\\[([^]*?)\\n\\s*\\];?`, 'g'))) found.push(...stringLiterals(block[1]));
  return found;
}

// Mermaid punctuation for a diagram whose tests in pele have no fragment list of their own.
const GENERIC_FRAGMENTS = [
  ' ', '  ', '\t', '\n', '\n\n', '\r\n', ':', ';', ',', '.', '-', '--', '-->', '->', '>', '<', '|', '"', "'", '`', '(', ')', '[', ']',
  '{', '}', '#', '%%', '%% c', '%%{init: {}}%%', '---\n', 'title ', 'accTitle: ', 'accDescr {', 'x', 'é', '日本', '#35;', '<br>',
];

// TeX that the random option sets resolve at every integer size, wide enough to outgrow a narrow
// column, since the golden math map answers only the TeX of the corpus at the sizes it asked for.
const FUZZ_TEX = ['x', '\\frac{a}{b}', 'x^2', 'a_{1}+b_{2}+c_{3}'];
const FUZZ_MATH = Object.fromEntries(
  FUZZ_TEX.map((tex, i) => [
    tex,
    Object.fromEntries(
      Array.from({ length: 64 }, (_, k) => {
        const size = k + 1;
        const box = { width: size * (2 + 3 * i), height: size * (1 + i / 2) };
        const markup = i % 2 === 0 ? { svg: `<path d="M0,0H${box.width}"/>` } : { html: `<b>${tex}</b>` };
        return [String(size), { ...markup, ...box }];
      })
    ),
  ])
);

// pele's oracle tests mutate with the FRAGMENTS lists of tests/<diagram>/oracle.test.ts, and its
// security tests add PAYLOADS to them; math fragments make a math resolver ask for something.
function fragmentsFor(diagram) {
  const tests = join(peleRoot, 'tests');
  const payloads = literalsOfBlocks(join(tests, 'support/inert.ts'), 'export const PAYLOADS = ');
  const math = ['$$', ...FUZZ_TEX.map((tex) => `$$${tex}$$`), 'a $$x^2$$ b'];
  let own;
  if (diagram === 'railroad') {
    own = literalsOfBlocks(join(tests, 'support/railroad-oracle.ts'), '(?:const COMMON = |fragments: )');
  } else if (existsSync(join(tests, diagram, 'oracle.test.ts'))) {
    own = literalsOfBlocks(join(tests, diagram, 'oracle.test.ts'), 'const [A-Z_]*FRAGMENTS = ');
  }
  return [...new Set([...(own?.length ? own : GENERIC_FRAGMENTS), ...payloads, ...math])];
}

function corpusOf(diagram) {
  const dir = join(goldenDir, diagram);
  return readdirSync(dir)
    .filter((f) => f.endsWith('.mmd'))
    .sort()
    .map((f) => readFileSync(join(dir, f), 'utf8'));
}

// Front matter and init directives of the corpus, for prepending to sources that have none.
function headersOf(corpus) {
  const headers = new Set();
  for (const source of corpus) {
    const front = /^\s*---\r?\n[^]*?\r?\n---\r?\n/.exec(source);
    if (front) headers.add(front[0].trimStart());
    for (const directive of source.matchAll(/%%\{[^]*?\}%%/g)) headers.add(directive[0] + '\n');
  }
  return [...headers].sort();
}

function sectionOf(source) {
  let type;
  try {
    type = detectType(source);
  } catch {
    return null;
  }
  return type === 'xychart' ? 'xyChart' : type;
}

// Option changes that no golden profile combines, each drawn with its own chance.
const TWEAKS = [
  ['maxWidth', (rnd, pick) => pick([1, 40, 80, 120, 200, 320, 400, 639, 641, 800, 1200, 60 + Math.floor(rnd() * 1400)])],
  ['autoDirection', () => false],
  ['directionBreakpoint', (rnd, pick) => pick([0, 300, 1000])],
  ['fontSize', (rnd, pick) => pick([10, 12, 14, 20, 24])],
  ['padding', (rnd, pick) => pick([0, 2, 16, 30])],
  ['responsive', (rnd, pick) => pick([true, false])],
  ['fontFamily', (rnd, pick) => pick(['serif', 'monospace', 'Arial, sans-serif'])],
  ['links', () => false],
  ['images', () => false],
];

/**
 * One random option set, with the source it is rendered from.
 * @returns {{ label: string, options: object, source: string }}
 */
function variation(rnd, profiles, source, headers) {
  const pick = pickWith(rnd);
  const names = Object.keys(profiles);
  const base = pick(names);
  const options = structuredClone(profiles[base]);
  const changed = [];
  while (changed.length === 0) {
    for (const [key, value] of TWEAKS) {
      if (rnd() < 0.3) {
        options[key] = value(rnd, pick);
        changed.push(key);
      }
    }
    // The callback options come from the golden profiles, so the maps answer what the corpus asks.
    for (const name of ['icons', 'math', 'measurer']) {
      const owner = names.find((n) => profiles[n][name] !== undefined);
      if (owner && options[name] === undefined && rnd() < 0.2) {
        options[name] = profiles[owner][name];
        changed.push(name);
      }
    }
    if (rnd() < 0.15) {
      const section = sectionOf(source);
      if (section) {
        options.config = { [section]: { useMaxWidth: false } };
        changed.push('config');
      }
    }
  }
  if (options.math !== undefined) options.math = { ...options.math, ...FUZZ_MATH };
  let text = source;
  if (headers.length > 0 && !/^\s*---/.test(source) && rnd() < 0.25) {
    text = pick(headers) + source;
    changed.push('front matter');
  }
  return { label: `${base}+${changed.join(',')}`, options, source: text };
}

function casesFor(diagram, index, seed, count, variations, profiles) {
  const corpus = corpusOf(diagram);
  const headers = headersOf(corpus);
  const rnd = random(Math.imul(seed, 0x9e3779b1) ^ (index + 1));
  const next = mutator(corpus, fragmentsFor(diagram), rnd);
  const cases = [];
  for (let i = 0; i < count; i++) {
    // The mutator cuts between UTF-16 code units, but typst hands the plugin UTF-8, where a lone
    // surrogate has already become U+FFFD, so pele is given that same text.
    const source = next().toWellFormed();
    for (const [name, options] of Object.entries(profiles)) cases.push({ diagram, label: name, source, options });
    for (let v = 0; v < variations; v++) cases.push({ diagram, ...variation(rnd, profiles, source, headers) });
  }
  return cases;
}

function startWorkers(jobs) {
  return Array.from({ length: jobs }, () => new Worker(self, { workerData: { worker: true }, resourceLimits: { stackSizeMb: WORKER_STACK_MB } }));
}

// Hands each task to the next idle worker and resolves with the answers in task order.
function runAll(workers, tasks, send, receive) {
  return new Promise((resolve, reject) => {
    const answers = new Array(tasks.length);
    let nextTask = 0;
    let pending = tasks.length;
    if (pending === 0) return resolve(answers);
    const feed = (worker) => {
      if (nextTask >= tasks.length) return;
      const at = nextTask++;
      worker.removeAllListeners('message');
      worker.removeAllListeners('error');
      worker.once('error', reject);
      worker.once('message', (message) => {
        answers[at] = receive(message);
        if (--pending === 0) resolve(answers);
        else feed(worker);
      });
      worker.postMessage(send(tasks[at]));
    };
    for (const worker of workers) feed(worker);
  });
}

function chunks(list, size) {
  const out = [];
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
  return out;
}

const PORTED = [
  'agentflow', 'architecture', 'block', 'c4', 'class', 'cynefin', 'er', 'eventmodeling', 'flowchart', 'gantt', 'git', 'info', 'ishikawa',
  'journey', 'kanban', 'mindmap', 'packet', 'pie', 'quadrant', 'radar', 'railroad', 'requirement', 'sankey', 'sequence', 'state',
  'swimlane', 'timeline', 'treemap', 'treeview', 'usecase', 'venn', 'wardley', 'xychart',
];

// Options are printed as their difference from the default profile, with a callback map named
// after the profile it was taken from.
function optionsDiff(options, profiles) {
  const defaults = profiles.default;
  const diff = {};
  for (const [key, value] of Object.entries(options)) {
    if (isDeepStrictEqual(value, defaults[key])) continue;
    const callback = ['icons', 'math', 'measurer'].includes(key);
    const owner = callback ? Object.keys(profiles).find((n) => isDeepStrictEqual(profiles[n][key], value)) : undefined;
    const fuzzed = key === 'math' ? Object.keys(profiles).find((n) => isDeepStrictEqual({ ...profiles[n].math, ...FUZZ_MATH }, value)) : undefined;
    diff[key] = owner ? `<${owner} profile>` : fuzzed ? `<${fuzzed} profile with FUZZ_MATH>` : value;
  }
  for (const key of Object.keys(defaults)) if (!Object.hasOwn(options, key)) diff[key] = '<unset>';
  return diff;
}

async function main() {
  const { values: flags, positionals } = parseArgs({
    allowPositionals: true,
    options: {
      seed: { type: 'string', default: '1' },
      count: { type: 'string', default: '1000' },
      variations: { type: 'string', default: '1' },
      jobs: { type: 'string', default: String(Math.max(1, availableParallelism() - 1)) },
      out: { type: 'string' },
      'no-shrink': { type: 'boolean', default: false },
    },
  });
  const diagrams = positionals.length > 0 ? positionals : PORTED;
  const unknown = diagrams.filter((d) => !PORTED.includes(d));
  if (unknown.length > 0) {
    console.error(`unknown diagram ${unknown.join(', ')}`);
    process.exit(2);
  }
  const seed = Number(flags.seed);
  const count = Number(flags.count);
  const variations = Number(flags.variations);
  const profiles = JSON.parse(readFileSync(join(goldenDir, 'manifest.json'), 'utf8')).profiles;
  loadPlugin(wasmPath);

  const started = Date.now();
  const cases = diagrams.flatMap((diagram) => casesFor(diagram, PORTED.indexOf(diagram), seed, count, variations, profiles));
  const workers = startWorkers(Math.max(1, Number(flags.jobs)));
  try {
    const batches = chunks(cases.map((c, id) => ({ id, source: c.source, options: c.options })), 24);
    const answers = await runAll(workers, batches, (cases) => ({ cases }), (message) => message.results);
    const mismatch = new Array(cases.length).fill(null);
    const rendered = new Array(cases.length).fill(false);
    for (const batch of answers) {
      for (const answer of batch) {
        mismatch[answer.id] = answer.mismatch;
        rendered[answer.id] = answer.rendered;
      }
    }

    const groups = new Map();
    for (let id = 0; id < cases.length; id++) {
      if (!mismatch[id]) continue;
      const { diagram, label } = cases[id];
      const key = `${diagram}\u0000${mismatch[id].kind}`;
      if (!groups.has(key)) groups.set(key, { diagram, kind: mismatch[id].kind, count: 0, labels: new Map(), first: id });
      const group = groups.get(key);
      group.count++;
      const profile = label.split('+')[0] + (label.includes('+') ? '+…' : '');
      group.labels.set(profile, (group.labels.get(profile) ?? 0) + 1);
    }
    const list = [...groups.values()];
    if (!flags['no-shrink']) {
      const shrunk = await runAll(
        workers,
        list,
        (g) => ({ shrink: { id: g.first, source: cases[g.first].source, options: cases[g.first].options, kind: g.kind, defaults: profiles.default } }),
        (message) => message.shrunk
      );
      list.forEach((g, i) => (g.reproducer = shrunk[i]));
    }

    const report = { seed, count, variations, diagrams: {} };
    for (const diagram of diagrams) {
      const ids = cases.flatMap((c, id) => (c.diagram === diagram ? [id] : []));
      const accepted = ids.filter((id) => rendered[id]).length;
      const own = list.filter((g) => g.diagram === diagram);
      const mismatched = own.reduce((n, g) => n + g.count, 0);
      console.log(`${diagram}: ${ids.length} cases (${accepted} rendered by pele), ${mismatched} mismatched in ${own.length} kinds`);
      report.diagrams[diagram] = { cases: ids.length, rendered: accepted, mismatched, kinds: [] };
      for (const g of own) {
        const first = cases[g.first];
        const repro = g.reproducer ?? { source: first.source, options: first.options, detail: mismatch[g.first].detail };
        const entry = {
          kind: g.kind,
          count: g.count,
          profiles: Object.fromEntries(g.labels),
          source: repro.source,
          options: optionsDiff(repro.options, profiles),
          detail: repro.detail,
        };
        report.diagrams[diagram].kinds.push(entry);
        console.log(`  ${g.count} x ${g.kind}`);
        console.log(`    profiles ${JSON.stringify(entry.profiles)}`);
        console.log(`    source ${JSON.stringify(entry.source)}`);
        console.log(`    options ${JSON.stringify(entry.options)}`);
        console.log(`    detail ${entry.detail.slice(0, 400)}`);
      }
    }
    const mismatched = list.reduce((n, g) => n + g.count, 0);
    console.log(`\ntotal ${cases.length} cases, ${mismatched} mismatched in ${list.length} kinds (seed ${seed}, ${((Date.now() - started) / 1000).toFixed(1)}s)`);
    if (flags.out) writeFileSync(flags.out, JSON.stringify(report, null, 2) + '\n');
    process.exitCode = mismatched > 0 ? 1 : 0;
  } finally {
    await Promise.all(workers.map((w) => w.terminate()));
  }
}

if (isMainThread) await main();
else if (workerData?.worker) serveWorker();
