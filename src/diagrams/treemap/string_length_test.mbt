///|
#skip("slow: draws over 536 million code units before it fails")
test "leaves outgrowing V8's longest string fail as nested too deeply" {
  let fill = "a".repeat(60000)
  let items = Array::makei(9000, i => "\"L\{i}\": 1:::cc").join("\n")
  let failure = try {
    @core.render(
      [@treemap.treemap],
      "treemap-beta\n\{items}\nclassDef cc fill:#\{fill};\n",
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
    content="limit: Diagram is nested too deeply. treemap treemap",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@treemap.treemap],
      "treemap-beta\ntitle \{"\"".repeat(90000000)}\n\"a\": 1\n",
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
    content="limit: Diagram is nested too deeply. treemap treemap",
  )
}
