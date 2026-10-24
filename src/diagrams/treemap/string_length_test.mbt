///|
#skip("slow: draws over 536 million code units before it fails")
test "leaves outgrowing V8's longest string fail as nested too deeply" {
  let fill = "a".repeat(60000)
  let items = Array::makei(9000, i => "\"L\{i}\": 1:::cc").join("\n")
  let failure = try {
    @core.render(
      [@treemap.treemap],
      "treemap-beta\n\{items}\nclassDef cc fill:#\{fill};\n",
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
    content="limit: Diagram is nested too deeply. treemap treemap",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@treemap.treemap],
      "treemap-beta\ntitle \{"\"".repeat(90000000)}\n\"a\": 1\n",
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
    content="limit: Diagram is nested too deeply. treemap treemap",
  )
}

///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn length_outcome(source : String) -> String {
  try {
    let rendered = @core.render([@treemap.treemap], source, {
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
test "a leaf named by tens of millions of entities is drawn as pele draws it" {
  inspect(
    length_outcome("treemap-beta\n\"\{"&".repeat(54000000)}\": 1\n"),
    content="270001553",
  )
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "a leaf named by over a hundred million entities fails as nested too deeply" {
  inspect(
    length_outcome("treemap-beta\n\"\{"&".repeat(110000000)}\": 1\n"),
    content="limit: Diagram is nested too deeply. treemap treemap",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a section named by tens of millions of entities is drawn as pele draws it" {
  inspect(
    length_outcome("treemap-beta\n\"\{"&".repeat(54000000)}\"\n  \"b\": 1\n"),
    content="270001778",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a leaf filled by tens of millions of entities is drawn as pele draws it" {
  inspect(
    length_outcome(
      "treemap-beta\n\"a\": 1:::cc\nclassDef cc fill:\{"&".repeat(54000000)};\n",
    ),
    content="270001046",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a section filled by tens of millions of entities is drawn as pele draws it" {
  inspect(
    length_outcome(
      "treemap-beta\n\"s\":::cc\n  \"a\": 1\nclassDef cc fill:\{"&".repeat(54000000)};\n",
    ),
    content="270001474",
  )
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "a leaf colored by tens of millions of entities fails as nested too deeply" {
  inspect(
    length_outcome(
      "treemap-beta\n\"a\": 1:::cc\nclassDef cc color:\{"&".repeat(54000000)};\n",
    ),
    content="limit: Diagram is nested too deeply. treemap treemap",
  )
}

///|
#skip("slow, and moon test runs wasm's allocator unmended, which can give a block of 512 MiB or more a smaller one; check-string-length checks it through the mended plugin")
test "a leaf label cut among more code points than V8's longest array holds fails as nested too deeply" {
  let outcome = (count : Int32) => {
    @core.render(
      [@treemap.treemap],
      "treemap-beta\n\"\{"a".repeat(count)}\": 1\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        output_limit: Some(1.0 / 0.0),
      },
    ).svg
    .length()
    .to_string() catch {
      @errors.PeleError(failure) =>
        "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
    }
  }
  inspect(outcome(134217728), content="134218886")
  inspect(
    outcome(134217729),
    content="limit: Diagram is nested too deeply. treemap treemap",
  )
}
