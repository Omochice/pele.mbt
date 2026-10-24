#let _plugin = plugin("plugin.wasm")

/// The fonts the default theme names in place of pele's generic families.
/// typst's SVG renderer resolves no generic family such as `sans-serif` or `monospace`, and pele lays labels out with Arial's metrics unless it is given a measurer, so Arial and its metric-compatible stand-ins come first.
/// DejaVu Sans Mono ships with typst, so code is drawn in it wherever the document is compiled.
#let default-fonts = (
  font: "Arial, Helvetica, Liberation Sans, Arimo",
  font-mono: "DejaVu Sans Mono",
)

/// The characters @font-measurer measures by default: printable ASCII, Latin-1 and common typographic punctuation.
#let measured-chars = (
  range(0x20, 0x7f).map(str.from-unicode).join()
    + range(0xa0, 0x100).map(str.from-unicode).join()
    + "‘’‚“”„–—…•‹›€′″"
)

/// Builds pele's `measurer` option from the advances typst sets the given fonts with, so that labels fit text drawn in them.
/// It reads the fonts, so it is called where the context is known, such as inside `context`.
///
/// - font (str, array): The font labels are drawn in, as for `text`.
/// - font-mono (str, array): The font code is drawn in, as for `text`.
/// - chars (str): The characters whose advances are measured one by one.
///   Any other character takes the mean advance of the lowercase Latin letters, or the advance of `日` where pele counts it as double width.
/// -> dictionary
#let font-measurer(font, font-mono: "DejaVu Sans Mono", chars: measured-chars) = {
  let letters = range(0x61, 0x7b).map(str.from-unicode)
  // pele's measurer is asked about one UTF-16 code unit at a time, so a character outside the basic plane can never be looked up.
  let singles = chars.codepoints().filter(c => str.to-unicode(c) >= 0x20 and str.to-unicode(c) < 0x10000)
  let styles = (:)
  for style in range(8) {
    // pele's style is a bit set of 1 for bold, 2 for italic and 4 for monospace.
    let face = (
      font: if style.bit-and(4) != 0 { font-mono } else { font },
      weight: if style.bit-and(1) != 0 { "bold" } else { "regular" },
      style: if style.bit-and(2) != 0 { "italic" } else { "normal" },
    )
    let advance(c) = measure(text(size: 1000pt, ..face, c)).width.pt()
    let advances = (:)
    for c in singles {
      advances.insert(c, advance(c))
    }
    styles.insert(str(style), (
      advances: advances,
      default: letters.map(advance).sum() / letters.len(),
      wide: advance("日"),
    ))
  }
  (unitsPerEm: 1000, styles: styles)
}

#let _css(value) = {
  if type(value) == color {
    value.to-hex()
  } else if type(value) == length {
    // pele's radius is a number of the SVG's own units, which have no relation to the page's.
    str(value.pt())
  } else {
    str(value)
  }
}

#let _theme(theme, options) = {
  if theme == none {
    return none
  }
  let resolved = (:)
  if "fontFamily" not in options {
    resolved.insert("font", default-fonts.font)
  }
  if "fontFamilyMono" not in options {
    resolved.insert("font-mono", default-fonts.font-mono)
  }
  for (name, value) in theme {
    resolved.insert(name, _css(value))
  }
  resolved
}

/// Renders Mermaid text with pele.
///
/// - source (str, content): The Mermaid text, or a raw block holding it.
/// - theme (dictionary, none): Values of pele's `--pele-*` custom properties, keyed by their name without `--pele-`, such as `bg`, `accent`, `radius` or `series-1`.
///   A color, length or number is written as CSS, and an absent key keeps pele's own value, except that `font` and `font-mono` default to @default-fonts unless `fontFamily` or `fontFamilyMono` is given.
///   `none` returns pele's own SVG, whose colors typst cannot resolve.
/// - ..options: pele's render options under pele's own names, such as `maxWidth`, `fontSize`, `config` or `now`.
/// -> dictionary with `svg`, `width`, `height`, `links`, `type` and `mermaidType`; panics with pele's message when the text cannot be rendered.
#let render(source, theme: (:), ..options) = {
  let source = if type(source) == content and source.func() == raw { source.text } else { source }
  assert(type(source) == str, message: "pele renders a string or a raw block, not " + repr(type(source)))
  assert(options.pos().len() == 0, message: "pele takes the Mermaid text as its only positional argument")
  let options = options.named()
  let theme = _theme(theme, options)
  if theme != none {
    options.insert("theme", theme)
  }
  let response = json(_plugin.try_render(bytes(source), bytes(json.encode(options, pretty: false))))
  if "error" in response {
    panic(response.error.message)
  }
  response
}

/// Renders Mermaid text with pele as an image.
/// Without a width or height, the diagram keeps its own size but shrinks to fit the space it is placed in, as pele's SVG does on a web page.
///
/// - source (str, content): The Mermaid text, or a raw block holding it.
/// - theme (dictionary, none): As for @render.
/// - width (auto, relative): As for `image`.
/// - height (auto, relative, fraction): As for `image`.
/// - alt (none, str): As for `image`.
/// - fit (str): As for `image`.
/// - ..options: pele's render options, as for @render.
/// -> content
#let mermaid(source, theme: (:), width: auto, height: auto, alt: none, fit: "contain", ..options) = {
  let result = render(source, theme: theme, ..options)
  let picture(width) = image(bytes(result.svg), format: "svg", width: width, height: height, alt: alt, fit: fit)
  if width != auto or height != auto {
    return picture(width)
  }
  layout(size => {
    let natural = measure(picture(auto)).width
    picture(if natural > size.width { size.width } else { auto })
  })
}
