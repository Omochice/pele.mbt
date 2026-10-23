///|
/// The size a block arrow needs, and the shift of its label from the center, away from the heads.
pub(all) struct ArrowSize {
  w : Double
  h : Double
  dx : Double
  dy : Double
}

///|
/// The directions an arrow points in, as a set of bits.
pub fn arrow_mask(_directions : Array[String]) -> Int32 {
  0
}

///|
/// The axis an arrow runs along: `x`, `y`, or none for one that points along both or neither.
pub fn arrow_axis(_mask : Int32) -> String {
  ""
}

///|
/// The size of an arrow around a label of that size.
pub fn arrow_size(_mask : Int32, _tw : Double, _th : Double) -> ArrowSize {
  { w: 0, h: 0, dx: 0, dy: 0, }
}

///|
/// The outline of an arrow of that size, centered on the origin.
pub fn draw_arrow(
  _mask : Int32,
  _w : Double,
  _h : Double,
  _attrs : String,
) -> String {
  ""
}
