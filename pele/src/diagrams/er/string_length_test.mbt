///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn drawn_or_failed(source : String) -> String {
  try {
    let rendered = @core.render([@er.er], source, {
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
test "an aliased entity name escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed("erDiagram\n\"\{"&".repeat(54000000)}\"[\"x\"] {\n}\n"),
    content="270000969",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "an attribute comment escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "erDiagram\nA {\n  string name \"\{"&".repeat(54000000)}\"\n}\n",
    ),
    content="270001692",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "a subgraph id escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "erDiagram\nsubgraph \"\{"&".repeat(54000000)}\"[\"x\"]\nA\nend\n",
    ),
    content="270001255",
  )
}
