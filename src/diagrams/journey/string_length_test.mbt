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
