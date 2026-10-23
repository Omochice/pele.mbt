///|
#skip("slow: draws over 536 million code units before it fails")
test "messages outgrowing V8's longest string fail as nested too deeply" {
  let markup = "<path d=\"\{"M0 0".repeat(12500)}\"/>"
  let messages = "A->>B: fa:fa-a\n".repeat(10700)
  let failure = try {
    @core.render([@sequence.sequence], "sequenceDiagram\n\{messages}", {
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
    content="limit: Diagram is nested too deeply. sequence sequence",
  )
}

///|
#skip("slow: draws over 280 million code units")
test "a front matter title longer than a doubling StringBuilder holds is drawn whole" {
  let title = "<".repeat(70000000)
  let svg = @core.render(
      [@sequence.sequence],
      "---\ntitle: \{title}\n---\nsequenceDiagram\nA->>B: x\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        output_limit: Some(1.0 / 0.0),
      },
    ).svg
  inspect(svg.length(), content="280002520")
  let start = svg.find("&lt;").unwrap()
  inspect(
    svg[start:start + 280000000] == "&lt;".repeat(70000000),
    content="true",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  let title = "\"".repeat(90000000)
  let failure = try {
    @core.render(
      [@sequence.sequence],
      "sequenceDiagram\ntitle \{title}\nA->>B: x\n",
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
    content="limit: Diagram is nested too deeply. sequence sequence",
  )
}
