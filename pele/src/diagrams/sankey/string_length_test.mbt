///|
#skip("slow: draws over 536 million code units before it fails")
test "links outgrowing V8's longest string fail as nested too deeply" {
  let source = "A\{"&".repeat(50000)}"
  let links = Array::makei(1090, i => "\{source},B\{i},1").join("\n")
  let failure = try {
    @core.render([@sankey.sankey], "sankey\n\n\{links}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. sankey sankey")
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@sankey.sankey], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 54 million characters several times before it fails")
test "a node named by tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("sankey\n\nA\{"&".repeat(54000000)},B,1\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. sankey sankey",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a front matter title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@sankey.sankey],
      "---\ntitle: x\{"\"".repeat(90000000)}\n---\nsankey\n\nA,B,1\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. sankey sankey")
}

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
#skip("slow: escapes 54 million characters several times before it fails")
test "a value prefix of tens of millions of entities fails as nested too deeply" {
  inspect(
    length_outcome(
      "---\nconfig:\n  sankey:\n    prefix: \"\{"&".repeat(54000000)}\"\n---\nsankey\n\nA,B,1\n",
    ),
    content="limit: Diagram is nested too deeply. sankey sankey",
  )
}

///|
#skip("slow: escapes 54 million characters several times before it fails")
test "a value suffix of tens of millions of entities fails as nested too deeply" {
  inspect(
    length_outcome(
      "---\nconfig:\n  sankey:\n    suffix: \"\{"&".repeat(54000000)}\"\n---\nsankey\n\nA,B,1\n",
    ),
    content="limit: Diagram is nested too deeply. sankey sankey",
  )
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "a node color of tens of millions of entities fails as nested too deeply" {
  inspect(
    length_outcome(
      "---\nconfig:\n  sankey:\n    nodeColors:\n      A: \"\{"&".repeat(54000000)}\"\n---\nsankey\n\nA,B,1\n",
    ),
    content="limit: Diagram is nested too deeply. sankey sankey",
  )
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

///|
#skip("slow: escapes 110 million characters before it fails")
test "a link color of over a hundred million entities fails as nested too deeply" {
  inspect(
    length_outcome(
      "---\nconfig:\n  sankey:\n    linkColor: \"\{"&".repeat(110000000)}\"\n---\nsankey\n\nA,B,1\n",
    ),
    content="limit: Diagram is nested too deeply. sankey sankey",
  )
}

///|
#skip("slow, and moon test runs wasm's allocator unmended, which can give a block of 512 MiB or more a smaller one; check-string-length checks it through the mended plugin")
test "a node named by 2^28 or more letters, written several times, fails as nested too deeply" {
  let failure = try {
    @core.render([@sankey.sankey], "sankey\n\n\{"a".repeat(270000000)},B,1\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. sankey sankey")
}
