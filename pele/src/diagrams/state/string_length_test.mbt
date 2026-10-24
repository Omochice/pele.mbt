///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn outcome(source : String) -> String {
  try {
    let rendered = @core.render([@state.state], source, {
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
test "a state named by tens of millions of entities under a short label is drawn as pele draws it" {
  inspect(
    outcome("stateDiagram-v2\nstate \"x\" as \{"&".repeat(54000000)}\n"),
    content="270000931",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a tooltip of tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome(
      "stateDiagram-v2\nA\nclick A \"https://x\" \"\{"&".repeat(54000000)}\"\n",
    ),
    content="270001003",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a link of tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome(
      "stateDiagram-v2\nA\nclick A href \"https://x/\{"&".repeat(54000000)}\"\n",
    ),
    content="270000988",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a state colored by tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome("stateDiagram-v2\nA\nstyle A color:\{"&".repeat(54000000)}\n"),
    content="270000947",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a state filled by tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome("stateDiagram-v2\nA\nstyle A fill:\{"&".repeat(54000000)}\n"),
    content="270000947",
  )
}
