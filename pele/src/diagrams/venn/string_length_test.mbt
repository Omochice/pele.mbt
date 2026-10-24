///|
#skip("slow: draws over 536 million code units before it fails")
test "texts outgrowing V8's longest string fail as nested too deeply" {
  let texts = Array::makei(2180, i => "  text T\{i}[\"\{"&".repeat(50000)}\"]").join(
    "\n",
  )
  let failure = try {
    @core.render([@venn.venn], "venn-beta\nset A\n\{texts}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. venn venn")
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@venn.venn], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "a text labelled by over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome_of("venn-beta\nset A\n  text T[\"\{"&".repeat(110000000)}\"]\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. venn venn",
  )
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "a set labelled by over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome_of("venn-beta\nset A[\"\{"&".repeat(110000000)}\"]\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. venn venn",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@venn.venn],
      "venn-beta\ntitle \{"\"".repeat(90000000)}\nset A\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. venn venn")
}

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
#skip("slow: escapes 110 million characters before it fails")
test "a text named by over a hundred million entities under a short label fails as nested too deeply" {
  inspect(
    length_outcome(
      "venn-beta\nset A\n  text \"\{"&".repeat(110000000)}\"[\"x\"]\n",
    ),
    content="limit: Diagram is nested too deeply. venn venn",
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
#skip("slow: escapes 110 million characters before it fails")
test "a set filled by over a hundred million entities fails as nested too deeply" {
  inspect(
    length_outcome(
      "venn-beta\nset A\nstyle A fill: \"\{"&".repeat(110000000)}\"\n",
    ),
    content="limit: Diagram is nested too deeply. venn venn",
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
