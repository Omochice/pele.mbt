///|
fn format(spec : String, value : Double) -> String {
  @treemap.formatter(spec)(value)
}

///|
test "writes a number with up to twelve significant digits" {
  inspect(format("", 0.0), content="0")
  inspect(format("", 1234.0), content="1234")
  inspect(format("", 0.35), content="0.35")
  inspect(format("", 0.30000000000000004), content="0.3")
  inspect(format("", 1234567890123.456), content="1234567890120")
  inspect(format("", 1.5e-7), content="1.5e-7")
  inspect(format("", 999999999999.5), content="1000000000000")
  inspect(format("", 123456789012345680000.0), content="123456789012000000000")
  inspect(format("", 1.0e21), content="1e+21")
  inspect(format("", -1234.5), content="-1234.5")
  inspect(format("", @double.not_a_number), content="NaN")
  inspect(format("", @double.infinity), content="Infinity")
}

///|
test "groups thousands with a comma" {
  inspect(format(",", 0.0), content="0")
  inspect(format(",", 999.0), content="999")
  inspect(format(",", 1234.0), content="1,234")
  inspect(format(",", 1234567.5), content="1,234,567.5")
  inspect(format(",", -1234.5), content="-1,234.5")
  inspect(format(",", 0.000123456), content="0.000123456")
  inspect(
    format(",", 123456789012345680000.0),
    content="123,456,789,012,000,000,000",
  )
  inspect(format(",", 1.0e21), content="1e+21")
}

///|
test "puts a dollar sign before the number" {
  inspect(format("$", 0.0), content="$0")
  inspect(format("$", 1234.0), content="$1234")
  inspect(format("$", 1234567.5), content="$1234567.5")
  inspect(format("$", -1234.5), content="-$1234.5")
  inspect(format("$,", 1234567.0), content="$1,234,567")
}

///|
test "reads the documented dollar format with thousands separators" {
  inspect(format("$0,0", 700000.0), content="$700,000")
  inspect(format("$0,0", 900000.0), content="$900,000")
  inspect(format("$0,0", 12.0), content="$12")
  inspect(format("$0,0", 1234567.5), content="$1,234,567.5")
}

///|
test "writes a plus sign for non-negative numbers" {
  inspect(format("+,", 1000.0), content="+1,000")
  inspect(format("+,", 0.0), content="+0")
  inspect(format("+,", -1000.0), content="-1,000")
}

///|
test "reads a precision as significant digits when there is no type" {
  inspect(format(".3", 1234.0), content="1230")
  inspect(format(".3", 0.000123456), content="0.000123")
  inspect(format(".3", 1.0), content="1")
  inspect(format(".0", 12.0), content="10")
  inspect(format(".0", 0.5), content="0.5")
  inspect(format(".0", 2.5), content="3")
  inspect(format("~", 1234.5), content="1234.5")
}

///|
test "falls back to thousands separators for a specifier it does not know" {
  inspect(format("not a format", 1234.0), content="1,234")
  inspect(format("not a format", 1234567.5), content="1,234,567.5")
  inspect(format("(,", 1234567.0), content="1,234,567")
}
