///|
/// Writes a label drawn line by line from its start as `write_left_label` does under the
/// attributes `attrs` followed by the `style` attribute `resolve_style` makes of `css`, which is
/// escaped a piece at a time.
/// A style of tens of millions of `&` escapes to more than a doubling StringBuilder holds.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_left_label_styled(
  out : @svg.Markup,
  label : @text.Label,
  x : Double,
  top : Double,
  attrs : String,
  css : String,
) -> Unit raise @errors.PeleError {
  let shared = @svg.shared_style(label)
  // An escaped style holds no `"`, so the emphasis `text_style` adds is found from `attrs` alone.
  let emphasis = @util.slice(@svg.text_style(attrs, shared), attrs.length())
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
      @svg.write_label_styled(out, line, x + width / 2, cy, attrs, css)
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
      out.write("<text\{attrs}")
      @svg.write_style(out, css)
      out.write_group(
        "\{emphasis} x=\"\{@svg.num(x)}\" y=\"\{@svg.num(cy + label.size * 0.35)}\" text-anchor=\"start\" xml:space=\"preserve\">",
        text,
        "</text>",
      )
    }
  }
}
