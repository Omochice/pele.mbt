///|
#skip("slow: draws over 536 million code units before it fails")
test "graticule rings outgrowing V8's longest string fail as nested too deeply" {
  let axes = Array::makei(1050000, i => "a\{i}").join(", ")
  let failure = try {
    @core.render(
      [@radar.radar],
      "radar-beta\ngraticule polygon\nticks 32\naxis \{axes}\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. radar radar")
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@radar.radar], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "an axis labelled by over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome_of("radar-beta\naxis a[\"\{"&".repeat(110000000)}\"]\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. radar radar",
  )
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "a curve labelled by over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome_of(
      "radar-beta\naxis a\ncurve c[\"\{"&".repeat(110000000)}\"]{1}\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    ),
    content="limit: Diagram is nested too deeply. radar radar",
  )
}

///|
/// The outcome of rendering `source` with no limit on the source or the output, or the error it fails with.
fn backtrack_outcome(source : String) -> String {
  try {
    @core.render([@radar.radar], source, {
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
#skip("slow: draws an axis label of four million characters")
test "an axis label fails as nested too deeply where pele's pattern runs out of V8's backtracking stack" {
  inspect(
    backtrack_outcome("radar-beta\naxis a[\"\{"a".repeat(4194294)}\"]\n"),
    content="rendered",
  )
  inspect(
    backtrack_outcome("radar-beta\naxis a[\"\{"a".repeat(4194295)}\"]\n"),
    content="limit: Diagram is nested too deeply. radar radar",
  )
}


///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@radar.radar],
      "radar-beta\ntitle \{"\"".repeat(90000000)}\naxis a\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. radar radar")
}

