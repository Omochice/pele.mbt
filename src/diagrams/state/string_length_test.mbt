///|
#skip("slow: draws over 536 million code units before it fails")
test "states outgrowing V8's longest string fail as nested too deeply" {
  let fill = "a".repeat(50000)
  let items = Array::makei(10700, i => "[*] --> S\{i}:::c").join("\n")
  let failure = try {
    @core.render(
      [@state.state],
      "stateDiagram-v2\nclassDef c fill:#\{fill}\n\{items}\n",
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
    content="limit: Diagram is nested too deeply. state stateDiagram",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a state label drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  let icons = Array::make(5400, "fa:fa-x").join(" ")
  let failure = try {
    @core.render([@state.state], "stateDiagram-v2\nA : \{icons}\n", {
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
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. state stateDiagram",
  )
}

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
#skip("slow: escapes 110 million characters before it fails")
test "a state named by over a hundred million entities under a short label fails as nested too deeply" {
  inspect(
    outcome("stateDiagram-v2\nstate \"x\" as \{"&".repeat(110000000)}\n"),
    content="limit: Diagram is nested too deeply. state stateDiagram",
  )
}

///|
#skip("slow: escapes 54 million characters several times before it fails")
test "a note on a state named by tens of millions of entities fails as nested too deeply" {
  let name = "&".repeat(54000000)
  inspect(
    outcome(
      "stateDiagram-v2\nstate \"x\" as \{name}\nnote right of \{name} : n\n",
    ),
    content="limit: Diagram is nested too deeply. state stateDiagram",
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
#skip("slow: escapes 110 million characters before it fails")
test "a tooltip of over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome(
      "stateDiagram-v2\nA\nclick A \"https://x\" \"\{"&".repeat(110000000)}\"\n",
    ),
    content="limit: Diagram is nested too deeply. state stateDiagram",
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
#skip("slow: escapes 110 million characters before it fails")
test "a link of over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome(
      "stateDiagram-v2\nA\nclick A href \"https://x/\{"&".repeat(110000000)}\"\n",
    ),
    content="limit: Diagram is nested too deeply. state stateDiagram",
  )
}
