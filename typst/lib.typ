#let _plugin = plugin("plugin.wasm")

/// The fonts the default theme names in place of pele's generic families.
/// typst's SVG renderer resolves no generic family such as `sans-serif` or `monospace`, and pele lays labels out with Arial's metrics, so Arial and its metric-compatible stand-ins come first.
/// DejaVu Sans Mono ships with typst, so code is drawn in it wherever the document is compiled.
#let default-fonts = (
  font: "Arial, Helvetica, Liberation Sans, Arimo",
  font-mono: "DejaVu Sans Mono",
)

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
