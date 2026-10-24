# Output ceiling

pele builds its SVG by string concatenation, and V8 throws a `RangeError` once a string would pass 536870888 UTF-16 code units, the longest string it makes on a 64-bit host.
pele reports that as the `limit` error "Diagram is nested too deeply." before it checks its own output limit, so an input whose SVG crosses that length fails there even under the default options.
The port reproduces this: `Markup` in `pele/src/svg/markup.mbt` keeps a drawing as pieces, counts its length as each piece is written, and raises the same error at the same point.

The port stops below V8's longest string.
It runs as wasm32 with one linear memory of at most 4 GiB, and holds a drawing's pieces, the single string made of them, and the UTF-8 bytes of the response at once, so it stops at 400000000 code units of SVG (`HOLD_LIMIT` in `pele/src/svg/markup.mbt`).
An SVG larger than that, which pele draws and a wasm32 plugin cannot hold, fails with the `limit` error "Diagram output is too large for the wasm port: it would hold more than 400000000 code units, the most the port can hold at once.", tagged with the diagram's type.
pele checks its output limit against such a drawing as against any other, so the port does as well, from the length it keeps of a drawing it does not hold: under the default output limit, or any output limit below the drawing's length, the drawing fails with pele's "Diagram output is longer than the limit of N characters.", and only one the output limit allows fails with the port's error; the flowchart case "edges pele draws past the port but under V8, under the default output limit" checks it.
This ceiling is the one intentional, platform-imposed difference from pele: every SVG at or under it is drawn byte for byte as pele draws it, apart from the enormous inputs listed under [Known constraints](known-constraints.md).

## The answer

The plugin answers with JSON, which `typst/src/plugin/response.mbt` first counts and then writes into one block of its final size, so the SVG is held only once more however long it is.
A failure is answered the same way, because its message can quote a whole line of the source, and a syntax error's snippet and message are built at their final size before that.
typst reads the answer from one block of the plugin's memory, so an answer over 1000000000 bytes fails instead with the `limit` error "Diagram output is longer than the typst plugin can return: its JSON response would pass the plugin's limit of 1000000000 bytes.", tagged with the diagram's type, or for a failure with the failure's.

## Which diagrams can reach it

A diagram reaches the ceiling when some repeated part of its source multiplies into the SVG without a cap, so that a source within the limit draws an SVG past it.
Every diagram that writes a `classDef` or `style` into each of many elements can, and so can every diagram that draws host icons, because the icon markup the host supplies is unbounded.
The `limit` option caps only the length of the source, so once it is raised a diagram also reaches the ceiling by count alone, because an element draws hundreds of code units from a source line of a dozen and few diagrams cap how many elements they draw.
Repeated text amplifies further, because `&` escapes to five code units and an element often writes its name both in its `data-id` and in its label.

Every diagram builds its SVG with `Markup`, so each fails with a `limit` error where pele does, and each has amplifying inputs in `scripts/string-length-cases.mjs` and tests, skipped where they are slow, in `pele/src/diagrams/<diagram>/string_length_test.mbt`.
The C4 diagram draws no host markup, only an empty icon box of about 260 code units for each icon span in a label, so it reaches V8's longest string only from a source of tens of millions of code units under a raised `limit`.
The git graph draws neither host icons nor styles but writes each `&` of a commit id as five code units twice, in the commit's `data-id` and in its label, so that with the `limit` option raised a source a tenth of V8's longest string reaches the ceiling.
Some diagrams reach the ceiling only past a cap that looks as if it bounded them:

- pele draws no host icons or math in a pie chart, and only the slices of at least one percent, but every entry has a legend item.
- The packet diagram draws at most 10000 rows, which keeps it under 2^28 code units at the default 32 bits per row, but `packet.bitsPerRow` may be raised to 4096.
- The radar chart draws at most 32 graticule rings, but a polygon ring passes through every axis.
- The ids of an event model's time frames have at most three digits, which bounds the frames, but each frame draws the whole data block it names.

Laying out a Venn diagram takes pele time that grows faster than the number of sets, so the Venn input puts many texts in one set instead.

The event model, Ishikawa, and journey diagrams are drawn down for a narrow host after they are drawn across, so each also has an input whose drawing down pele draws between 2^28 code units and the hold limit.
A diagram drawn more than once to fit a narrow host, through `tighten`, `fit_width` or `turn_to_fit` in `pele/src/diagrams/common/`, measures a drawing past the hold limit as pele does, because `markup_document` leaves that document as a stand-in that keeps only its length rather than failing, and `pele/src/core/core.mbt` refuses only the drawing the diagram answers with.
The journey case "long tasks, drawn down within the port after across past it" and the journey and Ishikawa cases "drawn down past V8 after across past the port" check that the drawing down is drawn, or fails as nested too deeply, where pele's is, after a drawing across past the hold limit.

The info diagram draws only its title and pele's version, so no part of it repeats; it reaches the ceiling only through a single title or accessible description, and its cases check both where pele draws them and where pele fails.

## Long text

A single text can reach the ceiling on its own, however small the diagram: a label of thousands of host icons or `$$…$$` spans, each drawing the host's markup, or a label, id or style of tens of millions of `&`, each escaped to five code units.
Apart from the inputs under [Known constraints](known-constraints.md), none of these is built as one string before it is written, because a `StringBuilder` doubles its buffer and wasm's allocator refuses the block of 1 GiB that would follow 2^28 code units, while `Markup` keeps a long piece as it is and allocates the whole drawing at its final size.
The writers that put such text into `Markup` are these:

- `Markup::write_esc`, `Markup::write_esc_text` and `Markup::write_data_id` in `pele/src/svg/escape.mbt` escape 65536 code units at a time, and search each escaped piece together with the end of the one before for the private aliases, such as `var(--_w)`, that the root element declares.
- `write_label`, `write_edge_label` and `write_struck_title` in `pele/src/svg/` and `write_left_label` in `pele/src/diagrams/common/` write each span's text with the escape writers and each host drawing as a piece of its own, and `write_label_styled` and `write_label_with_id` add a style and an id written the same way.
- `write_style`, `write_rounded_style` and `write_styled` in `pele/src/svg/style_writers.mbt` write the style that `resolve_raw_style` makes of a `classDef` or `style` a piece at a time, and `write_icon` in `pele/src/diagrams/common/` writes an icon's name and drawing apart.

Every diagram writes its labels, titles, ids, tooltips, links, icon names, styles and axis labels with these writers, and `markup_document` writes the accessible name and description with them as well, holding them with the content so that they count toward the hold limit.
Each has a case named for the text it fills, such as "host icons in one node label", "one tooltip of many &" or "a title past V8", and the info and pie cases check the accessible text.
The requirement diagram draws no host icons, so its case fills a field with math instead; a kanban card breaks its label to fit its column, so its case keeps math typeset almost without width on one line; and a C4 label draws each icon span only as an empty box, so its cases hold millions of spans.

The few texts that are rewritten before they are written are built at their final size instead: `plain_text` in `pele/src/diagrams/common/fit.mbt`, which escapes a journey or timeline title before it is wrapped into lines, the use case's `literal`, a syntax error's snippet, and the style that typst's theme rewrites.
The theme rewrites each tag of the SVG as `write_drawable` in `typst/src/typst/` copies it into the answer, and `rebuild` in `typst/src/typst/declarations.mbt` makes a new style only where a declaration changes.
`inline` in `pele/src/text/label.mbt` takes a line's text as slices of the source rather than copying it, and `@util.slice` shares the strings of one or two ASCII code units, so a source lexed into tens of millions of one-character tokens does not hold a string for each.

pele reads a quoted string in the git graph, pie, packet, radar, Wardley map, Cynefin, architecture and a railroad terminal with a pattern that runs out of V8's backtracking stack past 4194294 characters, and reports that as the `limit` error while lexing, so a quoted label there reaches V8's longest string only through host icons the label draws; their cases of `&` fail in pele and in the port while lexing, as [V8's backtracking stack](#v8s-backtracking-stack) describes.

## V8's longest array

V8 holds at most 2^27 elements in an array grown by pushing, `JS_ARRAY_MAX_LENGTH` in `pele/src/util/js_array.mbt`, and pele reports the `RangeError` of a push past it as "Diagram is nested too deeply.".
pele's agentflow lexer keeps four numbers per token in one array, so it fails on opening its 2^25 + 1st token, and the port's agentflow lexer raises the same error there; the agentflow cases "a style of 2^25 - 16 &, the most tokens pele lexes" and "a style of 2^25 - 15 &, one token more than pele lexes" check both sides of it.
pele cuts a label too wide for its box among `Array.from` of its code points, so a label of more than 2^27 code points fails as nested too deeply, and `fit_text` in `pele/src/diagrams/common/` raises the same; the treemap cases "a leaf label of 2^27 a, cut among as many code points as V8 holds" and "a leaf label of 2^27 + 1 a, one code point past what V8 holds" check it.

## V8's backtracking stack

A regular expression that repeats a group with more than one way through it, such as `(?:a|bc)*`, keeps a few slots of V8's backtracking stack for every repetition until the match ends.
That stack holds 64 MiB of four-byte slots, and V8 throws a `RangeError` once a match fills all but the 32 it keeps as slack, so pele reports a long enough match of such a pattern as the `limit` error "Diagram is nested too deeply.", tagged with the diagram's type unless it happens before detection.
`BACKTRACK_STACK_SLOTS` in `pele/src/util/backtrack.mbt` is that size, and each scanner that answers as one of these patterns counts the slots its match takes and raises the error where V8 throws.
The table below lists the slots each pattern takes, measured under node 24.21 and checked against V8 on random inputs near the point where it throws.
They do not depend on the rest of the input, except for the font list, whose pattern has the `u` flag and which V8 matches as two-byte text once it holds a character past Latin-1.

| Pattern                                                                                | Where pele runs it                                                                                                                              | Slots                                                                                                                                                                                                                                       |
| -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `"([^"\\]\|\\.)*"\|'([^'\\]\|\\.)*'`                                                   | a quoted string in the git graph, pie, packet, radar, Wardley map, Cynefin, architecture and railroad, in `pele/src/diagrams/common/tokens.mbt` | four for each character or escape pair, and four more for a closed `"` string, whose `'` alternative stays untried                                                                                                                          |
| `\[(?:"([^"\\]\|\\.)*"\|'([^'\\]\|\\.)*'\|[^\[\]\r\n]+)\]`                             | an architecture label                                                                                                                           | as a quoted string, with four more when `]` closes the quote                                                                                                                                                                                |
| `%[xXdDbB][0-9A-Fa-f]+(?:-[0-9A-Fa-f]+\|\.[0-9A-Fa-f]+)*`                              | an ABNF numeric value                                                                                                                           | five for each part after the first                                                                                                                                                                                                          |
| `[A-Za-z](?:[A-Za-z0-9_()&]\|-(?!>))*(?:[ \t]+[A-Za-z(](?:[A-Za-z0-9_()&]\|-(?!>))*)*` | a Wardley name                                                                                                                                  | three, two for each character after a word's first, five for each further word, and one or two more where an arrow or blanks before no word end it                                                                                          |
| `(?:\r?\n)+` and `(?:\r?\n)*\s*\n`                                                     | a run of line breaks in a flowchart, and the line breaks after the flowchart and agentflow keywords                                             | two for each line break, and two more when a later line break in the blanks ends the second                                                                                                                                                 |
| `%{2}{\s*(?:(\w+)\s*:\|(\w+))\s*(?:(\w+)\|((?:(?!}%{2}).\|\r?\n)*))?\s*(?:}%{2})?`     | every `%%{...}%%` directive, in the trimmed text and in the text itself, before detection                                                       | two for each character of the body, and 28 more after a colon or 26 without one                                                                                                                                                             |
| `^\s*FAMILY(?:\s*,\s*FAMILY)*\s*$`                                                     | the host's font lists, as every diagram draws its root element                                                                                  | in a Latin-1 list eleven for each font tried after the first; in a two-byte list four for it, two for each blank and quoted character, and four for each unquoted character after a font's first; four more for an unclosed quote in either |

A closed `"` string therefore fails past 4194294 characters or escape pairs, and a `'` string or one left unclosed, which runs to the end of the text, past 4194295.
Every other pattern in pele's sources repeats only single characters, greedily or lazily, which V8 matches without keeping slots, except the tree view's bare name, which pele never runs because a scanner of its own answers for it.
Each pattern has cases in `scripts/string-length-cases.mjs` named "at V8's backtracking stack", each next to one "just short of" it, and tests next to its scanner or skipped ones in the diagrams' `string_length_test.mbt`.

## Checking against pele

`scripts/check-string-length.mjs` renders each case of `scripts/string-length-cases.mjs` through pele's dist and through the plugin, and checks it in one of three bands: an input pele rejects, one pele draws within the port's reach, and one pele draws past it.
It runs pele with `TZ=UTC`, as the goldens are made, and renders each drawing within the port's reach again through the theme typst sends, which has to answer without trapping.
Each case builds its source only when the check reaches it, so a check of one diagram holds only the case it renders, and `node scripts/check-string-length.mjs <diagram>` runs in node's default heap for every diagram but the journey, quadrant, railroad, timeline, use case and XY chart, where pele itself runs out of that heap on some case and the check needs `NODE_OPTIONS=--max-old-space-size=20480`.
The plugin's memory on the largest cases comes close to wasm's 4 GiB: it grows to the whole 4 GiB on the event model case "time frames sharing long data, drawn down", which it draws, and on the styled flowchart, swimlane, ER, requirement and agentflow cases, which end in a `limit` error in both, and to 3831 MiB on the info, sequence and class drawings of 270M letters.
