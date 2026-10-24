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
/// Raises the `limit` error pele gives for a text it would have to cut of more code points than
/// V8's longest array holds.
pub fn fit_text(
  text : String,
  max : Double,
  size : Double,
  min : Double,
  measurer : @text.TextMeasurer,
  style~ : Int32 = 0,
) -> Fitted? raise @errors.PeleError {
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
  // pele cuts among the text's code points held in an array, which V8 holds to a length its
  // longest array allows.
  let count = code_point_count(text)
  if count > @util.JS_ARRAY_MAX_LENGTH {
    raise @errors.nested_too_deeply()
  }
  // Without surrogate pairs each code point starts at its own index, and no table of where they
  // start is made, which for a text of hundreds of millions of characters is larger than wasm
  // allocates.
  let starts = if count == text.length() {
    None
  } else {
    Some(code_point_starts(text))
  }
  let start_of = (at : Int32) => {
    match starts {
      Some(starts) => starts[at]
      None => at
    }
  }
  let cut_at = (at : Int32) => {
    @util.trim_end(@util.slice(text, 0, end=start_of(at))) + "…"
  }
  let mut low = 0
  let mut high = count - 1
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
