///|
fn tick_list(lo : Double, hi : Double, count : Double) -> Array[Double] {
  ticks_between(lo, hi, tick_step(hi - lo, count))
}

///|
fn ticks(lo : Double, hi : Double, count : Double) -> String {
  "[" + tick_list(lo, hi, count).map(tick => tick.to_string()).join(", ") + "]"
}

///|
test "ticks step by 1, 2 or 5 times a power of ten" {
  inspect(
    ticks(0, 100, 10),
    content="[0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]",
  )
  inspect(ticks(0, 100, 4), content="[0, 20, 40, 60, 80, 100]")
  inspect(
    ticks(4000, 11000, 7),
    content="[4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000]",
  )
  inspect(
    ticks(0, 198.2, 8),
    content="[0, 20, 40, 60, 80, 100, 120, 140, 160, 180]",
  )
  inspect(ticks(-6, 8, 7), content="[-6, -4, -2, 0, 2, 4, 6, 8]")
  inspect(ticks(3, 7, 2), content="[4, 6]")
}

///|
test "ticks below one are exact decimals" {
  inspect(
    ticks(0, 1, 10),
    content="[0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]",
  )
  inspect(ticks(0.3, 0.7, 4), content="[0.3, 0.4, 0.5, 0.6, 0.7]")
  inspect(ticks(-0.34, 2.4, 6), content="[0, 0.5, 1, 1.5, 2]")
  inspect(
    ticks(0, 0.0005, 5),
    content="[0, 0.0001, 0.0002, 0.0003, 0.0004, 0.0005]",
  )
}

///|
test "ticks cope with huge and tiny ranges" {
  inspect(
    ticks(0, 1.0e300, 5),
    content="[0, 2e+299, 4e+299, 6e+299, 8e+299, 1e+300]",
  )
  assert_true(tick_list(0, 1.0e-12, 2).length() > 1)
  assert_true(tick_list(1.0e15, 1.0e15 + 10, 5).length() > 1)
  inspect(tick_value(tick_step(1, 10), 3).to_string(), content="0.3")
}
