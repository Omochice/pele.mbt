///|
/// An edge label centered on (`x`, `y`) on a patch of the background, so the line does not run through the text.
/// `attrs` are added to the text element.
pub fn edge_label_svg(
  id : String,
  label : @text.Label,
  x : Double,
  y : Double,
  attrs : String,
) -> String {
  let w = label.width + 8
  let h = label.height
  "<g class=\"pele-edge-label\" data-id=\"\{esc_text(id)}\">" +
  "<rect x=\"\{num(x - w / 2)}\" y=\"\{num(y - h / 2)}\" width=\"\{num(w)}\" height=\"\{num(h)}\" rx=\"3\" fill=\"var(--_bg)\"/>" +
  label_svg(label, x, y, attrs) +
  "</g>"
}
