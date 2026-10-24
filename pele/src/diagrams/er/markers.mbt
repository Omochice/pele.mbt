///|
/// How far a marker reaches back along its line from the box it touches.
pub const MARKER_LENGTH : Double = 18

///|
const BAR : Double = 5

///|
const FOOT : Double = 6

///|
const FOOT_LENGTH : Double = 10

///|
const RING : Double = 3.5

///|
/// A crow's foot marker for Mermaid's lower-cased cardinality `kind`, over the end of a line that meets a box at (`x`, `y`) travelling along the unit vector (`dx`, `dy`).
pub fn er_marker(
  kind : String,
  x : Double,
  y : Double,
  dx : Double,
  dy : Double,
) -> String {
  let at = (back : Double, side : Double) => {
    @svg.num(x - dx * back - dy * side) +
    "," +
    @svg.num(y - dy * back + dx * side)
  }
  let bar = (back : Double) => "M\{at(back, -BAR)}L\{at(back, BAR)}"
  let foot = "M\{at(0, -FOOT)}L\{at(FOOT_LENGTH, 0)}L\{at(0, FOOT)}"
  let ring = (back : Double) => {
    "<circle class=\"pele-marker\" cx=\"\{@svg.num(x - dx * back)}\" cy=\"\{@svg.num(y - dy * back)}\" r=\"\{@svg.num(RING)}\" fill=\"var(--_bg)\"/>"
  }
  let path = (d : String) => "<path class=\"pele-marker\" d=\"\{d}\"/>"
  match kind {
    "only_one" => path(bar(6) + bar(10))
    "zero_or_one" => path(bar(6)) + ring(13.5)
    "one_or_more" => path(foot + bar(FOOT_LENGTH + 3.5))
    "zero_or_more" => path(foot) + ring(FOOT_LENGTH + RING + 0.5)
    "md_parent" =>
      "<path class=\"pele-marker\" d=\"M\{at(0, 0)}L\{at(6, 4)}L\{at(12, 0)}L\{at(6, -4)}Z\" fill=\"var(--_bg)\"/>"
    _ => ""
  }
}
