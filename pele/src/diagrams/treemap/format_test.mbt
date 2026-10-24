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

///|
test "writes a fixed number of decimals for the f type" {
  inspect(format(".1f", 0.0), content="0.0")
  inspect(format(".1f", 12.0), content="12.0")
  inspect(format(".1f", 12.6), content="12.6")
  inspect(format(".1f", 0.357), content="0.4")
  inspect(format(".1f", 1234567.5), content="1234567.5")
  inspect(format(".1f", 1.005), content="1.0")
  inspect(format(".1f", 1.5e-7), content="0.0")
  inspect(format(".1f", 1.0e21), content="1e+21")
  inspect(format(".1f", @double.not_a_number), content="NaN")
  inspect(format("$.2f", 5.0), content="$5.00")
  inspect(format("$.2f", 0.357), content="$0.36")
  inspect(format("$.2f", 12.6), content="$12.60")
  inspect(format("$,.2f", 1234.5), content="$1,234.50")
  inspect(format("$,.2f", 1234567890123.456), content="$1,234,567,890,123.46")
  inspect(format("f", 1.5), content="1.500000")
  inspect(format(".0f", 12.6), content="13")
  inspect(format(".0f", 2.5), content="3")
  inspect(format(".0f", 0.5), content="1")
}

///|
test "writes a percentage for the % type" {
  inspect(format(".1%", 0.357), content="35.7%")
  inspect(format(".1%", 0.35), content="35.0%")
  inspect(format(".1%", 12.0), content="1200.0%")
  inspect(format(".1%", 1.0e21), content="1e+23%")
  inspect(format(".1%", 0.30000000000000004), content="30.0%")
  inspect(format("$.1%", 0.25), content="$25.0%")
  inspect(format("%", 0.357), content="35.700000%")
}

///|
test "rounds to an integer for the d type" {
  inspect(format("d", 12.6), content="13")
  inspect(format("d", 2.5), content="3")
  inspect(format("d", 0.5), content="1")
  inspect(format("d", 1234567.5), content="1234568")
  inspect(format("d", 123456789012345680000.0), content="123456789012345683968")
  inspect(format("d", -1234.5), content="-1235")
}

///|
test "writes an exponent for the e type" {
  inspect(format(".2e", 0.0), content="0.00e+0")
  inspect(format(".2e", 12.6), content="1.26e+1")
  inspect(format(".2e", 0.000123456), content="1.23e-4")
  inspect(format(".2e", 1234567.5), content="1.23e+6")
  inspect(format(".2e", 1.0e21), content="1.00e+21")
  inspect(format("e", 1234.5), content="1.234500e+3")
}

///|
test "drops insignificant zeros with a tilde" {
  inspect(format(".3~f", 1.5), content="1.5")
  inspect(format(".3~f", 1234.0), content="1234")
  inspect(format(".3~f", 12.3456), content="12.346")
  inspect(format(".3~f", 1.5e-7), content="0")
  inspect(format(".3~f", 0.0), content="0")
  inspect(format(".2~f", 100.0), content="100")
  inspect(format(".2~f", 100.5), content="100.5")
  inspect(format(".2~f", 0.001), content="0")
}

///|
test "limits the precision to twenty digits" {
  inspect(format(".999f", 1.0), content="1.00000000000000000000")
  inspect(format(".999f", 1.005), content="1.00499999999999989342")
}

///|
test "ignores a fill, an alignment and a width" {
  inspect(format(">10,.2f", 1234.5), content="1,234.50")
}
