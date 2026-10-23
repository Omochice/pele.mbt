///|
#skip("slow: draws over 536 million code units before it fails")
test "links outgrowing V8's longest string fail as nested too deeply" {
  let source = "A\{"&".repeat(50000)}"
  let links = Array::makei(1090, i => "\{source},B\{i},1").join("\n")
  let failure = try {
    @core.render([@sankey.sankey], "sankey\n\n\{links}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. sankey sankey")
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@sankey.sankey], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 54 million characters several times before it fails")
test "a node named by tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("sankey\n\nA\{"&".repeat(54000000)},B,1\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. sankey sankey",
  )
}
