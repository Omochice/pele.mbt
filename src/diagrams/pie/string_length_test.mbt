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

///|
#skip("slow: draws over 300 million code units")
test "an accessible description longer than a doubling StringBuilder holds is drawn" {
  let descr = "&".repeat(60000000)
  let svg = @core.render([@pie.pie], "pie\naccDescr: \{descr}\n\"a\":1\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }).svg
  inspect(svg.length(), content="300001356")
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "an accessible description outgrowing V8's longest string fails as nested too deeply" {
  let descr = "&".repeat(110000000)
  let failure = try {
    @core.render([@pie.pie], "pie\naccDescr: \{descr}\n\"a\":1\n", {
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

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@pie.pie], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 54 million characters several times before it fails")
test "an entry named by tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("pie\n\"\{"&".repeat(54000000)}\": 1\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. pie pie",
  )
}
