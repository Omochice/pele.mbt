///|
/// One step of the mulberry32 generator, as a number in `[0, 1)`.
pub fn seeded_random(seed : Double) -> Double {
  abort("not implemented")
}

///|
/// Mermaid's string hash, a 32-bit integer.
pub fn hash_string(text : String) -> Int32 {
  abort("not implemented")
}

///|
/// A configured seed other than zero wins; otherwise the seed comes from the diagram's id.
pub fn resolve_seed(configured : Double?, id : String) -> Double {
  abort("not implemented")
}

///|
/// How a wavy line is drawn along one axis.
pub(all) struct WaveOptions {
  segments : Int32
  vertical : Bool
  /// Multipliers Mermaid uses to vary the seed per point and per control point.
  point_step : Int32
  control_step : Int32
  control_shift : Int32
  pin_start : Bool
  pin_end : Bool
}

///|
pub let fold : WaveOptions = {
  segments: 7,
  vertical: true,
  point_step: 17,
  control_step: 31,
  control_shift: 7,
  pin_start: false,
  pin_end: false,
}

///|
pub let horizon : WaveOptions = {
  segments: 7,
  vertical: false,
  point_step: 23,
  control_step: 37,
  control_shift: 11,
  pin_start: false,
  pin_end: false,
}

///|
/// A wavy line along one axis from `from` to `to`, centered on `center` in the other axis.
/// Curves are flat lists of numbers: a start point, then six numbers per cubic segment.
pub fn wave(
  from : Double,
  to : Double,
  center : Double,
  seed : Double,
  amplitude : Double,
  options : WaveOptions,
) -> Array[Double] {
  abort("not implemented")
}

///|
/// The cliff: a steep S from `(cx, top)` down to `(cx, bottom)`.
pub fn cliff(
  cx : Double,
  top : Double,
  bottom : Double,
  amplitude : Double,
) -> Array[Double] {
  abort("not implemented")
}

///|
/// Path commands that continue from the curve's start point to its end.
pub fn forward(curve : Array[Double]) -> String {
  abort("not implemented")
}

///|
/// Path commands that continue from the curve's end point back to its start.
pub fn backward(curve : Array[Double]) -> String {
  abort("not implemented")
}

///|
pub fn curve_path(curve : Array[Double]) -> String {
  abort("not implemented")
}

///|
pub fn ellipse_path(
  cx : Double,
  cy : Double,
  rx : Double,
  ry : Double,
) -> String {
  abort("not implemented")
}
