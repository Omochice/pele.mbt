///|
/// An edge's path, with where each of its ends is and the way a marker there points.
pub(all) struct EdgePath {
  /// The path data.
  d : String
  /// The commands of `d` as `fill_under` reads them, when whoever wrote `d` kept them.
  tokens : Array[Double]?
  sx : Double
  sy : Double
  /// The way a marker at the start points: back toward the node the edge leaves.
  sdx : Double
  sdy : Double
  ex : Double
  ey : Double
  /// The way a marker at the end points: into the node the edge arrives at.
  edx : Double
  edy : Double
}

///|
/// JavaScript's `value || 1`: 1 in place of 0, -0 and NaN.
fn or_one(value : Double) -> Double {
  if value == 0 || value.is_nan() {
    1
  } else {
    value
  }
}
