///|
#skip("slow: draws over 536 million code units before it fails")
test "commit ids outgrowing V8's longest string fail as nested too deeply" {
  let entities = "&".repeat(540000)
  let commits = Array::makei(100, i => "commit id: \"c\{i}\{entities}\"").join(
    "\n",
  )
  let failure = try {
    @core.render([@git.git], "gitGraph\n\{commits}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. gitGraph gitGraph",
  )
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@git.git], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "a commit id of tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("gitGraph\ncommit id: \"\{"&".repeat(54000000)}\"\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. gitGraph gitGraph",
  )
}
