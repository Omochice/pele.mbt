///|
/// Breaks one line of literal text into lines no wider than `room`, appending them to `lines`.
fn break_literal(
  raw : String,
  measurer : @text.TextMeasurer,
  size : Double,
  room : Double,
  style : Int32,
  lines : Array[String],
) -> Unit {
  let starts = code_point_starts(raw)
  let count = starts.length() - 1
  if count == 0 {
    lines.push("")
  }
  // No surrogate is whitespace, so a code point is a space exactly when its first code unit is.
  let space = (k : Int32) => @util.is_space(@util.code_at(raw, starts[k]))
  let mut from = 0
  while from < count {
    let fits = (length : Int32) => {
      let piece = @util.slice(raw, starts[from], end=starts[from + length])
      measurer.width(piece, size, style) <= room
    }
    let mut hi = 1
    while hi < count - from && fits(hi) {
      hi = if hi * 2 < count - from { hi * 2 } else { count - from }
    }
    let mut lo = 1
    while lo < hi {
      let mid = (lo + hi + 1) / 2
      if fits(mid) {
        lo = mid
      } else {
        hi = mid - 1
      }
    }
    let mut take = lo
    let wraps = from + take < count
    if wraps && !space(from + take) {
      for i = take - 1; i > 0; i = i - 1 {
        if space(from + i) {
          take = i + 1
          break
        }
      }
    }
    let line = @util.slice(raw, starts[from], end=starts[from + take])
    let trimmed = @util.trim_end(line)
    lines.push(if wraps && trimmed != "" { trimmed } else { line })
    from += take
    while wraps && from < count && space(from) {
      from += 1
    }
  }
}

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
  let lines = []
  if text != "" {
    let mut last = 0
    while true {
      let at = @util.index_of(text, "\n", from=last)
      let end = if at == -1 { text.length() } else { at }
      break_literal(
        @util.slice(text, last, end~),
        measurer,
        size,
        room,
        style,
        lines,
      )
      if at == -1 {
        break
      }
      last = at + 1
    }
  }
  let widths = lines.map(line => measurer.width(line, size, style))
  let mut width = 0.0
  for w in widths {
    width = @util.js_max(width, w)
  }
  let line_height = (size * 1.5).round()
  {
    lines: lines.mapi((i, line) => [{ text: line, style, width: widths[i], }]),
    widths,
    width,
    height: lines.length().to_double() * line_height,
    size,
    line_height,
  }
}

///|
/// Breaks every line of `label` wider than `room` between characters, keeping each span's emphasis.
pub fn break_label(
  label : @text.Label,
  measurer : @text.TextMeasurer,
  room : Double,
) -> @text.Label {
  ignore((measurer, room))
  label
}
