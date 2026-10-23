///|
/// The SVG the plugin returns for `source` under `options`.
fn rendered_svg(source : String, options : String) -> String {
  let (status, body) = respond(source, options)
  guard status == 0 &&
    body is Object(fields) &&
    fields.get("svg") is Some(String(svg)) else {
    abort("render failed: \{body.stringify()}")
  }
  svg
}

///|
fn count_math(svg : String) -> Int32 {
  let mut count = 0
  let mut at = @util.index_of(svg, "class=\"pele-math\"")
  while at != -1 {
    count += 1
    at = @util.index_of(svg, "class=\"pele-math\"", from=at + 1)
  }
  count
}

///|
let x_squared : String = "{\"math\":{\"x^2\":{\"16\":{\"svg\":\"<path/>\",\"width\":20,\"height\":12}}}}"

///|
test "math the options map is typeset in a diagram that typesets math" {
  let svg = rendered_svg("graph TD\nA[\"$$x^2$$\"]", x_squared)
  inspect(
    svg.contains(
      "<svg class=\"pele-math\" x=\"-10\" y=\"-6\" width=\"20\" height=\"12\" overflow=\"visible\"><path/></svg>",
    ),
    content="true",
  )
}

///|
test "math is typeset at the size the label asks for" {
  let svg = rendered_svg(
    "graph TD\nA[\"$$x^2$$\"]", "{\"math\":{\"x^2\":{\"14\":{\"svg\":\"<path/>\",\"width\":20,\"height\":12}}}}",
  )
  inspect(count_math(svg), content="0")
}

///|
test "a math option that is not an object is ignored" {
  for options in ["{\"math\":[]}", "{\"math\":\"x\"}", "{\"math\":null}"] {
    let svg = rendered_svg("graph TD\nA[\"$$x^2$$\"]", options)
    inspect(count_math(svg), content="0")
  }
}

///|
test "a title stays text" {
  let svg = rendered_svg(
    "---\ntitle: T $$x^2$$\n---\ngraph TD\nA[\"$$x^2$$\"]", "{\"math\":{\"x^2\":{\"16\":{\"svg\":\"<path/>\",\"width\":20,\"height\":12},\"18\":{\"svg\":\"<path/>\",\"width\":20,\"height\":12}}}}",
  )
  inspect(svg.contains("T $$x^2$$<"), content="true")
  inspect(count_math(svg), content="1")
}

///|
test "a diagram that does not typeset math keeps it as text" {
  let svg = rendered_svg("mindmap\n  root((\"$$x^2$$\"))", x_squared)
  inspect(count_math(svg), content="1")
  let svg = rendered_svg(
    "journey\ntitle t\nsection $$x^2$$\n  a $$x^2$$: 5: Me", x_squared,
  )
  inspect(count_math(svg), content="0")
}
