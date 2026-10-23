///|
/// A picture with a title put above it.
pub(all) struct Titled {
  width : Double
  height : Double
  content : String
}

///|
/// Puts a diagram title above content that was laid out without one.
pub fn with_title(
  title : String?,
  measurer : @text.TextMeasurer,
  size : Double,
  pad : Double,
  width : Double,
  height : Double,
  content : String,
) -> Titled {
  let label = title_label(title, measurer, size, 4000)
  if label.height == 0 {
    return { width, height, content, }
  }
  let shift = label.height + 12
  let full = @util.js_max(width, (label.width + 2 * pad).ceil())
  {
    width: full,
    height: (height + shift).ceil(),
    content: label_svg(
      label,
      full / 2,
      pad + label.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ) +
    "<g transform=\"translate(\{num((full - width) / 2)},\{num(shift)})\">\{content}</g>",
  }
}

///|
/// A diagram title, set in bold as text whatever it holds, as Mermaid draws it.
/// Returns an empty label without a title.
pub fn title_label(
  title : String?,
  measurer : @text.TextMeasurer,
  size : Double,
  max_width : Double,
) -> @text.Label {
  // pele turns math off around the title; labels here never typeset math, so there is nothing to turn off.
  @text.layout_label(
    title,
    false,
    measurer,
    size,
    max_width,
    base=@text.STYLE_BOLD,
  )
}

