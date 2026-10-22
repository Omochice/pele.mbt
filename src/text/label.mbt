///|
/// A run of text with one emphasis.
pub(all) struct Span {
  mut text : String
  style : Int32
  mut width : Double
}

///|
/// Text laid out in lines of spans, measured.
pub(all) struct Label {
  lines : Array[Array[Span]]
  widths : Array[Double]
  width : Double
  height : Double
  size : Double
  line_height : Double
}

///|
/// Lays out label text with inline HTML emphasis, explicit breaks, and wrapping at `max_width`.
/// `markdown` also reads `*` and `_` emphasis; `base` is the emphasis of the whole label.
pub fn layout_label(
  raw : String?,
  markdown : Bool,
  measurer : TextMeasurer,
  size : Double,
  max_width : Double,
  base~ : Int32 = 0,
) -> Label {
  ignore((raw, markdown, measurer, size, max_width, base))
  { lines: [], widths: [], width: 0, height: 0, size: 0, line_height: 0, }
}
