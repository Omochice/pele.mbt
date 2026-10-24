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
  lazy('mindmap', 'one node named by many &', () => `mindmap\n${'&'.repeat(60000000)}\n`, RAISED),
  ['sequence', 'host icons in one message label', `sequenceDiagram\nA->>B: ${Array(5400).fill('fa:fa-x').join(' ')}\n`, ICONS],
  // A participant without an alias is labelled with its name, which its data-ids and lifeline repeat.
  lazy('sequence', 'one participant named by many &', () => `sequenceDiagram\nparticipant ${'&'.repeat(54000000)}\n`, RAISED),
  // pele fails this while parsing, because its pattern for a quoted string runs out of V8's
  // backtracking stack past 4194294 characters; the port, which has no such stack, fails as the
  // id is written twice past V8's longest string, with the same error.
  lazy('git', 'one commit id of many &', () => `gitGraph\ncommit id: "${'&'.repeat(54000000)}"\n`, RAISED),
  // An entry's name is written in its data-id and as its text.
  lazy('treeview', 'one entry named by many &', () => `treeView-beta\n  "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('treeview', 'one entry described by many &', () => `treeView-beta\n  a "${'&'.repeat(110000000)}"\n`, RAISED),
  ['wardley', 'host icons in one anchor label', `wardley-beta\nanchor "${Array(5400).fill('fa:fa-x').join(' ')}" [0.5, 0.5]\n`, ICONS],
  ['wardley', 'host icons in one link label', `wardley-beta\ncomponent A [0.2, 0.2]\ncomponent B [0.8, 0.8]\nA->B; ${Array(5400).fill('fa:fa-x').join(' ')}\n`, ICONS],
  // pele fails this while parsing, as it does a commit id of the same length; the port fails as
  // the slice's and the legend item's data-ids and the label pass V8's longest string.
  lazy('pie', 'one entry named by many &', () => `pie\n"${'&'.repeat(54000000)}": 1\n`, RAISED),
  lazy('eventmodeling', 'one frame with data of many &', () => `eventmodeling\ntf 01 evt E "${'&'.repeat(110000000)}"\n`, RAISED),
  lazy('eventmodeling', 'one frame with data drawn past what a doubling StringBuilder holds', () => `eventmodeling\ntf 01 evt E "${'&'.repeat(60000000)}"\n`, RAISED),
  lazy('eventmodeling', 'one note of many &', () => `eventmodeling\ntf 01 evt E\nnote 01 {\n${'&'.repeat(110000000)}\n}\n`, RAISED),
  lazy('ishikawa', 'one cause of many &', () => `ishikawa-beta\nProblem\n  C\n    ${'&'.repeat(110000000)}\n`, RAISED),
  // A category's text is written in its data-id and as its label.
  lazy('ishikawa', 'one category of many &', () => `ishikawa-beta\nProblem\n  ${'&'.repeat(54000000)}\n`, RAISED),
  // A task's and a section's text are written in their data-ids and as their labels.
  lazy('journey', 'one task of many &', () => `journey\nsection S\n  ${'&'.repeat(54000000)}: 5: Me\n`, RAISED),
  lazy('journey', 'one section of many &', () => `journey\nsection ${'&'.repeat(54000000)}\n  T: 5: Me\n`, RAISED),
  // pele fails this while parsing, as it does a commit id of the same length; the port fails as
  // the field's label, drawn down for a narrow host, passes V8's longest string.
  lazy('packet', 'one field of many &, drawn down', () => `packet\n0-31: "${'&'.repeat(62000000)}"\n`, { ...RAISED, maxWidth: 300 }),
  // A point's name is written in its data-id and as its label.
  lazy('quadrant', 'one point named by many &', () => `quadrantChart\n${'&'.repeat(54000000)}: [0.5, 0.5]\n`, RAISED),
  // pele fails these while parsing, as it does a commit id past 4194294 characters; the port fails
  // as the label passes V8's longest string.
  lazy('radar', 'one axis labelled by many &', () => `radar-beta\naxis a["${'&'.repeat(110000000)}"]\n`, RAISED),
  lazy('radar', 'one curve labelled by many &', () => `radar-beta\naxis a\ncurve c["${'&'.repeat(110000000)}"]{1}\n`, RAISED),
  // A quoted terminal fails in pele while parsing past 4194294 characters; a special sequence does not.
  lazy('railroad', 'one special sequence of many &', () => `railroad-ebnf-beta\nr = ? ${'&'.repeat(110000000)} ? ;\n`, RAISED),
  lazy('sankey', 'one node named by many &', () => `sankey\n\nA${'&'.repeat(54000000)},B,1\n`, RAISED),
  // A period's and a section's text are written in their data-ids and as their labels.
  lazy('timeline', 'one period of many &', () => `timeline\n  ${'&'.repeat(54000000)} : e\n`, RAISED),
  lazy('timeline', 'one section of many &', () => `timeline\nsection ${'&'.repeat(54000000)}\n  p : e\n`, RAISED),
  lazy('venn', 'one text labelled by many &', () => `venn-beta\nset A\n  text T["${'&'.repeat(110000000)}"]\n`, RAISED),
  lazy('venn', 'one set labelled by many &', () => `venn-beta\nset A["${'&'.repeat(110000000)}"]\n`, RAISED),
  lazy('xychart', 'one category of many &', () => `xychart\nx-axis ["${'&'.repeat(110000000)}"]\nbar [1]\n`, RAISED),
  lazy('xychart', 'one category drawn past what a doubling StringBuilder holds', () => `xychart\nx-axis ["${'&'.repeat(60000000)}"]\nbar [1]\n`, RAISED),
  // A series' title is written in its data-id, its legend item's data-id and its legend label.
  lazy('xychart', 'one series titled by many &', () => `xychart\nbar "${'&'.repeat(54000000)}" [1]\n`, RAISED),
  // pele checks its output limit against a drawing past the port's hold limit, so the port gives
  // pele's output limit error rather than its own wherever the output limit is below the drawing.
  [
    'flowchart',
    'edges pele draws past the port but under V8, under the default output limit',
    `graph LR\nclassDef c ${fill}\n${names('n', 10600).map((name) => `${name}:::c`).join('-->')}\n`,
    { limit: Number.MAX_VALUE, maxEdges: 1000000000, maxWidth: 300 },
  ],
  // The SVG, at 2^28 code units or more, needs a block of at least 512 MiB, where MoonBit's
  // allocator once handed out a smaller free block and the drawing overwrote what lay past it.
  lazy('git', 'a branch named by 140M a, drawn into a block of 512 MiB or more', () => `gitGraph\ncommit\nbranch ${'a'.repeat(140000000)}\ncommit\n`, RAISED),
  // The source alone needs such a block once it is decoded, before anything is drawn.
  lazy('git', 'a branch named by 270M a, read into a block of 512 MiB or more', () => `gitGraph\ncommit\nbranch ${'a'.repeat(270000000)}\ncommit\n`, RAISED),
  // pele's pattern for a quoted string, `"([^"\\]|\\.)*"|'([^'\\]|\\.)*'`, takes four slots of V8's
  // backtracking stack for each character or escape pair, and V8 throws once the stack holds more
  // than 64 MiB: past 4194294 of them in a closed double-quoted string, one more in any other.
  lazy('git', 'a double-quoted commit id just short of V8\'s backtracking stack', () => `gitGraph\ncommit id: "${'a'.repeat(4194294)}"\n`, RAISED),
  lazy('git', 'a double-quoted commit id at V8\'s backtracking stack', () => `gitGraph\ncommit id: "${'a'.repeat(4194295)}"\n`, RAISED),
  lazy('git', 'a single-quoted commit id just short of V8\'s backtracking stack', () => `gitGraph\ncommit id: '${'a'.repeat(4194295)}'\n`, RAISED),
  lazy('git', 'a single-quoted commit id at V8\'s backtracking stack', () => `gitGraph\ncommit id: '${'a'.repeat(4194296)}'\n`, RAISED),
  // An unclosed string runs to the end of the text, through the line break pele adds.
  lazy('git', 'an unclosed commit id just short of V8\'s backtracking stack', () => `gitGraph\ncommit id: "${'a'.repeat(4194293)}\n`, RAISED),
  lazy('git', 'an unclosed commit id at V8\'s backtracking stack', () => `gitGraph\ncommit id: "${'a'.repeat(4194294)}\n`, RAISED),
  lazy('pie', 'an entry name just short of V8\'s backtracking stack', () => `pie\n"${'a'.repeat(4194294)}": 1\n`, RAISED),
  lazy('pie', 'an entry name at V8\'s backtracking stack', () => `pie\n"${'a'.repeat(4194295)}": 1\n`, RAISED),
  lazy('packet', 'a field label just short of V8\'s backtracking stack', () => `packet\n0-31: "${'a'.repeat(4194294)}"\n`, RAISED),
  lazy('packet', 'a field label at V8\'s backtracking stack', () => `packet\n0-31: "${'a'.repeat(4194295)}"\n`, RAISED),
  lazy('radar', 'an axis label just short of V8\'s backtracking stack', () => `radar-beta\naxis a["${'a'.repeat(4194294)}"]\n`, RAISED),
  lazy('radar', 'an axis label at V8\'s backtracking stack', () => `radar-beta\naxis a["${'a'.repeat(4194295)}"]\n`, RAISED),
  lazy('wardley', 'an anchor label just short of V8\'s backtracking stack', () => `wardley-beta\nanchor "${'a'.repeat(4194294)}" [0.5, 0.5]\n`, RAISED),
  lazy('wardley', 'an anchor label at V8\'s backtracking stack', () => `wardley-beta\nanchor "${'a'.repeat(4194295)}" [0.5, 0.5]\n`, RAISED),
  lazy('cynefin', 'an item just short of V8\'s backtracking stack', () => `cynefin-beta\ncomplex\n  "${'a'.repeat(4194294)}"\n`, RAISED),
  lazy('cynefin', 'an item at V8\'s backtracking stack', () => `cynefin-beta\ncomplex\n  "${'a'.repeat(4194295)}"\n`, RAISED),
  // The grammar has no place for a string, so pele lexes it and then fails to parse it.
  lazy('architecture', 'a misplaced string just short of V8\'s backtracking stack', () => `architecture-beta\n"${'a'.repeat(4194294)}"\n`, RAISED),
  lazy('architecture', 'a misplaced string at V8\'s backtracking stack', () => `architecture-beta\n"${'a'.repeat(4194295)}"\n`, RAISED),
  lazy('railroad', 'a PEG terminal just short of V8\'s backtracking stack', () => `railroad-peg-beta\nr <- "${'a'.repeat(4194294)}" ;\n`, RAISED),
  lazy('railroad', 'a PEG terminal at V8\'s backtracking stack', () => `railroad-peg-beta\nr <- "${'a'.repeat(4194295)}" ;\n`, RAISED),
  lazy('railroad', 'a single-quoted PEG terminal just short of V8\'s backtracking stack', () => `railroad-peg-beta\nr <- '${'a'.repeat(4194295)}' ;\n`, RAISED),
  lazy('railroad', 'a single-quoted PEG terminal at V8\'s backtracking stack', () => `railroad-peg-beta\nr <- '${'a'.repeat(4194296)}' ;\n`, RAISED),
  lazy('railroad', 'an EBNF terminal just short of V8\'s backtracking stack', () => `railroad-ebnf-beta\nr = "${'a'.repeat(4194294)}" ;\n`, RAISED),
  lazy('railroad', 'an EBNF terminal at V8\'s backtracking stack', () => `railroad-ebnf-beta\nr = "${'a'.repeat(4194295)}" ;\n`, RAISED),
  lazy('railroad', 'a terminal just short of V8\'s backtracking stack', () => `railroad-beta\nr = terminal("${'a'.repeat(4194294)}") ;\n`, RAISED),
  lazy('railroad', 'a terminal at V8\'s backtracking stack', () => `railroad-beta\nr = terminal("${'a'.repeat(4194295)}") ;\n`, RAISED),
  // An architecture label is read with the same alternatives inside brackets, followed by a third
  // that stays untried when the bracket closes the quote, whichever quote it is.
  lazy('architecture', 'a service label just short of V8\'s backtracking stack', () => `architecture-beta\nservice s(server)["${'a'.repeat(4194294)}"]\n`, RAISED),
  lazy('architecture', 'a service label at V8\'s backtracking stack', () => `architecture-beta\nservice s(server)["${'a'.repeat(4194295)}"]\n`, RAISED),
  lazy('architecture', 'a single-quoted service label just short of V8\'s backtracking stack', () => `architecture-beta\nservice s(server)['${'a'.repeat(4194294)}']\n`, RAISED),
  lazy('architecture', 'a single-quoted service label at V8\'s backtracking stack', () => `architecture-beta\nservice s(server)['${'a'.repeat(4194295)}']\n`, RAISED),
  lazy('architecture', 'a service label with text after its quote just short of V8\'s backtracking stack', () => `architecture-beta\nservice s(server)["${'a'.repeat(4194295)}"x]\n`, RAISED),
  lazy('architecture', 'a service label with text after its quote at V8\'s backtracking stack', () => `architecture-beta\nservice s(server)["${'a'.repeat(4194296)}"x]\n`, RAISED),
  // An ABNF numeric value, `%[xXdDbB][0-9A-Fa-f]+(?:-[0-9A-Fa-f]+|\.[0-9A-Fa-f]+)*`, takes five slots
  // for each part after its first, however many digits each has.
  lazy('railroad', 'an ABNF value just short of V8\'s backtracking stack', () => `railroad-abnf-beta\nr = %x1${'.1'.repeat(3355435)} ;\n`, RAISED),
  lazy('railroad', 'an ABNF value at V8\'s backtracking stack', () => `railroad-abnf-beta\nr = %x1${'.1'.repeat(3355436)} ;\n`, RAISED),
  // A Wardley name, `[A-Za-z](?:[A-Za-z0-9_()&]|-(?!>))*(?:[ \t]+[A-Za-z(](?:[A-Za-z0-9_()&]|-(?!>))*)*`,
  // takes two slots for each character after a word's first and five for each further word.
  lazy('wardley', 'a component name just short of V8\'s backtracking stack', () => `wardley-beta\ncomponent ${'a'.repeat(8388590)} [0.5, 0.5]\n`, RAISED),
  lazy('wardley', 'a component name at V8\'s backtracking stack', () => `wardley-beta\ncomponent ${'a'.repeat(8388591)} [0.5, 0.5]\n`, RAISED),
  lazy('wardley', 'a component name of many words just short of V8\'s backtracking stack', () => `wardley-beta\ncomponent a${' a'.repeat(3355435)} [0.5, 0.5]\n`, RAISED),
  lazy('wardley', 'a component name of many words at V8\'s backtracking stack', () => `wardley-beta\ncomponent a${' a'.repeat(3355436)} [0.5, 0.5]\n`, RAISED),
  // A flowchart reads a run of line breaks with `(?:\r?\n)+`, and the line breaks after its keyword
  // with `(?:\r?\n)*\s*\n`, taking two slots for each; the second takes two more when the blanks
  // after the run hold another line break.
  lazy('flowchart', 'line breaks just short of V8\'s backtracking stack', () => `graph TD\nA${'\n'.repeat(8388591)}B\n`, RAISED),
  lazy('flowchart', 'line breaks at V8\'s backtracking stack', () => `graph TD\nA${'\n'.repeat(8388592)}B\n`, RAISED),
  lazy('flowchart', 'line breaks after the keyword just short of V8\'s backtracking stack', () => `graph${'\n'.repeat(8388590)}A\n`, RAISED),
  lazy('flowchart', 'line breaks after the keyword at V8\'s backtracking stack', () => `graph${'\n'.repeat(8388591)}A\n`, RAISED),
  lazy('flowchart', 'line breaks and a blank line after the keyword just short of V8\'s backtracking stack', () => `graph${'\n'.repeat(8388589)} \nA\n`, RAISED),
  lazy('flowchart', 'line breaks and a blank line after the keyword at V8\'s backtracking stack', () => `graph${'\n'.repeat(8388590)} \nA\n`, RAISED),
  lazy('agentflow', 'line breaks after the keyword just short of V8\'s backtracking stack', () => `agentflow-beta${'\n'.repeat(8388590)}a\n`, RAISED),
  lazy('agentflow', 'line breaks after the keyword at V8\'s backtracking stack', () => `agentflow-beta${'\n'.repeat(8388591)}a\n`, RAISED),
  lazy('agentflow', 'line breaks and a blank line after the keyword just short of V8\'s backtracking stack', () => `agentflow-beta${'\n'.repeat(8388589)} \na\n`, RAISED),
  lazy('agentflow', 'line breaks and a blank line after the keyword at V8\'s backtracking stack', () => `agentflow-beta${'\n'.repeat(8388590)} \na\n`, RAISED),
  // pele reads a `%%{...}%%` directive in any diagram with a pattern that takes two slots for each
  // character of its body, once in the trimmed text and once in the text itself, and fails before
  // the diagram's type is known.
  lazy('pie', 'a directive just short of V8\'s backtracking stack', () => `%%{init: ${'!'.repeat(8388577)}}%%\npie\n"a": 1\n`, RAISED),
  lazy('pie', 'a directive at V8\'s backtracking stack', () => `%%{init: ${'!'.repeat(8388578)}}%%\npie\n"a": 1\n`, RAISED),
  lazy('pie', 'a directive without a colon just short of V8\'s backtracking stack', () => `%%{wrap ${'!'.repeat(8388578)}}%%\npie\n"a": 1\n`, RAISED),
  lazy('pie', 'a directive without a colon at V8\'s backtracking stack', () => `%%{wrap ${'!'.repeat(8388579)}}%%\npie\n"a": 1\n`, RAISED),
  lazy('pie', 'an unclosed directive before trailing line breaks just short of V8\'s backtracking stack', () => `pie\n"a": 1\n%%{init: ${'!'.repeat(8388574)}\n\n\n`, RAISED),
  lazy('pie', 'an unclosed directive before trailing line breaks at V8\'s backtracking stack', () => `pie\n"a": 1\n%%{init: ${'!'.repeat(8388575)}\n\n\n`, RAISED),
  // Every diagram checks the host's font lists with a pattern that takes eleven slots for each font
  // after the first, whatever its quotes and blanks, as it draws its root element.
  ['pie', 'a font list just short of V8\'s backtracking stack', 'pie\n"a": 1\n', { ...RAISED, fontFamily: `a${',a'.repeat(1525197)}` }],
  ['pie', 'a font list at V8\'s backtracking stack', 'pie\n"a": 1\n', { ...RAISED, fontFamily: `a${',a'.repeat(1525198)}` }],
  ['pie', 'a monospace font list just short of V8\'s backtracking stack', 'pie\n"a": 1\n', { ...RAISED, fontFamilyMono: `"a"${", 'b c'".repeat(1525197)}` }],
  ['pie', 'a monospace font list at V8\'s backtracking stack', 'pie\n"a": 1\n', { ...RAISED, fontFamilyMono: `"a"${", 'b c'".repeat(1525198)}` }],
  // A list with a character past Latin-1 is matched as two-byte text, where the pattern takes four
  // slots for each font after the first, two for each quoted character or blank, and four for each
  // unquoted character after a font's first.
  ['pie', 'a two-byte font list just short of V8\'s backtracking stack', 'pie\n"a": 1\n', { ...RAISED, fontFamily: `Ā${',a'.repeat(4194294)}` }],
  ['pie', 'a two-byte font list at V8\'s backtracking stack', 'pie\n"a": 1\n', { ...RAISED, fontFamily: `Ā${',a'.repeat(4194295)}` }],
  ['pie', 'a long two-byte font name just short of V8\'s backtracking stack', 'pie\n"a": 1\n', { ...RAISED, fontFamily: `Ā${'a'.repeat(4194294)}` }],
  ['pie', 'a long two-byte font name at V8\'s backtracking stack', 'pie\n"a": 1\n', { ...RAISED, fontFamily: `Ā${'a'.repeat(4194295)}` }],
  ['pie', 'a long quoted two-byte font name just short of V8\'s backtracking stack', 'pie\n"a": 1\n', { ...RAISED, fontFamily: `Ā,"${'a'.repeat(8388586)}"` }],
  ['pie', 'a long quoted two-byte font name at V8\'s backtracking stack', 'pie\n"a": 1\n', { ...RAISED, fontFamily: `Ā,"${'a'.repeat(8388587)}"` }],
  // A journey wraps its title into lines, each its own tspan, after escaping every `<` of it.
  lazy('journey', 'a front matter title wrapped past what a doubling StringBuilder holds', () => `---\ntitle: ${'<'.repeat(70000000)}\n---\njourney\nsection S\n  T: 5: Me\n`, RAISED),
  lazy('journey', 'a front matter title wrapped past what a doubling StringBuilder holds, drawn down', () => `---\ntitle: ${'<'.repeat(70000000)}\n---\njourney\nsection S\n  T: 5: Me\n`, { ...RAISED, maxWidth: 300 }),
  lazy('journey', 'a title past V8', () => `journey\ntitle ${'"'.repeat(90000000)}\nsection S\n  T: 5: Me\n`, RAISED),
  lazy('timeline', 'a front matter title wrapped past what a doubling StringBuilder holds', () => `---\ntitle: ${'<'.repeat(70000000)}\n---\ntimeline\n  p : e\n`, RAISED),
  lazy('timeline', 'a title past V8', () => `timeline\ntitle ${'"'.repeat(90000000)}\n  p : e\n`, RAISED),
  // A YAML plain scalar cannot start with `"`, so a front matter title of `"` starts with `x`.
  lazy('flowchart', 'a front matter title past V8', () => `---\ntitle: x${'"'.repeat(90000000)}\n---\ngraph TD\nA\n`, RAISED),
  lazy('swimlane', 'a front matter title past V8', () => `---\ntitle: x${'"'.repeat(90000000)}\n---\nswimlane-beta TB\nsubgraph L\nA\nend\n`, RAISED),
  lazy('er', 'a front matter title past V8', () => `---\ntitle: x${'"'.repeat(90000000)}\n---\nerDiagram\nA {\n}\n`, RAISED),
  lazy('block', 'a front matter title past V8', () => `---\ntitle: x${'"'.repeat(90000000)}\n---\nblock-beta\nA\n`, RAISED),
  lazy('agentflow', 'a front matter title past V8', () => `---\ntitle: x${'"'.repeat(90000000)}\n---\nagentflow-beta TB\n  a\n`, RAISED),
  lazy('requirement', 'a front matter title past V8', () => `---\ntitle: x${'"'.repeat(90000000)}\n---\nrequirementDiagram\nrequirement r {\n}\n`, RAISED),
  lazy('usecase', 'a front matter title past V8', () => `---\ntitle: x${'"'.repeat(90000000)}\n---\nusecase-beta\nU("x")\n`, RAISED),
  lazy('kanban', 'a front matter title past V8', () => `---\ntitle: x${'"'.repeat(90000000)}\n---\nkanban\nc[Col]\n  k[x]\n`, RAISED),
  lazy('mindmap', 'a front matter title past V8', () => `---\ntitle: x${'"'.repeat(90000000)}\n---\nmindmap\nroot\n`, RAISED),
  lazy('treemap', 'a title past V8', () => `treemap-beta\ntitle ${'"'.repeat(90000000)}\n"a": 1\n`, RAISED),
  lazy('architecture', 'a title past V8', () => `architecture-beta\ntitle ${'"'.repeat(90000000)}\nservice s(server)[x]\n`, RAISED),
  lazy('c4', 'a title past V8', () => `C4Context\ntitle ${'"'.repeat(90000000)}\nPerson(p, "x")\n`, RAISED),
  lazy('cynefin', 'a title past V8', () => `cynefin-beta\ntitle ${'"'.repeat(90000000)}\ncomplex\n  "x"\n`, RAISED),
  lazy('git', 'a title past V8', () => `gitGraph\ntitle ${'"'.repeat(90000000)}\ncommit\n`, RAISED),
  lazy('treeview', 'a title past V8', () => `treeView-beta\ntitle ${'"'.repeat(90000000)}\n  a\n`, RAISED),
  lazy('wardley', 'a title past V8', () => `wardley-beta\ntitle ${'"'.repeat(90000000)}\ncomponent A [0.2, 0.2]\n`, RAISED),
  lazy('pie', 'a title past V8', () => `pie\ntitle ${'"'.repeat(90000000)}\n"a":1\n`, RAISED),
  lazy('packet', 'a title past V8', () => `packet\ntitle ${'"'.repeat(90000000)}\n0-31: "a"\n`, RAISED),
  lazy('quadrant', 'a title past V8', () => `quadrantChart\ntitle ${'"'.repeat(90000000)}\nP: [0.5, 0.5]\n`, RAISED),
  lazy('radar', 'a title past V8', () => `radar-beta\ntitle ${'"'.repeat(90000000)}\naxis a\n`, RAISED),
  lazy('railroad', 'a title past V8', () => `railroad-peg-beta\ntitle ${'"'.repeat(90000000)}\nr <- "a" ;\n`, RAISED),
  lazy('venn', 'a title past V8', () => `venn-beta\ntitle ${'"'.repeat(90000000)}\nset A\n`, RAISED),
  lazy('xychart', 'a title past V8', () => `xychart\ntitle "${'&'.repeat(110000000)}"\nbar [1]\n`, RAISED),
  lazy('ishikawa', 'a front matter title past V8', () => `---\ntitle: x${'"'.repeat(90000000)}\n---\nishikawa-beta\nProblem\n  C\n`, RAISED),
  lazy('eventmodeling', 'a title past V8', () => `eventmodeling title ${'"'.repeat(90000000)}\ntf 01 evt E\n`, RAISED),
  lazy('sankey', 'a front matter title past V8', () => `---\ntitle: x${'"'.repeat(90000000)}\n---\nsankey\n\nA,B,1\n`, RAISED),
  lazy('gantt', 'a title past V8', () => `gantt\ndateFormat YYYY-MM-DD\ntitle ${'"'.repeat(90000000)}\nsection s\nt :2026-01-01, 1d\n`, RAISED),
  lazy('gantt', 'a title over no tasks past V8', () => `gantt\ntitle ${'"'.repeat(90000000)}\n`, RAISED),
  // A Gantt chart without tasks draws only its title.
  lazy('gantt', 'a title over no tasks longer than a doubling StringBuilder holds', () => `gantt\ntitle ${'<'.repeat(70000000)}\n`, RAISED),
  // Each of these escapes 54 million `&` into more than a doubling StringBuilder holds, which pele
  // draws, and 110 million into more than V8's longest string, which pele fails.
  lazy('class', 'one member of many &', () => `classDiagram\nclass A {\n  ${'&'.repeat(54000000)}\n}\n`, RAISED),
  lazy('class', 'one member past V8', () => `classDiagram\nclass A {\n  ${'&'.repeat(110000000)}\n}\n`, RAISED),
  lazy('class', 'one annotation of many &', () => `classDiagram\nclass A {\n  <<${'&'.repeat(54000000)}>>\n}\n`, RAISED),
  lazy('class', 'one annotation past V8', () => `classDiagram\nclass A {\n  <<${'&'.repeat(110000000)}>>\n}\n`, RAISED),
  // A class is named in its data-id, and labelled by its name unless it has a label.
  lazy('class', 'one class named by many &, with a short label', () => `classDiagram\nclass \`${'&'.repeat(54000000)}\`["x"]\n`, RAISED),
  lazy('class', 'one class named past V8, with a short label', () => `classDiagram\nclass \`${'&'.repeat(110000000)}\`["x"]\n`, RAISED),
  // An edge's id names both its ends, in the edge's data-id and in its label's.
  lazy('class', 'an edge from a class named by many &', () => `classDiagram\nclass \`${'&'.repeat(54000000)}\`["x"]\n\`${'&'.repeat(54000000)}\` --> B\n`, RAISED),
  lazy('class', 'an edge label from a class named by many &', () => `classDiagram\nclass \`${'&'.repeat(54000000)}\`["x"]\n\`${'&'.repeat(54000000)}\` --> B : l\n`, RAISED),
  lazy('class', 'one cardinality of many &', () => `classDiagram\nA "${'&'.repeat(54000000)}" --> B\n`, RAISED),
  lazy('class', 'one cardinality past V8', () => `classDiagram\nA "${'&'.repeat(110000000)}" --> B\n`, RAISED),
  lazy('class', 'one tooltip of many &', () => `classDiagram\nclass A\nclick A call f() "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('class', 'one tooltip past V8', () => `classDiagram\nclass A\nclick A call f() "${'&'.repeat(110000000)}"\n`, RAISED),
  lazy('class', 'one link of many &', () => `classDiagram\nclass A\nclick A href "https://x/${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('class', 'one link past V8', () => `classDiagram\nclass A\nclick A href "https://x/${'&'.repeat(110000000)}"\n`, RAISED),
  // A narrow host makes an edge run through the title of the first namespace, which is drawn again
  // over the edges with the namespace's id.
  lazy(
    'class',
    'a struck namespace title named by many &',
    () =>
      `classDiagram\n    namespace \`${'&'.repeat(54000000)}\`["Company.Engineering.Backend"] {\n        class Developer {\n            +writeCode()\n        }\n    }\n    namespace Company.Engineering.Frontend {\n        class Designer {\n            +createMockup()\n        }\n    }\n    namespace Company.Engineering {\n        class TechLead {\n            +planSprint()\n        }\n    }\n    TechLead --> Developer : leads\n    TechLead --> Designer : leads\n`,
    { ...RAISED, maxWidth: 400 },
  ),
  // A style is escaped into the style attribute of each element it applies to.
  lazy('class', 'one class colored by many &', () => `classDiagram\nclass A\nstyle A color:${'&'.repeat(54000000)}\n`, RAISED),
  lazy('class', 'one class colored past V8', () => `classDiagram\nclass A\nstyle A color:${'&'.repeat(110000000)}\n`, RAISED),
  // The stroke is written in the class's box and again in its dividers.
  lazy('class', 'one class stroked by many &', () => `classDiagram\nclass A {\n  x\n}\nstyle A stroke:${'&'.repeat(54000000)}\n`, RAISED),
  // A static member is underlined in its own copy of the class's text style.
  lazy('class', 'a static member of a class colored by many &', () => `classDiagram\nclass A {\n  +x$\n}\nstyle A color:${'&'.repeat(54000000)}\n`, RAISED),
  lazy('state', 'one state named by many &, with a short label', () => `stateDiagram-v2\nstate "x" as ${'&'.repeat(54000000)}\n`, RAISED),
  lazy('state', 'one state named past V8, with a short label', () => `stateDiagram-v2\nstate "x" as ${'&'.repeat(110000000)}\n`, RAISED),
  // A note is named after its state, and so is the edge to it, which names both.
  lazy('state', 'a note on a state named by many &', () => `stateDiagram-v2\nstate "x" as ${'&'.repeat(54000000)}\nnote right of ${'&'.repeat(54000000)} : n\n`, RAISED),
  lazy('state', 'one tooltip of many &', () => `stateDiagram-v2\nA\nclick A "https://x" "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('state', 'one tooltip past V8', () => `stateDiagram-v2\nA\nclick A "https://x" "${'&'.repeat(110000000)}"\n`, RAISED),
  lazy('state', 'one link of many &', () => `stateDiagram-v2\nA\nclick A href "https://x/${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('state', 'one link past V8', () => `stateDiagram-v2\nA\nclick A href "https://x/${'&'.repeat(110000000)}"\n`, RAISED),
  lazy('state', 'one state colored by many &', () => `stateDiagram-v2\nA\nstyle A color:${'&'.repeat(54000000)}\n`, RAISED),
  lazy('state', 'one state colored past V8', () => `stateDiagram-v2\nA\nstyle A color:${'&'.repeat(110000000)}\n`, RAISED),
  // A fill goes into the style of the state's box, and a color into its label's.
  lazy('state', 'one state filled by many &', () => `stateDiagram-v2\nA\nstyle A fill:${'&'.repeat(54000000)}\n`, RAISED),
  // An element's alias is its data-id, and a relation's names both its ends.
  lazy('c4', 'one person aliased by many &', () => `C4Context\nPerson(${'&'.repeat(54000000)}, "x")\n`, RAISED),
  lazy('c4', 'one person aliased past V8', () => `C4Context\nPerson(${'&'.repeat(110000000)}, "x")\n`, RAISED),
  lazy('c4', 'one boundary aliased by many &', () => `C4Context\nBoundary(${'&'.repeat(54000000)}, "x") {\n  Person(p, "x")\n}\n`, RAISED),
  lazy('c4', 'a relation between people aliased by many &', () => `C4Context\nPerson(${'&'.repeat(54000000)}, "x")\nPerson(q, "y")\nRel(${'&'.repeat(54000000)}, q, "")\n`, RAISED),
  lazy('c4', 'one relation described by many &', () => `C4Context\nPerson(p, "x")\nPerson(q, "y")\nRel(p, q, "l", "t", "${'&'.repeat(54000000)}")\n`, RAISED),
  lazy('c4', 'one link of many &', () => `C4Context\nPerson(p, "x", "d", "s", "t", "https://x/${'&'.repeat(54000000)}")\n`, RAISED),
  // A system's fill goes once into its box; a person's text color into each of its labels.
  lazy('c4', 'one system filled by many &', () => `C4Context\nSystem(s, "x")\nUpdateElementStyle(s, "${'&'.repeat(54000000)}")\n`, RAISED),
  lazy('c4', 'one person colored by many &', () => `C4Context\nPerson(p, "x")\nUpdateElementStyle(p, $fontColor="${'&'.repeat(54000000)}")\n`, RAISED),
  lazy('c4', 'one relation lined by many &', () => `C4Context\nPerson(p, "x")\nPerson(q, "y")\nRel(p, q, "l")\nUpdateRelStyle(p, q, "red", "${'&'.repeat(54000000)}")\n`, RAISED),
  // A leaf's or a section's name is its data-id; its label is cut to fit its box.
  lazy('treemap', 'one leaf named by many &', () => `treemap-beta\n"${'&'.repeat(54000000)}": 1\n`, RAISED),
  lazy('treemap', 'one leaf named past V8', () => `treemap-beta\n"${'&'.repeat(110000000)}": 1\n`, RAISED),
  lazy('treemap', 'one section named by many &', () => `treemap-beta\n"${'&'.repeat(54000000)}"\n  "b": 1\n`, RAISED),
  // A fill goes once into the box, whose tint it also turns off; a color into the name and the value.
  lazy('treemap', 'one leaf filled by many &', () => `treemap-beta\n"a": 1:::cc\nclassDef cc fill:${'&'.repeat(54000000)};\n`, RAISED),
  lazy('treemap', 'one section filled by many &', () => `treemap-beta\n"s":::cc\n  "a": 1\nclassDef cc fill:${'&'.repeat(54000000)};\n`, RAISED),
  lazy('treemap', 'one leaf colored by many &', () => `treemap-beta\n"a": 1:::cc\nclassDef cc color:${'&'.repeat(54000000)};\n`, RAISED),
  // A block is labelled by its id unless it has a label, and an edge's id names both its ends.
  lazy('block', 'one block named by many &, with a short label', () => `block-beta\n${'&'.repeat(54000000)}["x"]\n`, RAISED),
  lazy('block', 'one block named past V8, with a short label', () => `block-beta\n${'&'.repeat(110000000)}["x"]\n`, RAISED),
  lazy('block', 'one block named by many &', () => `block-beta\n${'&'.repeat(54000000)}\n`, RAISED),
  lazy('block', 'an edge label from a block named by many &', () => `block-beta\n${'&'.repeat(54000000)}["x"] B\n${'&'.repeat(54000000)} -- "l" --> B\n`, RAISED),
  lazy('block', 'one block colored by many &', () => `block-beta\nA\nstyle A color:${'&'.repeat(54000000)}\n`, RAISED),
  lazy('block', 'one block colored past V8', () => `block-beta\nA\nstyle A color:${'&'.repeat(110000000)}\n`, RAISED),
  lazy('block', 'one block filled by many &', () => `block-beta\nA\nstyle A fill:${'&'.repeat(54000000)}\n`, RAISED),
  lazy('block', 'one block classed with a color of many &', () => `block-beta\nA\nclassDef c color:${'&'.repeat(54000000)};\nclass A c\n`, RAISED),
  lazy('kanban', 'one card named by many &', () => `kanban\nc[Col]\n  ${'&'.repeat(54000000)}[x]\n`, RAISED),
  lazy('kanban', 'one card named past V8', () => `kanban\nc[Col]\n  ${'&'.repeat(110000000)}[x]\n`, RAISED),
  lazy('kanban', 'one column named by many &', () => `kanban\n${'&'.repeat(54000000)}[Col]\n  k[x]\n`, RAISED),
  // A linked ticket is written in the link's address and as the link's text.
  lazy('kanban', 'one linked ticket of many &', () => `---\nconfig:\n  kanban:\n    ticketBaseUrl: "https://x/#TICKET#"\n---\nkanban\nc[Col]\n  k[x]@{ ticket: "${'&'.repeat(54000000)}" }\n`, RAISED),
  // A card breaks its text to fit its column, which math typeset wide enough widens to hold it on one line.
  lazy('kanban', 'one card line of many & beside wide math', () => `kanban\nc[Col]\n  m[$$x$$]\n  k[${'&'.repeat(54000000)}]\n`, { ...RAISED, math: { x: { 14: { svg: '<path/>', width: 10000000000, height: 10 } } } }),
  lazy('kanban', 'one card line past V8 beside wide math', () => `kanban\nc[Col]\n  m[$$x$$]\n  k[${'&'.repeat(110000000)}]\n`, { ...RAISED, math: { x: { 14: { svg: '<path/>', width: 10000000000, height: 10 } } } }),
  // A card's icon is named in the data-icon of the host's drawing of it.
  lazyWith('kanban', 'one card icon named by many &', () => `kanban\nc[Col]\n  k[x]@{ icon: "${'&'.repeat(54000000)}" }\n`, () => ({ ...RAISED, icons: { ['&'.repeat(54000000)]: '<path/>' } })),
  lazyWith('kanban', 'one card icon named past V8', () => `kanban\nc[Col]\n  k[x]@{ icon: "${'&'.repeat(110000000)}" }\n`, () => ({ ...RAISED, icons: { ['&'.repeat(110000000)]: '<path/>' } })),
  // A value's prefix and suffix are written in each node's label and each link's title.
  lazy('sankey', 'a value prefix of many &', () => `---\nconfig:\n  sankey:\n    prefix: "${'&'.repeat(54000000)}"\n---\nsankey\n\nA,B,1\n`, RAISED),
  lazy('sankey', 'a value suffix of many &', () => `---\nconfig:\n  sankey:\n    suffix: "${'&'.repeat(54000000)}"\n---\nsankey\n\nA,B,1\n`, RAISED),
  // A node's color fills its bar and the links that leave it; a link color fills each link.
  lazy('sankey', 'a node color of many &', () => `---\nconfig:\n  sankey:\n    nodeColors:\n      A: "${'&'.repeat(54000000)}"\n---\nsankey\n\nA,B,1\n`, RAISED),
  lazy('sankey', 'a link color of many &', () => `---\nconfig:\n  sankey:\n    linkColor: "${'&'.repeat(54000000)}"\n---\nsankey\n\nA,B,1\n`, RAISED),
  lazy('sankey', 'a link color past V8', () => `---\nconfig:\n  sankey:\n    linkColor: "${'&'.repeat(110000000)}"\n---\nsankey\n\nA,B,1\n`, RAISED),
  // A node's icon is named in the data-icon of the host's drawing of it.
  lazyWith('mindmap', 'one icon named by many &', () => `mindmap\nroot\n  A\n  ::icon(${'&'.repeat(54000000)})\n`, () => ({ ...RAISED, icons: { ['&'.repeat(54000000)]: '<path/>' } })),
  lazyWith('mindmap', 'one icon named past V8', () => `mindmap\nroot\n  A\n  ::icon(${'&'.repeat(110000000)})\n`, () => ({ ...RAISED, icons: { ['&'.repeat(110000000)]: '<path/>' } })),
  // A text's id is its data-id, written among its label's attributes.
  lazy('venn', 'one text named by many &, with a short label', () => `venn-beta\nset A\n  text "${'&'.repeat(54000000)}"["x"]\n`, RAISED),
  lazy('venn', 'one text named past V8, with a short label', () => `venn-beta\nset A\n  text "${'&'.repeat(110000000)}"["x"]\n`, RAISED),
  lazy('venn', 'one set filled by many &', () => `venn-beta\nset A\nstyle A fill: "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('venn', 'one set filled past V8', () => `venn-beta\nset A\nstyle A fill: "${'&'.repeat(110000000)}"\n`, RAISED),
  lazy('venn', 'one set colored by many &', () => `venn-beta\nset A\nstyle A color: "${'&'.repeat(54000000)}"\n`, RAISED),
  // A text holding a `#35;` code is shown with every `&` escaped and the whole decoded back.
  lazy('railroad', 'one special sequence with a code and many &', () => `railroad-ebnf-beta\nr = ? #35;${'&'.repeat(54000000)} ? ;\n`, RAISED),
  lazy('railroad', 'one special sequence with a code past V8', () => `railroad-ebnf-beta\nr = ? #35;${'&'.repeat(110000000)} ? ;\n`, RAISED),
  lazy('gantt', 'one task id of many &', () => `gantt\ndateFormat YYYY-MM-DD\nsection s\nt :${'&'.repeat(54000000)}, 2026-01-01, 1d\n`, RAISED),
  // A vertical marker's id is written in its line's data-id and in its label's.
  lazy('gantt', 'one vertical marker id of many &', () => `gantt\ndateFormat YYYY-MM-DD\nsection s\nt :2026-01-01, 3d\nv :vert, ${'&'.repeat(54000000)}, 2026-01-02, 0d\n`, RAISED),
  // A section's text is written in its label's data-id and as its label.
  lazy('gantt', 'one section of many &', () => `gantt\ndateFormat YYYY-MM-DD\nsection ${'&'.repeat(54000000)}\nt :2026-01-01, 1d\n`, RAISED),
  // Every tick of an axis format without directives has the same label, which is drawn once on each axis.
  lazy('gantt', 'an axis format of many &', () => `gantt\ndateFormat YYYY-MM-DD\naxisFormat ${'&'.repeat(54000000)}\nsection s\nt :2026-01-01, 1d\n`, RAISED),
  lazy('gantt', 'an axis format of many &, on both axes', () => `gantt\ndateFormat YYYY-MM-DD\naxisFormat ${'&'.repeat(54000000)}\ntopAxis\nsection s\nt :2026-01-01, 1d\n`, RAISED),
  lazy('gantt', 'a today marker style of many &', () => `gantt\ndateFormat YYYY-MM-DD\ntodayMarker stroke:${'&'.repeat(54000000)}\nsection s\nt :2026-01-01, 3d\n`, { ...RAISED, now: Date.UTC(2026, 0, 2) }),
  lazy('gantt', 'a task link of many &', () => `gantt\ndateFormat YYYY-MM-DD\nsection s\nt :a, 2026-01-01, 1d\nclick a href "${'&'.repeat(54000000)}"\n`, RAISED),
  // An entity's name is written in its data-id and, unless an alias takes its place, as its label.
  lazy('er', 'one aliased entity named by many &', () => `erDiagram\n"${'&'.repeat(54000000)}"["x"] {\n}\n`, RAISED),
  lazy('er', 'one entity named by many &', () => `erDiagram\n"${'&'.repeat(54000000)}" {\n}\n`, RAISED),
  lazy('er', 'one attribute comment of many &', () => `erDiagram\nA {\n  string name "${'&'.repeat(54000000)}"\n}\n`, RAISED),
  lazy('er', 'one subgraph id of many &', () => `erDiagram\nsubgraph "${'&'.repeat(54000000)}"["x"]\nA\nend\n`, RAISED),
  // An internal link writes the entity's label in its href and its data-href as well.
  lazy('er', 'one internal link of many &', () => `erDiagram\nA["${'&'.repeat(54000000)}"] {\n}\nclass A internal-link\n`, RAISED),
  // A relationship's id holds the names of its entities.
  lazy('er', 'one relationship of an entity named by many &', () => `erDiagram\n"${'&'.repeat(54000000)}"["x"] {\n}\n"${'&'.repeat(54000000)}" ||--o{ B : "r"\n`, RAISED),
  lazy('requirement', 'one field of many &', () => `requirementDiagram\nrequirement r {\n  text: "${'&'.repeat(54000000)}"\n}\n`, RAISED),
  // A requirement's name is written in its data-id and as its label.
  lazy('requirement', 'one requirement named by many &', () => `requirementDiagram\nrequirement "${'&'.repeat(54000000)}" {\n}\n`, RAISED),
  // A relationship's id holds the names of its ends.
  lazy('requirement', 'one relationship of a requirement named by many &', () => `requirementDiagram\nrequirement "${'&'.repeat(54000000)}" {\n}\nelement e {\n}\n"${'&'.repeat(54000000)}" - satisfies -> e\n`, RAISED),
  lazy('flowchart', 'one tooltip of many &', () => `graph TD\nA\nclick A callback "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('flowchart', 'one link of many &', () => `graph TD\nA\nclick A href "${'&'.repeat(54000000)}"\n`, RAISED),
  // An internal link writes the node's label in its href and its data-href as well.
  lazy('flowchart', 'one internal link of many &', () => `graph TD\nA["${'&'.repeat(54000000)}"]\nclass A internal-link\n`, RAISED),
  lazy('flowchart', 'one image of many &', () => `graph TD\nA@{ img: "${'&'.repeat(54000000)}", label: "x" }\n`, RAISED),
  lazy('flowchart', 'one icon of many &', () => `graph TD\nA@{ icon: "${'&'.repeat(54000000)}", label: "x" }\n`, RAISED),
  // A subgraph named by a quoted string takes the string as its id.
  lazy('flowchart', 'one subgraph id of many &', () => `graph TD\nsubgraph "${'&'.repeat(54000000)}" [x]\nA\nend\n`, RAISED),
  lazy('swimlane', 'one tooltip of many &', () => `swimlane-beta TB\nsubgraph L\nA\nend\nclick A callback "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('swimlane', 'one link of many &', () => `swimlane-beta TB\nsubgraph L\nA\nend\nclick A href "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('swimlane', 'one lane id of many &', () => `swimlane-beta TB\nsubgraph "${'&'.repeat(54000000)}" [x]\nA\nend\n`, RAISED),
  // Without a title a lane's id is its title as well.
  lazy('swimlane', 'one lane named by many &', () => `swimlane-beta TB\nsubgraph "${'&'.repeat(54000000)}"\nA\nend\n`, RAISED),
  lazy('agentflow', 'one tooltip of many &', () => `agentflow-beta TB\n  a\n  click a callback "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('agentflow', 'one link of many &', () => `agentflow-beta TB\n  a\n  click a href "${'&'.repeat(54000000)}"\n`, RAISED),
  // An internal link writes the agent's label in its href and its data-href as well.
  lazy('agentflow', 'one internal link of many &', () => `agentflow-beta TB\n  a["${'&'.repeat(54000000)}"]\n  class a internal-link\n`, RAISED),
  lazy('usecase', 'one actor icon of many &', () => `usecase-beta\nactor User@{ icon: "${'&'.repeat(54000000)}" }\n`, RAISED),
  lazy('usecase', 'one fill of many &', () => `usecase-beta\nU("x")\nstyle U fill:${'&'.repeat(54000000)}\n`, RAISED),
  lazy('usecase', 'one text color of many &', () => `usecase-beta\nU("x")\nstyle U color:${'&'.repeat(54000000)}\n`, RAISED),
  lazy('usecase', 'one stroke of many &', () => `usecase-beta\nU("x")\nstyle U stroke:${'&'.repeat(54000000)}\n`, RAISED),
  // A use case named only by its label has an id made of it, with each `&` as `_`.
  lazy('usecase', 'one use case named by many &', () => `usecase-beta\n"${'&'.repeat(54000000)}"\n`, RAISED),
  // A plain label is laid out from its text with each `&` as a five-unit reference, which pele cannot make past V8's longest string.
  lazy('usecase', 'one use case label of many &, past V8', () => `usecase-beta\nU("${'&'.repeat(110000000)}")\n`, RAISED),
  // A shaded block's color is written as the fill of its style, unchecked.
  lazy('sequence', 'one block color of many &', () => `sequenceDiagram\nrect ${'&'.repeat(54000000)}\nA->>B: x\nend\n`, RAISED),
  lazy('sequence', 'one block color of many &, past V8', () => `sequenceDiagram\nrect ${'&'.repeat(110000000)}\nA->>B: x\nend\n`, RAISED),
  // `%c` formats a date as about 21 code units, so an axis format of many of them makes one long tick label.
  lazy('gantt', 'an axis format of many %c', () => `gantt\ndateFormat YYYY-MM-DD\naxisFormat ${'%c'.repeat(13000000)}\nsection s\nt :2026-01-01, 1d\n`, RAISED),
  lazy('gantt', 'an axis format of many %c, past V8', () => `gantt\ndateFormat YYYY-MM-DD\naxisFormat ${'%c'.repeat(30000000)}\nsection s\nt :2026-01-01, 1d\n`, RAISED),
  // A syntax error quotes its whole line, which pele finds after lexing every `<<` of it as a token.
  lazy('class', 'a generic of 140M <, quoted whole in its syntax error', () => `classDiagram\nclass A~${'<'.repeat(140000000)}~\n`, RAISED),
  // Each tab of a quoted line is escaped in the JSON answer, which so holds twice as many bytes as the line.
  lazy('railroad', 'a special sequence of 140M tabs, quoted whole in its syntax error', () => `railroad-ebnf-beta\nr = ? ${'\t'.repeat(140000000)} ? ;\n`, RAISED),
  // pele's agentflow lexer keeps four numbers per token in one array, which V8 holds to 2^27
  // elements, so it fails as nested too deeply on opening its 2^25 + 1st token; each `&` of a
  // style is a token of its own, and these sources have 16 tokens besides.
  lazy('agentflow', 'a style of 30M &, quoted whole in its syntax error', () => `agentflow-beta TB\n  a\nstyle a fill:${'&'.repeat(30000000)}\n`, RAISED),
  lazy('agentflow', 'a style of 2^25 - 16 &, the most tokens pele lexes', () => `agentflow-beta TB\n  a\nstyle a fill:${'&'.repeat(33554416)}\n`, RAISED),
  lazy('agentflow', 'a style of 2^25 - 15 &, one token more than pele lexes', () => `agentflow-beta TB\n  a\nstyle a fill:${'&'.repeat(33554417)}\n`, RAISED),
  lazy('agentflow', 'a link style of 2^25 - 15 &, one token more than pele lexes', () => `agentflow-beta TB\n  a\nlinkStyle 0 stroke:${'&'.repeat(33554417)}\n`, RAISED),
  // A source of 2^28 code units or more is held with every copy made of it, so a title that long
  // is drawn only when it is copied once out of its line rather than at each step that trims it.
  lazy('info', 'a title of 270M a', () => `info\ntitle ${'a'.repeat(270000000)}\n`, RAISED),
  // A node's id and label are joined from the texts of their tokens, of which one may be 2^28 code units long.
  lazy('flowchart', 'a node id of 270M a, written twice', () => `graph TD\n${'a'.repeat(270000000)}\n`, RAISED),
  lazy('flowchart', 'a node label of 270M a', () => `graph TD\nA[${'a'.repeat(270000000)}]\n`, RAISED),
  lazy('swimlane', 'a node id of 270M a in a lane, written twice', () => `swimlane-beta TB\nsubgraph L\n${'a'.repeat(270000000)}\nend\n`, RAISED),
  lazy('class', 'a class named by 270M a, written twice', () => `classDiagram\nclass ${'a'.repeat(270000000)}\n`, RAISED),
  lazy('class', 'a member of 270M a', () => `classDiagram\nclass A {\n  ${'a'.repeat(270000000)}\n}\n`, RAISED),
  lazy('er', 'an entity named by 270M a, written twice', () => `erDiagram\n${'a'.repeat(270000000)} {}\n`, RAISED),
  lazy('agentflow', 'an agent named by 270M a, written twice', () => `agentflow-beta TB\n  ${'a'.repeat(270000000)}\n`, RAISED),
  lazy('gantt', 'a task named by 270M a', () => `gantt\ndateFormat YYYY-MM-DD\nsection S\n${'a'.repeat(270000000)} :2026-01-01, 1d\n`, RAISED),
  lazy('sequence', 'a message of 270M a', () => `sequenceDiagram\nA->>B: ${'a'.repeat(270000000)}\n`, RAISED),
  lazy('eventmodeling', 'a frame\'s entity named by 270M a', () => `eventmodeling\ntf 01 evt ${'a'.repeat(270000000)}\n`, RAISED),
];

// A case whose source is built only when the check reaches it, as a getter in the source's place,
// so that sources of a hundred million characters are not all held at once.
function lazy(diagram, name, source, options) {
  const entry = [diagram, name, undefined, options];
  Object.defineProperty(entry, 2, { get: source, enumerable: true });
  return entry;
}

// A lazy case whose options are built only when the check reaches it too, for an icon named by a
// text as long as the source.
function lazyWith(diagram, name, source, options) {
  const entry = lazy(diagram, name, source, undefined);
  Object.defineProperty(entry, 3, { get: options, enumerable: true });
  return entry;
}
