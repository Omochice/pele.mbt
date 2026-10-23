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
    lines: lines.mapi((i, line) => {
      [{ text: line, style, icon: None, width: widths[i], math: None, }]
    }),
    widths,
    width,
    height: lines.length().to_double() * line_height,
    size,
    line_height,
    heights: None,
  }
}

///|
/// Breaks every line of `label` wider than `room` between characters, keeping each span's emphasis.
pub fn break_label(
  label : @text.Label,
  measurer : @text.TextMeasurer,
  room : Double,
) -> @text.Label {
  if label.width <= room {
    return label
  }
  let lines : Array[Array[@text.Span]] = []
  let widths : Array[Double] = []
  for i, spans in label.lines {
    if label.widths[i] <= room {
      lines.push(spans)
      widths.push(label.widths[i])
      continue
    }
    let mut current : Array[@text.Span] = []
    let mut width = 0.0
    let commit = () => {
      lines.push(current)
      widths.push(width)
      current = []
      width = 0
    }
    for span in spans {
      if span.icon is Some(_) || span.math is Some(_) {
        if current.length() > 0 && width + span.width > room {
          commit()
        }
        current.push(span)
        width += span.width
        continue
      }
      let starts = code_point_starts(span.text)
      for k in 0..<(starts.length() - 1) {
        let char = @util.slice(span.text, starts[k], end=starts[k + 1])
        let mut last = match current.last() {
          Some(last) if last.icon is None &&
            last.math is None &&
            last.style == span.style => Some(last)
          _ => None
        }
        let next_width = match last {
          Some(last) => measurer.width(last.text + char, label.size, span.style)
          None => measurer.width(char, label.size, span.style)
        }
        let mut added = match last {
          Some(last) => next_width - last.width
          None => next_width
        }
        if current.length() > 0 && width + added > room {
          commit()
          last = None
          added = measurer.width(char, label.size, span.style)
        }
        match last {
          Some(last) => {
            last.text = last.text + char
            last.width = last.width + added
          }
          None =>
            current.push({
              text: char,
              style: span.style,
              icon: None,
              width: added,
              math: None,
            })
        }
        width += added
      }
    }
    if current.length() > 0 || spans.length() == 0 {
      commit()
    }
  }
  let mut width = 0.0
  for w in widths {
    width = @util.js_max(width, w)
  }
  let broken = {
    ..label,
    lines,
    widths,
    width,
    height: lines.length().to_double() * label.line_height,
  }
  if label.heights is Some(_) {
    @text.with_heights(broken)
  } else {
    broken
  }
}

///|
/// Writes `label` with every line starting at `x`, the first line's top at `top`.
/// A line is anchored at its start and keeps its spaces, so that where it begins does not depend on how its text was measured.
/// Aborts where the label would be longer than V8 allows, which `write_left_label` reports instead.
pub fn left_label_svg(
  label : @text.Label,
  x : Double,
  top : Double,
  attrs : String,
) -> String {
  let out = @svg.Markup::new()
  write_left_label(out, label, x, top, attrs) catch {
    _ => abort("label markup longer than V8's longest string")
  }
  out.to_string()
}

///|
/// Writes `label` to `out` as `left_label_svg` draws it, a piece at a time, so a label can be as
/// long as the markup holding it.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_left_label(
  out : @svg.Markup,
  label : @text.Label,
  x : Double,
  top : Double,
  attrs : String,
) -> Unit raise @errors.PeleError {
  let shared = @svg.shared_style(label)
  let open = "<text" + @svg.text_style(attrs, shared)
  for i, spans in label.lines {
    let cy = top + (i.to_double() + 0.5) * label.line_height
    if spans.iter().any(span => span.icon is Some(_)) {
      let width = label.widths[i]
      let line = {
        ..label,
        lines: [spans],
        widths: [width],
        width,
        height: label.line_height,
      }
      @svg.write_label(out, line, x + width / 2, cy, attrs)
      continue
    }
    let text = @svg.Markup::new()
    for span in spans {
      let own = @svg.span_style(span.style & shared.lnot())
      if own != "" {
        text.write("<tspan\{own}>")
        @svg.write_esc(text, span.text)
        text.write("</tspan>")
      } else {
        @svg.write_esc(text, span.text)
      }
    }
    if !text.is_empty() {
      out.write_group(
        "\{open} x=\"\{@svg.num(x)}\" y=\"\{@svg.num(cy + label.size * 0.35)}\" text-anchor=\"start\" xml:space=\"preserve\">",
        text,
        "</text>",
      )
    }
  }
}
