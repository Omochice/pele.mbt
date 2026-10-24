///|
/// A fishbone of `count` causes, each with a long name.
fn long_causes(count : Int32) -> String {
  let causes = Array::makei(count, i => "C\{i}\{"&".repeat(50000)}").join("\n")
  "ishikawa-beta\nProblem\n\{causes}\n"
}

///|
/// The outcome of rendering `source` with no source limit: the SVG's length and width, or the error.
fn outcome(source : String, max_width? : Double) -> String {
  try {
    let rendered = @core.render([@ishikawa.ishikawa], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
      max_width,
    })
    "\{rendered.svg.length()} wide \{rendered.width}"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "causes outgrowing V8's longest string fail as nested too deeply" {
  inspect(
    outcome(long_causes(1090)),
    content="limit: Diagram is nested too deeply. ishikawa ishikawa",
  )
}

///|
#skip("slow: draws over 300 million code units twice")
test "causes drawn down past what a StringBuilder grows to are drawn as pele draws them" {
  inspect(
    outcome(long_causes(545), max_width=300),
    content="324153279 wide 299",
  )
}

///|
#skip("slow: draws over 400 million code units across and 536 million down")
test "causes drawn across past the hold limit fail drawn down as nested too deeply" {
  inspect(
    outcome(long_causes(915), max_width=300),
    content="limit: Diagram is nested too deeply. ishikawa ishikawa",
  )
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@ishikawa.ishikawa], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "a cause of over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome_of("ishikawa-beta\nProblem\n  C\n    \{"&".repeat(110000000)}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. ishikawa ishikawa",
  )
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "a category of tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("ishikawa-beta\nProblem\n  \{"&".repeat(54000000)}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. ishikawa ishikawa",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a front matter title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@ishikawa.ishikawa],
      "---\ntitle: x\{"\"".repeat(90000000)}\n---\nishikawa-beta\nProblem\n  C\n",
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
    content="limit: Diagram is nested too deeply. ishikawa ishikawa",
  )
}
