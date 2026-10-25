// The expected widths were taken from textMeasurer in scripts/plugin-options.mjs, the reference for the measurer option.

///|
/// The width the measurer `spec`, written as JSON, gives `text`.
fn measure(
  spec : String,
  text : String,
  size : Double,
  style : Int32,
) -> Double raise {
  let options = decode_options(@util.parse_json("{\"measurer\":\{spec}}"))
  guard options.measurer is Some(measurer) else {
    fail("the measurer \{spec} was not installed")
  }
  measurer.width(text, size, style)
}

///|
let readme_spec = "{\"unitsPerEm\":2048,\"styles\":{\"0\":{\"advances\":{\"a\":1100,\" \":600},\"default\":1200,\"wide\":2048},\"1\":{\"advances\":{\"a\":1200},\"default\":1300}}}"

///|
test "advances are summed per code unit and scaled by the units per em" {
  inspect(measure(readme_spec, "a a", 16, 0), content="21.875")
  inspect(measure(readme_spec, "\u{e9}", 16, 0), content="9.375")
  inspect(measure(readme_spec, "\u{e9}", 13.5, 0), content="7.91015625")
}

///|
test "a style uses its own table, and one without a table uses style 0" {
  inspect(measure(readme_spec, "ab", 16, 1), content="19.53125")
  inspect(measure(readme_spec, "a", 16, 5), content="8.59375")
}

///|
test "wide code units take the wide advance, which defaults to the default" {
  inspect(measure(readme_spec, "日", 16, 0), content="16")
  inspect(measure(readme_spec, "日", 16, 1), content="10.15625")
  inspect(
    measure(
      "{\"styles\":{\"0\":{\"default\":600,\"wide\":null}}}", "a日", 10, 0,
    ),
    content="12",
  )
  inspect(
    measure(
      "{\"styles\":{\"0\":{\"default\":\"600\",\"wide\":700}}}", "a日", 10, 0,
    ),
    content="7",
  )
}

///|
test "control characters, combining marks and low surrogates take no width" {
  inspect(measure(readme_spec, "a\tb", 16, 0), content="17.96875")
  inspect(measure(readme_spec, "e\u{301}", 16, 0), content="9.375")
  inspect(measure(readme_spec, "\u{1f600}", 16, 0), content="16")
}

///|
test "an advance is looked up before the zero and double width ranges" {
  let spec = "{\"styles\":{\"0\":{\"advances\":{\"\\u0301\":500,\"ab\":9999,\"\\t\":700,\"b\":\"1\"},\"default\":100}}}"
  inspect(measure(spec, "e\u{301}ab\t", 16, 0), content="12.8")
}

///|
test "units per em that are not a positive number are 1000" {
  for units in ["0", "-5", "\"2048\""] {
    let spec = "{\"unitsPerEm\":\{units},\"styles\":{\"0\":{\"default\":500}}}"
    inspect(measure(spec, "ab", 10, 0), content="10")
  }
}

///|
test "a measurer without tables gives every text no width" {
  inspect(measure("{}", "abc", 16, 0), content="0")
  inspect(measure("{\"styles\":[{\"default\":600}]}", "a", 10, 0), content="0")
  let spec = "{\"styles\":{\"0\":[1],\"2\":{\"default\":300}}}"
  inspect(measure(spec, "ab", 10, 0), content="0")
  inspect(measure(spec, "ab", 10, 2), content="6")
}

///|
test "a measurer that is not an object is ignored" {
  for spec in ["null", "[]", "\"x\"", "1", "true"] {
    let options = decode_options(@util.parse_json("{\"measurer\":\{spec}}"))
    inspect(options.measurer is None, content="true")
  }
}

///|
/// The width and height the plugin gives a one-node flowchart under `options`.
fn flowchart_size(options : String) -> String {
  let (status, body) = respond("graph LR\nA[Hello world]", options)
  guard status == 0 &&
    body is Object(fields) &&
    fields.get("width") is Some(Number(width, ..)) &&
    fields.get("height") is Some(Number(height, ..)) else {
    abort("render failed: \{body.stringify()}")
  }
  "\{width}x\{height}"
}

///|
test "diagrams lay text out with the measurer" {
  inspect(flowchart_size("{}"), content="132x64")
  inspect(flowchart_size("{\"measurer\":{}}"), content="64x64")
  inspect(
    flowchart_size("{\"measurer\":{\"styles\":{\"0\":{\"default\":2000}}}}"),
    content=(
      #|212x82
    ),
  )
}
