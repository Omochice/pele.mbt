// Renders init directives nested around the depth where pele's config merge runs out of stack, each
// through pele's dist bundle in a fresh node process and through the wasm plugin, and compares the
// results byte for byte as check-golden does.
//
// Usage: node scripts/check-merge-depth.mjs [--measure [--runs <n>]]
// Build the plugin first with `moon build --target wasm --release`.
// PELE_ROOT points at a pele checkout with dist/ when vendor/pele is not initialized.
// With --measure, the plugin is left out and the deepest nesting pele merges is found by bisection,
// with every probe rendered <n> times (1 by default).
//
// pele's merge recurses, and where it stops depends on how much stack is left for it. A process
// that has rendered before may run the merge compiled with smaller frames and reach deeper, so
// these inputs cannot join the goldens, which one warm process renders. The arguments and the
// environment of a process take stack too, so each input is rendered by scripts/pele-render.mjs in
// a fresh process with an empty environment, the repository as its working directory, and nothing
// on its command line but that script's relative path.
// The bound the port reproduces is MERGE_MAX_DEPTH in src/preprocess/preprocess.mbt.

import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { isDeepStrictEqual, parseArgs } from 'node:util';
import { TYPST_CALL_DEPTH } from './call-depth.mjs';
import { loadPlugin } from './plugin-host.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const peleRoot = resolve(process.env.PELE_ROOT ?? join(root, 'vendor/pele'));
const wasmPath = join(root, '_build/wasm/release/build/plugin/plugin.wasm');
const options = JSON.parse(readFileSync(join(root, 'golden/manifest.json'), 'utf8')).profiles.default;

const { values: flags } = parseArgs({
  options: { measure: { type: 'boolean', default: false }, runs: { type: 'string', default: '1' } },
});

const MERGE_MAX_DEPTH = 4468;
const objects = (n) => '{"a":'.repeat(n) + '1' + '}'.repeat(n);
const graph = 'graph TD\nA-->B\nA-->C\n';

// Each case takes the number of objects the merge descends through, counting the directive's own.
// The flowchart keys change the drawing, so whether each was merged shows in the SVG.
const CASES = [
  ['a key after the nesting', (depth) => `%%{init: {"x": ${objects(depth - 1)}, "flowchart": {"curve": "step"}}}%%\n${graph}`],
  ['a key before the nesting', (depth) => `%%{init: {"flowchart": {"curve": "step"}, "x": ${objects(depth - 1)}}}%%\n${graph}`],
  [
    'keys around the nesting in an object already merged',
    (depth) =>
      `%%{init: {"flowchart": {"curve": "basis"}}}%%\n` +
      `%%{init: {"flowchart": {"rankSpacing": 120, "x": ${objects(depth - 2)}, "nodeSpacing": 120}}}%%\n${graph}`,
  ],
  // JavaScript lists an object's array index keys first, so the nesting under "0" is merged first.
  ['a key written before nesting under an array index', (depth) => `%%{init: {"flowchart": {"curve": "step"}, "0": ${objects(depth - 1)}}}%%\n${graph}`],
  ['a directive after the nesting one', (depth) => `%%{init: {"x": ${objects(depth - 1)}}}%%\n%%{init: {"flowchart": {"curve": "step"}}}%%\n${graph}`],
];
const DEPTHS = [3000, MERGE_MAX_DEPTH - 1, MERGE_MAX_DEPTH, MERGE_MAX_DEPTH + 1, MERGE_MAX_DEPTH + 2, 7000];

function peleOutcome(text) {
  const json = execFileSync(process.execPath, ['scripts/pele-render.mjs'], {
    cwd: root,
    env: {},
    input: JSON.stringify({ peleRoot, options, text }),
    maxBuffer: 1 << 26,
    // A render takes a tenth of a second, and a stuck child should fail the check rather than hold it.
    timeout: 60000,
  });
  return JSON.parse(json);
}

if (flags.measure) {
  const runs = Number(flags.runs);
  const [, build] = CASES[0];
  const merged = peleOutcome(build(2)).svg;
  const merges = (depth) => {
    for (let i = 0; i < runs; i++) if (peleOutcome(build(depth)).svg !== merged) return false;
    return true;
  };
  let low = 2;
  let high = 20000;
  if (merges(high)) throw new Error(`pele merges ${high} objects`);
  while (high - low > 1) {
    const middle = (low + high) >> 1;
    if (merges(middle)) low = middle;
    else high = middle;
  }
  console.log(`pele merges ${low} objects and stops at ${high}`);
  process.exit(0);
}

const plugin = loadPlugin(wasmPath, { callDepthLimit: TYPST_CALL_DEPTH });
const optionBytes = Buffer.from(JSON.stringify(options));

function difference(expected, text) {
  let outcome;
  try {
    outcome = plugin.call(Buffer.from(text), optionBytes);
  } catch (error) {
    return `trapped: ${error.message}`;
  }
  const actual = JSON.parse(outcome.result);
  if (expected.error) return isDeepStrictEqual(actual.error, expected.error) ? null : `error ${JSON.stringify(actual.error ?? 'none')}`;
  if (outcome.code !== 0) return `error ${JSON.stringify(actual.error)}`;
  for (const key of ['svg', 'type', 'mermaidType', 'width', 'height', 'links']) {
    if (!isDeepStrictEqual(actual[key], expected[key])) return `${key} differs`;
  }
  return null;
}

let failed = 0;
for (const [name, build] of CASES) {
  for (const depth of DEPTHS) {
    const text = build(depth);
    const expected = peleOutcome(text);
    const seen = expected.error ? expected.error.code : createHash('sha256').update(expected.svg).digest('hex').slice(0, 12);
    const problem = difference(expected, text);
    if (problem) failed++;
    console.log(`${problem ? 'FAIL' : 'PASS'} ${name}, ${depth} objects: pele ${seen}${problem ? `, plugin ${problem}` : ''}`);
  }
}
console.log(`\n${CASES.length * DEPTHS.length - failed}/${CASES.length * DEPTHS.length} passed`);
process.exit(failed > 0 ? 1 : 0);
