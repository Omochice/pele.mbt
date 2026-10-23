///|
#skip("slow: draws over 536 million code units before it fails")
test "entities outgrowing V8's longest string fail as nested too deeply" {
  let fill = "a".repeat(50000)
  let items = Array::makei(10700, i => "E\{i}:::c {}").join("\n")
  let failure = try {
    @core.render([@er.er], "erDiagram\nclassDef c fill:#\{fill}\n\{items}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. er er")
}

///|
/// How rendering `source` fails, under options in which the host draws the icon `fa:fa-x` as a
/// path of 100 thousand code units, with no limit on the source.
fn icon_failure(source : String) -> String {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  try {
    @core.render([@er.er], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      icons: Some(name => if name == "fa:fa-x" { Some(drawing) } else { None }),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "an entity name drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let icons = Array::make(5400, "fa:fa-x").join(" ")
  inspect(
    icon_failure("erDiagram\nA[\"\{icons}\"] {\n}\n"),
    content="limit: Diagram is nested too deeply. er er",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "an attribute comment drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let icons = Array::make(5400, "fa:fa-x").join(" ")
  inspect(
    icon_failure("erDiagram\nA {\n  string name \"\{icons}\"\n}\n"),
    content="limit: Diagram is nested too deeply. er er",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a front matter title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@er.er],
      "---\ntitle: x\{"\"".repeat(90000000)}\n---\nerDiagram\nA {\n}\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. er er")
}

///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn drawn_or_failed(source : String) -> String {
  try {
    let rendered = @core.render([@er.er], source, {
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
test "an aliased entity name escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed("erDiagram\n\"\{"&".repeat(54000000)}\"[\"x\"] {\n}\n"),
    content="270000969",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "an entity name escaped twice past V8's longest string fails as nested too deeply" {
  inspect(
    drawn_or_failed("erDiagram\n\"\{"&".repeat(54000000)}\" {\n}\n"),
    content="limit: Diagram is nested too deeply. er er",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "an attribute comment escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "erDiagram\nA {\n  string name \"\{"&".repeat(54000000)}\"\n}\n",
    ),
    content="270001692",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "a subgraph id escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "erDiagram\nsubgraph \"\{"&".repeat(54000000)}\"[\"x\"]\nA\nend\n",
    ),
    content="270001255",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "an internal link escaped past V8's longest string fails as nested too deeply" {
  inspect(
    drawn_or_failed(
      "erDiagram\nA[\"\{"&".repeat(54000000)}\"] {\n}\nclass A internal-link\n",
    ),
    content="limit: Diagram is nested too deeply. er er",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a relationship of an entity named past V8's longest string fails as nested too deeply" {
  let name = "&".repeat(54000000)
  inspect(
    drawn_or_failed(
      "erDiagram\n\"\{name}\"[\"x\"] {\n}\n\"\{name}\" ||--o{ B : \"r\"\n",
    ),
    content="limit: Diagram is nested too deeply. er er",
  )
}
