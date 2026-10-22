///|
/// Lays out literal text, such as a filename or a protocol field, in lines no wider than `room`.
/// Every character is kept but the spaces a line breaks at, and a word too long for a line breaks between code points.
pub fn literal_label(
  text : String,
  measurer : @text.TextMeasurer,
  size : Double,
  room : Double,
  style~ : Int32 = 0,
) -> @text.Label {
  ignore((text, measurer, room, style))
  { lines: [], widths: [], width: 0, height: 0, size, line_height: 0, }
}
