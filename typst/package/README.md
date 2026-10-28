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
#import "typst/package/lib.typ": mermaid

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

pele outlines a cluster title that edges run through with `color-mix(in srgb, …)` of `surface-alt` and `bg`, which typst does not evaluate, so the plugin computes the mix to a hex code as CSS Color 5 defines it.
It reads the colors written as a hex code of 3, 4, 6 or 8 digits, `rgb()` or `rgba()` in either the comma or the space separated form, a named color, `transparent`, or another such mix in sRGB.
A mix in another color space, or of any other color such as `hsl()`, `oklch()` or `currentColor`, is left as written, and typst draws nothing where it paints.
Its channels are rounded half up to bytes, as Chrome rounds the channels of `rgb()`.

typst resolves no generic font family such as `sans-serif` or `monospace`, and draws such text in its default serif font.
The theme therefore names `Arial, Helvetica, Liberation Sans, Arimo` for `font`, as pele lays labels out with Arial's metrics unless it is given a measurer, and `DejaVu Sans Mono`, which ships with typst, for `font-mono`.
Either default gives way to `fontFamily` or `fontFamilyMono`, or to the theme's own key.

`theme: none` returns pele's SVG unchanged, which typst draws without its colors.

## Fonts

pele sizes every box from the widths of its labels, and without a measurer it takes them from a table of Arial's advances.
Text drawn in a font with other metrics then overflows its box or leaves a gap.
`font-measurer` measures a font's advances with typst and returns them in the form the `measurer` option takes, so labels are laid out in the font they are drawn in.

```typ
#import "typst/package/lib.typ": font-measurer, mermaid

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

## Monospace parts

`monospace` lists the parts of a diagram that are code, which pele measures and draws in the monospace font so that their boxes fit them.
That font is the theme's `font-mono`, `DejaVu Sans Mono` by default.

```typ
#mermaid(monospace: ("members",), "classDiagram\n  class A {\n    +title: string\n  }")
```

Each part names the text of one kind of diagram, as the following table lists.

| Part         | Text                                           |
| ------------ | ---------------------------------------------- |
| `members`    | Attributes and methods in class diagrams       |
| `attributes` | Attribute types, names and keys in ER diagrams |
| `files`      | File and directory names in tree view diagrams |
| `messages`   | Message text on arrows in sequence diagrams    |

A class or entity whose `style` or `classDef` sets a `font-family` keeps that font.
typst writes a list of one item with a trailing comma, so `("members")` is a string, which pele ignores as it ignores any value that is not a list and any part it does not know.

## Icons

pele asks a function for the drawing of each icon a diagram names, which typst cannot pass to a plugin, so `icons` gives the drawings as a dictionary instead.
Each key is an icon name as the diagram writes it, such as `fa:fa-car` in a label, `logos:aws-s3` in an architecture service or `mermaid-treeview:folder` in a tree view.
Each value is an SVG fragment drawn in a 24 by 24 box, whose strokes take the text color unless the fragment sets its own.

```typ
#mermaid(icons: ("fa:fa-car": "<path d=\"M3,15V11L6,6H18L21,11V15Z\"/>"), "graph TD\n  A[fa:fa-car Car]")
```

A name the dictionary lacks, or one whose value is not a string, takes no room in a label and keeps the diagram's own drawing elsewhere.
An empty string draws nothing in place of an architecture or tree view icon's built-in drawing.

## Math

pele typesets `$$…$$` in labels with a function the host gives it, and typst cannot pass a function to a plugin, so `math` takes the typeset markup as data instead.
It maps each TeX string, then the font size in pixels written as a number such as `"16"` or `"13.5"`, to a dictionary of `svg` markup and the `width` and `height` of the box it is drawn in.

```typ
#let math = ("x^2": ("16": (svg: "<text y=\"16\" fill=\"currentColor\">x²</text>", width: 18, height: 20)))
#mermaid(math: math, "graph LR\n  A[\"$$x^2$$ grows\"]")
```

Node labels ask for the diagram's font size, while edge labels and class cardinalities ask for smaller ones.
TeX the map does not hold at the size asked for stays as its text, and so does TeX in diagram titles and in the diagram types pele does not typeset math in.
pele also takes `html` markup in place of `svg`, but typst warns about the `foreignObject` that holds it and draws nothing there.
[golden/README.md](https://github.com/Omochice/pele.mbt/blob/main/golden/README.md#math) states the exact rules.

## Why the SVG is rewritten

Compiling a document that embeds pele's SVG with typst 0.15.1 showed the following.

- A fill or stroke written as `var(...)` is not resolved, so every shape is filled black and every line that has only such a stroke is not drawn.
- The parser of the `style` attribute stops at the first custom property declaration, so the root's `color`, `font` and `font-family`, which come after pele's `--_*` aliases, are lost.
- A corner radius in `style`, as pele writes `style="rx:..."`, is ignored, while the `rx` attribute is honored.
- A generic font family falls back to typst's serif font, while named families and lists of them are honored.
- A stroke written as `color-mix()` is not evaluated, so the text it outlines is drawn without its outline, and no warning is given.
- A hex code of 8 digits is drawn with its alpha.

With a theme, the plugin therefore replaces every reference with its value, drops the custom property declarations, computes each `color-mix()` it can read to a hex code and moves corner radii into `rx` and `ry` attributes.
Without a theme, the plugin returns pele's output byte for byte.

## Output ceiling

The plugin runs as wasm32, where all of a render lives in one linear memory of at most 4 GiB, and a drawing is held three times over at its largest: the pieces it is built from, the single string made of them, and the UTF-8 bytes of the JSON response.
A diagram that fits to its width is also drawn several times so their widths can be compared.
So the plugin stops at 400000000 code units of SVG: a drawing larger than that fails with the `limit` error "Diagram output is too large for the wasm port: it would hold more than 400000000 code units, the most the port can hold at once.", tagged with the diagram's type, where pele would still draw it.
The several-render fit path at that ceiling peaks at about 3.1 GiB, inside wasm's 4 GiB.

This ceiling is the one intentional, platform-imposed difference from pele: every input whose SVG is at most 400000000 code units is drawn byte for byte as pele draws it, apart from the few enormous inputs that [Known constraints](https://github.com/Omochice/pele.mbt/blob/main/doc/known-constraints.md) lists.
pele's own output limit is checked first, so the error appears only for a drawing that limit allows, apart from a Gantt axis label or a use case label whose text alone passes the ceiling, as Known constraints lists.
A second guard covers a response whose bytes, rather than code units, would not fit one of wasm's memory blocks: a JSON response over 1000000000 bytes fails with a `limit` error naming that byte limit.
It covers a failure as well as a drawing, since a failure's message can quote a whole line of the source; a drawing under the code-unit ceiling reaches it only when it is almost all non-ASCII text.

pele itself fails some enormous inputs with the `limit` error "Diagram is nested too deeply." only because the JavaScript engine it runs on cannot make a string, an array or a regular expression match that long.
The plugin does not reproduce those failures, and draws such an input whenever it fits under the ceiling above.

## Limitations

- The outline of a cluster title is not drawn when `surface-alt` or `bg` is a color the plugin cannot mix, as listed under [Theme](#theme).
- A diagram whose SVG would be longer than 400000000 code units fails with a `limit` error rather than being drawn, as described under [Output ceiling](#output-ceiling).
- A few inputs of tens to hundreds of millions of characters trap the plugin where pele draws or rejects them, as [Known constraints](https://github.com/Omochice/pele.mbt/blob/main/doc/known-constraints.md) lists.

## Checking

`node scripts/check-typst.mjs` compiles every document under `examples` and `tests` with the `typst` found on `PATH`, or the one `$TYPST` names.
A document passes when it compiles without an error or a warning, and a test named `*.fail.typ` passes when it fails with the message its first line names after `// error:`.
