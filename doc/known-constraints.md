# Known constraints

The port follows the behaviour pele means to have, not the limits of the JavaScript engine it runs on.
So it departs from pele on purpose where pele fails only because V8 runs out of room, and it still differs from pele on a few enormous inputs that it cannot handle within wasm.
Each input below is of millions to hundreds of millions of characters.

## Where pele fails on V8's limits

pele reports each of the failures below as the `limit` error "Diagram is nested too deeply.", tagged with the diagram's type unless it happens before detection.
The port does the work instead, and answers as pele would have without the engine's limit: with the drawing, with the error pele gives a slightly smaller input, with pele's output limit error, or with the port's own `limit` error where the drawing passes the hold limit that [Output ceiling](output-ceiling.md) describes.

- String length: pele builds its SVG by concatenation, and V8 throws a `RangeError` once a string would pass 536870888 UTF-16 code units, the longest string it makes on a 64-bit host.
    The port's hold limit is lower than that, so a drawing past V8's longest string fails in the port with pele's output limit error when the output limit is below its length, and otherwise with the port's own error.
- Array length: V8 holds at most 2^27 elements in an array grown by pushing.
    pele's agentflow lexer keeps four numbers per token in one array, so it fails on opening its 2^25 + 1st token, while the port lexes on and gives the syntax error pele gives a style of a token fewer.
    pele cuts a label too wide for its box among `Array.from` of its code points, so it fails on a label of more than 2^27 code points, which the port cuts and draws.
    pele's other arrays of one element per character, `split('')` in `generics.ts` and the spread in `sequence/db.ts`, fail past 2^27 elements in the same way.
- Regular expression backtracking: a pattern that repeats a group with more than one way through it keeps a few slots of V8's 64 MiB backtracking stack for every repetition, and V8 throws once the stack is full.
    pele runs such patterns over a quoted string in the git graph, pie, packet, radar, Wardley map, Cynefin, architecture and railroad diagrams, an architecture label, an ABNF numeric value, a Wardley name, a run of line breaks in a flowchart and after the flowchart and agentflow keywords, the body of every `%%{...}%%` directive, and the host's font lists.
    pele therefore fails a quoted string past about 4 million characters and a run of line breaks, a directive body or a name past about 8 million, all of which the port reads to their end.

Inputs nested deeply enough to run pele out of V8's call stack are covered by paragraphs of their own.

## Where the port cannot follow pele

On the first six inputs below the plugin traps, by refusing an allocation or running out of memory, where pele draws the diagram or, without V8's limits, would fail it with a `limit` error; each was rendered through pele and through the plugin to confirm it.
They are accepted as constraints rather than reproduced, because each would need another part of the port to be rebuilt around pieces.

- A `classDef` or `style` value of about 270 million plain letters in a flowchart, class, state, ER, block or agentflow diagram, which pele draws: `resolve_style` and `resolve_raw_style` in `pele/src/svg/` lowercase it with `lower_ascii` in `pele/src/svg/style.mbt` into a doubling `StringBuilder`, which needs more than the largest block wasm's allocator gives.
- A kanban card label of about 270 million plain letters, which pele fails on one of V8's limits: the plugin traps before the card's lines, each written into `Markup` on its own, are all written.
- A label that typesets math under a style or an id of 2^28 code units or more, which pele fails on one of V8's limits: `write_label_styled` and `write_label_with_id` give the math its color from their attributes made into one string.
- An option string of 2^28 code units or more, such as a single host icon drawing, which pele draws: the plugin reads its options with `JsonReader::string` in `pele/src/util/json.mbt` into a doubling `StringBuilder`, and `icon_svg` in `pele/src/diagrams/common/icon.mbt`, which the tree view and the architecture's `icon_slot` draw icons with, makes the icon one string as well.
- An ER attribute type of about 70 million `~`, which pele draws as an SVG of 280 million code units: `@text.layout_label` lays the attribute's label out from a source of 280 million code units.
- A source of more than 2^27 tokens, such as a class diagram of 134 million commas: pele fails on V8's array length on its 2^27 + 1st token, while the port runs out of memory before it gets there.
- A Gantt axis label or a use case label whose text alone passes the hold limit fails with the port's own `limit` error as soon as the text is built, before pele's output limit is checked, so under an output limit below the drawing the port gives its own error where pele, without V8's limits, would give the output limit's.
- `moon test` runs the allocator unmended, as [the allocator bug](allocator-bug.md) describes, so its tests of 2^28 code units or more are skipped and `scripts/check-string-length.mjs` checks the same inputs instead.
- A journey task or a timeline event of about 270 million characters, and a timeline event or a quadrant label of a hundred million, run pele itself out of node's heap, so there is no outcome of pele's to compare the port with.

The port also differs from pele on an init directive nested deeply enough, where pele's recursive merge runs V8 out of stack and keeps only the keys it merged before that.
The depth where that happens varies with the platform and the process: about 4,468 objects on arm64 macOS with node 24, and deeper on x86_64 Linux.
The port does not cut the merge off on purpose and applies every key of such a directive, so the two agree below the depth where pele stops and differ past it.

The port also differs from pele on a pie `legendPosition` nested deeply enough in arrays, where pele's `String()` joins the arrays by recursion, runs V8 out of stack and fails the diagram as nested too deeply.
The depth where that happens varies with the platform and the process: about 2,750 levels with node 24's default stack on arm64 macOS, against about 760 with a 300 KB stack and 11,500 with 4 MB.
The port does not cut the stringification off on purpose and writes such a legend position to the end, so the two agree below the depth where pele stops and differ past it.
