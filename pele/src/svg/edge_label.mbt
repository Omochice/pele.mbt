///|
/// Writes an edge label centered on (`x`, `y`) to `out`, on a patch of the background so the line
/// does not run through the text, with `attrs` added to the text element.
pub fn write_edge_label(
  out : Markup,
  id : String,
  label : @text.Label,
  x : Double,
  y : Double,
  attrs : String,
  icons? : @types.IconResolver,
) -> Unit raise @errors.PeleError {
  write_edge_label_parts(
    out,
    out => out.write(" data-id=\"\{esc_text(id)}\""),
    label,
    x,
    y,
    attrs,
    icons?,
  )
}

///|
/// Writes an edge label to `out` as `write_edge_label` does, with `id` escaped a piece at a time,
/// and with the `style` attribute `resolve_style` makes of `css` after `attrs`, as
/// `write_label_styled` writes it.
/// An id made of a long source name escapes to more than a doubling StringBuilder holds.
pub fn write_edge_label_with_id(
  out : Markup,
  id : String,
  label : @text.Label,
  x : Double,
  y : Double,
  attrs : String,
  css~ : String = "",
  icons? : @types.IconResolver,
) -> Unit raise @errors.PeleError {
  write_edge_label_parts(
    out,
    out => out.write_data_id(id),
    label,
    x,
    y,
    attrs,
    css~,
    icons?,
  )
}

///|
/// Writes an edge label to `out` as `write_edge_label` draws it, with `write_id` writing its
/// ` data-id` attribute and the label written as `write_label_styled` writes it.
fn write_edge_label_parts(
  out : Markup,
  write_id : (Markup) -> Unit raise @errors.PeleError,
  label : @text.Label,
  x : Double,
  y : Double,
  attrs : String,
  css~ : String = "",
  icons? : @types.IconResolver,
) -> Unit raise @errors.PeleError {
  let w = label.width + 8
  let h = label.height
  out.write("<g class=\"pele-edge-label\"")
  write_id(out)
  out.write(
    "><rect x=\"\{num(x - w / 2)}\" y=\"\{num(y - h / 2)}\" width=\"\{num(w)}\" height=\"\{num(h)}\" rx=\"3\" fill=\"var(--_bg)\"/>",
  )
  write_label_styled(out, label, x, y, attrs, css, icons?)
  out.write("</g>")
}
