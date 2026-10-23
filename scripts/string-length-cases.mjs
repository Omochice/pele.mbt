// The inputs scripts/check-string-length.mjs renders, as [diagram, name, source, options].
// The options are in the JSON form the plugin reads, so an icon resolver is a map from name to fragment.
// Each diagram that can repeat a long string or a short element many times has a source just past
// V8's longest string, the same as its skipped test in src/diagrams/<diagram>/string_length_test.mbt.
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
  // A git graph draws no icons or styles; each `&` of a commit id is escaped to five code units,
  // once in the commit's data-id and once in its label, so the source is a tenth of V8's longest string.
  ['git', 'commit ids written as entities', `gitGraph\n${names('c', 100).map((name) => `commit id: "${name}${'&'.repeat(540000)}"`).join('\n')}\n`, RAISED],
  ['treeview', 'entries drawing a host icon', `treeView-beta\n${names('f', 10700).map((name) => `  ${name} icon(x:a)`).join('\n')}\n`, { ...RAISED, icons: { 'x:a': `<path d="M${'1'.repeat(50000)}"/>` } }],
  ['wardley', 'anchors drawing a host icon', `wardley-beta\n${names('', 10700).map((name) => `anchor "fa:fa-a ${name}" [0.5, 0.5]`).join('\n')}\n`, { ...RAISED, icons: { 'fa:fa-a': `<path d="M${'1'.repeat(50000)}"/>` } }],
  // Only slices of at least one percent are drawn, but every entry has a legend item.
  ['pie', 'legend items', `pie\n${names('', 2700000).map((name) => `"${name}":1`).join('\n')}\n`, RAISED],
  ['eventmodeling', 'time frames sharing long data', `eventmodeling\n${names('', 999).map((_, i) => `tf ${i + 1} evt E [[D]]`).join('\n')}\ndata D {\n  f: '${'&'.repeat(94000)}'\n}\n`, RAISED],
  // Drawn down, after it is drawn across, because the host is narrow.
  ['eventmodeling', 'time frames sharing long data, drawn down', `eventmodeling\n${names('', 549).map((_, i) => `tf ${i + 1} evt E [[D]]`).join('\n')}\ndata D {\n  f: '${'&'.repeat(94000)}'\n}\n`, { ...RAISED, maxWidth: 300 }],
  ['ishikawa', 'long causes', `ishikawa-beta\nProblem\n${names('C', 1090).map((name) => `${name}${'&'.repeat(50000)}`).join('\n')}\n`, RAISED],
  ['ishikawa', 'long causes, drawn down', `ishikawa-beta\nProblem\n${names('C', 545).map((name) => `${name}${'&'.repeat(50000)}`).join('\n')}\n`, { ...RAISED, maxWidth: 300 }],
  ['journey', 'long tasks', `journey\nsection S\n${names('T', 930).map((name) => `  ${name}${'&'.repeat(50000)}: 5: Me`).join('\n')}\n`, RAISED],
  // Drawn down, after it is drawn across, because the host is narrow; the people make the drawing down the larger.
  ['journey', 'long people, drawn down', `journey\nsection S\n${names('T', 990).map((name) => `  ${name}: 5: ${names('P', 10).map((person) => `${person}${'&'.repeat(5000)}`).join(', ')}`).join('\n')}\n`, { ...RAISED, maxWidth: 300 }],
  // A packet draws at most ten thousand rows, so only rows as wide as the config allows hold enough fields.
  ['packet', 'one-bit fields in wide rows', `---\nconfig:\n  packet:\n    bitsPerRow: 4096\n---\npacket\n${names('', 2130000).map((name) => `${name}: "a"`).join('\n')}\n`, RAISED],
  ['quadrant', 'long point names', `quadrantChart\n${names('P', 1100).map((name) => `${name}${'&'.repeat(50000)}: [0.5, 0.5]`).join('\n')}\n`, RAISED],
  // Each of the at most 32 graticule rings is a polygon through every axis.
  ['radar', 'polygon rings through many axes', `radar-beta\ngraticule polygon\nticks 32\naxis ${names('a', 1050000).join(', ')}\n`, RAISED],
  ['railroad', 'many rules', `railroad-peg-beta\n${names('r', 880000).map((name) => `${name} <- "a" ;`).join('\n')}\n`, RAISED],
  ['railroad', 'one long rule', `railroad-peg-beta\nr <- ${Array(2600000).fill('"a"').join(' ')} ;\n`, RAISED],
  // Every link names its long source node in its id.
  ['sankey', 'links from a long-named node', `sankey\n\n${names('B', 1090).map((name) => `A${'&'.repeat(50000)},${name},1`).join('\n')}\n`, RAISED],
  ['timeline', 'long events', `timeline\n${names('', 1650).map((name) => `  ${name} : E${'&'.repeat(50000)}`).join('\n')}\n`, RAISED],
  // Laying out many sets takes time that grows faster than their count, so the texts of one set amplify instead.
  ['venn', 'long texts in one set', `venn-beta\nset A\n${names('T', 2180).map((name) => `  text ${name}["${'&'.repeat(50000)}"]`).join('\n')}\n`, RAISED],
  ['xychart', 'bar series', `xychart\n${Array(1060).fill(`bar [${Array(10000).fill(1).join(',')}]`).join('\n')}\n`, RAISED],
  // Drawn across past the port's hold limit, which is only measured, then drawn down within it.
  ['journey', 'long tasks, drawn down within the port after across past it', `journey\nsection S\n${names('T', 846).map((name) => `  ${name}${'&'.repeat(50000)}: 5: Me`).join('\n')}\n`, { ...RAISED, maxWidth: 300 }],
  // Drawn across past the port's hold limit, which is only measured, then down past V8's longest string.
  ['journey', 'long people, drawn down past V8 after across past the port', `journey\nsection S\n${names('T', 1630).map((name) => `  ${name}: 5: ${names('P', 10).map((person) => `${person}${'&'.repeat(5000)}`).join(', ')}`).join('\n')}\n`, { ...RAISED, maxWidth: 300 }],
  ['ishikawa', 'long causes, drawn down past V8 after across past the port', `ishikawa-beta\nProblem\n${names('C', 915).map((name) => `${name}${'&'.repeat(50000)}`).join('\n')}\n`, { ...RAISED, maxWidth: 300 }],
  // Each `&` of an accessible description is escaped to five code units in the document's head.
  ['pie', 'an accessible description longer than a doubling StringBuilder holds', `pie\naccDescr: ${'&'.repeat(60000000)}\n"a":1\n`, RAISED],
  ['pie', 'an accessible description past V8', `pie\naccDescr: ${'&'.repeat(110000000)}\n"a":1\n`, RAISED],
  // An info diagram repeats nothing, so only its one title or accessible description can grow.
  ['info', 'a title longer than a doubling StringBuilder holds', `info\ntitle ${'&'.repeat(60000000)}\n`, RAISED],
  // pele lays out a title of `&` in more than V8's default heap, so `"`, escaped to six code units, takes fewer.
  ['info', 'a title past V8', `info\ntitle ${'"'.repeat(90000000)}\n`, RAISED],
  ['info', 'an accessible description longer than a doubling StringBuilder holds', `info\naccDescr: ${'&'.repeat(60000000)}\n`, RAISED],
  ['info', 'an accessible description past V8', `info\naccDescr: ${'&'.repeat(110000000)}\n`, RAISED],
  // `<` rather than `&`, which YAML reads as an anchor.
  ['sequence', 'a front matter title longer than a doubling StringBuilder holds', `---\ntitle: ${'<'.repeat(70000000)}\n---\nsequenceDiagram\nA->>B: x\n`, RAISED],
  ['sequence', 'a title past V8', `sequenceDiagram\ntitle ${'"'.repeat(90000000)}\nA->>B: x\n`, RAISED],
  ['block', 'host icons in one block label', `block-beta\nA["${Array(5400).fill('fa:fa-x').join(' ')}"]\n`, ICONS],
  ['cynefin', 'host icons in one item', `cynefin-beta\ncomplex\n  "${Array(5400).fill('fa:fa-x').join(' ')}"\n`, ICONS],
  ['gantt', 'host icons in one section label', `gantt\ndateFormat YYYY-MM-DD\nsection ${Array(5400).fill('fa:fa-x').join(' ')}\nt :2026-01-01, 1d\n`, ICONS],
  // A card breaks its label to fit the column, so the math is typeset almost without width to keep it on one line.
  [
    'kanban',
    'host math in one line of a card',
    `kanban\nc[Col]\n  k[${'$$x$$'.repeat(5400)}]\n`,
    { ...RAISED, math: { x: { 14: { svg: `<path d="${'M0 0'.repeat(25000)}"/>`, width: 0.001, height: 10 } } } },
  ],
  ['agentflow', 'host icons in one agent label', `agentflow-beta TB\n  a["${Array(5400).fill('fa:fa-x').join(' ')}"]\n`, ICONS],
  ['state', 'host icons in one state label', `stateDiagram-v2\nA : ${Array(5400).fill('fa:fa-x').join(' ')}\n`, ICONS],
  ['class', 'host icons in one class label', `classDiagram\nclass A["${Array(5400).fill('fa:fa-x').join(' ')}"]\n`, ICONS],
  ['er', 'host icons in one entity name', `erDiagram\nA["${Array(5400).fill('fa:fa-x').join(' ')}"] {\n}\n`, ICONS],
  ['er', 'host icons in one attribute comment', `erDiagram\nA {\n  string name "${Array(5400).fill('fa:fa-x').join(' ')}"\n}\n`, ICONS],
  ['usecase', 'host icons in one use case label', `usecase-beta\nU("${Array(5400).fill('fa:fa-x').join(' ')}")\n`, ICONS],
  // A requirement diagram draws no host icons, but it typesets math.
  [
    'requirement',
    'host math in one field',
    `requirementDiagram\nrequirement r {\n  text: "${Array(5400).fill('$$x$$').join(' ')}"\n}\n`,
    { ...RAISED, math: { x: { 14: { svg: `<path d="${'M0 0'.repeat(25000)}"/>`, width: 10, height: 10 } } } },
  ],
  ['architecture', 'host icons in one service label', `architecture-beta\nservice s(server)[${Array(5400).fill('fa:fa-x').join(' ')}]\n`, ICONS],
  // Each icon span of a C4 label draws only an empty icon box, so one label needs millions of them.
  ['c4', 'icon spans in one person label', `C4Context\nPerson(p, "${'fa:fa-a '.repeat(2200000)}")\n`, { ...RAISED, icons: { 'fa:fa-a': '<path d="M4,4H20"/>' } }],
  [
    'c4',
    'icon spans in one boundary label',
    `C4Context\nBoundary(b, "${'fa:fa-a '.repeat(2200000)}") {\n  Person(p, "x")\n}\n`,
    { ...RAISED, icons: { 'fa:fa-a': '<path d="M4,4H20"/>' } },
  ],
  ['mindmap', 'host icons in one node label', `mindmap\nroot["${Array(5400).fill('fa:fa-x').join(' ')}"]\n`, ICONS],
  // A node without a label is named by its text, which is written in its data-id and in its label.
  ['mindmap', 'one node named by many &', `mindmap\n${'&'.repeat(60000000)}\n`, RAISED],
  ['sequence', 'host icons in one message label', `sequenceDiagram\nA->>B: ${Array(5400).fill('fa:fa-x').join(' ')}\n`, ICONS],
  // A participant without an alias is labelled with its name, which its data-ids and lifeline repeat.
  ['sequence', 'one participant named by many &', `sequenceDiagram\nparticipant ${'&'.repeat(54000000)}\n`, RAISED],
  // pele fails this while parsing, because its pattern for a quoted string runs out of V8's
  // backtracking stack past 4194294 characters; the port, which has no such stack, fails as the
  // id is written twice past V8's longest string, with the same error.
  ['git', 'one commit id of many &', `gitGraph\ncommit id: "${'&'.repeat(54000000)}"\n`, RAISED],
  // An entry's name is written in its data-id and as its text.
  ['treeview', 'one entry named by many &', `treeView-beta\n  "${'&'.repeat(54000000)}"\n`, RAISED],
  ['treeview', 'one entry described by many &', `treeView-beta\n  a "${'&'.repeat(110000000)}"\n`, RAISED],
];
