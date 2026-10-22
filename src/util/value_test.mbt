///|
test "strings convert to numbers as Number() reads them" {
  let inputs = [
    " 12 ", "1e3", "0x1F", "0X1f", ".5", "5.", "+5", "-5", "-0x5", "Infinity", "-Infinity",
    "+Infinity", "infinity", "1_000", "", "  ", "12px", "0b101", "0o17", "1e1000",
    "00012", "-.5e-1", "1.5E+2", ".", "e5", "1e", "0x", "\u{a0}12\u{2028}", "0.1",
    "123456789012345678901234567890",
  ]
  inspect(
    inputs.map(s => @util.js_number(Json::string(s)).to_string()).join(" "),
    content="12 1000 31 31 0.5 5 5 -5 NaN Infinity -Infinity Infinity NaN NaN 0 0 NaN 5 15 Infinity 12 -0.05 150 NaN NaN NaN NaN 12 0.1 1.2345678901234568e+29",
  )
}

///|
test "minus zero keeps its sign" {
  inspect(1.0 / @util.js_number(Json::string("-0")) < 0.0, content="true")
}

///|
test "other values convert to numbers as Number() reads them" {
  let values : Array[Json] = [[1, 2], [5], [], {}, true, false, null, "x"]
  inspect(
    values.map(v => @util.js_number(v).to_string()).join(" "),
    content="NaN 5 0 NaN 1 0 0 NaN",
  )
}
