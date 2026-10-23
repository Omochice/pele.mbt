///|
/// The two decimals of a coordinate, by hundredths.
let fraction : Array[String] = Array::makei(100, i => {
  if i == 0 {
    ""
  } else if i % 10 == 0 {
    "." + (i / 10).to_string()
  } else if i < 10 {
    ".0" + i.to_string()
  } else {
    "." + i.to_string()
  }
})

///|
/// A coordinate as pele writes it: rounded to hundredths, without trailing zeros.
pub fn num(value : Double) -> String {
  let n = (value * 100).round()
  if n == 0 {
    return "0"
  }
  if n > 0 {
    if n < 1.0e11 {
      let q = (n / 100).floor()
      return q.to_int64().to_string() + fraction[(n - q * 100).to_int()]
    }
  } else if n > -1.0e11 {
    let m = -n
    let q = (m / 100).floor()
    return "-" + q.to_int64().to_string() + fraction[(m - q * 100).to_int()]
  }
  (n / 100).to_string()
}

///|
fn is_xml_forbidden(c : Int32) -> Bool {
  (c >= 0 && c <= 8) ||
  c == 0xb ||
  c == 0xc ||
  (c >= 0xe && c <= 0x1f) ||
  c == 0x7f
}

///|
/// Escapes text for XML and drops the control characters XML does not allow.
pub fn esc(text : String) -> String {
  let out = StringBuilder()
  let mut last = 0
  for i in 0..<text.length() {
    let c = @util.code_at(text, i)
    let replacement = match c {
      0x26 => "&amp;"
      0x3c => "&lt;"
      0x3e => "&gt;"
      0x22 => "&quot;"
      _ => if is_xml_forbidden(c) { "" } else { continue }
    }
    @util.write_range(out, text, last, i)
    out.write_string(replacement)
    last = i + 1
  }
  if last == 0 {
    return text
  }
  @util.write_range(out, text, last, text.length())
  out.to_string()
}

///|
/// Escapes text that is only ever read as text: a tooltip, an accessible name, a `data-id`.
/// Entity codes are turned into their characters first.
pub fn esc_text(text : String) -> String {
  esc(@text.decode_entities(text))
}

///|
const BOLD_ATTR : String = " font-weight=\"var(--_w)\""

///|
const ITALIC_ATTR : String = " font-style=\"italic\""

///|
/// The attributes of a span's own emphasis.
pub fn span_style(style : Int32) -> String {
  (if (style & @text.STYLE_BOLD) != 0 { BOLD_ATTR } else { "" }) +
  (if (style & @text.STYLE_ITALIC) != 0 { ITALIC_ATTR } else { "" })
}

///|
/// The emphasis every span of a label has, which is written once on the text element.
pub fn shared_style(label : @text.Label) -> Int32 {
  let mut shared = @text.STYLE_BOLD | @text.STYLE_ITALIC
  let mut any = false
  for line in label.lines {
    for span in line {
      if span.text == "" {
        continue
      }
      shared = shared & span.style
      any = true
    }
  }
  if any {
    shared
  } else {
    0
  }
}

///|
/// Adds the shared emphasis to a text element's attributes, unless they give a weight of their own.
pub fn text_style(attrs : String, shared : Int32) -> String {
  attrs +
  (if (shared & @text.STYLE_BOLD) != 0 && !attrs.contains(" font-weight=\"") {
    BOLD_ATTR
  } else {
    ""
  }) +
  (if (shared & @text.STYLE_ITALIC) != 0 && !attrs.contains(" font-style=\"") {
    ITALIC_ATTR
  } else {
    ""
  })
}

///|
/// Writes a measured label as SVG text centered on (`cx`, `cy`).
/// `icons` draws inside the square of each icon span, which is otherwise left empty.
pub fn label_svg(
  label : @text.Label,
  cx : Double,
  cy : Double,
  attrs : String,
  icons? : @types.IconResolver,
) -> String {
  ignore(icons)
  let lines = label.lines
  if lines.is_empty() {
    return ""
  }
  let lh = label.line_height
  let shift = label.size * 0.35
  let mut top = cy - label.height / 2
  if lines.length() == 1 && lines[0].length() == 1 && lines[0][0].style == 0 {
    return "<text\{attrs} x=\"\{num(cx)}\" y=\"\{num(top + lh / 2 + shift)}\" text-anchor=\"middle\">\{esc(lines[0][0].text)}</text>"
  }
  let shared = shared_style(label)
  let body = StringBuilder()
  for line in lines {
    let y = top + lh / 2 + shift
    for j, span in line {
      let pos = if j == 0 { " x=\"\{num(cx)}\" y=\"\{num(y)}\"" } else { "" }
      body.write_string(
        "<tspan\{pos}\{span_style(span.style & shared.lnot())}>\{esc(span.text)}</tspan>",
      )
    }
    if line.is_empty() {
      body.write_string("<tspan x=\"\{num(cx)}\" y=\"\{num(y)}\"> </tspan>")
    }
    top += lh
  }
  "<text\{text_style(attrs, shared)} text-anchor=\"middle\" xml:space=\"preserve\">\{body.to_string()}</text>"
}
