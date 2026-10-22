///|
/// `Math.hypot(x, y)` as V8 computes it: the larger magnitude is factored out and the squares are
/// added with Kahan's compensation, so the last bit differs from `sqrt(x * x + y * y)` often
/// enough to move a coordinate in the output.
fn hypot(x : Double, y : Double) -> Double {
  let a = if x.is_nan() { 0.0 } else { x.abs() }
  let b = if y.is_nan() { 0.0 } else { y.abs() }
  let max = if a >= b { a } else { b }
  if max.is_inf() {
    return @double.infinity
  }
  if x.is_nan() || y.is_nan() {
    return @double.not_a_number
  }
  if max == 0 {
    return 0
  }
  let mut sum = 0.0
  let mut compensation = 0.0
  for value in [a, b] {
    let n = value / max
    let summand = n * n - compensation
    let preliminary = sum + summand
    compensation = preliminary - sum - summand
    sum = preliminary
  }
  sum.sqrt() * max
}
