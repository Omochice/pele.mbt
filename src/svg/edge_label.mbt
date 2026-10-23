///|
/// An edge label centered on (`x`, `y`) on a patch of the background, so the line does not run through the text.
/// `attrs` are added to the text element.
pub fn edge_label_svg(
  id : String,
  label : @text.Label,
  x : Double,
  y : Double,
  attrs : String,
  icons? : @types.IconResolver,
) -> String {
  written(out => write_edge_label(out, id, label, x, y, attrs, icons?))
}

///|
/// Writes an edge label to `out` as `edge_label_svg` draws it.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_edge_label(
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
  out.write(
    "<g class=\"pele-edge-label\" data-id=\"\{esc_text(id)}\">" +
    "<rect x=\"\{num(x - w / 2)}\" y=\"\{num(y - h / 2)}\" width=\"\{num(w)}\" height=\"\{num(h)}\" rx=\"3\" fill=\"var(--_bg)\"/>",
  )
  write_label(out, label, x, y, attrs, icons?)
  out.write("</g>")
}
