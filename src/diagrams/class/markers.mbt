///|
/// How far the line stops short of the node so that it meets the back of the marker.
pub fn class_marker_trim(kind : String) -> Double {
  ignore(kind)
  0
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
  ignore((kind, x, y, dx, dy, color))
  ""
}
