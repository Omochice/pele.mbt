///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn outcome(source : String, max_width? : Double) -> String {
  try {
    let rendered = @core.render([@class.class], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
      max_width,
    })
    "\{rendered.svg.length()}"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a member of tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome("classDiagram\nclass A {\n  \{"&".repeat(54000000)}\n}\n"),
    content="270001344",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "an annotation of tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome("classDiagram\nclass A {\n  <<\{"&".repeat(54000000)}>>\n}\n"),
    content="270001349",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a class named by tens of millions of entities under a short label is drawn as pele draws it" {
  inspect(
    outcome("classDiagram\nclass `\{"&".repeat(54000000)}`[\"x\"]\n"),
    content="270001156",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a cardinality of tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome("classDiagram\nA \"\{"&".repeat(54000000)}\" --> B\n"),
    content="270001971",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a tooltip of tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome(
      "classDiagram\nclass A\nclick A call f() \"\{"&".repeat(54000000)}\"\n",
    ),
    content="270001182",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a link of tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome(
      "classDiagram\nclass A\nclick A href \"https://x/\{"&".repeat(54000000)}\"\n",
    ),
    content="270001223",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a class colored by tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome("classDiagram\nclass A\nstyle A color:\{"&".repeat(54000000)}\n"),
    content="270001172",
  )
}

///|
#skip("slow: lexes 70 million tokens before it fails")
test "a generic of 140 million < fails with its whole line quoted" {
  let generic = "<".repeat(140000000)
  let failure = try {
    @core.render([@class.class], "classDiagram\nclass A~\{generic}~\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) => {
      assert_eq(
        failure.message,
        "Parse error on line 2:\nclass A~\{generic}~\n----------^\nExpecting 'UNICODE_TEXT', 'NUM', 'ALPHA', 'MINUS', got 'ANNOTATION_START'",
      )
      "\{failure.code.to_string()}: \{failure.message.length()} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
    }
  }
  inspect(failure, content="syntax: 140000118 class classDiagram")
}

///|
#skip("slow, and moon test runs wasm's allocator unmended, which can give a block of 512 MiB or more a smaller one; check-string-length checks it through the mended plugin")
test "a member of 2^28 or more letters is drawn" {
  inspect(
    outcome("classDiagram\nclass A {\n  \{"a".repeat(270000000)}\n}\n"),
    content="270001354",
  )
}
