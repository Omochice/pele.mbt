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
#skip("slow, and moon test runs wasm's allocator unmended, which can give a block of 512 MiB or more a smaller one; check-string-length checks it through the mended plugin")
test "a leaf label of more than 2^27 code points is cut to fit its leaf" {
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
  inspect(outcome(134217729), content="134218887")
}
