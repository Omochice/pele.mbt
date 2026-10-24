///|
/// The number with no decimals, as JavaScript's `toFixed(0)` writes it.
pub fn to_fixed0(value : Double) -> String {
  if value.is_nan() || value.is_inf() || value.abs() >= 1.0e21 {
    return value.to_string()
  }
  let negative = value < 0
  let magnitude = value.abs()
  let whole = magnitude.floor()
  // The fraction is exact in binary, so this compares the value itself rather than a rounded product.
  let rounded = if magnitude - whole >= 0.5 { whole + 1 } else { whole }
  (if negative { "-" } else { "" }) + rounded.to_string()
}
