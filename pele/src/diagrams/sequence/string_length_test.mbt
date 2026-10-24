///|
#skip("slow: draws over 280 million code units")
test "a front matter title longer than a doubling StringBuilder holds is drawn whole" {
  let title = "<".repeat(70000000)
  let svg = @core.render(
      [@sequence.sequence],
      "---\ntitle: \{title}\n---\nsequenceDiagram\nA->>B: x\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        output_limit: Some(1.0 / 0.0),
      },
    ).svg
  inspect(svg.length(), content="280002520")
  let start = svg.find("&lt;").unwrap()
  inspect(
    svg[start:start + 280000000] == "&lt;".repeat(70000000),
    content="true",
  )
}

///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn drawn_or_failed(source : String) -> String {
  try {
    let rendered = @core.render([@sequence.sequence], source, {
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
test "a block color escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "sequenceDiagram\nrect \{"&".repeat(54000000)}\nA->>B: x\nend\n",
    ),
    content="270002468",
  )
}

///|
#skip("slow, and moon test runs wasm's allocator unmended, which can give a block of 512 MiB or more a smaller one; check-string-length checks it through the mended plugin")
test "a message of 2^28 or more letters is drawn" {
  let svg = @core.render(
      [@sequence.sequence],
      "sequenceDiagram\nA->>B: \{"a".repeat(270000000)}\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        output_limit: Some(1.0 / 0.0),
      },
    ).svg
  inspect(svg.length(), content="270002422")
}
