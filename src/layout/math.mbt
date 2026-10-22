///|
/// `Math.hypot` of two numbers as V8 computes it.
/// V8 scales by the larger magnitude and sums the squares with Kahan compensation, which differs from `sqrt(x * x + y * y)` in the last bit for about a third of inputs, and the layout compares the result against thresholds.
fn hypot(x : Double, y : Double) -> Double {
  let ax = x.abs()
  let ay = y.abs()
  if ax.is_inf() || ay.is_inf() {
    return @double.infinity
  }
  if ax.is_nan() || ay.is_nan() {
    return @double.not_a_number
  }
  let max = if ay > ax { ay } else { ax }
  if max == 0.0 {
    return 0.0
  }
  let mut sum = 0.0
  let mut compensation = 0.0
  for value in [ax, ay] {
    let n = value / max
    let summand = n * n - compensation
    let preliminary = sum + summand
    compensation = preliminary - sum - summand
    sum = preliminary
  }
  sum.sqrt() * max
}
