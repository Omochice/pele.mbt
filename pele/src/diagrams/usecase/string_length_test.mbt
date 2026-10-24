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
