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
/// The outcome of rendering `source` with no limit on the source or the output, or the error it fails with.
fn backtrack_outcome(source : String) -> String {
  try {
    @core.render([@pie.pie], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
test "an entry name of millions of characters is drawn" {
  inspect(
    backtrack_outcome("pie\n\"\{"a".repeat(5000000)}\": 1\n"),
    content="rendered",
  )
}

///|
test "a directive of millions of characters is read" {
  inspect(
    backtrack_outcome("%%{init: \{"!".repeat(9000000)}}%%\npie\n\"a\": 1\n"),
    content="rendered",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render([@pie.pie], "pie\ntitle \{"\"".repeat(90000000)}\n\"a\":1\n", {
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
