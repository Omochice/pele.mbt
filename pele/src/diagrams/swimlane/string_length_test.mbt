///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn drawn_or_failed(source : String) -> String {
  try {
    let rendered = @core.render([@swimlane.swimlane], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
    })
    rendered.svg.length().to_string()
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: draws over 270 million code units")
test "a tooltip escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "swimlane-beta TB\nsubgraph L\nA\nend\nclick A callback \"\{"&".repeat(54000000)}\"\n",
    ),
    content="270001339",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "a link escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "swimlane-beta TB\nsubgraph L\nA\nend\nclick A href \"\{"&".repeat(54000000)}\"\n",
    ),
    content="270001354",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "a lane id escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "swimlane-beta TB\nsubgraph \"\{"&".repeat(54000000)}\" [x]\nA\nend\n",
    ),
    content="270001313",
  )
}
