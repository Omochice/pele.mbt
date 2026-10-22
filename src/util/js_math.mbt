///|
/// `Math.max` of two numbers: NaN if either is, and +0 over -0.
pub fn js_max(a : Double, b : Double) -> Double {
  if a.is_nan() || b.is_nan() {
    @double.not_a_number
  } else if a > b {
    a
  } else if b > a {
    b
  } else if a == 0.0 && 1.0 / a < 0.0 {
    b
  } else {
    a
  }
}

///|
/// `Math.min` of two numbers: NaN if either is, and -0 over +0.
pub fn js_min(a : Double, b : Double) -> Double {
  if a.is_nan() || b.is_nan() {
    @double.not_a_number
  } else if a < b {
    a
  } else if b < a {
    b
  } else if a == 0.0 && 1.0 / a > 0.0 {
    b
  } else {
    a
  }
}
