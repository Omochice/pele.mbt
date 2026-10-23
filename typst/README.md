# pele for typst

This package draws Mermaid diagrams in typst documents with pele, a Mermaid to SVG renderer, ported to MoonBit and compiled to a WebAssembly plugin.
It needs no network access and no external program.

## Building

The plugin is not tracked by the repository, so it is built from the sources and copied next to `lib.typ`.

```sh
node scripts/build-typst.mjs
```

The script runs `moon build --target wasm --release` with the `moon` found on `PATH`, or the one `$MOON` names.

## Usage

`mermaid` renders Mermaid text and places it as an image.
Without a `width` or `height`, a diagram keeps its own size but shrinks to fit the space it is placed in.

```typ
#import "typst/lib.typ": mermaid

#mermaid("graph TD\n  A --> B")

#show raw.where(lang: "mermaid"): it => mermaid(it)
```

`render` takes the same arguments and returns pele's whole result as a dictionary of `svg`, `width`, `height`, `links`, `type` and `mermaidType`.
When pele cannot render the text, both panic with pele's message.

Named arguments other than `theme`, `width`, `height`, `alt` and `fit` are passed to pele as its render options, under pele's own names such as `maxWidth`, `fontSize`, `fontFamily`, `config` or `now`.
A plugin cannot read the clock, so a gantt chart is drawn as of the Unix epoch unless `now` gives the time in milliseconds.

## Theme

pele colors its SVG with CSS custom properties, which typst does not resolve, so the package resolves them in the plugin before typst reads the SVG.
`theme` sets their values, keyed by the name of pele's `--pele-*` property without `--pele-`.

```typ
#mermaid(theme: (bg: rgb("#1e1e2e"), fg: white, accent: blue, radius: 8pt, series-1: teal), "pie\n  \"A\": 1")
```

The keys are `bg`, `fg`, `muted`, `line`, `surface`, `surface-alt`, `border`, `accent`, `critical`, `radius`, `font`, `font-mono`, `heading-weight`, `title-weight`, `bold-weight` and `series-1` to `series-8`.
A color is written as its hex code, a length as a number of the SVG's units, and anything else as its string.
An absent key keeps pele's own value.
A value holding `;`, `{` or `}` is ignored, as it could end the declaration it is written into.

typst resolves no generic font family such as `sans-serif` or `monospace`, and draws such text in its default serif font.
The theme therefore names `Arial, Helvetica, Liberation Sans, Arimo` for `font`, as pele lays labels out with Arial's metrics unless it is given a measurer, and `DejaVu Sans Mono`, which ships with typst, for `font-mono`.
Either default gives way to `fontFamily` or `fontFamilyMono`, or to the theme's own key.

`theme: none` returns pele's SVG unchanged, which typst draws without its colors.

## Fonts

pele sizes every box from the widths of its labels, and without a measurer it takes them from a table of Arial's advances.
Text drawn in a font with other metrics then overflows its box or leaves a gap.
`font-measurer` measures a font's advances with typst and returns them in the form the `measurer` option takes, so labels are laid out in the font they are drawn in.

```typ
#import "typst/lib.typ": font-measurer, mermaid

#context mermaid(
  fontFamily: "Libertinus Serif",
  measurer: font-measurer("Libertinus Serif"),
  "graph LR\n  A[Measured in its own font] --> B",
)
```

It reads the fonts, so it is called inside `context`.
The font is named twice because `fontFamily` is the CSS font list the SVG is drawn with, while `font-measurer` takes a font as `text` does.
`font-mono` names the font of code, `DejaVu Sans Mono` by default, and `chars` the characters measured one by one, `measured-chars` by default.
Any other character takes the mean advance of the lowercase Latin letters, or the advance of `日` where pele counts it as double width.

The `measurer` option can also be written by hand, as a dictionary of `unitsPerEm` and `styles`, which maps each of pele's styles to its `advances`, `default` and `wide` advance in font units.
The section "Callback options" of the repository's `golden/README.md` gives its exact rules.
It is a table rather than a function because a plugin cannot call back into typst, so kerning and ligatures are not part of it.

## Icons

pele asks a function for the drawing of each icon a diagram names, which typst cannot pass to a plugin, so `icons` gives the drawings as a dictionary instead.
Each key is an icon name as the diagram writes it, such as `fa:fa-car` in a label, `logos:aws-s3` in an architecture service or `mermaid-treeview:folder` in a tree view.
Each value is an SVG fragment drawn in a 24 by 24 box, whose strokes take the text color unless the fragment sets its own.

```typ
#mermaid(icons: ("fa:fa-car": "<path d=\"M3,15V11L6,6H18L21,11V15Z\"/>"), "graph TD\n  A[fa:fa-car Car]")
```

A name the dictionary lacks, or one whose value is not a string, takes no room in a label and keeps the diagram's own drawing elsewhere.
An empty string draws nothing in place of an architecture or tree view icon's built-in drawing.

## Why the SVG is rewritten

Compiling a document that embeds pele's SVG with typst 0.15.1 showed the following.

- A fill or stroke written as `var(...)` is not resolved, so every shape is filled black and every line that has only such a stroke is not drawn.
- The parser of the `style` attribute stops at the first custom property declaration, so the root's `color`, `font` and `font-family`, which come after pele's `--_*` aliases, are lost.
- A corner radius in `style`, as pele writes `style="rx:..."`, is ignored, while the `rx` attribute is honored.
- A generic font family falls back to typst's serif font, while named families and lists of them are honored.

With a theme, the plugin therefore replaces every reference with its value, drops the custom property declarations and moves corner radii into `rx` and `ry` attributes.
Without a theme, the plugin returns pele's output byte for byte.

## Limitations

- typst does not evaluate `color-mix()`, so the halo pele draws behind the titles of nested clusters is left out.
- Math, which pele takes as a function, is not supported.

## Checking

`node scripts/check-typst.mjs` compiles every document under `examples` and `tests` with the `typst` found on `PATH`, or the one `$TYPST` names.
A document passes when it compiles without an error or a warning, and a test named `*.fail.typ` passes when it fails with the message its first line names after `// error:`.
