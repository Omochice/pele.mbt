// Writes src/diagrams/flowchart/golden_cases_test.mbt: for every flowchart golden source, what pele's parse() makes of it under the default profile.
// A failure is written as its code, type and message, which must match the golden's; a success as a hash of the model's dump, which src/diagrams/flowchart/dump_test.mbt writes in the same form as `dump` below.
// Sources that pele detects as another diagram type are left out.
//
// Usage: [PELE_ROOT=<dir>] node scripts/gen-flowchart-golden-test.mjs [--dumps <dir>]
// With --dumps, each success's full dump is also written to <dir>/<id>.txt for comparing by eye.

import { mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const goldenDir = join(root, 'golden/flowchart');
const out = join(root, 'src/diagrams/flowchart/golden_cases_test.mbt');
// PELE_ROOT points at another checkout of pele, for a worktree whose submodule is not initialized.
const peleRoot = process.env.PELE_ROOT ?? join(root, 'vendor/pele');
const { parse } = await import(join(peleRoot, 'dist/pele.js'));
const manifest = JSON.parse(readFileSync(join(root, 'golden/manifest.json'), 'utf8'));
const profile = manifest.profiles.default;
const options = { limit: profile.limit, maxEdges: profile.maxEdges };

const dumpsAt = process.argv.indexOf('--dumps');
const dumps = dumpsAt >= 0 ? process.argv[dumpsAt + 1] : undefined;
if (dumps) mkdirSync(dumps, { recursive: true });

const q = (s) => '"' + s.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n').replace(/\r/g, '\\r') + '"';
const opt = (s) => (s === undefined ? '-' : q(s));
const list = (a) => (a === undefined ? '-' : '[' + a.map(q).join(',') + ']');
const num = (n) => (n === undefined ? '-' : String(n));
const json = (v) => {
  if (v === undefined) return '-';
  if (v === null) return 'null';
  if (typeof v === 'boolean' || typeof v === 'number') return String(v);
  if (typeof v === 'string') return q(v);
  if (Array.isArray(v)) return '[' + v.map(json).join(',') + ']';
  return '{' + Object.entries(v).map(([k, x]) => q(k) + ':' + json(x)).join(',') + '}';
};

function dump(db) {
  const lines = [`dir ${opt(db.direction)}`];
  if (db.title !== undefined) lines.push(`title ${q(db.title)}`);
  if (db.accTitle !== undefined) lines.push(`accTitle ${q(db.accTitle)}`);
  if (db.accDescr !== undefined) lines.push(`accDescr ${q(db.accDescr)}`);
  for (const n of db.nodes.values()) {
    lines.push(
      `node ${q(n.id)} text=${opt(n.text)} lt=${n.labelType} type=${opt(n.type)} styles=${list(n.styles)} classes=${list(n.classes)} dir=${opt(n.dir)} props=${json(n.props)} link=${opt(n.link)} target=${opt(n.linkTarget)} icon=${opt(n.icon)} form=${opt(n.form)} pos=${opt(n.pos)} img=${opt(n.img)} constraint=${opt(n.constraint)} w=${num(n.assetWidth)} h=${num(n.assetHeight)}`
    );
  }
  for (const e of db.edges) {
    lines.push(
      `edge ${q(e.start)} ${q(e.end)} id=${opt(e.id)} user=${e.isUserDefinedId} type=${opt(e.type)} text=${q(e.text)} lt=${e.labelType} stroke=${opt(e.stroke)} length=${num(e.length)} style=${list(e.style)} classes=${list(e.classes)} interpolate=${json(e.interpolate)} animate=${json(e.animate)} animation=${json(e.animation)}`
    );
  }
  for (const s of db.subgraphs) {
    lines.push(`subgraph ${q(s.id)} title=${q(s.title)} lt=${s.labelType} dir=${opt(s.dir)} nodes=${list(s.nodes)} classes=${list(s.classes)} metadata=${json(s.metadata)}`);
  }
  for (const c of db.classes.values()) lines.push(`class ${q(c.id)} styles=${list(c.styles)} text=${list(c.textStyles)}`);
  for (const [id, t] of db.tooltips) lines.push(`tooltip ${q(id)} ${q(t)}`);
  lines.push(`defaultStyle=${list(db.defaultEdgeStyle)} defaultInterpolate=${opt(db.defaultInterpolate)}`);
  return lines.join('\n');
}

// FNV-1a over UTF-16 code units, as `fnv1a` in src/diagrams/flowchart/golden_test.mbt.
function fnv1a(text) {
  let h = 0x811c9dc5;
  for (let i = 0; i < text.length; i++) {
    h ^= text.charCodeAt(i);
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return h.toString(16).padStart(8, '0');
}

// A MoonBit string literal; sources hold no lone surrogates.
function literal(s) {
  let r = '"';
  for (const ch of s) {
    const c = ch.codePointAt(0);
    if (ch === '"') r += '\\"';
    else if (ch === '\\') r += '\\\\';
    else if (ch === '\n') r += '\\n';
    else if (c < 0x20 || c > 0x7e) r += `\\u{${c.toString(16)}}`;
    else r += ch;
  }
  return r + '"';
}

const failureOf = (e) => `error ${e.code} ${e.type ?? 'null'} ${e.mermaidType ?? 'null'}\n${e.message}`;

const ids = readdirSync(goldenDir)
  .filter((f) => f.endsWith('.mmd'))
  .map((f) => f.slice(0, -4))
  .sort();
const rows = [];
let skipped = 0;
let renderErrors = 0;
for (const id of ids) {
  const source = readFileSync(join(goldenDir, `${id}.mmd`), 'utf8');
  const golden = JSON.parse(readFileSync(join(goldenDir, `${id}.json`), 'utf8'));
  let expected;
  try {
    const model = parse(source, options);
    if (model.type !== 'flowchart') {
      skipped++;
      continue;
    }
    expected = `ok ${fnv1a(dump(model))}`;
    if (dumps) writeFileSync(join(dumps, `${id}.txt`), dump(model) + '\n');
    if (golden.error) renderErrors++;
  } catch (e) {
    expected = failureOf(e);
    if (!golden.error || failureOf(golden.error) !== expected) {
      throw new Error(`${id}: pele's parse() disagrees with the golden: ${expected}`);
    }
  }
  rows.push(`  (${literal(id)}, ${literal(source)}, ${literal(expected)}),`);
}

writeFileSync(
  out,
  `// Generated by scripts/gen-flowchart-golden-test.mjs from golden/flowchart and pele ${manifest.pele.version}. Do not edit.

///|
/// Each flowchart golden's id, source, and what pele's parse() makes of it.
let golden_cases : Array[(String, String, String)] = [
${rows.join('\n')}
]
`
);
console.log(`${rows.length} cases written, ${skipped} sources of other diagram types left out, ${renderErrors} goldens fail only when drawn`);
