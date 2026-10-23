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
