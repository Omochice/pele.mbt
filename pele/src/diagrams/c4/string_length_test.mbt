///|
#skip("slow: draws over 536 million code units before it fails")
test "people with many icon spans past V8's longest string fail as nested too deeply" {
  let label = "fa:fa-a ".repeat(1000)
  let people = Array::makei(2100, i => "Person(p\{i}, \"\{label}\")").join("\n")
  let failure = try {
    @core.render([@c4.c4], "C4Context\n\{people}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      icons: Some(name => {
        if name == "fa:fa-a" {
          Some("<path d=\"M4,4H20\"/>")
        } else {
          None
        }
      }),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. c4 c4")
}

///|
/// How rendering `source` fails with no limit on the source, under options that resolve the icon
/// `fa:fa-a`, which a C4 label draws only as an empty box.
fn icon_failure(source : String) -> String {
  try {
    @core.render([@c4.c4], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      icons: Some(name => {
        if name == "fa:fa-a" {
          Some("<path d=\"M4,4H20\"/>")
        } else {
          None
        }
      }),
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
test "a person label of millions of icon spans fails as nested too deeply" {
  let label = "fa:fa-a ".repeat(2200000)
  inspect(
    icon_failure("C4Context\nPerson(p, \"\{label}\")\n"),
    content="limit: Diagram is nested too deeply. c4 c4",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a boundary label of millions of icon spans fails as nested too deeply" {
  let label = "fa:fa-a ".repeat(2200000)
  inspect(
    icon_failure(
      "C4Context\nBoundary(b, \"\{label}\") {\n  Person(p, \"x\")\n}\n",
    ),
    content="limit: Diagram is nested too deeply. c4 c4",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@c4.c4],
      "C4Context\ntitle \{"\"".repeat(90000000)}\nPerson(p, \"x\")\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. c4 c4")
}

///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn outcome(source : String) -> String {
  try {
    let rendered = @core.render([@c4.c4], source, {
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
test "a person aliased by tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome("C4Context\nPerson(\{"&".repeat(54000000)}, \"x\")\n"),
    content="270001258",
  )
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "a person aliased by over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome("C4Context\nPerson(\{"&".repeat(110000000)}, \"x\")\n"),
    content="limit: Diagram is nested too deeply. c4 c4",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a boundary aliased by tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome(
      "C4Context\nBoundary(\{"&".repeat(54000000)}, \"x\") {\n  Person(p, \"x\")\n}\n",
    ),
    content="270001747",
  )
}

///|
#skip("slow: escapes 54 million characters several times before it fails")
test "a relation between people aliased by tens of millions of entities fails as nested too deeply" {
  let name = "&".repeat(54000000)
  inspect(
    outcome(
      "C4Context\nPerson(\{name}, \"x\")\nPerson(q, \"y\")\nRel(\{name}, q, \"\")\n",
    ),
    content="limit: Diagram is nested too deeply. c4 c4",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a relation described by tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome(
      "C4Context\nPerson(p, \"x\")\nPerson(q, \"y\")\nRel(p, q, \"l\", \"t\", \"\{"&".repeat(54000000)}\")\n",
    ),
    content="270002373",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a link of tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome(
      "C4Context\nPerson(p, \"x\", \"d\", \"s\", \"t\", \"https://x/\{"&".repeat(54000000)}\")\n",
    ),
    content="270001388",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a system filled by tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome(
      "C4Context\nSystem(s, \"x\")\nUpdateElementStyle(s, \"\{"&".repeat(54000000)}\")\n",
    ),
    content="270001243",
  )
}

///|
#skip("slow: escapes 54 million characters several times before it fails")
test "a person colored by tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome(
      "C4Context\nPerson(p, \"x\")\nUpdateElementStyle(p, $fontColor=\"\{"&".repeat(54000000)}\")\n",
    ),
    content="limit: Diagram is nested too deeply. c4 c4",
  )
}

///|
#skip("slow: escapes 54 million characters several times before it fails")
test "a relation lined by tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome(
      "C4Context\nPerson(p, \"x\")\nPerson(q, \"y\")\nRel(p, q, \"l\")\nUpdateRelStyle(p, q, \"red\", \"\{"&".repeat(54000000)}\")\n",
    ),
    content="limit: Diagram is nested too deeply. c4 c4",
  )
}
