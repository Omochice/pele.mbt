///|
/// Options under which the host draws the icon `fa:fa-x` as a path of 100 thousand code units,
/// with no limit on the source or the output.
fn icon_options() -> @types.RenderOptions {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  {
    ..@types.RenderOptions::default(),
    limit: Some(1.0 / 0.0),
    output_limit: Some(1.0 / 0.0),
    icons: Some(name => if name == "fa:fa-x" { Some(drawing) } else { None }),
  }
}

///|
fn icon_label(count : Int32) -> String {
  "graph TD\nA[\"\{Array::make(count, "fa:fa-x").join(" ")}\"]\n"
}

///|
#skip("slow: draws over 300 million code units")
test "a node label longer than a doubling StringBuilder holds is drawn" {
  let svg = @core.render(
      [@flowchart.flowchart],
      icon_label(3000),
      icon_options(),
    ).svg
  inspect(svg.length(), content="300835316")
}

///|
/// The outcome of rendering `source` with no limit on the source, or the error it fails with.
fn backtrack_outcome(source : String) -> String {
  try {
    @core.render([@flowchart.flowchart], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
test "a run of millions of line breaks is skipped" {
  inspect(
    backtrack_outcome("graph TD\nA\{"\n".repeat(9000000)}B\n"),
    content="rendered",
  )
}

///|
test "millions of line breaks after the keyword are skipped" {
  inspect(
    backtrack_outcome("graph\{"\n".repeat(9000000)}A\n"),
    content="rendered",
  )
  inspect(
    backtrack_outcome("graph\{"\n".repeat(9000000)} \nA\n"),
    content="rendered",
  )
}

///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn drawn_or_failed(source : String) -> String {
  try {
    let rendered = @core.render([@flowchart.flowchart], source, {
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
test "a tooltip escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "graph TD\nA\nclick A callback \"\{"&".repeat(54000000)}\"\n",
    ),
    content="270001011",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "a link escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed("graph TD\nA\nclick A href \"\{"&".repeat(54000000)}\"\n"),
    content="270001026",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "an image escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "graph TD\nA@{ img: \"\{"&".repeat(54000000)}\", label: \"x\" }\n",
    ),
    content="270000947",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "an icon name escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "graph TD\nA@{ icon: \"\{"&".repeat(54000000)}\", label: \"x\" }\n",
    ),
    content="270001063",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "a subgraph id escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "graph TD\nsubgraph \"\{"&".repeat(54000000)}\" [x]\nA\nend\n",
    ),
    content="270001272",
  )
}

///|
fn unlimited() -> @types.RenderOptions {
  {
    ..@types.RenderOptions::default(),
    limit: Some(1.0 / 0.0),
    output_limit: Some(1.0 / 0.0),
  }
}

///|
#skip("slow, and moon test runs wasm's allocator unmended, which can give a block of 512 MiB or more a smaller one; check-string-length checks it through the mended plugin")
test "a node label of 2^28 or more letters is drawn" {
  let svg = @core.render(
      [@flowchart.flowchart],
      "graph TD\nA[\{"a".repeat(270000000)}]\n",
      unlimited(),
    ).svg
  inspect(svg.length(), content="270001025")
}
