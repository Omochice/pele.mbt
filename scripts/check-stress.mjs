// Feeds the inputs of pele's stress tests through the wasm plugin and through pele's dist bundle,
// and checks that the plugin never traps and ends in the same outcome as pele: success, or a
// PeleError of the same code.
//
// Usage: node scripts/check-stress.mjs [--typst [--jobs <n>]] [--stack-sizes <kb>,<kb>...] [filter ...]
// Build the plugin first with `moon build --target wasm --release`.
// Run it inside `nix develop`, which sets PELE_ROOT to the built pele whose tests/ and dist/ it reads.
// A filter keeps the tests whose "<file> > <name>" contains it.
//
// The inputs are not stored: they are rebuilt from pele's tests on every run, because they add up
// to tens of megabytes. Each test file is loaded with its imports replaced by recorders, so every
// string handed to `render`, `parse` or an internal entry such as a lexer is collected without
// running pele's sources. Strings given to internal entries are rendered as whole diagrams too.
//
// The plugin runs under node by default, rewritten to trap past the thousand call frames typst's
// interpreter allows, since V8 allows wasm a far deeper stack; the deepest inputs are listed.
// With --typst it runs under `typst compile` itself (the binary is $TYPST, or typst on PATH),
// which is slow but confirms the emulation.
//
// With --stack-sizes, pele's outcomes are computed again under each given V8 stack size and every
// input whose outcome depends on it is reported, since a RangeError from a deep stack is how
// pele reports nesting as a limit.

import { execFile, execFileSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { availableParallelism, tmpdir } from 'node:os';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { parseArgs } from 'node:util';
import { fixAllocator } from './allocator.mjs';
import { TYPST_CALL_DEPTH } from './call-depth.mjs';
import { peleRoot } from './pele-root.mjs';
import { loadPlugin } from './plugin-host.mjs';

process.env.TZ = 'UTC';

const self = fileURLToPath(import.meta.url);
const root = join(dirname(self), '..');
const wasmPath = join(root, '_build/wasm/release/build/Omochice/pele-typst/plugin/plugin.wasm');
// gen-golden pins the same clock, so gantt charts do not depend on the day the check runs.
const NOW = 1767225600000;

const { values: flags, positionals: filters } = parseArgs({
  allowPositionals: true,
  options: {
    typst: { type: 'boolean', default: false },
    jobs: { type: 'string', default: String(Math.max(1, availableParallelism() >> 1)) },
    'stack-sizes': { type: 'string', default: '' },
    'pele-outcomes': { type: 'boolean', default: false },
  },
});
const typst = flags.typst ? (process.env.TYPST ?? 'typst') : null;
const jobs = Number(flags.jobs);
const stackSizes = flags['stack-sizes'] ? flags['stack-sizes'].split(',').map(Number) : [];
const peleOnly = flags['pele-outcomes'];

function stressFiles() {
  const tests = join(peleRoot, 'tests');
  const files = [join(tests, 'stress.test.ts')];
  for (const entry of readdirSync(tests, { withFileTypes: true }).sort((a, b) => (a.name < b.name ? -1 : 1))) {
    const file = join(tests, entry.name, 'stress.test.ts');
    if (entry.isDirectory() && existsSync(file)) files.push(file);
  }
  return files;
}

let recordInto = null;

// Stands for an import of pele's sources and for whatever it returns: any property, call,
// iteration or comparison gives the same harmless value, so a test body runs to its end.
// A call or `new` of an import records its leading string.
function standIn(name) {
  const record = (callArgs) => {
    if (name !== null && recordInto && typeof callArgs[0] === 'string') {
      recordInto.push({ via: name, text: callArgs[0], options: callArgs[1] });
    }
    return anything;
  };
  return new Proxy(function () {}, {
    get: (_, key) => {
      if (key === Symbol.toPrimitive) return () => 0;
      if (key === Symbol.iterator) return function* () {};
      if (key === 'then') return undefined;
      return anything;
    },
    apply: (_, __, callArgs) => record(callArgs),
    construct: (_, callArgs) => record(callArgs),
  });
}

const anything = standIn(null);
const recorders = new Map();
function recorder(name) {
  if (!recorders.has(name)) recorders.set(name, standIn(name));
  return recorders.get(name);
}

const tests = [];
let currentFile = '';
globalThis.__stress = new Proxy(
  {
    describe: (_, body) => body(),
    it: (name, body) => tests.push({ file: currentFile, name, body }),
    expect: (value) => {
      if (typeof value === 'function') {
        try {
          value();
        } catch {}
      }
      return anything;
    },
  },
  { get: (target, key) => target[key] ?? recorder(key) }
);

function bindings(list) {
  return list
    .split(',')
    .map((name) => name.trim())
    .filter(Boolean)
    .map((name) => name.replace(/\s+as\s+/, ': '))
    .join(', ');
}

// Nesting that pele's stress tests leave out, each deep enough to exhaust typst's call depth
// through any recursion that follows it.
const DEEP = 3000;
const deepObject = '{"a":'.repeat(DEEP) + '1' + '}'.repeat(DEEP);
const deepArray = '['.repeat(DEEP) + ']'.repeat(DEEP);
const NESTING = [
  ['init directive of nested objects', { text: `%%{init: {"x":${deepObject},"flowchart":{"wrappingWidth":10}}}%%\ngraph TD\nA-->B\n` }],
  ['init directive of nested arrays', { text: `%%{init: {"x":${deepArray}}}%%\ngraph TD\nA-->B\n` }],
  ['sequence properties of nested objects', { text: `sequenceDiagram\nparticipant A\nproperties A: {"x":${deepObject}}\nA->>A: x\n` }],
  ['sequence links of nested arrays', { text: `sequenceDiagram\nparticipant A\nlinks A: ${deepArray}\nA->>A: x\n` }],
  ['label of nested tags', { text: `graph TD\nA["${'<b>'.repeat(DEEP)}x${'</b>'.repeat(DEEP)}"]\n` }],
  ['label of nested emphasis', { text: 'graph TD\nA["`' + '**a _b '.repeat(DEEP) + 'x' + ' b_ a**'.repeat(DEEP) + '`"]\n' }],
  ['config option of nested objects', { text: 'graph TD\nA-->B\n', options: { config: JSON.parse(`{"x":${deepObject}}`) } }],
  // pele writes this one with String(), whose recursion runs out of V8's stack at a depth that varies
  // with the platform and the process, about 2,750 with node 24 on arm64 macOS, while the port writes
  // it to the end, so the cases stay at depths where pele's String() still gets through.
  ['legend position of 1,000 nested arrays', { text: legendPosition(1000) }],
  ['legend position of 2,000 nested arrays', { text: legendPosition(2000) }],
];

function legendPosition(depth) {
  return `%%{init: {"pie": {"legendPosition": ${'['.repeat(depth)}"left"${']'.repeat(depth)}}}}%%\npie\n"a": 1\n`;
}

async function collect() {
  // Files rather than data: URLs, whose decoding in node overflows the small stacks --stack-sizes asks for.
  const dir = mkdtempSync(join(tmpdir(), 'pele-stress-tests-'));
  try {
    for (const [i, file] of stressFiles().entries()) {
      currentFile = relative(peleRoot, file);
      const code = stripTypeScriptTypes(readFileSync(file, 'utf8')).replace(
        /^import\s*\{([^}]*)\}\s*from\s*'[^']*';?/gm,
        (_, list) => `const { ${bindings(list)} } = globalThis.__stress;`
      );
      const module = join(dir, `${i}.mjs`);
      writeFileSync(module, code);
      await import(pathToFileURL(module).href);
    }
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
  for (const [name, { text, options = {} }] of NESTING) {
    tests.push({ file: 'nesting', name, body: () => recorder('render')(text, { limit: Infinity, ...options }) });
  }
  const inputs = [];
  const seen = new Set();
  const optionIds = new Map();
  for (const test of tests) {
    const label = `${test.file} > ${test.name}`;
    if (filters.length > 0 && !filters.some((filter) => label.includes(filter))) continue;
    recordInto = [];
    try {
      test.body();
    } catch {}
    for (const call of recordInto) {
      const given = givenOptions(call);
      // Options are told apart by identity, not by their JSON, which a small --stack-size cannot
      // write for deeply nested ones.
      if (!optionIds.has(given)) optionIds.set(given, optionIds.size);
      const key = `${call.text}\u0000${optionIds.get(given)}`;
      if (seen.has(key)) continue;
      seen.add(key);
      inputs.push({ label: `${label} (${call.via})`, text: call.text, options: optionsFor(given) });
    }
    recordInto = null;
  }
  return inputs;
}

const NO_OPTIONS = {};
// Text given to an internal entry is often longer than the default limit of a whole diagram.
const INTERNAL_OPTIONS = { limit: Infinity, maxEdges: Infinity };

function givenOptions({ via, options }) {
  return via === 'render' || via === 'parse' ? (options ?? NO_OPTIONS) : INTERNAL_OPTIONS;
}

// Options a JSON object can carry. The measurer is dropped because the plugin always measures
// with pele's metrics, as pele does in node without one. Infinity has no JSON form; the largest
// double compares the same against any length or count.
function optionsFor(given) {
  const out = {};
  for (const [key, value] of Object.entries(given)) {
    if (key === 'measurer' || key === 'icons' || key === 'math') continue;
    if (value instanceof Date) out[key] = value.getTime();
    else if (value === Infinity) out[key] = Number.MAX_VALUE;
    else out[key] = value;
  }
  out.now ??= NOW;
  return out;
}

function errorOutcome(error) {
  if (error.name === 'PeleError') return { kind: error.code, message: error.message };
  return { kind: 'other', message: `${error.name}: ${error.message}` };
}

const { render: peleRender } = await import(pathToFileURL(join(peleRoot, 'dist/pele.js')).href);

function peleOutcome({ text, options }) {
  const started = performance.now();
  let outcome = { kind: 'ok' };
  try {
    peleRender(text, options);
  } catch (error) {
    outcome = errorOutcome(error);
  }
  return { ...outcome, ms: Math.round(performance.now() - started) };
}

// The plugin under node, held to typst's call depth.
function nodeHost() {
  const plugin = loadPlugin(wasmPath, { callDepthLimit: TYPST_CALL_DEPTH });
  return async ({ text, options }) => {
    try {
      const { code, result, depth } = plugin.call(Buffer.from(text), Buffer.from(JSON.stringify(options)));
      const outcome = code === 0 ? { kind: 'ok' } : errorOutcome(JSON.parse(result).error);
      return { ...outcome, depth };
    } catch (error) {
      return { kind: 'trap', message: String(error) };
    }
  };
}

// The plugin under typst itself, to confirm what the node host emulates.
function typstHost() {
  const dir = mkdtempSync(join(tmpdir(), 'pele-stress-'));
  writeFileSync(join(dir, 'plugin.wasm'), fixAllocator(readFileSync(wasmPath)));
  process.on('exit', () => rmSync(dir, { recursive: true, force: true }));
  let next = 0;
  return async ({ text, options }) => {
    const id = next++;
    writeFileSync(join(dir, `${id}.mmd`), text);
    writeFileSync(join(dir, `${id}.json`), JSON.stringify(options));
    writeFileSync(
      join(dir, `${id}.typ`),
      `#let p = plugin("plugin.wasm")\n#p.render(read("${id}.mmd", encoding: none), read("${id}.json", encoding: none)).len()\n`
    );
    const stderr = await new Promise((resolve) => {
      const args = ['compile', '--root', dir, join(dir, `${id}.typ`), join(dir, `${id}.pdf`)];
      execFile(typst, args, { maxBuffer: 1 << 26 }, (_, __, text) => resolve(text));
    });
    for (const suffix of ['mmd', 'json', 'typ', 'pdf']) rmSync(join(dir, `${id}.${suffix}`), { force: true });
    const errored = /plugin errored with: (.*)/.exec(stderr);
    if (errored) return errorOutcome(JSON.parse(errored[1]).error);
    const panicked = /plugin panicked: (.*)/.exec(stderr);
    if (panicked) return { kind: 'trap', message: panicked[1] };
    if (/error:/.test(stderr)) return { kind: 'host', message: stderr };
    return { kind: 'ok' };
  };
}

async function timed(run) {
  const started = performance.now();
  const outcome = await run();
  return { ...outcome, ms: Math.round(performance.now() - started) };
}

const inputs = await collect();
if (peleOnly) {
  process.stdout.write(JSON.stringify(inputs.map((input) => peleOutcome(input).kind)));
  process.exit(0);
}

const expected = inputs.map(peleOutcome);
const host = typst ? typstHost() : nodeHost();
const got = new Array(inputs.length);
let cursor = 0;
await Promise.all(
  Array.from({ length: typst ? jobs : 1 }, async () => {
    while (cursor < inputs.length) {
      const i = cursor++;
      got[i] = await timed(() => host(inputs[i]));
    }
  })
);

const firstLine = (outcome) => (outcome.message ? ` (${outcome.message.split('\n')[0]})` : '');
const totals = { pass: 0, fail: 0, trap: 0 };
for (const [i, input] of inputs.entries()) {
  const want = expected[i];
  let kind = 'pass';
  if (got[i].kind === 'trap') kind = 'trap';
  else if (got[i].kind !== want.kind) kind = 'fail';
  totals[kind]++;
  const detail = kind === 'pass' ? firstLine(want) : `: pele ${want.kind}${firstLine(want)}, plugin ${got[i].kind}${firstLine(got[i])}`;
  const depth = got[i].depth === undefined ? '' : ` depth ${got[i].depth}`;
  console.log(`${kind.toUpperCase()} [${want.kind}] ${input.label} pele ${want.ms}ms plugin ${got[i].ms}ms${depth}${detail}`);
}

if (!typst) {
  const deepest = [...inputs.keys()].filter((i) => got[i].depth !== undefined).sort((a, b) => got[b].depth - got[a].depth);
  console.log(`\ndeepest calls, of the ${TYPST_CALL_DEPTH} frames typst allows:`);
  for (const i of deepest.slice(0, 5)) console.log(`  ${got[i].depth} ${inputs[i].label}`);
}

let dependent = 0;
for (const size of stackSizes) {
  const json = execFileSync(process.execPath, [`--stack-size=${size}`, self, '--pele-outcomes', ...filters], {
    maxBuffer: 1 << 26,
  });
  for (const [i, kind] of JSON.parse(json).entries()) {
    if (kind === expected[i].kind) continue;
    dependent++;
    console.log(`STACK ${size}KB ${inputs[i].label}: pele ${kind} instead of ${expected[i].kind}`);
  }
}

console.log(`\ntotal ${totals.pass}/${inputs.length} passed, ${totals.fail} failed, ${totals.trap} trapped`);
if (stackSizes.length > 0) console.log(`${dependent} outcomes of pele depend on the stack size`);
process.exit(totals.fail + totals.trap > 0 ? 1 : 0);

