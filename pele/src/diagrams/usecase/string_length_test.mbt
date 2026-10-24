///|
#skip("slow: draws over 536 million code units before it fails")
test "use cases outgrowing V8's longest string fail as nested too deeply" {
  let fill = "a".repeat(50000)
  let items = Array::makei(10700, i => "U\{i}(\"x\"):::c").join("\n")
  let failure = try {
    @core.render(
      [@usecase.usecase],
      "usecase-beta\nclassDef c fill:#\{fill}\n\{items}\n",
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
    content="limit: Diagram is nested too deeply. usecase usecase",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a use case label drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  let icons = Array::make(5400, "fa:fa-x").join(" ")
  let failure = try {
    @core.render([@usecase.usecase], "usecase-beta\nU(\"\{icons}\")\n", {
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
    content="limit: Diagram is nested too deeply. usecase usecase",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a front matter title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@usecase.usecase],
      "---\ntitle: x\{"\"".repeat(90000000)}\n---\nusecase-beta\nU(\"x\")\n",
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
    content="limit: Diagram is nested too deeply. usecase usecase",
  )
}

///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn drawn_or_failed(source : String) -> String {
  try {
    let rendered = @core.render([@usecase.usecase], source, {
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
test "an actor icon name escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "usecase-beta\nactor User@{ icon: \"\{"&".repeat(54000000)}\" }\n",
    ),
    content="270001280",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "a fill escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "usecase-beta\nU(\"x\")\nstyle U fill:\{"&".repeat(54000000)}\n",
    ),
    content="270000959",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "a text color escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "usecase-beta\nU(\"x\")\nstyle U color:\{"&".repeat(54000000)}\n",
    ),
    content="270000959",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "a stroke escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "usecase-beta\nU(\"x\")\nstyle U stroke:\{"&".repeat(54000000)}\n",
    ),
    content="270000961",
  )
}

///|
#skip("slow: draws over 320 million code units")
test "a use case named by a label referenced past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed("usecase-beta\n\"\{"&".repeat(54000000)}\"\n"),
    content="324000968",
  )
}

///|
test "a label referenced past the port's hold limit fails with the port's limit" {
  inspect(
    drawn_or_failed("usecase-beta\nU(\"\{"&".repeat(110000000)}\")\n"),
    content=(
      #|limit: Diagram output is too large for the wasm port: it would hold more than 400000000 code units, the most the port can hold at once. usecase usecase
    ),
  )
}
