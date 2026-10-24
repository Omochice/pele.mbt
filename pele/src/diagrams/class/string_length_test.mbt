///|
#skip("slow: draws over 536 million code units before it fails")
test "classes outgrowing V8's longest string fail as nested too deeply" {
  let fill = "a".repeat(50000)
  let classes = Array::makei(10700, i => "class C\{i}:::c").join("\n")
  let failure = try {
    @core.render(
      [@class.class],
      "classDiagram\nclassDef c fill:#\{fill}\n\{classes}\n",
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
    content="limit: Diagram is nested too deeply. class classDiagram",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a class label drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  let icons = Array::make(5400, "fa:fa-x").join(" ")
  let failure = try {
    @core.render([@class.class], "classDiagram\nclass A[\"\{icons}\"]\n", {
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
    content="limit: Diagram is nested too deeply. class classDiagram",
  )
}

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
#skip("slow: escapes 110 million characters before it fails")
test "a member of over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome("classDiagram\nclass A {\n  \{"&".repeat(110000000)}\n}\n"),
    content="limit: Diagram is nested too deeply. class classDiagram",
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
#skip("slow: escapes 110 million characters before it fails")
test "an annotation of over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome("classDiagram\nclass A {\n  <<\{"&".repeat(110000000)}>>\n}\n"),
    content="limit: Diagram is nested too deeply. class classDiagram",
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
#skip("slow: escapes 110 million characters before it fails")
test "a class named by over a hundred million entities under a short label fails as nested too deeply" {
  inspect(
    outcome("classDiagram\nclass `\{"&".repeat(110000000)}`[\"x\"]\n"),
    content="limit: Diagram is nested too deeply. class classDiagram",
  )
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "an edge from a class named by tens of millions of entities fails as nested too deeply" {
  let name = "&".repeat(54000000)
  inspect(
    outcome("classDiagram\nclass `\{name}`[\"x\"]\n`\{name}` --> B\n"),
    content="limit: Diagram is nested too deeply. class classDiagram",
  )
}

///|
#skip("slow: escapes 54 million characters three times before it fails")
test "an edge label from a class named by tens of millions of entities fails as nested too deeply" {
  let name = "&".repeat(54000000)
  inspect(
    outcome("classDiagram\nclass `\{name}`[\"x\"]\n`\{name}` --> B : l\n"),
    content="limit: Diagram is nested too deeply. class classDiagram",
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
#skip("slow: escapes 110 million characters before it fails")
test "a cardinality of over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome("classDiagram\nA \"\{"&".repeat(110000000)}\" --> B\n"),
    content="limit: Diagram is nested too deeply. class classDiagram",
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
#skip("slow: escapes 110 million characters before it fails")
test "a tooltip of over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome(
      "classDiagram\nclass A\nclick A call f() \"\{"&".repeat(110000000)}\"\n",
    ),
    content="limit: Diagram is nested too deeply. class classDiagram",
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
#skip("slow: escapes 110 million characters before it fails")
test "a link of over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome(
      "classDiagram\nclass A\nclick A href \"https://x/\{"&".repeat(110000000)}\"\n",
    ),
    content="limit: Diagram is nested too deeply. class classDiagram",
  )
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "a struck namespace title named by tens of millions of entities fails as nested too deeply" {
  let name = "&".repeat(54000000)
  let source =
    #|classDiagram
    #|    namespace `NAME`["Company.Engineering.Backend"] {
    #|        class Developer {
    #|            +writeCode()
    #|        }
    #|    }
    #|    namespace Company.Engineering.Frontend {
    #|        class Designer {
    #|            +createMockup()
    #|        }
    #|    }
    #|    namespace Company.Engineering {
    #|        class TechLead {
    #|            +planSprint()
    #|        }
    #|    }
    #|    TechLead --> Developer : leads
    #|    TechLead --> Designer : leads
    #|
  inspect(
    outcome(source.replace(old="NAME", new=name), max_width=400),
    content="limit: Diagram is nested too deeply. class classDiagram",
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
#skip("slow: escapes 110 million characters before it fails")
test "a class colored by over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome("classDiagram\nclass A\nstyle A color:\{"&".repeat(110000000)}\n"),
    content="limit: Diagram is nested too deeply. class classDiagram",
  )
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "a class stroked by tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome(
      "classDiagram\nclass A {\n  x\n}\nstyle A stroke:\{"&".repeat(54000000)}\n",
    ),
    content="limit: Diagram is nested too deeply. class classDiagram",
  )
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "a static member of a class colored by tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome(
      "classDiagram\nclass A {\n  +x$\n}\nstyle A color:\{"&".repeat(54000000)}\n",
    ),
    content="limit: Diagram is nested too deeply. class classDiagram",
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
test "a class named by 2^28 or more letters, written twice, fails as nested too deeply" {
  inspect(
    outcome("classDiagram\nclass \{"a".repeat(270000000)}\n"),
    content="limit: Diagram is nested too deeply. class classDiagram",
  )
}

///|
#skip("slow, and moon test runs wasm's allocator unmended, which can give a block of 512 MiB or more a smaller one; check-string-length checks it through the mended plugin")
test "a member of 2^28 or more letters is drawn" {
  inspect(
    outcome("classDiagram\nclass A {\n  \{"a".repeat(270000000)}\n}\n"),
    content="270001354",
  )
}
