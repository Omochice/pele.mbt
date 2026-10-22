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
