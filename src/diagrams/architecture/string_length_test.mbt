///|
#skip("slow: draws over 536 million code units before it fails")
test "services drawing host icons past V8's longest string fail as nested too deeply" {
  let icon = "<path d=\"M0,0\{"H1".repeat(25000)}\"/>"
  let services = Array::makei(10700, i => "service s\{i}(big)[x]").join("\n")
  let failure = try {
    @core.render(
      [@architecture.architecture],
      "architecture-beta\n\{services}\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        icons: Some(name => if name == "big" { Some(icon) } else { None }),
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
    content="limit: Diagram is nested too deeply. architecture architecture",
  )
}
