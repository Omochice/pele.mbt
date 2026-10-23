///|
#skip("slow: draws over 536 million code units before it fails")
test "elements outgrowing V8's longest string fail as nested too deeply" {
  let fill = "a".repeat(50000)
  let items = Array::makei(10700, i => "element e\{i}:::c {\n}").join("\n")
  let failure = try {
    @core.render(
      [@requirement.requirement],
      "requirementDiagram\nclassDef c fill:#\{fill}\n\{items}\n",
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
    content="limit: Diagram is nested too deeply. requirement requirement",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a field drawing host math in each of thousands of spans fails as nested too deeply" {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  let maths = Array::make(5400, "$$x$$").join(" ")
  let failure = try {
    @core.render(
      [@requirement.requirement],
      "requirementDiagram\nrequirement r {\n  text: \"\{maths}\"\n}\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        math: Some((tex, size) => {
          if tex == "x" && size == 14 {
            Some({ "svg": drawing, "width": 10, "height": 10 })
          } else {
            None
          }
        }),
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
    content="limit: Diagram is nested too deeply. requirement requirement",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a front matter title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@requirement.requirement],
      "---\ntitle: x\{"\"".repeat(90000000)}\n---\nrequirementDiagram\nrequirement r {\n}\n",
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
    content="limit: Diagram is nested too deeply. requirement requirement",
  )
}
