///|
/// How far a marker reaches back along its line from the box it touches.
pub const MARKER_LENGTH : Double = 18

///|
/// A crow's foot marker for Mermaid's lower-cased cardinality `kind`, over the end of a line that meets a box at (`x`, `y`) travelling along the unit vector (`dx`, `dy`).
pub fn er_marker(
  kind : String,
  x : Double,
  y : Double,
  dx : Double,
  dy : Double,
) -> String {
  ignore((kind, x, y, dx, dy))
  ""
}
