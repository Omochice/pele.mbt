# Output ceiling

The port runs as wasm32, with one linear memory of at most 4 GiB and an allocator whose largest block is about 1 GiB, so it has limits of its own that pele, running on node, does not share.
This document describes those limits and where the port reports them as a `limit` error rather than trapping.
pele also fails some enormous inputs where V8, the engine it runs on, runs out of string length, array length or regular expression stack; the port does not reproduce those failures, as [Known constraints](known-constraints.md) describes.

## The hold limit

The port holds a drawing's pieces, the single string made of them, and the UTF-8 bytes of the response at once, so it stops at 400000000 code units of SVG (`HOLD_LIMIT` in `pele/src/svg/markup.mbt`).
`Markup` in the same file keeps a drawing as pieces, and once it passes the hold limit it drops them and only counts, in 64 bits, since a drawing that is only counted can pass what 32 bits hold.
An SVG larger than the hold limit, which pele draws and a wasm32 plugin cannot hold, fails with the `limit` error "Diagram output is too large for the wasm port: it would hold more than 400000000 code units, the most the port can hold at once.", tagged with the diagram's type.
The message names the port, because the limit is the port's and not one of pele's.
pele checks its output limit against such a drawing as against any other, so the port does as well, from the length it keeps of a drawing it does not hold: under the default output limit, or any output limit below the drawing's length, the drawing fails with pele's "Diagram output is longer than the limit of N characters.", and only one the output limit allows fails with the port's error; the flowchart case "edges pele draws past the port, under the default output limit" checks it.
This ceiling is the one intentional, platform-imposed difference from pele: every SVG at or under it is drawn byte for byte as pele draws it, apart from the enormous inputs listed under [Known constraints](known-constraints.md).

A diagram drawn more than once to fit a narrow host, through `tighten`, `fit_width` or `turn_to_fit` in `pele/src/diagrams/common/`, measures a drawing past the hold limit as pele does, because `markup_document` leaves that document as a stand-in that keeps only its length rather than failing, and `pele/src/core/core.mbt` refuses only the drawing the diagram answers with.
The journey case "long tasks, drawn down within the port after across past it" checks that the drawing down is drawn after a drawing across past the hold limit.

Two texts are built as one string at their final size before they are written: a Gantt axis label formatted by `time_format` in `pele/src/diagrams/gantt/axis.mbt`, and a use case label made literal by `literal` in `pele/src/diagrams/usecase/render.mbt`.
Each counts its length first and fails with the same `limit` error once that passes the hold limit, because a drawing that writes it could not be held either, and a longer string would ask the allocator for more than its largest block.

## The answer

The plugin answers with JSON, which `typst/src/plugin/response.mbt` first counts and then writes into one block of its final size, so the SVG is held only once more however long it is.
A failure is answered the same way, because its message can quote a whole line of the source, and a syntax error's snippet and message are built at their final size before that.
typst reads the answer from one block of the plugin's memory, so an answer over 1000000000 bytes fails instead with the `limit` error "Diagram output is longer than the typst plugin can return: its JSON response would pass the plugin's limit of 1000000000 bytes.", tagged with the diagram's type, or for a failure with the failure's.

## The largest block

The allocator moonc links in gives no block over 1040187380 bytes once it is mended, as [the allocator bug](allocator-bug.md) describes, so no string of the port may pass about 520 million code units and no array of four-byte elements 260 million.
The hold limit keeps every drawing under that.
The agentflow lexer keeps each number of a token's span in an array of its own rather than four in one, so that none of its arrays holds more than one element per token and it reaches that block no sooner than its array of token types.

## Which diagrams can reach it

A diagram reaches the hold limit when some repeated part of its source multiplies into the SVG without a cap, so that a source within the limit draws an SVG past it.
Every diagram that writes a `classDef` or `style` into each of many elements can, and so can every diagram that draws host icons, because the icon markup the host supplies is unbounded.
The `limit` option caps only the length of the source, so once it is raised a diagram also reaches the hold limit by count alone, because an element draws hundreds of code units from a source line of a dozen and few diagrams cap how many elements they draw.
Repeated text amplifies further, because `&` escapes to five code units and an element often writes its name both in its `data-id` and in its label.

Every diagram builds its SVG with `Markup`, so each stops at the hold limit.
The C4 diagram draws no host markup, only an empty icon box of about 260 code units for each icon span in a label, so it reaches the hold limit only from a source of millions of icon spans under a raised `limit`.
The git graph draws neither host icons nor styles but writes each `&` of a commit id as five code units twice, in the commit's `data-id` and in its label, so that with the `limit` option raised a source a tenth of the hold limit reaches it.
Some diagrams reach the hold limit only past a cap that looks as if it bounded them:

- pele draws no host icons or math in a pie chart, and only the slices of at least one percent, but every entry has a legend item.
- The packet diagram draws at most 10000 rows, which keeps it under 2^28 code units at the default 32 bits per row, but `packet.bitsPerRow` may be raised to 4096.
- The radar chart draws at most 32 graticule rings, but a polygon ring passes through every axis.
- The ids of an event model's time frames have at most three digits, which bounds the frames, but each frame draws the whole data block it names.

## Long text

A single text can pass what a doubling `StringBuilder` holds on its own, however small the diagram: a label of thousands of host icons or `$$…$$` spans, each drawing the host's markup, or a label, id or style of tens of millions of `&`, each escaped to five code units.
Apart from the inputs under [Known constraints](known-constraints.md), none of these is built as one string before it is written, because a `StringBuilder` doubles its buffer and wasm's allocator refuses the block of 1 GiB that would follow 2^28 code units, while `Markup` keeps a long piece as it is and allocates the whole drawing at its final size.
The writers that put such text into `Markup` are these:

- `Markup::write_esc`, `Markup::write_esc_text` and `Markup::write_data_id` in `pele/src/svg/escape.mbt` escape 65536 code units at a time, and search each escaped piece together with the end of the one before for the private aliases, such as `var(--_w)`, that the root element declares.
- `write_label`, `write_edge_label` and `write_struck_title` in `pele/src/svg/` and `write_left_label` in `pele/src/diagrams/common/` write each span's text with the escape writers and each host drawing as a piece of its own, and `write_label_styled` and `write_label_with_id` add a style and an id written the same way.
- `write_style`, `write_rounded_style` and `write_styled` in `pele/src/svg/style_writers.mbt` write the style that `resolve_raw_style` makes of a `classDef` or `style` a piece at a time, and `write_icon` in `pele/src/diagrams/common/` writes an icon's name and drawing apart.

Every diagram writes its labels, titles, ids, tooltips, links, icon names, styles and axis labels with these writers, and `markup_document` writes the accessible name and description with them as well, holding them with the content so that they count toward the hold limit.
Most have a case named for the text it fills, such as "one tooltip of many &" or "one node label longer than a doubling StringBuilder holds", and the info and pie cases check the accessible text.

The few texts that are rewritten before they are written are built at their final size instead: `plain_text` in `pele/src/diagrams/common/fit.mbt`, which escapes a journey or timeline title before it is wrapped into lines, the use case's `literal`, the Gantt chart's `time_format`, a syntax error's snippet, and the style that typst's theme rewrites.
The theme rewrites each tag of the SVG as `write_drawable` in `typst/src/theme/` copies it into the answer, and `rebuild` in `typst/src/theme/declarations.mbt` makes a new style only where a declaration changes.
`inline` in `pele/src/text/label.mbt` takes a line's text as slices of the source rather than copying it, and `@util.slice` shares the strings of one or two ASCII code units, so a source lexed into tens of millions of one-character tokens does not hold a string for each.

## Checking against pele

`scripts/check-string-length.mjs` renders each case of `scripts/string-length-cases.mjs` through pele's dist and through the plugin, and checks it in one of three bands: an input pele rejects with an error of its own, which the plugin must give as it is; one pele draws within the port's reach, which the plugin must draw byte for byte; and one pele draws past it, which the plugin must fail with its own `limit` error.
The cases hold only inputs that pele draws or rejects without running into one of V8's limits, since the port does not reproduce those failures.
It runs pele with `TZ=UTC`, as the goldens are made, and renders each drawing within the port's reach again through the theme typst sends, which has to answer without trapping.
Each case builds its source only when the check reaches it, so a check of one diagram holds only the case it renders, and pele itself runs out of node's default heap on some cases, so the whole check runs under `NODE_OPTIONS=--max-old-space-size=20480`.
The plugin's memory on the largest cases comes close to wasm's 4 GiB.
