// The inputs scripts/check-string-length.mjs renders, as [diagram, name, source, options].
// The options are in the JSON form the plugin reads, so an icon resolver is a map from name to fragment.
// Each source is one whose drawing pele makes past what a doubling StringBuilder holds, or past the
// port's hold limit, or whose error quotes a line that long; many are the same as a test in
// pele/src/diagrams/<diagram>/string_length_test.mbt, which skips the slow ones.
// Every case builds its source and options only when the check reaches it, so that a check of one
// diagram holds no other diagram's inputs and only one of its own at a time.

const names = (prefix, count) => Array.from({ length: count }, (_, i) => `${prefix}${i}`);
const fill = `fill:#${'a'.repeat(50000)}`;
export const RAISED = { limit: Number.MAX_VALUE, outputLimit: Number.MAX_VALUE };
// A single label grows without bound when the host's drawing of an icon is drawn in each of its
// icon spans, whatever diagram the label is in.
const ICONS = { ...RAISED, icons: { 'fa:fa-x': `<path d="${'M0 0'.repeat(25000)}"/>` } };
const iconLabel = (count) => `graph TD\nA["${Array(count).fill('fa:fa-x').join(' ')}"]\n`;

export const CASES = [
  lazy(
    'flowchart',
    'nodes drawn past what a doubling StringBuilder holds',
    () => `graph TD\nclassDef c ${fill}\n${names('n', 6000).map((name) => `${name}:::c`).join(';')}\n`,
    RAISED,
  ),
  // pele draws this past the port's hold limit, so the port returns its own limit error: the one
  // intentional, platform-imposed difference from pele.
  lazy(
    'flowchart',
    'edges pele draws past the port',
    () => `graph LR\nclassDef c ${fill}\n${names('n', 10600).map((name) => `${name}:::c`).join('-->')}\n`,
    { ...RAISED, maxEdges: 1000000000, maxWidth: 300 },
  ),
  lazy('flowchart', 'one node label longer than a doubling StringBuilder holds', () => iconLabel(3000), ICONS),
  // Drawn down, after it is drawn across, because the host is narrow.
  lazy('eventmodeling', 'time frames sharing long data, drawn down', () => `eventmodeling\n${names('', 549).map((_, i) => `tf ${i + 1} evt E [[D]]`).join('\n')}\ndata D {\n  f: '${'&'.repeat(94000)}'\n}\n`, { ...RAISED, maxWidth: 300 }),
  lazy('ishikawa', 'long causes, drawn down', () => `ishikawa-beta\nProblem\n${names('C', 545).map((name) => `${name}${'&'.repeat(50000)}`).join('\n')}\n`, { ...RAISED, maxWidth: 300 }),
  // Drawn down, after it is drawn across, because the host is narrow; the people make the drawing down the larger.
  lazy('journey', 'long people, drawn down', () => `journey\nsection S\n${names('T', 990).map((name) => `  ${name}: 5: ${names('P', 10).map((person) => `${person}${'&'.repeat(5000)}`).join(', ')}`).join('\n')}\n`, { ...RAISED, maxWidth: 300 }),
  // Drawn across past the port's hold limit, which is only measured, then drawn down within it.
  lazy('journey', 'long tasks, drawn down within the port after across past it', () => `journey\nsection S\n${names('T', 846).map((name) => `  ${name}${'&'.repeat(50000)}: 5: Me`).join('\n')}\n`, { ...RAISED, maxWidth: 300 }),
  // Each `&` of an accessible description is escaped to five code units in the document's head.
  lazy('pie', 'an accessible description longer than a doubling StringBuilder holds', () => `pie\naccDescr: ${'&'.repeat(60000000)}\n"a":1\n`, RAISED),
  // An info diagram repeats nothing, so only its one title or accessible description can grow.
  lazy('info', 'a title longer than a doubling StringBuilder holds', () => `info\ntitle ${'&'.repeat(60000000)}\n`, RAISED),
  lazy('info', 'an accessible description longer than a doubling StringBuilder holds', () => `info\naccDescr: ${'&'.repeat(60000000)}\n`, RAISED),
  // `<` rather than `&`, which YAML reads as an anchor.
  lazy('sequence', 'a front matter title longer than a doubling StringBuilder holds', () => `---\ntitle: ${'<'.repeat(70000000)}\n---\nsequenceDiagram\nA->>B: x\n`, RAISED),
  lazy('eventmodeling', 'one frame with data drawn past what a doubling StringBuilder holds', () => `eventmodeling\ntf 01 evt E "${'&'.repeat(60000000)}"\n`, RAISED),
  lazy('xychart', 'one category drawn past what a doubling StringBuilder holds', () => `xychart\nx-axis ["${'&'.repeat(60000000)}"]\nbar [1]\n`, RAISED),
  // pele checks its output limit against a drawing past the port's hold limit, so the port gives
  // pele's output limit error rather than its own wherever the output limit is below the drawing.
  lazy(
    'flowchart',
    'edges pele draws past the port, under the default output limit',
    () => `graph LR\nclassDef c ${fill}\n${names('n', 10600).map((name) => `${name}:::c`).join('-->')}\n`,
    { limit: Number.MAX_VALUE, maxEdges: 1000000000, maxWidth: 300 },
  ),
  // The SVG, at 2^28 code units or more, needs a block of at least 512 MiB, where MoonBit's
  // allocator once handed out a smaller free block and the drawing overwrote what lay past it.
  lazy('git', 'a branch named by 140M a, drawn into a block of 512 MiB or more', () => `gitGraph\ncommit\nbranch ${'a'.repeat(140000000)}\ncommit\n`, RAISED),
  // A journey wraps its title into lines, each its own tspan, after escaping every `<` of it.
  lazy('journey', 'a front matter title wrapped past what a doubling StringBuilder holds', () => `---\ntitle: ${'<'.repeat(70000000)}\n---\njourney\nsection S\n  T: 5: Me\n`, RAISED),
  lazy('journey', 'a front matter title wrapped past what a doubling StringBuilder holds, drawn down', () => `---\ntitle: ${'<'.repeat(70000000)}\n---\njourney\nsection S\n  T: 5: Me\n`, { ...RAISED, maxWidth: 300 }),
  lazy('timeline', 'a front matter title wrapped past what a doubling StringBuilder holds', () => `---\ntitle: ${'<'.repeat(70000000)}\n---\ntimeline\n  p : e\n`, RAISED),
  // A Gantt chart without tasks draws only its title.
  lazy('gantt', 'a title over no tasks longer than a doubling StringBuilder holds', () => `gantt\ntitle ${'<'.repeat(70000000)}\n`, RAISED),
  // Each of these escapes 54 million `&` into more than a doubling StringBuilder holds.
  lazy('class', 'one member of many &', () => `classDiagram\nclass A {\n  ${'&'.repeat(54000000)}\n}\n`, RAISED),
  lazy('class', 'one annotation of many &', () => `classDiagram\nclass A {\n  <<${'&'.repeat(54000000)}>>\n}\n`, RAISED),
  // A class is named in its data-id, and labelled by its name unless it has a label.
  lazy('class', 'one class named by many &, with a short label', () => `classDiagram\nclass \`${'&'.repeat(54000000)}\`["x"]\n`, RAISED),
  lazy('class', 'one cardinality of many &', () => `classDiagram\nA "${'&'.repeat(54000000)}" --> B\n`, RAISED),
  lazy('class', 'one tooltip of many &', () => `classDiagram\nclass A\nclick A call f() "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('class', 'one link of many &', () => `classDiagram\nclass A\nclick A href "https://x/${'&'.repeat(54000000)}"\n`, RAISED),
  // A style is escaped into the style attribute of each element it applies to.
  lazy('class', 'one class colored by many &', () => `classDiagram\nclass A\nstyle A color:${'&'.repeat(54000000)}\n`, RAISED),
  lazy('state', 'one state named by many &, with a short label', () => `stateDiagram-v2\nstate "x" as ${'&'.repeat(54000000)}\n`, RAISED),
  lazy('state', 'one tooltip of many &', () => `stateDiagram-v2\nA\nclick A "https://x" "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('state', 'one link of many &', () => `stateDiagram-v2\nA\nclick A href "https://x/${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('state', 'one state colored by many &', () => `stateDiagram-v2\nA\nstyle A color:${'&'.repeat(54000000)}\n`, RAISED),
  // A fill goes into the style of the state's box, and a color into its label's.
  lazy('state', 'one state filled by many &', () => `stateDiagram-v2\nA\nstyle A fill:${'&'.repeat(54000000)}\n`, RAISED),
  // An element's alias is its data-id, and a relation's names both its ends.
  lazy('c4', 'one person aliased by many &', () => `C4Context\nPerson(${'&'.repeat(54000000)}, "x")\n`, RAISED),
  lazy('c4', 'one boundary aliased by many &', () => `C4Context\nBoundary(${'&'.repeat(54000000)}, "x") {\n  Person(p, "x")\n}\n`, RAISED),
  lazy('c4', 'one relation described by many &', () => `C4Context\nPerson(p, "x")\nPerson(q, "y")\nRel(p, q, "l", "t", "${'&'.repeat(54000000)}")\n`, RAISED),
  lazy('c4', 'one link of many &', () => `C4Context\nPerson(p, "x", "d", "s", "t", "https://x/${'&'.repeat(54000000)}")\n`, RAISED),
  // A system's fill goes once into its box; a person's text color into each of its labels.
  lazy('c4', 'one system filled by many &', () => `C4Context\nSystem(s, "x")\nUpdateElementStyle(s, "${'&'.repeat(54000000)}")\n`, RAISED),
  // A leaf's or a section's name is its data-id; its label is cut to fit its box.
  lazy('treemap', 'one leaf named by many &', () => `treemap-beta\n"${'&'.repeat(54000000)}": 1\n`, RAISED),
  lazy('treemap', 'one section named by many &', () => `treemap-beta\n"${'&'.repeat(54000000)}"\n  "b": 1\n`, RAISED),
  // A fill goes once into the box, whose tint it also turns off; a color into the name and the value.
  lazy('treemap', 'one leaf filled by many &', () => `treemap-beta\n"a": 1:::cc\nclassDef cc fill:${'&'.repeat(54000000)};\n`, RAISED),
  lazy('treemap', 'one section filled by many &', () => `treemap-beta\n"s":::cc\n  "a": 1\nclassDef cc fill:${'&'.repeat(54000000)};\n`, RAISED),
  // A block is labelled by its id unless it has a label, and an edge's id names both its ends.
  lazy('block', 'one block named by many &, with a short label', () => `block-beta\n${'&'.repeat(54000000)}["x"]\n`, RAISED),
  lazy('block', 'one block colored by many &', () => `block-beta\nA\nstyle A color:${'&'.repeat(54000000)}\n`, RAISED),
  lazy('block', 'one block filled by many &', () => `block-beta\nA\nstyle A fill:${'&'.repeat(54000000)}\n`, RAISED),
  lazy('block', 'one block classed with a color of many &', () => `block-beta\nA\nclassDef c color:${'&'.repeat(54000000)};\nclass A c\n`, RAISED),
  lazy('kanban', 'one card named by many &', () => `kanban\nc[Col]\n  ${'&'.repeat(54000000)}[x]\n`, RAISED),
  lazy('kanban', 'one column named by many &', () => `kanban\n${'&'.repeat(54000000)}[Col]\n  k[x]\n`, RAISED),
  // A card breaks its text to fit its column, which math typeset wide enough widens to hold it on one line.
  lazy('kanban', 'one card line of many & beside wide math', () => `kanban\nc[Col]\n  m[$$x$$]\n  k[${'&'.repeat(54000000)}]\n`, { ...RAISED, math: { x: { 14: { svg: '<path/>', width: 10000000000, height: 10 } } } }),
  // A card's icon is named in the data-icon of the host's drawing of it.
  lazyWith('kanban', 'one card icon named by many &', () => `kanban\nc[Col]\n  k[x]@{ icon: "${'&'.repeat(54000000)}" }\n`, () => ({ ...RAISED, icons: { ['&'.repeat(54000000)]: '<path/>' } })),
  lazy('sankey', 'a link color of many &', () => `---\nconfig:\n  sankey:\n    linkColor: "${'&'.repeat(54000000)}"\n---\nsankey\n\nA,B,1\n`, RAISED),
  // A node's icon is named in the data-icon of the host's drawing of it.
  lazyWith('mindmap', 'one icon named by many &', () => `mindmap\nroot\n  A\n  ::icon(${'&'.repeat(54000000)})\n`, () => ({ ...RAISED, icons: { ['&'.repeat(54000000)]: '<path/>' } })),
  // A text's id is its data-id, written among its label's attributes.
  lazy('venn', 'one text named by many &, with a short label', () => `venn-beta\nset A\n  text "${'&'.repeat(54000000)}"["x"]\n`, RAISED),
  lazy('venn', 'one set filled by many &', () => `venn-beta\nset A\nstyle A fill: "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('venn', 'one set colored by many &', () => `venn-beta\nset A\nstyle A color: "${'&'.repeat(54000000)}"\n`, RAISED),
  // A text holding a `#35;` code is shown with every `&` escaped and the whole decoded back.
  lazy('railroad', 'one special sequence with a code and many &', () => `railroad-ebnf-beta\nr = ? #35;${'&'.repeat(54000000)} ? ;\n`, RAISED),
  lazy('gantt', 'one task id of many &', () => `gantt\ndateFormat YYYY-MM-DD\nsection s\nt :${'&'.repeat(54000000)}, 2026-01-01, 1d\n`, RAISED),
  // Every tick of an axis format without directives has the same label, which is drawn once on each axis.
  lazy('gantt', 'an axis format of many &', () => `gantt\ndateFormat YYYY-MM-DD\naxisFormat ${'&'.repeat(54000000)}\nsection s\nt :2026-01-01, 1d\n`, RAISED),
  lazy('gantt', 'a today marker style of many &', () => `gantt\ndateFormat YYYY-MM-DD\ntodayMarker stroke:${'&'.repeat(54000000)}\nsection s\nt :2026-01-01, 3d\n`, { ...RAISED, now: Date.UTC(2026, 0, 2) }),
  lazy('gantt', 'a task link of many &', () => `gantt\ndateFormat YYYY-MM-DD\nsection s\nt :a, 2026-01-01, 1d\nclick a href "${'&'.repeat(54000000)}"\n`, RAISED),
  // An entity's name is written in its data-id and, unless an alias takes its place, as its label.
  lazy('er', 'one aliased entity named by many &', () => `erDiagram\n"${'&'.repeat(54000000)}"["x"] {\n}\n`, RAISED),
  lazy('er', 'one attribute comment of many &', () => `erDiagram\nA {\n  string name "${'&'.repeat(54000000)}"\n}\n`, RAISED),
  lazy('er', 'one subgraph id of many &', () => `erDiagram\nsubgraph "${'&'.repeat(54000000)}"["x"]\nA\nend\n`, RAISED),
  lazy('requirement', 'one field of many &', () => `requirementDiagram\nrequirement r {\n  text: "${'&'.repeat(54000000)}"\n}\n`, RAISED),
  lazy('flowchart', 'one tooltip of many &', () => `graph TD\nA\nclick A callback "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('flowchart', 'one link of many &', () => `graph TD\nA\nclick A href "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('flowchart', 'one image of many &', () => `graph TD\nA@{ img: "${'&'.repeat(54000000)}", label: "x" }\n`, RAISED),
  lazy('flowchart', 'one icon of many &', () => `graph TD\nA@{ icon: "${'&'.repeat(54000000)}", label: "x" }\n`, RAISED),
  // A subgraph named by a quoted string takes the string as its id.
  lazy('flowchart', 'one subgraph id of many &', () => `graph TD\nsubgraph "${'&'.repeat(54000000)}" [x]\nA\nend\n`, RAISED),
  lazy('swimlane', 'one tooltip of many &', () => `swimlane-beta TB\nsubgraph L\nA\nend\nclick A callback "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('swimlane', 'one link of many &', () => `swimlane-beta TB\nsubgraph L\nA\nend\nclick A href "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('swimlane', 'one lane id of many &', () => `swimlane-beta TB\nsubgraph "${'&'.repeat(54000000)}" [x]\nA\nend\n`, RAISED),
  lazy('agentflow', 'one tooltip of many &', () => `agentflow-beta TB\n  a\n  click a callback "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('agentflow', 'one link of many &', () => `agentflow-beta TB\n  a\n  click a href "${'&'.repeat(54000000)}"\n`, RAISED),
  lazy('usecase', 'one actor icon of many &', () => `usecase-beta\nactor User@{ icon: "${'&'.repeat(54000000)}" }\n`, RAISED),
  lazy('usecase', 'one fill of many &', () => `usecase-beta\nU("x")\nstyle U fill:${'&'.repeat(54000000)}\n`, RAISED),
  lazy('usecase', 'one text color of many &', () => `usecase-beta\nU("x")\nstyle U color:${'&'.repeat(54000000)}\n`, RAISED),
  lazy('usecase', 'one stroke of many &', () => `usecase-beta\nU("x")\nstyle U stroke:${'&'.repeat(54000000)}\n`, RAISED),
  // A use case named only by its label has an id made of it, with each `&` as `_`.
  lazy('usecase', 'one use case named by many &', () => `usecase-beta\n"${'&'.repeat(54000000)}"\n`, RAISED),
  // A shaded block's color is written as the fill of its style, unchecked.
  lazy('sequence', 'one block color of many &', () => `sequenceDiagram\nrect ${'&'.repeat(54000000)}\nA->>B: x\nend\n`, RAISED),
  // `%c` formats a date as about 21 code units, so an axis format of many of them makes one long tick label.
  lazy('gantt', 'an axis format of many %c', () => `gantt\ndateFormat YYYY-MM-DD\naxisFormat ${'%c'.repeat(13000000)}\nsection s\nt :2026-01-01, 1d\n`, RAISED),
  // A syntax error quotes its whole line, which pele finds after lexing every `<<` of it as a token.
  lazy('class', 'a generic of 140M <, quoted whole in its syntax error', () => `classDiagram\nclass A~${'<'.repeat(140000000)}~\n`, RAISED),
  // Each tab of a quoted line is escaped in the JSON answer, which so holds twice as many bytes as the line.
  lazy('railroad', 'a special sequence of 140M tabs, quoted whole in its syntax error', () => `railroad-ebnf-beta\nr = ? ${'\t'.repeat(140000000)} ? ;\n`, RAISED),
  // A point's style runs to the line's end as one token per `-`, of which only the part before the next colon is read.
  lazy('quadrant', 'a point color followed by 110M -', () => `quadrantChart\nP: [0.5, 0.5] color: x:${'-'.repeat(110000000)}\n`, RAISED),
  // Each `&` of a style is a token of its own.
  lazy('agentflow', 'a style of 30M &, quoted whole in its syntax error', () => `agentflow-beta TB\n  a\nstyle a fill:${'&'.repeat(30000000)}\n`, RAISED),
  // A source of 2^28 code units or more is held with every copy made of it, so a title that long
  // is drawn only when it is copied once out of its line rather than at each step that trims it.
  lazy('info', 'a title of 270M a', () => `info\ntitle ${'a'.repeat(270000000)}\n`, RAISED),
  lazy('flowchart', 'a node label of 270M a', () => `graph TD\nA[${'a'.repeat(270000000)}]\n`, RAISED),
  lazy('class', 'a member of 270M a', () => `classDiagram\nclass A {\n  ${'a'.repeat(270000000)}\n}\n`, RAISED),
  lazy('gantt', 'a task named by 270M a', () => `gantt\ndateFormat YYYY-MM-DD\nsection S\n${'a'.repeat(270000000)} :2026-01-01, 1d\n`, RAISED),
  lazy('sequence', 'a message of 270M a', () => `sequenceDiagram\nA->>B: ${'a'.repeat(270000000)}\n`, RAISED),
  lazy('eventmodeling', 'a frame\'s entity named by 270M a', () => `eventmodeling\ntf 01 evt ${'a'.repeat(270000000)}\n`, RAISED),
  lazy('xychart', 'a category of 270M a', () => `xychart\nx-axis [${'a'.repeat(270000000)}]\nbar [1]\n`, RAISED),
  // pele cuts a label too wide for its box among its code points, held in an array of one element each.
  lazy('treemap', 'a leaf label of 2^27 a, cut among its code points', () => `treemap-beta\n"${'a'.repeat(134217728)}": 1\n`, RAISED),
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
