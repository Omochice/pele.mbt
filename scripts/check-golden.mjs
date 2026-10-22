// Renders every golden source of the ported diagrams through the wasm plugin and compares the
// result with pele's output byte for byte.
//
// Usage: node scripts/check-golden.mjs [diagram ...]
// Build the plugin first with `moon build --target wasm --release`.

import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { isDeepStrictEqual } from 'node:util';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const goldenDir = join(root, 'golden');
const wasmPath = join(root, '_build/wasm/release/build/plugin/plugin.wasm');

// Diagrams whose goldens are expected to pass. The others are reported as skipped, not failed,
// so the list grows as diagrams are ported.
const PORTED = ['cynefin', 'flowchart', 'git', 'info', 'ishikawa', 'journey', 'kanban', 'mindmap', 'packet', 'pie', 'quadrant', 'radar', 'railroad', 'sankey', 'timeline', 'treemap', 'treeview', 'venn'];

const requested = process.argv.slice(2);
const diagrams = requested.length > 0 ? requested : PORTED;
const manifest = JSON.parse(readFileSync(join(goldenDir, 'manifest.json'), 'utf8'));
const profiles = Object.entries(manifest.profiles).map(([name, options]) => ({
  name,
  optionBytes: Buffer.from(JSON.stringify(options)),
}));

if (!existsSync(wasmPath)) {
  console.error(`missing ${wasmPath}; run \`moon build --target wasm --release\` first`);
  process.exit(1);
}
const module = new WebAssembly.Module(readFileSync(wasmPath));
const foreign = WebAssembly.Module.imports(module).filter((i) => i.module !== 'typst_env');
if (foreign.length > 0) {
  console.error('the plugin imports more than typst_env:', foreign);
  process.exit(1);
}

// A fresh instance per call, because a trapped instance is left in an undefined state.
function call(source, optionBytes) {
  const args = Buffer.concat([source, optionBytes]);
  let instance;
  let result;
  const memory = () => new Uint8Array(instance.exports.memory.buffer);
  instance = new WebAssembly.Instance(module, {
    typst_env: {
      wasm_minimal_protocol_write_args_to_buffer: (ptr) => memory().set(args, ptr),
      wasm_minimal_protocol_send_result_to_host: (ptr, len) => {
        result = Buffer.from(memory().slice(ptr, ptr + len)).toString('utf8');
      },
    },
  });
  const code = instance.exports.render(source.length, optionBytes.length);
  return { code, result };
}

function excerpt(text, at) {
  return JSON.stringify(text.slice(Math.max(0, at - 30), at + 50));
}

function firstDifference(expected, actual) {
  let i = 0;
  while (i < expected.length && i < actual.length && expected[i] === actual[i]) i++;
  return `at ${i}: expected ${excerpt(expected, i)}, got ${excerpt(actual, i)}`;
}

// Files without a profile-specific variant are shared with the default profile.
function expectedStem(id, dir, profile) {
  if (profile === 'default') return id;
  return existsSync(join(dir, `${id}.${profile}.json`)) ? `${id}.${profile}` : id;
}

function compare(id, dir, profile) {
  const stem = expectedStem(id, dir, profile.name);
  const source = readFileSync(join(dir, `${id}.mmd`));
  const expected = JSON.parse(readFileSync(join(dir, `${stem}.json`), 'utf8'));
  let outcome;
  try {
    outcome = call(source, profile.optionBytes);
  } catch (error) {
    if (error instanceof WebAssembly.RuntimeError) return { kind: 'trap', detail: error.message };
    throw error;
  }
  let actual;
  try {
    actual = JSON.parse(outcome.result);
  } catch {
    return { kind: 'fail', detail: `result is not JSON: ${JSON.stringify(String(outcome.result).slice(0, 80))}` };
  }
  if (expected.error) {
    if (outcome.code !== 1) return { kind: 'fail', detail: `expected an error, got status ${outcome.code}` };
    if (!isDeepStrictEqual(actual.error, expected.error)) {
      return { kind: 'fail', detail: `error differs: expected ${JSON.stringify(expected.error)}, got ${JSON.stringify(actual.error)}` };
    }
    return { kind: 'pass' };
  }
  if (outcome.code !== 0) return { kind: 'fail', detail: `expected success, got ${JSON.stringify(actual.error ?? actual)}` };
  const svg = readFileSync(join(dir, `${stem}.svg`), 'utf8');
  if (actual.svg !== svg) return { kind: 'fail', detail: `svg differs ${firstDifference(svg, String(actual.svg))}` };
  for (const key of ['type', 'mermaidType', 'width', 'height', 'links']) {
    if (!isDeepStrictEqual(actual[key], expected[key])) {
      return { kind: 'fail', detail: `${key} differs: expected ${JSON.stringify(expected[key])}, got ${JSON.stringify(actual[key])}` };
    }
  }
  return { kind: 'pass' };
}

const totals = { pass: 0, fail: 0, trap: 0 };
const perProfile = [];
for (const entry of readdirSync(goldenDir, { withFileTypes: true })) {
  if (!entry.isDirectory()) continue;
  if (!diagrams.includes(entry.name)) {
    console.log(`skip ${entry.name} (not ported)`);
    continue;
  }
  const dir = join(goldenDir, entry.name);
  const ids = readdirSync(dir)
    .filter((f) => f.endsWith('.mmd'))
    .map((f) => f.slice(0, -4))
    .sort();
  for (const profile of profiles) {
    const tally = { label: `${entry.name} ${profile.name}`, pass: 0, total: 0 };
    perProfile.push(tally);
    for (const id of ids) {
      const { kind, detail } = compare(id, dir, profile);
      totals[kind]++;
      tally.total++;
      if (kind === 'pass') tally.pass++;
      console.log(`${kind.toUpperCase()} ${entry.name} ${profile.name}/${id}${detail ? `: ${detail}` : ''}`);
    }
  }
}
console.log();
for (const { label, pass, total } of perProfile) console.log(`${label} ${pass}/${total}`);
const total = totals.pass + totals.fail + totals.trap;
console.log(`\ntotal ${totals.pass}/${total} passed, ${totals.fail} failed, ${totals.trap} trapped`);
process.exit(totals.fail + totals.trap > 0 ? 1 : 0);
