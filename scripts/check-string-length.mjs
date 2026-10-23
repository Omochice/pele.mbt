// Renders diagrams whose SVG outgrows the longest string V8 can make through the wasm plugin
// and through pele's dist bundle, and checks that both fail with the same error.
// pele's concatenation throws a RangeError there, which pele reports as a `limit` error, before
// its output limit is ever checked.
//
// Usage: node scripts/check-string-length.mjs
// Build the plugin first with `moon build --target wasm --release`.
// PELE_ROOT points at a pele checkout with dist/ when vendor/pele is not initialized.
// Each input makes pele and the plugin produce over half a billion characters, so a run takes a
// minute or more.

import { constants } from 'node:buffer';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { isDeepStrictEqual } from 'node:util';
import { loadPlugin } from './plugin-host.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const peleRoot = process.env.PELE_ROOT ?? join(root, 'vendor/pele');
const wasmPath = join(root, '_build/wasm/release/build/plugin/plugin.wasm');

// The maximum the port assumes; 32-bit V8 builds and other engines allow a different length,
// and pele's outcomes there are not the ones the port reproduces.
const V8_MAX_STRING_LENGTH = 536870888;
if (constants.MAX_STRING_LENGTH !== V8_MAX_STRING_LENGTH) {
  console.error(`node ${process.version} allows strings of ${constants.MAX_STRING_LENGTH} characters, not ${V8_MAX_STRING_LENGTH}`);
  process.exit(1);
}

const names = (prefix, count) => Array.from({ length: count }, (_, i) => `${prefix}${i}`);
const RAISED = { limit: Number.MAX_VALUE };

// The same inputs as src/diagrams/flowchart/string_length_test.mbt.
const CASES = [
  [
    'edges under the default options',
    `graph TD\nlinkStyle default stroke:#${'a'.repeat(49000)}\n${names('a', 60).join(' & ')} <--> ${names('b', 61).join(' & ')}\n`,
    {},
  ],
  ['nodes', `graph TD\nclassDef c fill:#${'a'.repeat(50000)}\n${names('n', 10700).map((name) => `${name}:::c`).join(';')}\n`, RAISED],
  [
    'nodes and edges only together',
    `graph TD\nclassDef default fill:#${'a'.repeat(50000)}\nlinkStyle default stroke:#${'a'.repeat(50000)}\n${names('n', 3600).join('-->')}\n`,
    RAISED,
  ],
];

const { render } = await import(pathToFileURL(join(peleRoot, 'dist/pele.js')).href);
const plugin = loadPlugin(wasmPath);

function outcome(error) {
  return { name: error.name, code: error.code ?? null, message: error.message, type: error.type ?? null, mermaidType: error.mermaidType ?? null };
}

function peleOutcome(text, options) {
  try {
    return { svgLength: render(text, options).svg.length };
  } catch (error) {
    return outcome(error);
  }
}

function pluginOutcome(text, options) {
  try {
    const { code, result } = plugin.call(Buffer.from(text), Buffer.from(JSON.stringify(options)));
    const json = JSON.parse(result);
    return code === 0 ? { svgLength: json.svg.length } : outcome(json.error);
  } catch (error) {
    return { trap: String(error) };
  }
}

console.log(`node ${process.version} ${process.arch}, longest string ${constants.MAX_STRING_LENGTH}`);
let failed = 0;
for (const [name, text, options] of CASES) {
  const want = peleOutcome(text, options);
  const got = pluginOutcome(text, options);
  const pass = isDeepStrictEqual(want, got);
  if (!pass) failed++;
  console.log(`${pass ? 'PASS' : 'FAIL'} ${name}: pele ${JSON.stringify(want)}${pass ? '' : `, plugin ${JSON.stringify(got)}`}`);
}
console.log(`\ntotal ${CASES.length - failed}/${CASES.length} passed`);
process.exit(failed > 0 ? 1 : 0);
