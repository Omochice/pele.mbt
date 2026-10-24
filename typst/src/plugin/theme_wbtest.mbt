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

///|
/// A class diagram whose edges run through the title of a namespace nested three deep, when it is at most 400 wide.
const STRUCK_NAMESPACE : String =
  #|classDiagram
  #|  namespace Company.Engineering.Backend {
  #|    class Developer
  #|  }
  #|  namespace Company.Engineering.Frontend {
  #|    class Designer
  #|  }
  #|  namespace Company.Engineering {
  #|    class TechLead
  #|  }
  #|  TechLead --> Developer : leads
  #|  TechLead --> Designer : leads

///|
/// The strokes, separated by spaces, of the halos behind the struck cluster titles of `STRUCK_NAMESPACE` under `theme`, or of pele's own SVG when `theme` is `None`.
fn halo_strokes(theme : String?) -> String {
  let options = match theme {
    Some(theme) => "{\"maxWidth\":400,\"theme\":\{theme}}"
    None => "{\"maxWidth\":400}"
  }
  let (status, body) = respond(STRUCK_NAMESPACE, options)
  guard status == 0 &&
    body is Object(fields) &&
    fields.get("svg") is Some(String(svg)) else {
    abort("render failed: \{body.stringify()}")
  }
  let strokes = []
  for part in svg.split("<text fill=\"none\" stroke=\"").drop(1) {
    let part = part.to_owned()
    strokes.push(part.view(end_offset=part.find("\"").unwrap()).to_owned())
  }
  strokes.join(" ")
}

///|
test "a theme mixes the halo of a struck cluster title into a color typst draws" {
  inspect(
    halo_strokes(None),
    content=(
      #|color-mix(in srgb,var(--_a) 87.5%,var(--_bg)) color-mix(in srgb,var(--_a) 87.5%,var(--_bg))
    ),
  )
  inspect(
    halo_strokes(Some("{}")),
    content=(
      #|#e9e9e9 #e9e9e9
    ),
  )
  inspect(
    halo_strokes(Some("{\"surface-alt\":\"#45475a\",\"bg\":\"#1e1e2e\"}")),
    content=(
      #|#404255 #404255
    ),
  )
}
