///|
test "toFixed(0) rounds exact halves away from zero" {
  inspect(@util.to_fixed0(0.5), content="1")
  inspect(@util.to_fixed0(1.5), content="2")
  inspect(@util.to_fixed0(2.5), content="3")
  inspect(@util.to_fixed0(99.5), content="100")
  inspect(@util.to_fixed0(-0.5), content="-1")
  inspect(@util.to_fixed0(-1.5), content="-2")
  inspect(@util.to_fixed0(4503599627370495.5), content="4503599627370496")
}

///|
test "toFixed(0) rounds the exact binary value of a near-half" {
  inspect(@util.to_fixed0(0.49999999999999994), content="0")
  inspect(@util.to_fixed0(1.4999999999999998), content="1")
}

///|
test "toFixed(0) of pie percentages" {
  inspect(@util.to_fixed0(42.96 / 108.03 * 100), content="40")
  inspect(@util.to_fixed0(79.42386831275721), content="79")
  inspect(@util.to_fixed0(3.0864197530864197), content="3")
  inspect(@util.to_fixed0(123.456), content="123")
}

///|
test "toFixed(0) keeps the sign of a negative that rounds to zero" {
  inspect(@util.to_fixed0(0), content="0")
  inspect(@util.to_fixed0(-0.0), content="0")
  inspect(@util.to_fixed0(0.4), content="0")
  inspect(@util.to_fixed0(-0.4), content="-0")
}

///|
test "toFixed(0) writes large and non-finite values as numbers" {
  inspect(@util.to_fixed0(1.0e21), content="1e+21")
  inspect(@util.to_fixed0(1.5e21), content="1.5e+21")
  inspect(@util.to_fixed0(@double.infinity), content="Infinity")
  inspect(@util.to_fixed0(@double.not_a_number), content="NaN")
}
