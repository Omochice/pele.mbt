///|
#skip("slow: draws over 536 million code units before it fails")
test "events outgrowing V8's longest string fail as nested too deeply" {
  let periods = Array::makei(1650, i => "  \{i} : E\{"&".repeat(50000)}").join(
    "\n",
  )
  let failure = try {
    @core.render([@timeline.timeline], "timeline\n\{periods}\n", {
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
    content="limit: Diagram is nested too deeply. timeline timeline",
  )
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@timeline.timeline], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "a period of tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("timeline\n  \{"&".repeat(54000000)} : e\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. timeline timeline",
  )
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "a section of tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("timeline\nsection \{"&".repeat(54000000)}\n  p : e\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. timeline timeline",
  )
}

///|
#skip("slow: draws over 350 million code units")
test "a front matter title wrapped past what a StringBuilder grows to is drawn as pele draws it" {
  let title = "<".repeat(70000000)
  let rendered = @core.render(
    [@timeline.timeline],
    "---\ntitle: \{title}\n---\ntimeline\n  p : e\n",
    {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
    },
  )
  inspect(
    "\{rendered.svg.length()} wide \{rendered.width}",
    content="357774107 wide 334",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  inspect(
    outcome_of("timeline\ntitle \{"\"".repeat(90000000)}\n  p : e\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. timeline timeline",
  )
}
