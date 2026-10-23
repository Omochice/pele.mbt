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
