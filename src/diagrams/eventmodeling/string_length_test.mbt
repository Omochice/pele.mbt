///|
/// An event model of `frames` time frames that all show one long data block.
fn shared_data(frames : Int32) -> String {
  let lines = Array::makei(frames, i => "tf \{i + 1} evt E [[D]]").join("\n")
  "eventmodeling\n\{lines}\ndata D {\n  f: '\{"&".repeat(94000)}'\n}\n"
}

///|
/// The outcome of rendering `source` with no source limit: the SVG's length and width, or the error.
fn outcome(source : String, max_width? : Double) -> String {
  try {
    let rendered = @core.render([@eventmodeling.eventmodeling], source, {
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
test "data outgrowing V8's longest string fails as nested too deeply" {
  inspect(
    outcome(shared_data(999)),
    content="limit: Diagram is nested too deeply. eventmodeling eventmodeling",
  )
}

///|
#skip("slow: draws over 300 million code units twice")
test "data drawn down past what a StringBuilder grows to is drawn as pele draws it" {
  inspect(
    outcome(shared_data(549), max_width=300),
    content="317617910 wide 300",
  )
}
