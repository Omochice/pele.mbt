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
const MONO_ATTR : String = " font-family=\"var(--_fm)\""

///|
const SUB_ATTR : String = " baseline-shift=\"sub\" font-size=\"smaller\""

///|
const SUP_ATTR : String = " baseline-shift=\"super\" font-size=\"smaller\""

///|
/// The attributes of a span's own emphasis.
pub fn span_style(style : Int32) -> String {
  (if (style & @text.STYLE_BOLD) != 0 { BOLD_ATTR } else { "" }) +
  (if (style & @text.STYLE_ITALIC) != 0 { ITALIC_ATTR } else { "" }) +
  (if (style & @text.STYLE_MONO) != 0 { MONO_ATTR } else { "" }) +
  (if (style & @text.STYLE_SUB) != 0 {
    SUB_ATTR
  } else if (style & @text.STYLE_SUP) != 0 {
    SUP_ATTR
  } else {
    ""
  })
}

///|
/// The emphasis every span of a label has, which is written once on the text element.
pub fn shared_style(label : @text.Label) -> Int32 {
  let mut shared = @text.STYLE_BOLD | @text.STYLE_ITALIC | @text.STYLE_MONO
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
  }) +
  (if (shared & @text.STYLE_MONO) != 0 && !attrs.contains(" font-family=\"") {
    MONO_ATTR
  } else {
    ""
  })
}

///|
/// Writes a measured label to `out` as SVG text centered on (`cx`, `cy`), keeping each host drawing
/// a piece of its own rather than copying it, so a label can be as long as the markup holding it.
/// `icons` draws inside the square of each icon span, which is otherwise left empty.
pub fn write_label(
  out : Markup,
  label : @text.Label,
  cx : Double,
  cy : Double,
  attrs : String,
  icons? : @types.IconResolver,
) -> Unit raise @errors.PeleError {
  write_label_parts(
    out,
    label,
    cx,
    cy,
    out => out.write(attrs),
    () => attrs.contains(" font-weight=\""),
    () => attrs.contains(" font-style=\""),
    () => attrs.contains(" font-family=\""),
    () => attrs,
    icons?,
  )
}

///|
/// Writes a measured label to `out` as `write_label` draws it under the attributes `write_attrs`
/// writes, which hold ` font-weight="` when `weighted` says so, ` font-style="` when `styled`
/// does and ` font-family="` when `familied` does, and which `math_attrs` gives as one string to
/// math the label typesets.
/// The attributes are asked about only when the label needs them, so that a writer whose
/// attributes are too long for one string can tell from its parts.
fn write_label_parts(
  out : Markup,
  label : @text.Label,
  cx : Double,
  cy : Double,
  write_attrs : (Markup) -> Unit raise @errors.PeleError,
  weighted : () -> Bool,
  styled : () -> Bool,
  familied : () -> Bool,
  math_attrs : () -> String,
  icons? : @types.IconResolver,
) -> Unit raise @errors.PeleError {
  let lines = label.lines
  if lines.is_empty() {
    return
  }
  let lh = label.line_height
  let shift = label.size * 0.35
  let mut top = cy - label.height / 2
  if lines.length() == 1 &&
    lines[0].length() == 1 &&
    lines[0][0].icon is None &&
    lines[0][0].math is None &&
    lines[0][0].style == 0 {
    out.write("<text")
    write_attrs(out)
    out.write(
      " x=\"\{num(cx)}\" y=\"\{num(top + lh / 2 + shift)}\" text-anchor=\"middle\">",
    )
    out.write_esc(lines[0][0].text)
    out.write("</text>")
    return
  }
  let shared = shared_style(label)
  let mut look : MathLook? = None
  let body = Markup::new()
  let extra = Markup::new()
  for i, line in lines {
    let h = match label.heights {
      Some(heights) => heights[i]
      None => lh
    }
    let mid = top + h / 2
    let y = mid + shift
    if line.iter().any(span => span.icon is Some(_) || span.math is Some(_)) {
      let mut x = cx - label.widths[i] / 2
      for span in line {
        if span.math is Some(math) {
          let box = "x=\"\{num(x)}\" y=\"\{num(mid - math.height / 2)}\" width=\"\{num(math.width)}\" height=\"\{num(math.height)}\""
          let math_look = match look {
            Some(math_look) => math_look
            None => {
              let math_look = MathLook::of(math_attrs())
              look = Some(math_look)
              math_look
            }
          }
          match math_look.halo {
            None => write_math(extra, math, box, label.size, math_look.attrs)
            Some(halo) =>
              extra.write("<rect \{box} rx=\"2\" fill=\"\{halo}\"/>")
          }
        } else if span.icon is Some(name) {
          let side = label.size * 1.1
          let drawing = match icons {
            Some(resolve) => resolve(name).unwrap_or("")
            None => ""
          }
          extra.write("<svg class=\"pele-icon\" data-icon=\"")
          extra.write_esc_text(name)
          extra.write(
            "\" x=\"\{num(x)}\" y=\"\{num(mid - side / 2)}\" width=\"\{num(side)}\" height=\"\{num(side)}\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\">",
          )
          extra.write(drawing)
          extra.write("</svg>")
        } else if span.text != "" {
          body.write(
            "<tspan x=\"\{num(x)}\" y=\"\{num(y)}\" text-anchor=\"start\"\{span_style(span.style & shared.lnot())}>",
          )
          body.write_esc(span.text)
          body.write("</tspan>")
        }
        x += span.width
      }
    } else {
      for j, span in line {
        let pos = if j == 0 { " x=\"\{num(cx)}\" y=\"\{num(y)}\"" } else { "" }
        body.write("<tspan\{pos}\{span_style(span.style & shared.lnot())}>")
        body.write_esc(span.text)
        body.write("</tspan>")
      }
      if line.is_empty() {
        body.write("<tspan x=\"\{num(cx)}\" y=\"\{num(y)}\"> </tspan>")
      }
    }
    top += h
  }
  out.write("<text")
  write_attrs(out)
  if (shared & @text.STYLE_BOLD) != 0 && !weighted() {
    out.write(BOLD_ATTR)
  }
  if (shared & @text.STYLE_ITALIC) != 0 && !styled() {
    out.write(ITALIC_ATTR)
  }
  if (shared & @text.STYLE_MONO) != 0 && !familied() {
    out.write(MONO_ATTR)
  }
  out.write_group(
    " text-anchor=\"middle\" xml:space=\"preserve\">", body, "</text>",
  )
  out.write_markup(extra)
}

///|
/// How math is drawn under a text's attributes.
/// Only color and opacity are copied, so that the math keeps the size it was typeset at, and an
/// outlined text, such as a cluster title, hides what is behind its math with a patch of `halo`.
priv struct MathLook {
  attrs : String
  halo : String?
}

///|
/// The value of the first ` name="…"` attribute, as `/ name="([^"]*)"/` captures it.
fn attr_value(attrs : String, name : String) -> String? {
  let key = " \{name}=\""
  let at = @util.index_of(attrs, key)
  guard at != -1 else { return None }
  let start = at + key.length()
  let end = @util.index_of(attrs, "\"", from=start)
  guard end != -1 else { return None }
  Some(@util.slice(attrs, start, end~))
}

///|
/// The value of the first `name:` declaration, as `/(?:^|;)\s*name:([^;]*)/` captures it.
fn style_value(style : String, name : String) -> String? {
  let mut start = 0
  while start <= style.length() {
    let mut i = start
    while @util.is_space(@util.code_at(style, i)) {
      i += 1
    }
    if @util.starts_with_at(style, name + ":", i) {
      let from = i + name.length() + 1
      let end = @util.index_of(style, ";", from~)
      return Some(
        @util.slice(
          style,
          from,
          end=if end == -1 { style.length() } else { end },
        ),
      )
    }
    let next = @util.index_of(style, ";", from=start)
    guard next != -1 else { return None }
    start = next + 1
  }
  None
}

///|
fn MathLook::of(attrs : String) -> MathLook {
  let style = attr_value(attrs, "style").unwrap_or("")
  let fill = match style_value(style, "fill") {
    Some(fill) => @util.trim(fill)
    None => @util.trim(attr_value(attrs, "fill").unwrap_or(""))
  }
  if fill == "none" {
    return {
      attrs: "",
      halo: Some(attr_value(attrs, "stroke").unwrap_or("none")),
    }
  }
  let color = if fill == "" { "" } else { " color=\"\{fill}\"" }
  let opacity = match style_value(style, "opacity") {
    Some(opacity) if @util.trim(opacity) != "" =>
      " opacity=\"\{@util.trim(opacity)}\""
    _ => ""
  }
  { attrs: color + opacity, halo: None, }
}

///|
/// Writes the host's markup in a box, trusted as it is.
fn write_math(
  out : Markup,
  math : @text.MathMarkup,
  box : String,
  size : Double,
  attrs : String,
) -> Unit {
  match math.body {
    Svg(svg) => {
      out.write("<svg class=\"pele-math\" \{box} overflow=\"visible\"\{attrs}>")
      out.write(svg)
      out.write("</svg>")
    }
    Html(html) => {
      out.write(
        "<foreignObject class=\"pele-math\" \{box} overflow=\"visible\"\{attrs}>" +
        "<div xmlns=\"http://www.w3.org/1999/xhtml\" style=\"display:flex;align-items:center;justify-content:center;width:100%;height:100%;font-size:\{num(size)}px;line-height:normal;white-space:nowrap\">",
      )
      out.write(html)
      out.write("</div></foreignObject>")
    }
  }
}
