///|
/// The finite, non-negative `x` as `(mantissa, exponent)` with `x == mantissa * 2^exponent`.
fn decompose(x : Double) -> (BigInt, Int32) {
  let bits = x.reinterpret_as_uint64()
  let biased = ((bits >> 52) & 0x7ffUL).to_int()
  let fraction = bits & 0xfffffffffffffUL
  if biased == 0 {
    (BigInt::from_uint64(fraction), -1074)
  } else {
    (BigInt::from_uint64(fraction | 0x10000000000000UL), biased - 1075)
  }
}

///|
/// `x * 10^shift` rounded to the nearest integer, a tie going to the larger one, as `toFixed` and
/// `toPrecision` round.
/// It is exact, since a binary double does not scale by a power of ten without error.
fn scaled(x : Double, shift : Int32) -> BigInt {
  let (mantissa, exponent) = decompose(x)
  let ten = BigInt::from_int(10)
  let mut numerator = mantissa
  let mut denominator = BigInt::from_int(1)
  if exponent >= 0 {
    numerator = numerator.shl(exponent)
  } else {
    denominator = denominator.shl(-exponent)
  }
  if shift >= 0 {
    numerator = numerator * ten.pow(BigInt::from_int(shift))
  } else {
    denominator = denominator * ten.pow(BigInt::from_int(-shift))
  }
  (numerator.shl(1) + denominator) / denominator.shl(1)
}

///|
/// The `count` significant digits of a positive `x` and the decimal exponent of the first, as
/// `toPrecision` and `toExponential` choose them.
fn significant(x : Double, count : Int32) -> (String, Int32) {
  if x == 0.0 {
    return ("0".repeat(count), 0)
  }
  let (mantissa, exponent) = decompose(x)
  // The estimate is at most one too low, and the loop below corrects it.
  let binary = mantissa.bit_length() + exponent - 1
  let mut e = (binary.to_double() * 0.30103).floor().to_int()
  let low = BigInt::from_int(10).pow(BigInt::from_int(count - 1))
  let high = low * BigInt::from_int(10)
  let mut n = scaled(x, count - 1 - e)
  for _ in 0..<4 {
    if n >= high {
      e += 1
    } else if n < low {
      e -= 1
    } else {
      break
    }
    n = scaled(x, count - 1 - e)
  }
  (n.to_string(), e)
}
