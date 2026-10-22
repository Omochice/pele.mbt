import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const peleRoot = join(root, 'vendor/pele');
const goldenDir = join(root, 'golden');
const { render } = await import(join(peleRoot, 'dist/pele.js'));

// Unset options are those whose default is "undefined means X":
// maxWidth (no width negotiation), responsive (derived from the diagram's useMaxWidth config),
// linkSchemes/imageSchemes (built-in scheme lists).
// `now` is fixed because gantt reads the current time otherwise, which would make goldens unstable.
const options = {
  fontFamily: 'sans-serif',
  fontFamilyMono: 'monospace',
  fontSize: 16,
  idPrefix: 'pele',
  padding: 8,
  autoDirection: true,
  directionBreakpoint: 640,
  limit: 50000,
  outputLimit: 4000000,
  maxEdges: 5000,
  links: true,
  images: true,
  linkRel: 'noopener',
  now: 1767225600000,
};

const diagrams = {
  agentflow: /agentflow-beta/,
  architecture: /architecture/,
  block: /block/,
  c4: /C4(?:Context|Container|Component|Dynamic|Deployment)/,
  class: /classDiagram/,
  cynefin: /cynefin-beta/,
  er: /erDiagram/,
  eventmodeling: /eventmodeling/,
  flowchart: /graph|flowchart/,
  gantt: /gantt/,
  git: /gitGraph/,
  info: /info/,
  ishikawa: /ishikawa/i,
  journey: /journey/,
  kanban: /kanban/,
  mindmap: /mindmap/,
  packet: /packet/,
  pie: /pie/,
  quadrant: /quadrant/i,
  radar: /radar/,
  railroad: /railroad-(?:ebnf-|abnf-|peg-)?beta/,
  requirement: /requirementDiagram/i,
  sankey: /sankey/i,
  sequence: /sequenceDiagram/i,
  state: /stateDiagram/,
  swimlane: /swimlane-beta/,
  timeline: /timeline/,
  treemap: /treemap/,
  treeview: /treeView-beta/,
  usecase: /usecase-beta/,
  venn: /venn-beta/,
  wardley: /wardley-beta/,
  xychart: /xychart/i,
};

// Port of loadCorpus in vendor/pele/tests/support/corpus.ts, with paths anchored to the pele root.
function loadCorpus(diagram, keyword) {
  const seeds = new Set();
  const dir = join(peleRoot, 'tests/compat', diagram);
  for (const file of readdirSync(dir).filter((f) => /\.spec\.[jt]s$/.test(f))) {
    const src = readFileSync(join(dir, file), 'utf8');
    for (const m of src.matchAll(/`((?:[^`\\]|\\.)*)`|'((?:[^'\\\n]|\\.)*)'|"((?:[^"\\\n]|\\.)*)"/g)) {
      const raw = m[1] ?? m[2] ?? m[3];
      if (!keyword.test(raw)) continue;
      try {
        seeds.add(new Function('return `' + raw.replace(/`/g, '\\`').replace(/\$\{/g, '\\${') + '`')());
      } catch {
        continue;
      }
    }
  }
  for (const sample of JSON.parse(readFileSync(join(peleRoot, 'tests/corpus', `${diagram}-docs.json`), 'utf8'))) {
    seeds.add(sample);
  }
  return [...seeds];
}

// agentflow-reference.json holds objects ({ src, model, ... }), not plain strings,
// so it is not part of the corpus.

const json = (value) => JSON.stringify(value, null, 2) + '\n';

mkdirSync(goldenDir, { recursive: true });
for (const entry of readdirSync(goldenDir, { withFileTypes: true }).filter((e) => e.name !== 'README.md')) {
  rmSync(join(goldenDir, entry.name), { recursive: true, force: true });
}
const counts = {};
for (const [diagram, keyword] of Object.entries(diagrams)) {
  const outDir = join(goldenDir, diagram);
  mkdirSync(outDir, { recursive: true });
  const count = { total: 0, ok: 0, error: 0 };
  for (const source of loadCorpus(diagram, keyword)) {
    const id = createHash('sha256').update(source).digest('hex').slice(0, 16);
    const base = join(outDir, id);
    writeFileSync(base + '.mmd', source);
    count.total++;
    try {
      const r = render(source, options);
      writeFileSync(base + '.svg', r.svg);
      writeFileSync(
        base + '.json',
        json({ type: r.type, mermaidType: r.mermaidType, width: r.width, height: r.height, links: r.links })
      );
      count.ok++;
    } catch (e) {
      if (e?.name !== 'PeleError') {
        console.warn(`warning: ${diagram}/${id} threw non-PeleError ${e?.constructor?.name}: ${e?.message}`);
      }
      writeFileSync(
        base + '.json',
        json({
          error: {
            name: e?.name === 'PeleError' ? 'PeleError' : (e?.constructor?.name ?? typeof e),
            code: e?.code ?? null,
            message: String(e?.message ?? e),
            type: e?.type ?? null,
            mermaidType: e?.mermaidType ?? null,
          },
        })
      );
      count.error++;
    }
  }
  counts[diagram] = count;
}

const pkg = JSON.parse(readFileSync(join(peleRoot, 'package.json'), 'utf8'));
writeFileSync(
  join(goldenDir, 'manifest.json'),
  json({
    pele: { version: pkg.version, commit: execFileSync('git', ['-C', peleRoot, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim() },
    node: process.version,
    options,
    diagrams: counts,
  })
);
