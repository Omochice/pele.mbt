///|
/// The outcome of rendering `source` with no source limit: the SVG's length and width, or the error.
fn outcome(source : String, max_width? : Double) -> String {
  try {
    let rendered = @core.render([@journey.journey], source, {
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
test "tasks outgrowing V8's longest string fail as nested too deeply" {
  let tasks = Array::makei(930, i => "  T\{i}\{"&".repeat(50000)}: 5: Me").join(
    "\n",
  )
  inspect(
    outcome("journey\nsection S\n\{tasks}\n"),
    content="limit: Diagram is nested too deeply. journey journey",
  )
}

///|
#skip("slow: draws over 300 million code units after 250 million")
test "people drawn down past what a StringBuilder grows to are drawn as pele draws them" {
  let people = Array::makei(10, i => "P\{i}\{"&".repeat(5000)}").join(", ")
  let tasks = Array::makei(990, i => "  T\{i}: 5: \{people}").join("\n")
  inspect(
    outcome("journey\nsection S\n\{tasks}\n", max_width=300),
    content="331194234 wide 300",
  )
}

///|
#skip("slow: draws over 400 million code units across before it draws down")
test "tasks drawn across past the hold limit are drawn down within it as pele draws them" {
  let tasks = Array::makei(846, i => "  T\{i}\{"&".repeat(50000)}: 5: Me").join(
    "\n",
  )
  inspect(
    outcome("journey\nsection S\n\{tasks}\n", max_width=300),
    content="290597950 wide 300",
  )
}

///|
#skip("slow: draws over 400 million code units across and 536 million down")
test "people drawn across past the hold limit fail drawn down as nested too deeply" {
  let people = Array::makei(10, i => "P\{i}\{"&".repeat(5000)}").join(", ")
  let tasks = Array::makei(1630, i => "  T\{i}: 5: \{people}").join("\n")
  inspect(
    outcome("journey\nsection S\n\{tasks}\n", max_width=300),
    content="limit: Diagram is nested too deeply. journey journey",
  )
}


///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@journey.journey], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "a task of tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("journey\nsection S\n  \{"&".repeat(54000000)}: 5: Me\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. journey journey",
  )
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "a section of tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("journey\nsection \{"&".repeat(54000000)}\n  T: 5: Me\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. journey journey",
  )
}

