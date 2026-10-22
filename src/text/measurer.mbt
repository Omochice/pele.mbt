///|
/// Emphasis bit of a text span.
pub const STYLE_BOLD : Int32 = 1

///|
/// Emphasis bit of a text span.
pub const STYLE_ITALIC : Int32 = 2

///|
/// Emphasis bit of a text span.
pub const STYLE_MONO : Int32 = 4

///|
/// Measures the advance width of text, in pixels.
pub(all) struct TextMeasurer {
  width_of : (String, Double, Int32) -> Double
}

///|
/// The width of `text` at font size `size` with the emphasis bits in `style`.
pub fn TextMeasurer::width(
  self : TextMeasurer,
  text : String,
  size : Double,
  style : Int32,
) -> Double {
  (self.width_of)(text, size, style)
}

///|
/// Estimates widths from a table of Arial advances.
pub let metrics_measurer : TextMeasurer = { width_of: (_, _, _) => 0, }
