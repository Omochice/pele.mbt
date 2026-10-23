///|
#skip("slow: draws over 536 million code units before it fails")
test "sections drawing host icons past V8's longest string fail as nested too deeply" {
  let icon = "<path d=\"M0,0\{"H1".repeat(25000)}\"/>"
  let sections = Array::makei(10700, i => {
    "section fa:fa-big s\{i}\nts\{i} :2026-01-01, 1d"
  }).join("\n")
  let failure = try {
    @core.render(
      [@gantt.gantt],
      "gantt\ndateFormat YYYY-MM-DD\n\{sections}\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        icons: Some(name => if name == "fa:fa-big" { Some(icon) } else { None }),
      },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. gantt gantt")
}
