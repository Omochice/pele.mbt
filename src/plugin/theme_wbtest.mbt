///|
/// The SVG the plugin returns for a small flowchart under `options`.
fn flowchart_svg(options : String) -> String {
  let (status, body) = respond("graph TD\nA-->B", options)
  guard status == 0 &&
    body is Object(fields) &&
    fields.get("svg") is Some(String(svg)) else {
    abort("render failed: \{body.stringify()}")
  }
  svg
}

///|
test "a theme leaves no custom property for typst to miss" {
  let svg = flowchart_svg("{\"theme\":{}}")
  inspect(svg.contains("var("), content="false")
  inspect(svg.contains("--"), content="false")
  inspect(svg.contains("style=\"rx:"), content="false")
  inspect(svg.contains("fill=\"#f3f3f3\""), content="true")
  inspect(svg.contains("rx=\"4px\""), content="true")
}

///|
test "theme values replace pele's fallbacks" {
  let svg = flowchart_svg(
    "{\"theme\":{\"surface\":\"#123456\",\"radius\":\"0\"}}",
  )
  inspect(svg.contains("fill=\"#123456\""), content="true")
  inspect(svg.contains("rx=\"0\""), content="true")
}

///|
test "theme entries that are not strings are ignored" {
  let svg = flowchart_svg("{\"theme\":{\"surface\":1,\"border\":\"red\"}}")
  inspect(svg.contains("fill=\"#f3f3f3\""), content="true")
  inspect(svg.contains("stroke=\"red\""), content="true")
}

///|
test "without a theme object the SVG is pele's own" {
  let own = flowchart_svg("{}")
  inspect(own.contains("fill=\"var(--_s)\""), content="true")
  inspect(flowchart_svg("{\"theme\":\"dark\"}") == own, content="true")
}
