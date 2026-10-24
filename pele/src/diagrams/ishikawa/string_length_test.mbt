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
#skip("slow: draws over 300 million code units twice")
test "causes drawn down past what a StringBuilder grows to are drawn as pele draws them" {
  inspect(
    outcome(long_causes(545), max_width=300),
    content="324153279 wide 299",
  )
}
