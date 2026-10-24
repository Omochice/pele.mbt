///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn outcome(source : String) -> String {
  try {
    let rendered = @core.render([@block.block], source, {
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
test "a block named by tens of millions of entities under a short label is drawn as pele draws it" {
  inspect(
    outcome("block-beta\n\{"&".repeat(54000000)}[\"x\"]\n"),
    content="270000977",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a block colored by tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome("block-beta\nA\nstyle A color:\{"&".repeat(54000000)}\n"),
    content="270000993",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a block filled by tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome("block-beta\nA\nstyle A fill:\{"&".repeat(54000000)}\n"),
    content="270000985",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a block classed with a color of tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome(
      "block-beta\nA\nclassDef c color:\{"&".repeat(54000000)};\nclass A c\n",
    ),
    content="270000995",
  )
}
