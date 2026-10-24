///|
#skip("slow: draws over 536 million code units before it fails")
test "bars outgrowing V8's longest string fail as nested too deeply" {
  let values = Array::make(10000, "1").join(",")
  let series = Array::make(1060, "bar [\{values}]").join("\n")
  let failure = try {
    @core.render([@xychart.xychart], "xychart\n\{series}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. xychart xychart",
  )
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@xychart.xychart], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "a category of over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome_of("xychart\nx-axis [\"\{"&".repeat(110000000)}\"]\nbar [1]\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. xychart xychart",
  )
}

///|
#skip("slow: draws over 300 million code units")
test "a category drawn past what a doubling StringBuilder holds is drawn" {
  inspect(
    outcome_of("xychart\nx-axis [\"\{"&".repeat(60000000)}\"]\nbar [1]\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
    }),
    content="rendered",
  )
}

///|
#skip("slow: escapes 54 million characters several times before it fails")
test "a series titled by tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("xychart\nbar \"\{"&".repeat(54000000)}\" [1]\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. xychart xychart",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@xychart.xychart],
      "xychart\ntitle \"\{"&".repeat(110000000)}\"\nbar [1]\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. xychart xychart",
  )
}

///|
#skip("slow, and moon test runs wasm's allocator unmended, which can give a block of 512 MiB or more a smaller one; check-string-length checks it through the mended plugin")
test "a category of 2^28 or more letters is drawn" {
  let svg = @core.render(
      [@xychart.xychart],
      "xychart\nx-axis [\{"a".repeat(270000000)}]\nbar [1]\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        output_limit: Some(1.0 / 0.0),
      },
    ).svg
  inspect(svg.length(), content="270001610")
}
