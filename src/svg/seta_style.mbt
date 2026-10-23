///|
/// Mermaid style declarations split as `resolve_style` splits them, with `shape`, `line` and
/// `text` kept as the CSS of a `style` attribute before it is escaped, or empty.
/// The CSS is escaped only as it is written, a piece at a time, because a value of tens of
/// millions of `&` escapes to more than a doubling StringBuilder holds.
pub(all) struct RawStyle {
  shape : String
  line : String
  text : String
  stroke : String?
  bold : Bool
  italic : Bool
  font_size : Double?
}

///|
/// The declarations split as `resolve_style` splits them, before any of them is escaped.
pub fn resolve_raw_style(declarations : Array[String]) -> RawStyle {
  let shape = Properties::new()
  let text = Properties::new()
  for declaration in declarations {
    let at = @util.index_of(declaration, ":")
    if at <= 0 {
      continue
    }
    let name = lower_ascii(
      @util.trim(@util.slice(declaration, 0, end=at)),
      kelvin=true,
    )
    let value = @util.trim(remove_important(@util.slice(declaration, at + 1)))
    if value == "" || is_unsafe(value) {
      continue
    }
    if shape_props.contains(name) {
      shape.set(name, value)
    }
    if text_props.contains(name) {
      text.set(if name == "color" { "fill" } else { name }, value)
    }
  }
  let weight = text.get("font-weight")
  let size = text.get("font-size")
  let font_size = match size {
    Some(size) if size != "" && is_pixel_size(size) => {
      let px = @util.parse_float(size)
      if px > 0 && px <= 200 {
        Some(px)
      } else {
        None
      }
    }
    _ => None
  }
  {
    shape: declarations_css(shape),
    line: declarations_css(shape, skip=name => {
      name == "fill" || name == "fill-opacity"
    }),
    text: declarations_css(text),
    stroke: shape.get("stroke"),
    bold: match weight {
      Some(weight) =>
        weight == "bold" || weight == "bolder" || @util.to_number(weight) >= 600
      None => false
    },
    italic: text.get("font-style") is Some("italic"),
    font_size,
  }
}

///|
/// Writes the `style` attribute `resolve_style` makes of `css`, escaping it a piece at a time.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_style(out : Markup, css : String) -> Unit raise @errors.PeleError {
  if css == "" {
    return
  }
  out.write(" style=\"")
  write_esc(out, css)
  out.write("\"")
}

///|
/// Writes the `style` attribute of `css` with the corner radius first, as `rounded` adds it to
/// attributes whose only `style` attribute is the one `resolve_style` makes of `css`.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_rounded_style(
  out : Markup,
  css : String,
) -> Unit raise @errors.PeleError {
  if css == "" {
    out.write(ROUNDED)
    return
  }
  out.write(" style=\"rx:var(--_r);")
  write_esc(out, css)
  out.write("\"")
}

///|
/// Writes a measured label as `write_label` does under the attributes `attrs` followed by the
/// `style` attribute `resolve_style` makes of `css`, which is escaped a piece at a time.
/// Math under such a label takes its color from the attributes written whole, so a label with
/// math still escapes all of `css` at once.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_label_styled(
  out : Markup,
  label : @text.Label,
  cx : Double,
  cy : Double,
  attrs : String,
  css : String,
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
    out.write("<text\{attrs}")
    write_style(out, css)
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
              let math_look = MathLook::of(attrs + attribute(css))
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
          write_esc_text(extra, name)
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
  // An escaped style holds no `"`, so whether the attributes give a weight or a style of their
  // own is found in `attrs` alone, and the emphasis goes after the style as `text_style` puts it.
  out.write("<text\{attrs}")
  write_style(out, css)
  out.write(
    @util.slice(text_style(attrs, shared), attrs.length()) +
    " text-anchor=\"middle\" xml:space=\"preserve\">",
  )
  out.write_markup(body)
  out.write("</text>")
  out.write_markup(extra)
}

///|
/// What stands in for the escaped CSS of a shape's fill and border while `draw_shape` draws it.
/// No drawing holds a NUL, which XML forbids.
const SHAPE_CSS : String = "\u{0}a\u{0}"

///|
/// What stands in for the escaped CSS of a shape's inner strokes while `draw_shape` draws it.
const LINE_CSS : String = "\u{0}l\u{0}"

///|
fn stand_in(css : String, mark : String) -> String {
  if css == "" {
    ""
  } else {
    " style=\"" + mark + "\""
  }
}

///|
/// Writes the outline `draw_shape` draws when `a` and `line` are each followed by the `style`
/// attribute `resolve_style` makes of `a_css` and `line_css`, escaping the CSS a piece at a time.
/// The shape is drawn around stand-ins for the CSS, which a drawing only looks past, as `rounded`
/// does to find where the `style` attribute starts.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_shape_styled(
  out : Markup,
  shape : String,
  w : Double,
  h : Double,
  a : String,
  a_css : String,
  line : String,
  line_css : String,
) -> Unit raise @errors.PeleError {
  let drawn = draw_shape(
    shape,
    w,
    h,
    a + stand_in(a_css, SHAPE_CSS),
    line + stand_in(line_css, LINE_CSS),
  )
  let mut from = 0
  let mut i = 0
  while i < drawn.length() {
    if drawn.unsafe_get(i).to_int() != 0 {
      i += 1
      continue
    }
    out.write(@util.slice(drawn, from, end=i))
    write_esc(
      out,
      if drawn.unsafe_get(i + 1) == 'a' {
        a_css
      } else {
        line_css
      },
    )
    i += SHAPE_CSS.length()
    from = i
  }
  out.write(@util.slice(drawn, from))
}
