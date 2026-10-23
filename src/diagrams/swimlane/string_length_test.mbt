///|
#skip("slow: draws over 536 million code units before it fails")
test "a lane outgrowing V8's longest string fails as nested too deeply" {
  let fill = "a".repeat(50000)
  let items = Array::makei(10700, i => "n\{i}:::c").join("\n")
  let failure = try {
    @core.render(
      [@swimlane.swimlane],
      "swimlane-beta TB\nclassDef c fill:#\{fill}\nsubgraph L\n\{items}\nend\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. swimlane swimlane",
  )
}
