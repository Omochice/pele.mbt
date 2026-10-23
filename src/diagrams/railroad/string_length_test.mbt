///|
/// The outcome of rendering `source` with no source limit, or the error it fails with.
fn outcome(source : String) -> String {
  try {
    @core.render([@railroad.railroad], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
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
test "rules outgrowing V8's longest string fail as nested too deeply" {
  let rules = Array::makei(880000, i => "r\{i} <- \"a\" ;").join("\n")
  inspect(
    outcome("railroad-peg-beta\n\{rules}\n"),
    content="limit: Diagram is nested too deeply. railroad railroadPeg",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a rule outgrowing V8's longest string fails as nested too deeply" {
  let items = Array::make(2600000, "\"a\"").join(" ")
  inspect(
    outcome("railroad-peg-beta\nr <- \{items} ;\n"),
    content="limit: Diagram is nested too deeply. railroad railroadPeg",
  )
}
