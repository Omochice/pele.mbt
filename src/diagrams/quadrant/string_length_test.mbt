///|
#skip("slow: draws over 536 million code units before it fails")
test "points outgrowing V8's longest string fail as nested too deeply" {
  let points = Array::makei(1100, i => "P\{i}\{"&".repeat(50000)}: [0.5, 0.5]").join(
    "\n",
  )
  let failure = try {
    @core.render([@quadrant.quadrant], "quadrantChart\n\{points}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. quadrantChart quadrantChart",
  )
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@quadrant.quadrant], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "a point named by tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("quadrantChart\n\{"&".repeat(54000000)}: [0.5, 0.5]\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. quadrantChart quadrantChart",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@quadrant.quadrant],
      "quadrantChart\ntitle \{"\"".repeat(90000000)}\nP: [0.5, 0.5]\n",
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
    content="limit: Diagram is nested too deeply. quadrantChart quadrantChart",
  )
}

///|
#skip("slow: lexes 110 million tokens before it fails")
test "a point color followed by 110 million - fails on the color alone" {
  inspect(
    outcome_of(
      "quadrantChart\nP: [0.5, 0.5] color: x:\{"-".repeat(110000000)}\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    ),
    content="semantic: value for color x is invalid, please use a valid hex code quadrantChart quadrantChart",
  )
}
