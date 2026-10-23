///|
#skip("slow: draws over 536 million code units before it fails")
test "entities outgrowing V8's longest string fail as nested too deeply" {
  let fill = "a".repeat(50000)
  let items = Array::makei(10700, i => "E\{i}:::c {}").join("\n")
  let failure = try {
    @core.render([@er.er], "erDiagram\nclassDef c fill:#\{fill}\n\{items}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. er er")
}

///|
/// How rendering `source` fails, under options in which the host draws the icon `fa:fa-x` as a
/// path of 100 thousand code units, with no limit on the source.
fn icon_failure(source : String) -> String {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  try {
    @core.render([@er.er], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      icons: Some(name => if name == "fa:fa-x" { Some(drawing) } else { None }),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "an entity name drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let icons = Array::make(5400, "fa:fa-x").join(" ")
  inspect(
    icon_failure("erDiagram\nA[\"\{icons}\"] {\n}\n"),
    content="limit: Diagram is nested too deeply. er er",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "an attribute comment drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let icons = Array::make(5400, "fa:fa-x").join(" ")
  inspect(
    icon_failure("erDiagram\nA {\n  string name \"\{icons}\"\n}\n"),
    content="limit: Diagram is nested too deeply. er er",
  )
}
