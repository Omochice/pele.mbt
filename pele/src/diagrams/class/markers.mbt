///|
const TRIANGLE : Double = 12

///|
const DIAMOND : Double = 16

///|
const HALF : Double = 6

///|
const RING : Double = 5

///|
/// How far the line stops short of the node so that it meets the back of the marker.
pub fn class_marker_trim(kind : String) -> Double {
  match kind {
    "extension" => TRIANGLE
    "composition" | "aggregation" => DIAMOND
    "lollipop" => 2 * RING
    "dependency" => @svg.marker_trim("arrow_point")
    _ => 0
  }
}

///|
/// Draws an end marker whose tip is at (x, y), pointing along (dx, dy).
pub fn class_marker(
  kind : String,
  x : Double,
  y : Double,
  dx : Double,
  dy : Double,
  color : String,
) -> String {
  let num = @svg.num
  let nx = -dy
  let ny = dx
  match kind {
    "extension" => {
      let bx = x - dx * TRIANGLE
      let by = y - dy * TRIANGLE
      "<path class=\"pele-marker\" d=\"M\{num(x)},\{num(y)}L\{num(bx + nx * HALF)},\{num(by + ny * HALF)}L\{num(bx - nx * HALF)},\{num(by - ny * HALF)}Z\" stroke-linejoin=\"round\"/>"
    }
    "composition" | "aggregation" => {
      let mx = x - dx * DIAMOND / 2
      let my = y - dy * DIAMOND / 2
      let half = HALF - 1
      let fill = if kind == "composition" { " fill=\"\{color}\"" } else { "" }
      "<path class=\"pele-marker\" d=\"M\{num(x)},\{num(y)}L\{num(mx + nx * half)},\{num(my + ny * half)}L\{num(x - dx * DIAMOND)},\{num(y - dy * DIAMOND)}L\{num(mx - nx * half)},\{num(my - ny * half)}Z\" stroke-linejoin=\"round\"\{fill}/>"
    }
    "lollipop" =>
      "<circle class=\"pele-marker\" cx=\"\{num(x - dx * RING)}\" cy=\"\{num(y - dy * RING)}\" r=\"5\"/>"
    "dependency" => @svg.marker("arrow_point", x, y, dx, dy, color)
    _ => ""
  }
}
