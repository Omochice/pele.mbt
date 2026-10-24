///|
/// The length of an arrowhead along its edge.
pub const ARROW : Double = 8

///|
/// How far an edge stops short of its end to leave room for a marker of Mermaid's `type`:
/// `arrow_point`, `arrow_circle` or `arrow_cross`, and none for anything else.
pub fn marker_trim(type_ : String) -> Double {
  match type_ {
    "arrow_point" => ARROW - 1
    "arrow_circle" => ARROW
    "arrow_cross" => 4
    _ => 0
  }
}

///|
/// Draws a marker of Mermaid's `type_` whose tip is at (`x`, `y`), pointing along (`dx`, `dy`).
/// Returns an empty string for a type that draws nothing.
pub fn marker(
  type_ : String,
  x : Double,
  y : Double,
  dx : Double,
  dy : Double,
  color : String,
) -> String {
  let nx = -dy
  let ny = dx
  match type_ {
    "arrow_point" => {
      let bx = x - dx * ARROW
      let by = y - dy * ARROW
      let half = ARROW * 0.42
      "<path class=\"pele-marker\" d=\"M\{num(x)},\{num(y)}L\{num(bx + nx * half)},\{num(by + ny * half)}L\{num(bx - nx * half)},\{num(by - ny * half)}Z\" fill=\"\{color}\" stroke=\"none\"/>"
    }
    "arrow_circle" =>
      "<circle class=\"pele-marker\" cx=\"\{num(x - dx * 4)}\" cy=\"\{num(y - dy * 4)}\" r=\"3.5\" fill=\"\{color}\" stroke=\"none\"/>"
    "arrow_cross" => {
      let cx = x - dx * 4
      let cy = y - dy * 4
      let a = 3.5
      let ux = (dx + nx) * a
      let uy = (dy + ny) * a
      let vx = (dx - nx) * a
      let vy = (dy - ny) * a
      "<path class=\"pele-marker\" d=\"M\{num(cx - ux)},\{num(cy - uy)}L\{num(cx + ux)},\{num(cy + uy)}M\{num(cx - vx)},\{num(cy - vy)}L\{num(cx + vx)},\{num(cy + vy)}\"/>"
    }
    _ => ""
  }
}
