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
