import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { peleCommit, peleRoot } from './pele-root.mjs';
import { peleOptions } from './plugin-options.mjs';

// Gantt floors axis ticks to local midnight, so the host's time zone would leak into the goldens.
// UTC is pinned because the wasm plugin has no time zone of its own.
process.env.TZ = 'UTC';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const goldenDir = join(root, 'golden');
const { detectType, render } = await import(join(peleRoot, 'dist/pele.js'));
const pele = { version: JSON.parse(readFileSync(join(peleRoot, 'package.json'), 'utf8')).version, commit: peleCommit() };

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

// 400 is below directionBreakpoint, so both width fitting and the automatic direction turn are exercised.
const narrow = { ...options, maxWidth: 400 };

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

// The string literals of a test file whose source text passes `accept`, with their escapes evaluated.
function* stringLiterals(src, accept) {
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

// Port of loadCorpus in pele's tests/support/corpus.ts, with paths anchored to the pele root.
function loadCorpus(diagram, keyword) {
  const seeds = new Set();
  const dir = join(peleRoot, 'tests/compat', diagram);
  for (const file of readdirSync(dir).filter((f) => /\.spec\.[jt]s$/.test(f))) {
    for (const seed of stringLiterals(readFileSync(join(dir, file), 'utf8'), (raw) => keyword.test(raw))) seeds.add(seed);
  }
  for (const sample of JSON.parse(readFileSync(join(peleRoot, 'tests/corpus', `${diagram}-docs.json`), 'utf8'))) {
    seeds.add(sample);
  }
  for (const seed of mathSeeds[diagram] ?? []) seeds.add(seed);
  return [...seeds];
}

// The directory of each pele diagram type whose name differs from it.
const directoryOf = { gitGraph: 'git', quadrantChart: 'quadrant', treeView: 'treeview' };

// No compat spec puts $$ in a diagram that typesets math, so a math resolver would never be asked
// for anything. The sources of pele's math render test are added, each under the diagram pele detects.
function loadMathSeeds() {
  const seeds = {};
  const src = readFileSync(join(peleRoot, 'tests/render/math.test.ts'), 'utf8');
  for (const seed of stringLiterals(src, (raw) => raw.includes('$$'))) {
    let type;
    try {
      type = detectType(seed);
    } catch {
      continue;
    }
    if (type === null) continue;
    (seeds[directoryOf[type] ?? type] ??= []).push(seed);
  }
  return seeds;
}

const mathSeeds = loadMathSeeds();

// agentflow-reference.json holds objects ({ src, model, ... }), not plain strings,
// so it is not part of the corpus.

const json = (value) => JSON.stringify(value, null, 2) + '\n';

function outcomeOf(source, opts, label) {
  try {
    const r = render(source, opts);
    return { svg: r.svg, meta: { type: r.type, mermaidType: r.mermaidType, width: r.width, height: r.height, links: r.links } };
  } catch (e) {
    if (e?.name !== 'PeleError') {
      console.warn(`warning: ${label} threw non-PeleError ${e?.constructor?.name}: ${e?.message}`);
    }
    return {
      meta: {
        error: {
          name: e?.name === 'PeleError' ? 'PeleError' : (e?.constructor?.name ?? typeof e),
          code: e?.code ?? null,
          message: String(e?.message ?? e),
          type: e?.type ?? null,
          mermaidType: e?.mermaidType ?? null,
        },
      },
    };
  }
}

function writeOutcome(path, outcome) {
  if (outcome.svg !== undefined) writeFileSync(path + '.svg', outcome.svg);
  writeFileSync(path + '.json', json(outcome.meta));
}

const corpora = Object.entries(diagrams).map(([diagram, keyword]) => [diagram, loadCorpus(diagram, keyword)]);

// Every icon name and every TeX string with its font sizes that pele asks the resolvers for over the
// whole corpus, while `icons` and `math` answer them.
function requests(opts, icons, math) {
  const names = new Set();
  const texts = new Map();
  const recording = {
    ...opts,
    icons: (name) => {
      names.add(name);
      return icons(name);
    },
    math: (tex, size) => {
      if (!texts.has(tex)) texts.set(tex, new Set());
      texts.get(tex).add(size);
      return math(tex, size);
    },
  };
  for (const [, sources] of corpora) {
    for (const source of sources) {
      try {
        render(source, recording);
      } catch {
        continue;
      }
    }
  }
  return { names, texts };
}

const escXml = (text) => text.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);
const byCodeUnit = (a, b) => (a < b ? -1 : a > b ? 1 : 0);

// Resolvers that answer everything, so that no request is skipped because an earlier one went unanswered.
const asked = requests(options, () => '<path/>', () => ({ svg: '', width: 1, height: 1 }));

// Every name resolves: pele draws an icon its resolver returns null for exactly as it does without a
// resolver, so a null entry would test nothing the default profile does not.
// Each fragment carries its name, so a fragment drawn for the wrong name shows in the SVG.
const iconMap = Object.fromEntries(
  [...asked.names].sort(byCodeUnit).map((name) => [name, `<path data-name="${escXml(name)}" d="M4,4H20V20H4Z"/>`])
);

// Every fifth TeX string stays unresolved, because with a resolver present pele lays such a label out
// on its math path even though it draws the TeX as text.
// SVG and HTML markup alternate by TeX length, and the heights reach past a line so that labels grow.
const mathMap = Object.fromEntries(
  [...asked.texts.keys()].sort(byCodeUnit).map((tex, i) => {
    if (i % 5 === 4) return [tex, null];
    const sizes = [...asked.texts.get(tex)].sort((a, b) => a - b);
    return [
      tex,
      Object.fromEntries(
        sizes.map((size) => {
          const width = (size * (tex.length + 2)) / 4;
          const height = (size * (5 + (tex.length % 4))) / 4;
          const markup =
            tex.length % 2 === 0
              ? { svg: `<path data-tex="${escXml(tex)}" d="M0,0H${width}"/>` }
              : { html: `<span data-tex="${escXml(tex)}">${escXml(tex)}</span>` };
          return [String(size), { ...markup, width, height }];
        })
      ),
    ];
  })
);

function asciiAdvances(advance, space) {
  const advances = {};
  for (let c = 32; c < 127; c++) advances[String.fromCharCode(c)] = c === 32 ? space : advance;
  return advances;
}

// A monospace-like table far from Arial, in 2048 units per em as many TrueType fonts are.
// Italic and mono differ from regular because pele's built-in table ignores italic and fixes mono at
// 600, so only a table where they matter catches a port that drops those style bits.
// Bold italic and the bold and italic mono styles are left out to exercise the fallback to style 0.
const metricsMeasurer = {
  unitsPerEm: 2048,
  styles: {
    0: { advances: { ...asciiAdvances(1229, 820), '…': 2048, '中': 1800 }, default: 1300, wide: 2048 },
    1: { advances: asciiAdvances(1352, 900), default: 1400, wide: 2200 },
    2: { advances: asciiAdvances(1180, 800), default: 1250 },
    4: { advances: asciiAdvances(1100, 1100), default: 1100, wide: 2200 },
  },
};

const profiles = {
  default: options,
  narrow,
  icons: { ...options, icons: iconMap },
  math: { ...options, math: mathMap },
  metrics: { ...options, measurer: metricsMeasurer },
  mono: { ...options, monospace: ['members', 'attributes', 'files', 'messages'] },
};
// What a comparison tool reads back from the manifest is what the goldens are rendered from.
const stored = JSON.parse(JSON.stringify(profiles));
const rendering = Object.fromEntries(Object.entries(stored).map(([name, profile]) => [name, peleOptions(profile)]));

// A map built from one pass must answer every request of a pass that uses it, since an answer can change
// the layout and with it what is asked next.
{
  const check = requests(rendering.default, rendering.icons.icons, rendering.math.math);
  const missing = [...check.names].filter((name) => !Object.hasOwn(iconMap, name));
  for (const [tex, sizes] of check.texts) {
    for (const size of sizes) {
      if (!Object.hasOwn(mathMap, tex) || (mathMap[tex] !== null && !Object.hasOwn(mathMap[tex], String(size)))) {
        missing.push(`$$${tex}$$ at ${size}`);
      }
    }
  }
  if (missing.length > 0) throw new Error(`the icon and math maps miss ${missing.join(', ')}`);
}

const variants = Object.keys(profiles).filter((name) => name !== 'default');

mkdirSync(goldenDir, { recursive: true });
for (const entry of readdirSync(goldenDir, { withFileTypes: true }).filter((e) => e.name !== 'README.md')) {
  rmSync(join(goldenDir, entry.name), { recursive: true, force: true });
}
const counts = {};
for (const [diagram, sources] of corpora) {
  const outDir = join(goldenDir, diagram);
  mkdirSync(outDir, { recursive: true });
  const count = { total: 0, ok: 0, error: 0 };
  for (const name of variants) count[name] = 0;
  for (const source of sources) {
    const id = createHash('sha256').update(source).digest('hex').slice(0, 16);
    const base = join(outDir, id);
    writeFileSync(base + '.mmd', source);
    count.total++;
    const outcome = outcomeOf(source, rendering.default, `${diagram}/${id}`);
    writeOutcome(base, outcome);
    if (outcome.meta.error) count.error++;
    else count.ok++;
    for (const name of variants) {
      const variant = outcomeOf(source, rendering[name], `${diagram}/${id} (${name})`);
      if (JSON.stringify(variant) !== JSON.stringify(outcome)) {
        writeOutcome(`${base}.${name}`, variant);
        count[name]++;
      }
    }
  }
  counts[diagram] = count;
}

writeFileSync(
  join(goldenDir, 'manifest.json'),
  json({
    pele,
    timeZone: process.env.TZ,
    profiles,
    diagrams: counts,
  })
);
