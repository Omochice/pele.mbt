# Golden fixtures

The files in this directory are the reference outputs of pele v1.8.0, rendered from pele's own test corpus.
A port is correct when it reproduces every file here.
The directory is generated, so it MUST NOT be edited by hand.

## Layout

Each source text is stored under the diagram whose corpus it came from, as `golden/<diagram>/<id>.*`.
The `<id>` is the first 16 hex characters of the SHA-256 of the source text, so the same text appearing in several corpora is kept once per diagram.

- `<id>.mmd` is the exact source text.
- `<id>.svg` is the exact `svg` string, present only when rendering succeeded.
- `<id>.json` holds `type`, `mermaidType`, `width`, `height`, and `links` on success.
    On failure it holds a single `error` object with `name`, `code`, `message`, `type`, and `mermaidType`.
- `<id>.<profile>.svg` and `<id>.<profile>.json` have the same shape as the files above and hold the output of another profile, such as `<id>.narrow.svg`.
    They exist only for sources whose outcome under that profile differs from the default outcome, so when they are missing the default files are also that profile's expectation.

Errors are goldens too, because a port has to reject the same inputs with the same code and message.
`manifest.json` records the pele version and commit, the node version, the option profiles, and per-diagram counts.
The `ok` and `error` counts describe the default profile, and a count named after any other profile counts the sources that have files of that profile.
It contains no timestamps, so regeneration is byte-identical.
`node scripts/check-golden.mjs --profile icons` checks only the named profile, and the flag may be repeated.

## Regenerating

The script reads the pinned pele checkout, so the submodule has to be initialised and built first.

```sh
git submodule update --init vendor/pele
(cd vendor/pele && npm ci && npm run build)
node scripts/gen-golden.mjs
```

`PELE_ROOT` names another built pele checkout to read instead of `vendor/pele`, for a git worktree whose submodule is not initialised.

The script deletes everything in `golden/` except this README and then rewrites it.
Corpus inputs are collected by a port of `loadCorpus` in `vendor/pele/tests/support/corpus.ts`, which takes string literals from `tests/compat/<diagram>/*.spec.{js,ts}` that match a per-diagram keyword and adds `tests/corpus/<diagram>-docs.json`.
`tests/corpus/agentflow-reference.json` is not included because its entries are objects rather than plain source strings.
The string literals of `tests/render/math.test.ts` that contain `$$` are added as well, each under the diagram that pele's `detectType` names for it.
No compat spec puts `$$` in a diagram that typesets math, so without them a math resolver would never be asked for anything.

## Pinned options

Every render uses one of the option profiles recorded under `profiles` in `manifest.json`.
Each profile is the JSON a host passes to the plugin as its options, and a comparison tool passes it unchanged.
The `default` profile holds pele's own defaults, written out explicitly so that a change of default upstream cannot alter the goldens silently.
The `narrow` profile is the default profile plus `maxWidth: 400`.
The value 400 is below `directionBreakpoint` (640), so both width fitting and the automatic direction turn take effect.
The `icons`, `math`, and `metrics` profiles are the default profile plus `icons`, `math`, and `measurer` respectively, in the JSON forms described under [Callback options](#callback-options).
A comparison tool has to read the profiles from the manifest instead of hard-coding them.
`now` is an exception: gantt charts read the current time by default, so it is fixed to 1767225600000 (2026-01-01T00:00:00Z).
The generator also runs pele with `TZ=UTC`, recorded as `timeZone` in the manifest.
Gantt reads a date-only value as UTC midnight but floors its axis ticks to local midnight, so without that pin the goldens would depend on the time zone of the machine that generated them.
`maxWidth` (outside the narrow profile), `responsive`, `linkSchemes`, and `imageSchemes` are left unset because their defaults mean "undefined selects the built-in behavior" rather than a concrete value.
`config` is unset as well, and so are `measurer`, `icons`, and `math` outside their own profiles.
The default measurer falls back to pele's built-in metrics table when no canvas is available, and a port has to reproduce that table to match text widths.

## Callback options

pele takes `icons`, `math`, and `measurer` as functions, which typst cannot pass to a plugin.
The plugin takes each as JSON data that fixes what the function returns instead.
`scripts/plugin-options.mjs` turns that data back into pele's functions for the generator, and it is the reference wherever this section leaves a question open.
An option whose value is not a JSON object (an array counts as not an object) is ignored, so pele behaves as if it were unset.
An object, even an empty one, installs the callback.
That distinction matters for math: with a resolver present, pele lays out every label that contains `$$` on its math path even where nothing is resolved.
Lookups use own keys only, so a key such as `__proto__` is an ordinary name.

### icons

`icons` maps an icon name to the SVG fragment pele's `IconResolver` returns for it.

```json
{ "fa:fa-car": "<path d=\"M4,4H20\"/>", "logos:react": null }
```

The name is the one the resolver receives, after pele has decoded entity codes in it.
A string value is returned as it is, and any other value or a missing name returns `null`, which pele treats as unresolved.
An empty string is not the same as `null`: labels treat it as unresolved, but architecture and tree view icons draw it instead of their built-in glyph.

### math

`math` maps a TeX string, then a font size, to the `MathMarkup` pele's `MathResolver` returns.

```json
{
  "x^2": {
    "16": { "svg": "<path d=\"M0,0H20\"/>", "width": 20, "height": 24 },
    "14": { "html": "<span>x²</span>", "width": 17.5, "height": 21 }
  },
  "\\frac{a}{b}": null
}
```

pele calls the resolver with the TeX between `$$` delimiters, after decoding entity codes, and with the label's font size in pixels.
There is no inline or display mode to key on: pele's resolver receives no such argument, and every `$$…$$` is typeset the same way.
The size key is the size written as JavaScript writes a number, such as `"16"` or `"13.5"`.
The markup is keyed by size because the host typesets at the size pele asks for, and pele asks for smaller sizes on edge labels and class cardinalities than on nodes.
A missing TeX string or size, or a value that is not an object at either level, returns `null`.
An object is handed to pele unchanged, and pele then applies its own check: `width` and `height` have to be finite and positive, and the markup has to be a string in `svg` when that key is present and in `html` otherwise.
Markup that fails the check counts as unresolved.
`svg` markup is drawn in a nested `<svg>` and `html` markup in a `<foreignObject>`, both in a box of the given width and height.

### measurer

`measurer` fixes a `TextMeasurer`, the function from a text, a font size, and a style to a width in pixels.

```json
{
  "unitsPerEm": 2048,
  "styles": {
    "0": { "advances": { "a": 1100, " ": 600 }, "default": 1200, "wide": 2048 },
    "1": { "advances": { "a": 1200 }, "default": 1300 }
  }
}
```

The style is pele's bit set of 1 for bold, 2 for italic, and 4 for monospace, so it runs from 0 to 7, and `styles` is keyed by it as a decimal string.
A style without an object of its own uses the one under `"0"`, and without that every advance is 0.
The width of a text is computed one UTF-16 code unit at a time:

- a code unit below 32 adds nothing;
- a code unit that is a key of `advances` adds that number, so a key is a single code unit;
- a code unit in the ranges pele's built-in measurer treats as zero width adds nothing;
- a code unit in the ranges it treats as double width adds `wide`;
- any other code unit adds `default`.

The ranges are those of `isZeroWidth` and `isWide` in `vendor/pele/src/text/measurer.ts`, so a character outside the basic plane adds `wide` for its high surrogate and nothing for its low one.
`default` is 0 when it is not a number, and `wide` is `default` when it is not a number.
The width is the sum of the advances times the font size divided by `unitsPerEm`, in that order, as pele's built-in measurer computes it with 1000.
`unitsPerEm` is 1000 when it is not a positive number, so a font's own units can be passed without converting them.
Line height is not part of the measurer: pele always sets lines 1.5 times the font size apart.
Other `measurer` keys are ignored.

### The generated maps

The generator first renders the whole corpus with resolvers that answer every request, and records every icon name and every TeX string with each font size asked for.
It builds one map for each profile from those requests, in code unit order, and checks that a render with the maps asks for nothing they lack.
Each icon fragment embeds its name, so a fragment drawn for the wrong icon shows in the SVG.
Every TeX string resolves to markup whose width and height grow with its length and the font size, alternating between `svg` and `html` by the parity of its length, except that every fifth one maps to `null`.
The `metrics` profile holds a monospace-like table in 2048 units per em with a distinct bold, italic, and monospace table, and leaves the other styles to fall back to style 0.

## Number formatting

Every coordinate in the SVG output is formatted by `num()` in `vendor/pele/src/svg/builder.ts`.
It rounds to hundredths and drops trailing zeros, so a port has to reproduce it exactly, including its handling of negative values and zero, for a byte-exact comparison.

## Output ceiling

pele builds its SVG by string concatenation, and V8 throws a `RangeError` once a string would pass 536870888 UTF-16 code units, the longest string it makes on a 64-bit host.
pele reports that as the `limit` error "Diagram is nested too deeply." before it checks its own output limit, so an input whose SVG crosses that length fails there even under the default options.
The port reproduces this: `Markup` in `src/svg/markup.mbt` keeps a drawing as pieces, counts its length as each piece is written, and raises the same error at the same point.

The port stops below V8's longest string.
It runs as wasm32 with one linear memory of at most 4 GiB, and holds a drawing's pieces, the single string made of them, and the UTF-8 bytes of the response at once, so it stops at 400000000 code units of SVG (`HOLD_LIMIT` in `src/svg/markup.mbt`).
An SVG larger than that, which pele draws and a wasm32 plugin cannot hold, fails with the `limit` error "Diagram output is too large for the wasm port: it would hold more than 400000000 code units, the most the port can hold at once.", tagged with the diagram's type.
pele checks its output limit against such a drawing as against any other, so the port does as well, from the length it keeps of a drawing it does not hold: under the default output limit, or any output limit below the drawing's length, the drawing fails with pele's "Diagram output is longer than the limit of N characters.", and only one the output limit allows fails with the port's error; the flowchart case "edges pele draws past the port but under V8, under the default output limit" checks it.
This ceiling is the one intentional, platform-imposed difference from pele: every SVG at or under it is drawn byte for byte as pele draws it, apart from the enormous inputs listed under [Known constraints](#known-constraints).

### The answer

The plugin answers with JSON, which `src/plugin/response.mbt` first counts and then writes into one block of its final size, so the SVG is held only once more however long it is.
A failure is answered the same way, because its message can quote a whole line of the source, and a syntax error's snippet and message are built at their final size before that.
typst reads the answer from one block of the plugin's memory, so an answer over 1000000000 bytes fails instead with the `limit` error "Diagram output is longer than the typst plugin can return: its JSON response would pass the plugin's limit of 1000000000 bytes.", tagged with the diagram's type, or for a failure with the failure's.

### Which diagrams can reach it

A diagram reaches the ceiling when some repeated part of its source multiplies into the SVG without a cap, so that a source within the limit draws an SVG past it.
Every diagram that writes a `classDef` or `style` into each of many elements can, and so can every diagram that draws host icons, because the icon markup the host supplies is unbounded.
The `limit` option caps only the length of the source, so once it is raised a diagram also reaches the ceiling by count alone, because an element draws hundreds of code units from a source line of a dozen and few diagrams cap how many elements they draw.
Repeated text amplifies further, because `&` escapes to five code units and an element often writes its name both in its `data-id` and in its label.

Every diagram builds its SVG with `Markup`, so each fails with a `limit` error where pele does, and each has amplifying inputs in `scripts/string-length-cases.mjs` and tests, skipped where they are slow, in `src/diagrams/<diagram>/string_length_test.mbt`.
The C4 diagram draws no host markup, only an empty icon box of about 260 code units for each icon span in a label, so it reaches V8's longest string only from a source of tens of millions of code units under a raised `limit`.
The git graph draws neither host icons nor styles but writes each `&` of a commit id as five code units twice, in the commit's `data-id` and in its label, so that with the `limit` option raised a source a tenth of V8's longest string reaches the ceiling.
Some diagrams reach the ceiling only past a cap that looks as if it bounded them:

- pele draws no host icons or math in a pie chart, and only the slices of at least one percent, but every entry has a legend item.
- The packet diagram draws at most 10000 rows, which keeps it under 2^28 code units at the default 32 bits per row, but `packet.bitsPerRow` may be raised to 4096.
- The radar chart draws at most 32 graticule rings, but a polygon ring passes through every axis.
- The ids of an event model's time frames have at most three digits, which bounds the frames, but each frame draws the whole data block it names.

Laying out a Venn diagram takes pele time that grows faster than the number of sets, so the Venn input puts many texts in one set instead.

The event model, Ishikawa, and journey diagrams are drawn down for a narrow host after they are drawn across, so each also has an input whose drawing down pele draws between 2^28 code units and the hold limit.
A diagram drawn more than once to fit a narrow host, through `tighten`, `fit_width` or `turn_to_fit` in `src/diagrams/common/`, measures a drawing past the hold limit as pele does, because `markup_document` leaves that document as a stand-in that keeps only its length rather than failing, and `src/core/core.mbt` refuses only the drawing the diagram answers with.
The journey case "long tasks, drawn down within the port after across past it" and the journey and Ishikawa cases "drawn down past V8 after across past the port" check that the drawing down is drawn, or fails as nested too deeply, where pele's is, after a drawing across past the hold limit.

The info diagram draws only its title and pele's version, so no part of it repeats; it reaches the ceiling only through a single title or accessible description, and its cases check both where pele draws them and where pele fails.

### Long text

A single text can reach the ceiling on its own, however small the diagram: a label of thousands of host icons or `$$…$$` spans, each drawing the host's markup, or a label, id or style of tens of millions of `&`, each escaped to five code units.
Apart from the inputs under [Known constraints](#known-constraints), none of these is built as one string before it is written, because a `StringBuilder` doubles its buffer and wasm's allocator refuses the block of 1 GiB that would follow 2^28 code units, while `Markup` keeps a long piece as it is and allocates the whole drawing at its final size.
The writers that put such text into `Markup` are these:

- `Markup::write_esc`, `Markup::write_esc_text` and `Markup::write_data_id` in `src/svg/escape.mbt` escape 65536 code units at a time, and search each escaped piece together with the end of the one before for the private aliases, such as `var(--_w)`, that the root element declares.
- `write_label`, `write_edge_label` and `write_struck_title` in `src/svg/` and `write_left_label` in `src/diagrams/common/` write each span's text with the escape writers and each host drawing as a piece of its own, and `write_label_styled` and `write_label_with_id` add a style and an id written the same way.
- `write_style`, `write_rounded_style` and `write_styled` in `src/svg/style_writers.mbt` write the style that `resolve_raw_style` makes of a `classDef` or `style` a piece at a time, and `write_icon` in `src/diagrams/common/` writes an icon's name and drawing apart.

Every diagram writes its labels, titles, ids, tooltips, links, icon names, styles and axis labels with these writers, and `markup_document` writes the accessible name and description with them as well, holding them with the content so that they count toward the hold limit.
Each has a case named for the text it fills, such as "host icons in one node label", "one tooltip of many &" or "a title past V8", and the info and pie cases check the accessible text.
The requirement diagram draws no host icons, so its case fills a field with math instead; a kanban card breaks its label to fit its column, so its case keeps math typeset almost without width on one line; and a C4 label draws each icon span only as an empty box, so its cases hold millions of spans.

The few texts that are rewritten before they are written are built at their final size instead: `plain_text` in `src/diagrams/common/fit.mbt`, which escapes a journey or timeline title before it is wrapped into lines, the use case's `literal`, a syntax error's snippet, and the style that typst's theme rewrites.
The theme rewrites each tag of the SVG as `write_drawable` in `src/typst/` copies it into the answer, and `rebuild` in `src/typst/declarations.mbt` makes a new style only where a declaration changes.
`inline` in `src/text/label.mbt` takes a line's text as slices of the source rather than copying it, and `@util.slice` shares the strings of one or two ASCII code units, so a source lexed into tens of millions of one-character tokens does not hold a string for each.

pele reads a quoted string in the git graph, pie, packet, radar, Wardley map, Cynefin, architecture and a railroad terminal with a pattern that runs out of V8's backtracking stack past 4194294 characters, and reports that as the `limit` error while lexing, so a quoted label there reaches V8's longest string only through host icons the label draws; their cases of `&` fail in pele and in the port while lexing, as [V8's backtracking stack](#v8s-backtracking-stack) describes.

### V8's longest array

V8 holds at most 2^27 elements in an array grown by pushing, `JS_ARRAY_MAX_LENGTH` in `src/util/js_array.mbt`, and pele reports the `RangeError` of a push past it as "Diagram is nested too deeply.".
pele's agentflow lexer keeps four numbers per token in one array, so it fails on opening its 2^25 + 1st token, and the port's agentflow lexer raises the same error there; the agentflow cases "a style of 2^25 - 16 &, the most tokens pele lexes" and "a style of 2^25 - 15 &, one token more than pele lexes" check both sides of it.
pele cuts a label too wide for its box among `Array.from` of its code points, so a label of more than 2^27 code points fails as nested too deeply, and `fit_text` in `src/diagrams/common/` raises the same; the treemap cases "a leaf label of 2^27 a, cut among as many code points as V8 holds" and "a leaf label of 2^27 + 1 a, one code point past what V8 holds" check it.

### Allocator

moonc 0.10.17 links into a wasm module a TLSF allocator ported from AssemblyScript's, which can give a request of 512 MiB or more a free block smaller than the request.
Its `searchBlock` rounds a request up to the next size class only below 536870910 bytes, since rounding the largest requests would pass its table of classes, and looks a larger request up in its own class, whose blocks span 32 MiB.
`malloc` then splits the block it finds as if it were large enough, writing the header of a free block past it, and whatever is written into the request overwrites the live blocks that follow.
The port makes such requests whenever a string reaches 2^28 code units: the SVG of a drawing that long, its JSON answer once it passes 512 MiB, and a source of that many characters with every copy the parser makes of it.
A git graph whose branch is named by 140M characters drew an SVG of the right length with garbage near its end, a name of 270M characters has answered with a short SVG where pele fails, and a sequence diagram with a front matter title of 70M `<` once answered with one code unit changed; how much is overwritten depends on what the heap holds, so the same input can pass one run and fail the next.
The program below, built with `moon build --target wasm` in debug or release and run under node's WASI, shows it in a fresh heap.

```moonbit
fn main {
  // 605000000 and 630000000 bytes fall in the same size class, [603979776, 637534208).
  let a : FixedArray[Byte] = FixedArray::make(605000000, 0)
  let after : FixedArray[Byte] = FixedArray::make(16, 7)
  let filler : FixedArray[Byte] = FixedArray::make(64000000, 7)
  println("a \{a.length()}")
  let b : FixedArray[Byte] = FixedArray::make(630000000, 1)
  println("after[0] = \{after[0]}, filler[0] = \{filler[0]} (7 expected)")
}
```

It prints `after[0] = b'\x01', filler[0] = b'\x01'`, because `a` is freed after its last use and `b` is given its block, so filling `b` overwrites the blocks after it.
Without `filler`, the split writes past the end of memory and `malloc` traps with "memory access out of bounds" where it should have grown the memory.
This is a bug in MoonBit's runtime, to be reported upstream with the program above.

`scripts/allocator.mjs` mends the allocator in the built plugin, since no option of moonc replaces it.
It raises the bound below which `searchBlock` and `growMemory` round a request up to 1040187393 bytes, the highest at which rounding up by as much as 2^25 - 1 bytes stays below 2^30, the first size past the table, and lowers the largest request `prepareSize` lets through from 1073741820 to 1040187388 bytes, so that a request too large to round traps rather than corrupting memory.
No block can therefore pass 1040187380 bytes, 32 MiB less than before, which the port reaches only with a source of more than 520 million characters, near V8's longest string.
`scripts/build-typst.mjs` writes the mended plugin to `typst/plugin.wasm`, and `scripts/plugin-host.mjs` mends the plugin it loads, so every check runs the allocator typst runs; both fail when the allocator's code is not as expected, as after an upgrade of moonc, which then has to be checked for the same bug.
The git graph cases "a branch named by 140M a, drawn into a block of 512 MiB or more" and "a branch named by 270M a, read into a block of 512 MiB or more" check the mended plugin, and the first fails without the mend.

`moon test` runs the allocator unmended, so the tests that hold a string of 2^28 code units or more are skipped, and `scripts/check-string-length.mjs` checks the same inputs through the mended plugin.
The Gantt test "an axis label formatted past what a doubling StringBuilder holds is drawn as pele draws it" shows why: its drawing of 273001582 code units comes out exactly 2^20 code units short under the unmended allocator, in a fresh instance of the plugin built in debug or release alike, and matches pele once the allocator is mended.

### V8's backtracking stack

A regular expression that repeats a group with more than one way through it, such as `(?:a|bc)*`, keeps a few slots of V8's backtracking stack for every repetition until the match ends.
That stack holds 64 MiB of four-byte slots, and V8 throws a `RangeError` once a match fills all but the 32 it keeps as slack, so pele reports a long enough match of such a pattern as the `limit` error "Diagram is nested too deeply.", tagged with the diagram's type unless it happens before detection.
`BACKTRACK_STACK_SLOTS` in `src/util/backtrack.mbt` is that size, and each scanner that answers as one of these patterns counts the slots its match takes and raises the error where V8 throws.
The table below lists the slots each pattern takes, measured under node 24.21 and checked against V8 on random inputs near the point where it throws.
They do not depend on the rest of the input, except for the font list, whose pattern has the `u` flag and which V8 matches as two-byte text once it holds a character past Latin-1.

| Pattern                                                                                | Where pele runs it                                                                                                                         | Slots                                                                                                                                                                                                                                       |
| -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `"([^"\\]\|\\.)*"\|'([^'\\]\|\\.)*'`                                                   | a quoted string in the git graph, pie, packet, radar, Wardley map, Cynefin, architecture and railroad, in `src/diagrams/common/tokens.mbt` | four for each character or escape pair, and four more for a closed `"` string, whose `'` alternative stays untried                                                                                                                          |
| `\[(?:"([^"\\]\|\\.)*"\|'([^'\\]\|\\.)*'\|[^\[\]\r\n]+)\]`                             | an architecture label                                                                                                                      | as a quoted string, with four more when `]` closes the quote                                                                                                                                                                                |
| `%[xXdDbB][0-9A-Fa-f]+(?:-[0-9A-Fa-f]+\|\.[0-9A-Fa-f]+)*`                              | an ABNF numeric value                                                                                                                      | five for each part after the first                                                                                                                                                                                                          |
| `[A-Za-z](?:[A-Za-z0-9_()&]\|-(?!>))*(?:[ \t]+[A-Za-z(](?:[A-Za-z0-9_()&]\|-(?!>))*)*` | a Wardley name                                                                                                                             | three, two for each character after a word's first, five for each further word, and one or two more where an arrow or blanks before no word end it                                                                                          |
| `(?:\r?\n)+` and `(?:\r?\n)*\s*\n`                                                     | a run of line breaks in a flowchart, and the line breaks after the flowchart and agentflow keywords                                        | two for each line break, and two more when a later line break in the blanks ends the second                                                                                                                                                 |
| `%{2}{\s*(?:(\w+)\s*:\|(\w+))\s*(?:(\w+)\|((?:(?!}%{2}).\|\r?\n)*))?\s*(?:}%{2})?`     | every `%%{...}%%` directive, in the trimmed text and in the text itself, before detection                                                  | two for each character of the body, and 28 more after a colon or 26 without one                                                                                                                                                             |
| `^\s*FAMILY(?:\s*,\s*FAMILY)*\s*$`                                                     | the host's font lists, as every diagram draws its root element                                                                             | in a Latin-1 list eleven for each font tried after the first; in a two-byte list four for it, two for each blank and quoted character, and four for each unquoted character after a font's first; four more for an unclosed quote in either |

A closed `"` string therefore fails past 4194294 characters or escape pairs, and a `'` string or one left unclosed, which runs to the end of the text, past 4194295.
Every other pattern in pele's sources repeats only single characters, greedily or lazily, which V8 matches without keeping slots, except the tree view's bare name, which pele never runs because a scanner of its own answers for it.
Each pattern has cases in `scripts/string-length-cases.mjs` named "at V8's backtracking stack", each next to one "just short of" it, and tests next to its scanner or skipped ones in the diagrams' `string_length_test.mbt`.

### Checking against pele

`scripts/check-string-length.mjs` renders each case of `scripts/string-length-cases.mjs` through pele's dist and through the plugin, and checks it in one of three bands: an input pele rejects, one pele draws within the port's reach, and one pele draws past it.
It runs pele with `TZ=UTC`, as the goldens are made, and renders each drawing within the port's reach again through the theme typst sends, which has to answer without trapping.
Each case builds its source only when the check reaches it, so a check of one diagram holds only the case it renders, and `node scripts/check-string-length.mjs <diagram>` runs in node's default heap for every diagram but the journey, quadrant, railroad, timeline, use case and XY chart, where pele itself runs out of that heap on some case and the check needs `NODE_OPTIONS=--max-old-space-size=20480`.
The plugin's memory on the largest cases comes close to wasm's 4 GiB: it grows to the whole 4 GiB on the event model case "time frames sharing long data, drawn down", which it draws, and on the styled flowchart, swimlane, ER, requirement and agentflow cases, which end in a `limit` error in both, and to 3831 MiB on the info, sequence and class drawings of 270M letters.

### Known constraints

The port still differs from pele, or cannot be compared with it, on the inputs below, each of tens to hundreds of millions of characters.
On the first seven the plugin traps, by refusing an allocation or running out of memory, where pele draws the diagram or fails it with a `limit` error; the first six were each rendered through pele and through the plugin to confirm it.
They are accepted as constraints rather than reproduced, because each would need another part of the port to be rebuilt around pieces.

- A `classDef` or `style` value of about 270 million plain letters in a flowchart, class, state, ER, block or agentflow diagram, which pele draws: `resolve_style` and `resolve_raw_style` in `src/svg/` lowercase it with `lower_ascii` in `src/svg/style.mbt` into a doubling `StringBuilder`, which needs more than the largest block wasm's allocator gives.
- A kanban card label of about 270 million plain letters, which pele fails as nested too deeply: the plugin traps before the card's lines, each written into `Markup` on its own, add up to that length.
- A label that typesets math under a style or an id of 2^28 code units or more, which pele fails as nested too deeply: `write_label_styled` and `write_label_with_id` give the math its color from their attributes made into one string.
- An option string of 2^28 code units or more, such as a single host icon drawing, which pele draws: the plugin reads its options with `JsonReader::string` in `src/util/json.mbt` into a doubling `StringBuilder`, and `icon_svg` in `src/diagrams/common/icon.mbt`, which the tree view and the architecture's `icon_slot` draw icons with, makes the icon one string as well.
- An ER attribute type of about 70 million `~`, which pele draws as an SVG of 280 million code units: `@text.layout_label` lays the attribute's label out from a source of 280 million code units.
- A source of more than 2^27 tokens in a lexer other than agentflow's, such as a class diagram of 134 million commas: pele fails as nested too deeply on its 2^27 + 1st token, while the port runs out of memory before it gets there.
- A use case label for which `literal` in `src/diagrams/usecase/render.mbt` makes a string between about 480 million code units and V8's longest string, which wasm cannot allocate where V8 can.
- pele's arrays of one element per character, `split('')` in `generics.ts`, `Array.from` in `literal-label.ts` and the spread in `sequence/db.ts`, fail past 2^27 elements, and the port is not shown to fail where they do, since no case reaches them.
- `moon test` runs the allocator unmended, as [Allocator](#allocator) describes, so its tests of 2^28 code units or more are skipped and `scripts/check-string-length.mjs` checks the same inputs instead.
- A journey task or a timeline event of about 270 million characters, and a timeline event or a quadrant label of a hundred million, run pele itself out of node's heap, so there is no outcome of pele's to compare the port with.
