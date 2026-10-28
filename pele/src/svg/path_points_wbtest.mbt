///|
/// The tokens of `d`, separated by spaces.
fn tokens_of(d : String) -> String {
  tokenize(d).map(n => n.to_string()).join(" ")
}

///|
test "tokenize keeps each command's code, its count of numbers and the numbers" {
  inspect(
    tokens_of("M1,2L-.5,3e1H4V-0.25C1 2 3 4 5 6Q1,2,3,4A5,5 0 0 1 9,9Z"),
    content="77 2 1 2 76 2 -0.5 30 72 1 4 86 1 -0.25 67 6 1 2 3 4 5 6 81 4 1 2 3 4 65 7 5 5 0 0 1 9 9 90 0",
  )
}

///|
test "tokenize reads numbers as pele's scanner does, not as a pattern of numbers would" {
  inspect(tokens_of("x5 M1.2.3,4"), content="77 3 1.2 0.3 4")
  let bare = tokenize("M-,.")
  inspect(bare.length(), content="4")
  inspect(1.0 / bare[2], content="-Infinity")
  inspect(1.0 / bare[3], content="Infinity")
  inspect(tokens_of("M1e,2E+1"), content="77 2 NaN 20")
  inspect(tokens_of("M1E+1,1e-1"), content="77 2 10 0.1")
  inspect(
    tokens_of("M0.12345678901234567890123,99999999999999999999"),
    content="77 2 0.12345678901234568 100000000000000000000",
  )
  inspect(tokens_of("M1,2l3,4"), content="77 4 1 2 3 4")
}

///|
test "route_path keeps the numbers of its path as tokenize reads them back" {
  let routes : Array[Array[Double]] = [
    [0, 0, 0, 100, 48, 0],
    [0.004, 0.006, 1, 48.333, -30.125, 1],
    [0, 0, 0, 0, 50.5, 0, 80.25, 50.5, 1, 80.25, 120.755, 0],
    [
      10.1, 10.2, 0, 10.1, 60.3, 0, 90.7, 60.3, 1, 90.7, 140.9, 0, 20.05, 140.9,
      1,
    ],
    [-5.555, -5.555, 1, 33.333, 77.777, 0],
  ]
  let curves : Array[String?] = [
    None,
    Some("linear"),
    Some("step"),
    Some("stepBefore"),
    Some("stepAfter"),
  ]
  for route in routes {
    for curve in curves {
      for trims in [(0.0, 0.0), (5.0, 7.25)] {
        let path = route_path(route, curve, trims.0, trims.1)
        assert_eq(path.tokens, Some(tokenize(path.d)))
      }
    }
  }
}

///|
test "enters tells a segment that crosses a box from one that passes by it" {
  let box = (0.0, 0.0, 10.0, 10.0)
  let cases : Array[Array[Double]] = [
    [-5, 5, 15, 5],
    [-5, -5, 15, -5],
    [-5, 15, 15, -5],
    [-5, 5, -1, 5],
    [5, 5, 5, 5],
    [10, 10, 20, 20],
    [@double.not_a_number, @double.not_a_number, 5, 5],
  ]
  debug_inspect(
    cases.map(points => enters(points, box.0, box.1, box.2, box.3)),
    content="[true, false, true, false, true, false, false]",
  )
}
