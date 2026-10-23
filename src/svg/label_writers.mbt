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
  write_label_around(
    out,
    label,
    cx,
    cy,
    out => out.write(attrs),
    attrs,
    css,
    icons?,
  )
}

///|
/// Writes a measured label as `write_label_styled` does under the attributes `before`, the id
/// `esc_text` makes of `id`, and `after`, escaping the id a piece at a time as well.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_label_with_id(
  out : Markup,
  label : @text.Label,
  cx : Double,
  cy : Double,
  before : String,
  id : String,
  after : String,
  css : String,
  icons? : @types.IconResolver,
) -> Unit raise @errors.PeleError {
  write_label_around(
    out,
    label,
    cx,
    cy,
    out => {
      out.write(before)
      write_esc_text(out, id)
      out.write(after)
    },
    before + after,
    css,
    icons?,
  )
}

///|
/// Writes a measured label as `write_label` does, with `write_attrs` writing its attributes
/// before the `style` attribute of `css`.
/// `attrs` stands for what `write_attrs` writes wherever the attributes are looked into, for a
/// weight, a font style or a color, which a data-id it leaves out never holds.
fn write_label_around(
  out : Markup,
  label : @text.Label,
  cx : Double,
  cy : Double,
  write_attrs : (Markup) -> Unit raise @errors.PeleError,
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
    out.write("<text")
    write_attrs(out)
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
  out.write("<text")
  write_attrs(out)
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
/// Writes an edge label to `out` as `write_edge_label` does, with `id` escaped as `esc_text`
/// escapes it a piece at a time.
/// An id made of a long source name escapes to more than a doubling StringBuilder holds.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_edge_label_chunked(
  out : Markup,
  id : String,
  label : @text.Label,
  x : Double,
  y : Double,
  attrs : String,
  icons? : @types.IconResolver,
) -> Unit raise @errors.PeleError {
  let w = label.width + 8
  let h = label.height
  out.write("<g class=\"pele-edge-label\" data-id=\"")
  write_esc_text(out, id)
  out.write(
    "\"><rect x=\"\{num(x - w / 2)}\" y=\"\{num(y - h / 2)}\" width=\"\{num(w)}\" height=\"\{num(h)}\" rx=\"3\" fill=\"var(--_bg)\"/>",
  )
  write_label(out, label, x, y, attrs, icons?)
  out.write("</g>")
}

///|
/// Writes a title that an edge runs through to `out` as `write_struck_title` does, with the id
/// written as `esc_text` escapes `id`, a piece at a time.
/// The diagrams that escape their ids before drawing such a title name a cluster by its source
/// text, which escapes to more than a doubling StringBuilder holds.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_struck_title_chunked(
  out : Markup,
  label : @text.Label,
  x : Double,
  y : Double,
  attrs : String,
  id : String,
  nodes : Array[@layout.CNode],
  index : Int32,
  icons? : @types.IconResolver,
) -> Unit raise @errors.PeleError {
  let mut depth = 1
  let mut p = nodes[index].parent
  while p >= 0 && depth < 8 {
    depth += 1
    p = nodes[p].parent
  }
  let mut behind = 1.0
  for _ in 0..<depth {
    behind *= 0.5
  }
  let fill = "color-mix(in srgb,var(--_a) \{num(100 * (1 - behind))}%,var(--_bg))"
  out.write("<g class=\"pele-cluster-title\" data-id=\"")
  write_esc_text(out, id)
  out.write("\">")
  write_label(
    out,
    label,
    x,
    y,
    " fill=\"none\" stroke=\"\{fill}\" stroke-width=\"5\" stroke-linejoin=\"round\"",
    icons?,
  )
  write_label(out, label, x, y, attrs, icons?)
  out.write("</g>")
}
