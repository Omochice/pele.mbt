///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn length_outcome(source : String) -> String {
  try {
    let rendered = @core.render([@venn.venn], source, {
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
test "a text named by tens of millions of entities under a short label is drawn as pele draws it" {
  inspect(
    length_outcome(
      "venn-beta\nset A\n  text \"\{"&".repeat(54000000)}\"[\"x\"]\n",
    ),
    content="270001133",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a set filled by tens of millions of entities is drawn as pele draws it" {
  inspect(
    length_outcome(
      "venn-beta\nset A\nstyle A fill: \"\{"&".repeat(54000000)}\"\n",
    ),
    content="270001028",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a set colored by tens of millions of entities is drawn as pele draws it" {
  inspect(
    length_outcome(
      "venn-beta\nset A\nstyle A color: \"\{"&".repeat(54000000)}\"\n",
    ),
    content="270001028",
  )
}
