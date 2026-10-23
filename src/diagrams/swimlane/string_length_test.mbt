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

///|
#skip("slow: draws over 536 million code units before it fails")
test "a lane title drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  let icons = Array::make(5400, "fa:fa-x").join(" ")
  let failure = try {
    @core.render(
      [@swimlane.swimlane],
      "swimlane-beta TB\nsubgraph L[\"\{icons}\"]\nA\nend\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        icons: Some(name => if name == "fa:fa-x" { Some(drawing) } else { None }),
      },
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

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a front matter title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@swimlane.swimlane],
      "---\ntitle: x\{"\"".repeat(90000000)}\n---\nswimlane-beta TB\nsubgraph L\nA\nend\n",
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
