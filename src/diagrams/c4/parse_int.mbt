///|
/// What JavaScript's `parseInt(text)` returns: leading whitespace and a sign skipped, `0x` read as hexadecimal, NaN without digits.
/// Values here only feed counts and clamped offsets, so digits past 2^53 are summed without pele's exact rounding.
fn parse_int(text : String) -> Double {
  let n = text.length()
  let mut p = 0
  while p < n && @util.is_space(@util.code_at(text, p)) {
    p += 1
  }
  let mut sign = 1.0
  let c = @util.code_at(text, p)
  if c == 45 || c == 43 {
    if c == 45 {
      sign = -1.0
    }
    p += 1
  }
  let mut radix = 10
  if @util.code_at(text, p) == 48 &&
    (@util.code_at(text, p + 1) == 120 || @util.code_at(text, p + 1) == 88) {
    radix = 16
    p += 2
  }
  let mut value = 0.0
  let mut digits = 0
  while p < n {
    let d = @util.code_at(text, p)
    let digit = if d >= 48 && d <= 57 {
      d - 48
    } else if radix == 16 && d >= 97 && d <= 102 {
      d - 87
    } else if radix == 16 && d >= 65 && d <= 70 {
      d - 55
    } else {
      break
    }
    value = value * radix.to_double() + digit.to_double()
    digits += 1
    p += 1
  }
  if digits == 0 {
    @double.not_a_number
  } else {
    sign * value
  }
}
