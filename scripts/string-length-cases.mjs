// The inputs scripts/check-string-length.mjs renders, as [diagram, name, source, options].
// Each diagram that can repeat a long string many times has a source just past V8's longest
// string, the same as its skipped test in src/diagrams/<diagram>/string_length_test.mbt.
// The diagrams missing here cannot: README.md under golden/ says why for each.

const names = (prefix, count) => Array.from({ length: count }, (_, i) => `${prefix}${i}`);
const fill = `fill:#${'a'.repeat(50000)}`;
export const RAISED = { limit: Number.MAX_VALUE, outputLimit: Number.MAX_VALUE };
// A single label grows without bound when the host's drawing of an icon is drawn in each of its
// icon spans, whatever diagram the label is in.
const ICONS = { ...RAISED, icons: { 'fa:fa-x': `<path d="${'M0 0'.repeat(25000)}"/>` } };
const iconLabel = (count) => `graph TD\nA["${Array(count).fill('fa:fa-x').join(' ')}"]\n`;
// A host icon as long as the fill, for the diagrams that draw one for each element.
const ICON = { ...RAISED, icons: { 'fa:fa-a': `<path d="${'M0 0'.repeat(12500)}"/>` } };

export const CASES = [
  [
    'flowchart',
    'edges under the default options',
    `graph TD\nlinkStyle default stroke:#${'a'.repeat(49000)}\n${names('a', 60).join(' & ')} <--> ${names('b', 61).join(' & ')}\n`,
    {},
  ],
  ['flowchart', 'nodes', `graph TD\nclassDef c ${fill}\n${names('n', 10700).map((name) => `${name}:::c`).join(';')}\n`, RAISED],
  [
    'flowchart',
    'nodes and edges only together',
    `graph TD\nclassDef default ${fill}\nlinkStyle default stroke:#${'a'.repeat(50000)}\n${names('n', 3600).join('-->')}\n`,
    RAISED,
  ],
  [
    'flowchart',
    'nodes drawn past what a doubling StringBuilder holds',
    `graph TD\nclassDef c ${fill}\n${names('n', 6000).map((name) => `${name}:::c`).join(';')}\n`,
    RAISED,
  ],
  // pele draws this between the port's hold limit and V8's longest string, so the port returns its
  // own limit error: the one intentional, platform-imposed difference from pele.
  [
    'flowchart',
    'edges pele draws past the port but under V8',
    `graph LR\nclassDef c ${fill}\n${names('n', 10600).map((name) => `${name}:::c`).join('-->')}\n`,
    { ...RAISED, maxEdges: 1000000000, maxWidth: 300 },
  ],
  ['swimlane', 'styled nodes in a lane', `swimlane-beta TB\nclassDef c ${fill}\nsubgraph L\n${names('n', 10700).map((name) => `${name}:::c`).join('\n')}\nend\n`, RAISED],
  ['class', 'styled classes', `classDiagram\nclassDef c ${fill}\n${names('C', 10700).map((name) => `class ${name}:::c`).join('\n')}\n`, RAISED],
  ['state', 'styled states', `stateDiagram-v2\nclassDef c ${fill}\n${names('S', 10700).map((name) => `[*] --> ${name}:::c`).join('\n')}\n`, RAISED],
  ['er', 'styled entities', `erDiagram\nclassDef c ${fill}\n${names('E', 10700).map((name) => `${name}:::c {}`).join('\n')}\n`, RAISED],
  ['block', 'styled blocks', `block-beta\nclassDef c ${fill};\n${names('B', 10700).map((name) => `${name}\nclass ${name} c`).join('\n')}\n`, RAISED],
  ['agentflow', 'styled agents', `agentflow-beta TB\nclassDef c ${fill}\n${names('a', 10700).map((name) => `${name}:::c`).join('\n')}\n`, RAISED],
  ['requirement', 'styled elements', `requirementDiagram\nclassDef c ${fill}\n${names('e', 10700).map((name) => `element ${name}:::c {\n}`).join('\n')}\n`, RAISED],
  // Leaves too small to draw are left out, so the fill is longer than elsewhere rather than the leaves more.
  ['treemap', 'styled leaves', `treemap-beta\n${names('L', 9000).map((name) => `"${name}": 1:::cc`).join('\n')}\nclassDef cc fill:#${'a'.repeat(60000)};\n`, RAISED],
  ['usecase', 'styled use cases', `usecase-beta\nclassDef c ${fill}\n${names('U', 10700).map((name) => `${name}("x"):::c`).join('\n')}\n`, RAISED],
  ['flowchart', 'host icons in one node label', iconLabel(5400), ICONS],
  ['flowchart', 'one node label longer than a doubling StringBuilder holds', iconLabel(3000), ICONS],
  ['swimlane', 'host icons in one lane title', `swimlane-beta TB\nsubgraph L["${Array(5400).fill('fa:fa-x').join(' ')}"]\nA\nend\n`, ICONS],
  [
    'architecture',
    'services drawing a host icon',
    `architecture-beta\n${names('s', 10700).map((name) => `service ${name}(big)[x]`).join('\n')}\n`,
    { ...RAISED, icons: { big: `<path d="M0,0${'H1'.repeat(25000)}"/>` } },
  ],
  // pele draws no host markup in a C4 label, only an empty icon box, so each span adds about 260 code units for 8 of source.
  [
    'c4',
    'people with many icon spans',
    `C4Context\n${names('p', 2100).map((name) => `Person(${name}, "${'fa:fa-a '.repeat(1000)}")`).join('\n')}\n`,
    { ...RAISED, icons: { 'fa:fa-a': '<path d="M4,4H20"/>' } },
  ],
  [
    'cynefin',
    'items drawing a host icon',
    `cynefin-beta\ncomplex\n${names('i', 10700).map((name) => `  "fa:fa-big ${name}"`).join('\n')}\n`,
    { ...RAISED, icons: { 'fa:fa-big': `<path d="M0,0${'H1'.repeat(25000)}"/>` } },
  ],
  [
    'gantt',
    'sections drawing a host icon',
    `gantt\ndateFormat YYYY-MM-DD\n${names('s', 10700).map((name) => `section fa:fa-big ${name}\nt${name} :2026-01-01, 1d`).join('\n')}\n`,
    { ...RAISED, icons: { 'fa:fa-big': `<path d="M0,0${'H1'.repeat(25000)}"/>` } },
  ],
  ['kanban', 'cards with an icon', `kanban\nc[Col]\n${names('k', 10700).map((name) => `  ${name}[fa:fa-a]`).join('\n')}\n`, ICON],
  ['mindmap', 'nodes with an icon', `mindmap\nroot\n${names('m', 10700).map((name) => `  ${name}[fa:fa-a]`).join('\n')}\n`, ICON],
  ['sequence', 'messages with an icon', `sequenceDiagram\n${'A->>B: fa:fa-a\n'.repeat(10700)}`, ICON],
];
