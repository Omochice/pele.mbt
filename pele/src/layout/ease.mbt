///|
/// How far along the flow the handles of a plain S reach, as a share of the way it travels along it.
/// Half gives an even S.
/// One that runs more than eight times as far across as along turns sooner and crosses in a straighter line, down to a quarter at sixteen times.
/// The layout uses this to tell how near two curves will pass, and the drawing to draw them.
pub fn ease(across : Double, along : Double) -> Double {
  let reach = across.abs()
  let reach = if reach == 0.0 || reach.is_nan() { 1.0 } else { reach }
  @util.js_max(0.25, @util.js_min(0.5, 4.0 * along.abs() / reach))
}
