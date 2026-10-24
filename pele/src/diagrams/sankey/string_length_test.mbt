///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn length_outcome(source : String) -> String {
  try {
    let rendered = @core.render([@sankey.sankey], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
    })
    "\{rendered.svg.length()}"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a link color of tens of millions of entities is drawn as pele draws it" {
  inspect(
    length_outcome(
      "---\nconfig:\n  sankey:\n    linkColor: \"\{"&".repeat(54000000)}\"\n---\nsankey\n\nA,B,1\n",
    ),
    content="270001573",
  )
}
