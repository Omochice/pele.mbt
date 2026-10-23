///|
#skip("slow: draws over 536 million code units before it fails")
test "a legend outgrowing V8's longest string fails as nested too deeply" {
  let entries = Array::makei(2700000, i => "\"\{i}\":1").join("\n")
  let failure = try {
    @core.render([@pie.pie], "pie\n\{entries}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. pie pie")
}
