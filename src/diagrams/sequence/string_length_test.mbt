///|
#skip("slow: draws over 536 million code units before it fails")
test "messages outgrowing V8's longest string fail as nested too deeply" {
  let markup = "<path d=\"\{"M0 0".repeat(12500)}\"/>"
  let messages = "A->>B: fa:fa-a\n".repeat(10700)
  let failure = try {
    @core.render([@sequence.sequence], "sequenceDiagram\n\{messages}", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      icons: Some(name => if name == "fa:fa-a" { Some(markup) } else { None }),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. sequence sequence",
  )
}

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
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  let title = "\"".repeat(90000000)
  let failure = try {
    @core.render(
      [@sequence.sequence],
      "sequenceDiagram\ntitle \{title}\nA->>B: x\n",
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
    content="limit: Diagram is nested too deeply. sequence sequence",
  )
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@sequence.sequence], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
/// Options under which the host draws the icon `fa:fa-x` as a path of 100 thousand code units,
/// with no limit on the source.
fn label_icon_options() -> @types.RenderOptions {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  {
    ..@types.RenderOptions::default(),
    limit: Some(1.0 / 0.0),
    icons: Some(name => if name == "fa:fa-x" { Some(drawing) } else { None }),
  }
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a message label drawing a host icon in each of thousands of spans fails as nested too deeply" {
  inspect(
    outcome_of(
      "sequenceDiagram\nA->>B: \{Array::make(5400, "fa:fa-x").join(" ")}\n",
      label_icon_options(),
    ),
    content="limit: Diagram is nested too deeply. sequence sequence",
  )
}

///|
#skip("slow: escapes 54 million characters several times before it fails")
test "a participant named by tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("sequenceDiagram\nparticipant \{"&".repeat(54000000)}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. sequence sequence",
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
#skip("slow: escapes over 536 million code units before it fails")
test "a block color escaped past V8's longest string fails as nested too deeply" {
  inspect(
    drawn_or_failed(
      "sequenceDiagram\nrect \{"&".repeat(110000000)}\nA->>B: x\nend\n",
    ),
    content="limit: Diagram is nested too deeply. sequence sequence",
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
