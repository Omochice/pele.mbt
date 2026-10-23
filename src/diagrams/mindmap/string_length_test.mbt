///|
#skip("slow: draws over 536 million code units before it fails")
test "nodes outgrowing V8's longest string fail as nested too deeply" {
  let markup = "<path d=\"\{"M0 0".repeat(12500)}\"/>"
  let nodes = Array::makei(10700, i => "  m\{i}[fa:fa-a]").join("\n")
  let failure = try {
    @core.render([@mindmap.mindmap], "mindmap\nroot\n\{nodes}\n", {
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
    content="limit: Diagram is nested too deeply. mindmap mindmap",
  )
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@mindmap.mindmap], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a node label drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let markup = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  let spans = Array::make(5400, "fa:fa-x").join(" ")
  inspect(
    outcome_of("mindmap\nroot[\"\{spans}\"]\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      icons: Some(name => if name == "fa:fa-x" { Some(markup) } else { None }),
    }),
    content="limit: Diagram is nested too deeply. mindmap mindmap",
  )
}

///|
#skip("slow: escapes 60 million characters twice before it fails")
test "a node named by tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("mindmap\n\{"&".repeat(60000000)}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. mindmap mindmap",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a front matter title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@mindmap.mindmap],
      "---\ntitle: x\{"\"".repeat(90000000)}\n---\nmindmap\nroot\n",
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
    content="limit: Diagram is nested too deeply. mindmap mindmap",
  )
}

///|
/// The outcome of rendering `source` with no source or output limit under a host that draws the
/// icon `icon`: the SVG's length, or the error.
fn length_with_icon(source : String, icon : String) -> String {
  try {
    let rendered = @core.render([@mindmap.mindmap], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
      icons: Some(name => if name == icon { Some("<path/>") } else { None }),
    })
    "\{rendered.svg.length()}"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "an icon named by tens of millions of entities is drawn as pele draws it" {
  let name = "&".repeat(54000000)
  inspect(
    length_with_icon("mindmap\nroot\n  A\n  ::icon(\{name})\n", name),
    content="270001541",
  )
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "an icon named by over a hundred million entities fails as nested too deeply" {
  let name = "&".repeat(110000000)
  inspect(
    length_with_icon("mindmap\nroot\n  A\n  ::icon(\{name})\n", name),
    content="limit: Diagram is nested too deeply. mindmap mindmap",
  )
}
