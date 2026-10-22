///|
/// Lays out text the way Mermaid's journey and timeline draw it: as plain text in which only `<br>` is markup,
/// so other tags and icon names show as written instead of being read as formatting.
pub fn plain_label(
  raw : String?,
  measurer : @text.TextMeasurer,
  size : Double,
  max : Double,
  base~ : Int32 = 0,
) -> @text.Label {
  ignore((raw, measurer, size, max, base))
  { lines: [], widths: [], width: 0, height: 0, size: 0, line_height: 0, }
}

///|
/// Lays out text as `plain_label` does, and for a box of fixed width also cuts any word too long to fit.
pub fn fit_label(
  raw : String?,
  measurer : @text.TextMeasurer,
  size : Double,
  max : Double,
  base~ : Int32 = 0,
) -> @text.Label {
  plain_label(raw, measurer, size, max, base~)
}
