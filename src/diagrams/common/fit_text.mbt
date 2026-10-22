///|
/// One line of text fitted into a width, with the font size it is drawn at.
pub(all) struct Fitted {
  text : String
  size : Double
  width : Double
}

///|
/// Fits one line of text into `max`: first by shrinking the font down to `min`, then by cutting the text and adding an ellipsis.
/// Returns `None` when not even one character fits.
pub fn fit_text(
  text : String,
  max : Double,
  size : Double,
  min : Double,
  measurer : @text.TextMeasurer,
  style~ : Int32 = 0,
) -> Fitted? {
  if text == "" || max <= 0 {
    return None
  }
  let mut width = measurer.width(text, size, style)
  if width <= max {
    return Some({ text, size, width, })
  }
  // Width grows with font size, so one division lands on the right size or just above it.
  let mut fitted = @util.js_max(min, (size * max / width).floor())
  while fitted >= min {
    width = measurer.width(text, fitted, style)
    if width <= max {
      return Some({ text, size: fitted, width, })
    }
    fitted -= 1
  }
  let starts = code_point_starts(text)
  let cut_at = (count : Int32) => {
    @util.trim_end(@util.slice(text, 0, end=starts[count])) + "…"
  }
  let mut low = 0
  let mut high = starts.length() - 2
  while low < high {
    let mid = (low + high + 1) >> 1
    if measurer.width(cut_at(mid), min, style) <= max {
      low = mid
    } else {
      high = mid - 1
    }
  }
  if low == 0 {
    return None
  }
  let cut = cut_at(low)
  width = measurer.width(cut, min, style)
  if width <= max {
    Some({ text: cut, size: min, width, })
  } else {
    None
  }
}
