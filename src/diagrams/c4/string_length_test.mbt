///|
#skip("slow: draws over 536 million code units before it fails")
test "people with many icon spans past V8's longest string fail as nested too deeply" {
  let label = "fa:fa-a ".repeat(1000)
  let people = Array::makei(2100, i => "Person(p\{i}, \"\{label}\")").join("\n")
  let failure = try {
    @core.render([@c4.c4], "C4Context\n\{people}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      icons: Some(name => {
        if name == "fa:fa-a" {
          Some("<path d=\"M4,4H20\"/>")
        } else {
          None
        }
      }),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. c4 c4")
}
