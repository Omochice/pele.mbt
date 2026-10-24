///|
fn same(actual : Double, expected : Double) -> Bool {
  if expected.is_nan() {
    actual.is_nan()
  } else {
    actual == expected && 1.0 / actual == 1.0 / expected
  }
}

///|
test "parseFloat reads the longest decimal prefix" {
  assert_true(same(@util.parse_float("1.5abc"), 1.5))
  assert_true(same(@util.parse_float("  -.5e3x"), -500.0))
  assert_true(same(@util.parse_float("1e"), 1.0))
  assert_true(same(@util.parse_float("1e+"), 1.0))
  assert_true(same(@util.parse_float("1.2.3"), 1.2))
  assert_true(same(@util.parse_float("5."), 5.0))
  assert_true(same(@util.parse_float("+7"), 7.0))
  assert_true(same(@util.parse_float("1_0"), 1.0))
  assert_true(same(@util.parse_float("0x10"), 0.0))
}

///|
test "parseFloat gives NaN without a number and handles the extremes" {
  assert_true(same(@util.parse_float("abc"), @double.not_a_number))
  assert_true(same(@util.parse_float(""), @double.not_a_number))
  assert_true(same(@util.parse_float("."), @double.not_a_number))
  assert_true(same(@util.parse_float("Infinityx"), @double.infinity))
  assert_true(same(@util.parse_float("-Infinity"), @double.neg_infinity))
  assert_true(same(@util.parse_float("1e999"), @double.infinity))
  assert_true(same(@util.parse_float("-0"), -0.0))
}

///|
test "Number accepts only a whole numeric string" {
  assert_true(same(@util.to_number(""), 0.0))
  assert_true(same(@util.to_number("  12 "), 12.0))
  assert_true(same(@util.to_number("1e3"), 1000.0))
  assert_true(same(@util.to_number(".5"), 0.5))
  assert_true(same(@util.to_number("5."), 5.0))
  assert_true(same(@util.to_number("+5"), 5.0))
  assert_true(same(@util.to_number("-Infinity"), @double.neg_infinity))
  assert_true(same(@util.to_number("1 2"), @double.not_a_number))
  assert_true(same(@util.to_number("1_0"), @double.not_a_number))
  assert_true(same(@util.to_number("1e"), @double.not_a_number))
  assert_true(same(@util.to_number("bold"), @double.not_a_number))
}

///|
test "Number reads prefixed integers without a sign" {
  assert_true(same(@util.to_number("0x1F"), 31.0))
  assert_true(same(@util.to_number("0o17"), 15.0))
  assert_true(same(@util.to_number("0b11"), 3.0))
  assert_true(same(@util.to_number("-0x1"), @double.not_a_number))
  assert_true(same(@util.to_number("0x"), @double.not_a_number))
}
