# Golden fixtures

The files in this directory are the reference outputs of pele v1.8.0, rendered from pele's own test corpus.
A port is correct when it reproduces every file here.
The directory is generated, so it MUST NOT be edited by hand.
The port's output ceiling, its known constraints, and how it is tested beyond these fixtures are described under [doc/](../doc/README.md).

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

The script reads the pele checkout that `PELE_ROOT` names and records `PELE_COMMIT` as its commit, and the development shell sets both to the pele pinned as the flake's `pele` input, already built.

```sh
nix develop -c node scripts/gen-golden.mjs
```

Without Nix, `PELE_ROOT` has to name a checkout of that commit built with `npm ci && npm run build`, and `PELE_COMMIT` has to name the commit unless that checkout is a git repository.

The script deletes everything in `golden/` except this README and then rewrites it.
Corpus inputs are collected by a port of `loadCorpus` in pele's `tests/support/corpus.ts`, which takes string literals from `tests/compat/<diagram>/*.spec.{js,ts}` that match a per-diagram keyword and adds `tests/corpus/<diagram>-docs.json`.
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

The ranges are those of `isZeroWidth` and `isWide` in pele's `src/text/measurer.ts`, so a character outside the basic plane adds `wide` for its high surrogate and nothing for its low one.
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

Every coordinate in the SVG output is formatted by `num()` in pele's `src/svg/builder.ts`.
It rounds to hundredths and drops trailing zeros, so a port has to reproduce it exactly, including its handling of negative values and zero, for a byte-exact comparison.
