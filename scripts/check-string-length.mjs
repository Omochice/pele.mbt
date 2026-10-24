// Renders diagrams whose SVG is hundreds of millions of code units long, through the wasm plugin and
// through pele's dist bundle, and checks that the plugin answers as pele does.
// A drawing up to the port's hold limit must come out byte for byte as pele's, however far past
// what a doubling StringBuilder could hold it is, and one past it must fail with the port's own
// limit error; an error pele gives must be given as it is.
// Each drawing is also rendered through the theme typst sends, which has to answer without trapping.
// A case's options are written as the plugin's JSON, and pele is given the callbacks they stand for.
//
// Usage: node scripts/check-string-length.mjs [diagram ...]
// Build the plugin first with `moon build --target wasm --release`.
// Run it inside `nix develop`, which sets PELE_ROOT to the built pele whose dist/ it reads.
// Each input makes pele and the plugin produce hundreds of millions of characters, so a case takes
// half a minute or more, and the plugin may grow its memory to 4 GiB.
// Node's default heap holds every case but some of the journey, quadrant, railroad, timeline,
// usecase and xychart ones, where pele itself needs more, so those diagrams are checked under
// NODE_OPTIONS=--max-old-space-size=20480.

import { constants } from 'node:buffer';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { isDeepStrictEqual } from 'node:util';
import { peleRoot } from './pele-root.mjs';
import { loadPlugin } from './plugin-host.mjs';
import { peleOptions } from './plugin-options.mjs';
import { CASES } from './string-length-cases.mjs';

// pele reads dates in the host's time zone and the plugin in UTC, as the golden fixtures are made.
process.env.TZ = 'UTC';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const wasmPath = join(root, '_build/wasm/release/build/Omochice/pele-typst/plugin/plugin.wasm');

// The longest drawing among the cases, which pele draws only where strings are as long as 64-bit
// V8 makes them; with shorter ones pele fails it on the engine's limit, which the port does not imitate.
const LONGEST_DRAWING = 535038344;
if (constants.MAX_STRING_LENGTH < LONGEST_DRAWING) {
  console.error(`node ${process.version} allows strings of ${constants.MAX_STRING_LENGTH} characters, fewer than ${LONGEST_DRAWING}`);
  process.exit(1);
}

const requested = process.argv.slice(2);
const cases = requested.length > 0 ? CASES.filter(([diagram]) => requested.includes(diagram)) : CASES;
const { render } = await import(pathToFileURL(join(peleRoot, 'dist/pele.js')).href);
const plugin = loadPlugin(wasmPath);

function outcome(error) {
  return { name: error.name, code: error.code ?? null, message: error.message, type: error.type ?? null, mermaidType: error.mermaidType ?? null };
}

// The most code units the wasm port holds, as pele/src/svg/markup.mbt's HOLD_LIMIT; past it the port
// returns its own limit error where pele still draws, the one platform-imposed difference from pele.
const HOLD_LIMIT = 400000000;

function peleOutcome(text, options) {
  try {
    const result = render(text, peleOptions(options));
    return { svgLength: result.svg.length, svg: Buffer.from(result.svg), type: result.type, mermaidType: result.mermaidType };
  } catch (error) {
    return outcome(error);
  }
}

// The port's own limit error for a drawing past its hold limit, tagged like the drawing.
function portLimit(type, mermaidType) {
  return {
    name: 'PeleError',
    code: 'limit',
    message: `Diagram output is too large for the wasm port: it would hold more than ${HOLD_LIMIT} code units, the most the port can hold at once.`,
    type,
    mermaidType,
  };
}

// The SVG of a drawing's answer, unescaped from its JSON string as UTF-8 bytes.
// An answer can be longer than the longest string node makes, so it is read as bytes rather than parsed.
function svgOfAnswer(bytes) {
  const opening = Buffer.from('{"svg":"');
  const out = Buffer.alloc(bytes.length);
  let o = 0;
  let i = opening.length;
  for (; bytes[i] !== 0x22; i++) {
    if (bytes[i] !== 0x5c) {
      out[o++] = bytes[i];
      continue;
    }
    i++;
    const escape = String.fromCharCode(bytes[i]);
    if (escape === 'u') {
      out[o++] = parseInt(bytes.subarray(i + 1, i + 5).toString('latin1'), 16);
      i += 4;
    } else {
      out[o++] = { n: 10, r: 13, t: 9, b: 8, f: 12 }[escape] ?? bytes[i];
    }
  }
  const svg = out.subarray(0, o);
  let svgLength = 0;
  for (const b of svg) {
    if ((b & 0xc0) !== 0x80) svgLength += b >= 0xf0 ? 2 : 1;
  }
  return { svgLength, svg };
}

function pluginOutcome(text, options) {
  try {
    const { code, bytes, memory } = plugin.call(Buffer.from(text), Buffer.from(JSON.stringify(options)));
    const mib = Math.round(memory / 2 ** 20);
    if (code !== 0) return { ...outcome(JSON.parse(bytes.toString('utf8')).error), mib };
    return { ...svgOfAnswer(bytes), mib };
  } catch (error) {
    return { trap: String(error) };
  }
}

function summary(result) {
  const { svg, mib, ...rest } = result;
  return JSON.stringify(rest);
}

console.log(`node ${process.version} ${process.arch}, longest string ${constants.MAX_STRING_LENGTH}`);
let failed = 0;
for (const [diagram, name, text, options] of cases) {
  const want = peleOutcome(text, options);
  const got = pluginOutcome(text, options);
  let pass;
  let band;
  let note = `plugin memory grown to ${got.mib} MiB`;
  const { mib, ...error } = got;
  if (!want.svg) {
    band = 'pele errors';
    pass = isDeepStrictEqual(want, error);
  } else if (want.svgLength <= HOLD_LIMIT) {
    band = 'pele draws, within the port';
    pass = got.svg !== undefined && got.svg.equals(want.svg);
    const themed = pluginOutcome(text, { ...options, theme: {} });
    if (themed.trap || themed.code !== undefined) pass = false;
    note += `, through the theme ${themed.trap ?? `${themed.mib} MiB`}`;
  } else {
    band = 'pele draws, past the port';
    pass = isDeepStrictEqual(portLimit(want.type, want.mermaidType), error);
  }
  if (!pass) failed++;
  console.log(`${pass ? 'PASS' : 'FAIL'} ${diagram}: ${name} (${band}): pele ${summary(want)}${pass ? '' : `, plugin ${summary(got)}`}; ${note}`);
}
console.log(`\ntotal ${cases.length - failed}/${cases.length} passed`);
process.exit(failed > 0 ? 1 : 0);
