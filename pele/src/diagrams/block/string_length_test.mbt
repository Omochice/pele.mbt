///|
#skip("slow: draws over 536 million code units before it fails")
test "blocks outgrowing V8's longest string fail as nested too deeply" {
  let fill = "a".repeat(50000)
  let items = Array::makei(10700, i => "B\{i}\nclass B\{i} c").join("\n")
  let failure = try {
    @core.render(
      [@block.block],
      "block-beta\nclassDef c fill:#\{fill};\n\{items}\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. block block")
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a block label drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  let icons = Array::make(5400, "fa:fa-x").join(" ")
  let failure = try {
    @core.render([@block.block], "block-beta\nA[\"\{icons}\"]\n", {
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
  inspect(failure, content="limit: Diagram is nested too deeply. block block")
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a front matter title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@block.block],
      "---\ntitle: x\{"\"".repeat(90000000)}\n---\nblock-beta\nA\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. block block")
}

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
#skip("slow: escapes 110 million characters before it fails")
test "a block named by over a hundred million entities under a short label fails as nested too deeply" {
  inspect(
    outcome("block-beta\n\{"&".repeat(110000000)}[\"x\"]\n"),
    content="limit: Diagram is nested too deeply. block block",
  )
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "a block named and labelled by tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome("block-beta\n\{"&".repeat(54000000)}\n"),
    content="limit: Diagram is nested too deeply. block block",
  )
}

///|
#skip("slow: escapes 54 million characters several times before it fails")
test "an edge label from a block named by tens of millions of entities fails as nested too deeply" {
  let name = "&".repeat(54000000)
  inspect(
    outcome("block-beta\n\{name}[\"x\"] B\n\{name} -- \"l\" --> B\n"),
    content="limit: Diagram is nested too deeply. block block",
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
#skip("slow: escapes 110 million characters before it fails")
test "a block colored by over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome("block-beta\nA\nstyle A color:\{"&".repeat(110000000)}\n"),
    content="limit: Diagram is nested too deeply. block block",
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
