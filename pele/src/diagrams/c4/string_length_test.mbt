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
