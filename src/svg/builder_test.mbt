///|
test "num rounds to hundredths and drops trailing zeros" {
  inspect(@svg.num(1.5), content="1.5")
  inspect(@svg.num(1.25), content="1.25")
  inspect(@svg.num(1.1), content="1.1")
  inspect(@svg.num(100), content="100")
  inspect(@svg.num(71.9345), content="71.93")
  inspect(@svg.num(25.6), content="25.6")
  inspect(@svg.num(404.6250000001), content="404.63")
  inspect(@svg.num(0.1 + 0.2), content="0.3")
}

///|
test "num rounds the scaled value half up like Math.round" {
  inspect(@svg.num(0.005), content="0.01")
  inspect(@svg.num(2.675), content="2.68")
  inspect(@svg.num(1.005), content="1")
  inspect(@svg.num(0.49999999999999994), content="0.5")
}

///|
test "num writes negatives with a sign" {
  inspect(@svg.num(-71.9345), content="-71.93")
  inspect(@svg.num(-77.1), content="-77.1")
  inspect(@svg.num(-0.015), content="-0.01")
}

///|
test "num writes zero and values that round to zero as 0" {
  inspect(@svg.num(0), content="0")
  inspect(@svg.num(-0.0), content="0")
  inspect(@svg.num(0.004), content="0")
  inspect(@svg.num(-0.004), content="0")
  inspect(@svg.num(-0.005), content="0")
}

///|
test "num falls back to number formatting from 1e9" {
  inspect(@svg.num(999999999.99), content="999999999.99")
  inspect(@svg.num(1.0e9), content="1000000000")
  inspect(@svg.num(-1.0e9), content="-1000000000")
  inspect(@svg.num(1234567890.123), content="1234567890.12")
  inspect(@svg.num(-1234567890.123), content="-1234567890.12")
  inspect(@svg.num(2.0e20), content="200000000000000000000")
  inspect(@svg.num(@double.infinity), content="Infinity")
  inspect(@svg.num(@double.neg_infinity), content="-Infinity")
  inspect(@svg.num(@double.not_a_number), content="NaN")
}
