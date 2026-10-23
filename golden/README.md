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
The port reproduces this: `src/svg/markup.mbt` tracks a drawing's length as it is assembled and raises the same error at the same point.
`scripts/check-string-length.mjs` renders, through pele's dist and through the plugin, one amplifying input per diagram that can reach it, and checks the three bands against each other: an input pele rejects, one pele draws within the port's reach, and one pele draws past it.
`scripts/string-length-cases.mjs` lists the inputs.

The port stops below V8's longest string.
It runs as wasm32 with one linear memory of at most 4 GiB, and holds a drawing's pieces, the single string made of them, and the UTF-8 bytes of the response at once, a fit diagram several times over, so it stops at 400000000 code units of SVG (`HOLD_LIMIT` in `src/svg/markup.mbt`).
An SVG larger than that, which pele draws and a wasm32 plugin cannot hold, fails with the `limit` error "Diagram output is too large for the wasm port: it would hold more than 400000000 code units, the most the port can hold at once.", tagged with the diagram's type.
This ceiling is the one intentional, platform-imposed difference from pele; every SVG at or under it is drawn byte for byte as pele draws it.

### Which diagrams can reach it

A diagram reaches the ceiling when some repeated part of its source multiplies into the SVG without a cap, so that a source within the limit draws an SVG past it.
Every diagram that writes a `classDef` or `style` into each of many elements can, and so can every diagram that draws host icons, because the icon markup the host supplies is unbounded.
The `limit` option caps only the length of the source, so once it is raised a diagram also reaches the ceiling by count alone, because an element draws hundreds of code units from a source line of a dozen and few diagrams cap how many elements they draw.
Repeated text amplifies further, because `&` escapes to five code units and an element often writes its name both in its `data-id` and in its label.

The flowchart (and the swimlane it renders through), class, state, ER, block, agentflow, requirement, treemap, use case, architecture, C4, Cynefin, Gantt, kanban, mindmap, sequence, git graph, tree view, Wardley map, pie, event model, Ishikawa, journey, packet, quadrant, radar, railroad, sankey, timeline, Venn, and XY chart diagrams build their SVG with `Markup` and so fail with a `limit` error where pele does; each has an amplifying input in `scripts/string-length-cases.mjs` and a skipped test in `src/diagrams/<diagram>/string_length_test.mbt`.
The C4 diagram draws no host markup, only an empty icon box of about 260 code units for each icon span in a label, so it reaches V8's longest string only from a source of tens of millions of code units under a raised `limit`.
The git graph draws neither host icons nor styles but writes each `&` of a commit id as five code units twice, in the commit's `data-id` and in its label, so that with the `limit` option raised a source a tenth of V8's longest string reaches the ceiling.
Some diagrams reach the ceiling only past a cap that looks as if it bounded them:

- pele draws no host icons or math in a pie chart, and only the slices of at least one percent, but every entry has a legend item.
- The packet diagram draws at most 10000 rows, which keeps it under 2^28 code units at the default 32 bits per row, but `packet.bitsPerRow` may be raised to 4096.
- The radar chart draws at most 32 graticule rings, but a polygon ring passes through every axis.
- The ids of an event model's time frames have at most three digits, which bounds the frames, but each frame draws the whole data block it names.

Laying out a Venn diagram takes pele time that grows faster than the number of sets, so the Venn input puts many texts in one set instead.

The event model, Ishikawa, and journey diagrams are drawn down for a narrow host after they are drawn across, so each also has an input whose drawing down pele draws between 2^28 code units and the hold limit.

The info diagram draws only its title and pele's version, so no part of it repeats; it reaches the ceiling only through a single title or accessible description.

A single label can reach the ceiling on its own, however small the diagram, because each of its icon spans draws the host's drawing of the icon and each of its `$$…$$` spans draws the host's math markup.
`write_label`, `write_edge_label` and `write_struck_title` in `src/svg/` write a label to `Markup` with each host drawing as a piece of its own, and `label_svg`, `edge_label_svg` and `struck_title` make their strings from them, aborting past V8's longest string since a string result has no error to carry.
The flowchart writes its node labels, cluster titles and edge labels with them, and the swimlane its lane titles, so those fail with the `limit` error where pele does; the cases "host icons in one node label", "one node label longer than a doubling StringBuilder holds" and "host icons in one lane title" check it.
The other diagrams still take their labels, titles and accessible descriptions as single strings, so one of them of thousands of host icons, or of tens of millions of `&`, traps there although their markup fails as pele does.
Moving their call sites to the writers is follow-up work.

A diagram that is drawn twice to fit a narrow host holds its first drawing to the hold limit as well.
When that first drawing passes the hold limit and pele goes on to a second drawing, the port fails with its hold-limit error where pele draws the second drawing within the hold limit, or fails with "Diagram is nested too deeply." on it.
