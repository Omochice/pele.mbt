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
/// High surrogates count as wide, so a character outside the BMP takes an em.
fn is_wide(c : Int32) -> Bool {
  (c >= 0x1100 && c <= 0x115f) ||
  (c >= 0x2e80 && c <= 0xa4cf) ||
  (c >= 0xac00 && c <= 0xd7a3) ||
  (c >= 0xf900 && c <= 0xfaff) ||
  (c >= 0xfe30 && c <= 0xfe4f) ||
  (c >= 0xff00 && c <= 0xff60) ||
  (c >= 0xffe0 && c <= 0xffe6) ||
  (c >= 0xd800 && c <= 0xdbff)
}

///|
fn is_zero_width(c : Int32) -> Bool {
  (c >= 0x300 && c <= 0x36f) ||
  (c >= 0x200b && c <= 0x200f) ||
  (c >= 0xdc00 && c <= 0xdfff) ||
  (c >= 0xfe00 && c <= 0xfe0f) ||
  c == 0xfeff
}

///|
fn metrics_width(text : String, size : Double, style : Int32) -> Double {
  let mono = (style & STYLE_MONO) != 0
  let table = if (style & STYLE_BOLD) != 0 {
    bold_advances
  } else {
    regular_advances
  }
  let mut units = 0
  for i in 0..<text.length() {
    let c = text.unsafe_get(i).to_int()
    if c < 32 {
      continue
    }
    if c < 127 {
      units += if mono { 600 } else { table[c - 32] }
    } else if is_zero_width(c) {
      continue
    } else if is_wide(c) {
      units += if mono { 1200 } else { 1000 }
    } else {
      units += if mono { 600 } else { 580 }
    }
  }
  units.to_double() * size / 1000
}

///|
/// Estimates widths from a table of Arial advances.
/// pele falls back to it where no canvas is available, which is always the case here.
pub let metrics_measurer : TextMeasurer = { width_of: metrics_width, }
