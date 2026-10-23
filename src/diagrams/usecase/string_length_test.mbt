///|
#skip("slow: draws over 536 million code units before it fails")
test "use cases outgrowing V8's longest string fail as nested too deeply" {
  let fill = "a".repeat(50000)
  let items = Array::makei(10700, i => "U\{i}(\"x\"):::c").join("\n")
  let failure = try {
    @core.render(
      [@usecase.usecase],
      "usecase-beta\nclassDef c fill:#\{fill}\n\{items}\n",
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
    content="limit: Diagram is nested too deeply. usecase usecase",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a use case label drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  let icons = Array::make(5400, "fa:fa-x").join(" ")
  let failure = try {
    @core.render([@usecase.usecase], "usecase-beta\nU(\"\{icons}\")\n", {
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
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. usecase usecase",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a front matter title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@usecase.usecase],
      "---\ntitle: x\{"\"".repeat(90000000)}\n---\nusecase-beta\nU(\"x\")\n",
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
    content="limit: Diagram is nested too deeply. usecase usecase",
  )
}
