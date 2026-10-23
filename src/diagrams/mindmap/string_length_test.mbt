///|
#skip("slow: draws over 536 million code units before it fails")
test "nodes outgrowing V8's longest string fail as nested too deeply" {
  let markup = "<path d=\"\{"M0 0".repeat(12500)}\"/>"
  let nodes = Array::makei(10700, i => "  m\{i}[fa:fa-a]").join("\n")
  let failure = try {
    @core.render([@mindmap.mindmap], "mindmap\nroot\n\{nodes}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      icons: Some(name => if name == "fa:fa-a" { Some(markup) } else { None }),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. mindmap mindmap",
  )
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@mindmap.mindmap], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a node label drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let markup = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  let spans = Array::make(5400, "fa:fa-x").join(" ")
  inspect(
    outcome_of("mindmap\nroot[\"\{spans}\"]\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      icons: Some(name => if name == "fa:fa-x" { Some(markup) } else { None }),
    }),
    content="limit: Diagram is nested too deeply. mindmap mindmap",
  )
}

///|
#skip("slow: escapes 60 million characters twice before it fails")
test "a node named by tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("mindmap\n\{"&".repeat(60000000)}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. mindmap mindmap",
  )
}
