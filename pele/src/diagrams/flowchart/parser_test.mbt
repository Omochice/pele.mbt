// Ported from pele v1.8.0, tests/flowchart/parser.test.ts.

///|
fn parse(source : String) -> @flowchart.FlowDb raise @errors.PeleError {
  let db = @flowchart.FlowDb::new()
  @flowchart.parse_flowchart(source, db)
  db
}

///|
test "merges a repeated subgraph id into one subgraph" {
  let db = parse("flowchart LR\nsubgraph S\n  x\nend\nsubgraph S\n  y\nend")
  inspect(db.subgraphs.length(), content="1")
  inspect(db.subgraphs[0].nodes.join(","), content="x,y")
}

///|
/// Mermaid 12.1.0 throws a TypeError here; an unnamed subgraph is clearly meant to work.
test "accepts a subgraph with no name" {
  let db = parse("flowchart TD\nsubgraph\n  a --> b\nend")
  inspect(db.subgraphs.length(), content="1")
  inspect(db.subgraphs[0].id, content="subGraph0")
  inspect(db.subgraphs[0].nodes.join(","), content="b,a")
}

///|
test "reports a linkStyle index that does not exist" {
  let message = try {
    ignore(parse("graph TD\nA-->B\nlinkStyle 1 stroke-width:1px;"))
    ""
  } catch {
    @errors.PeleError(failure) => failure.message
  }
  inspect(
    message.has_prefix(
      "The index 1 for linkStyle is out of bounds. Valid indices for linkStyle are between 0 and 0.",
    ),
    content="true",
  )
}

///|
test "reports the position of a syntax error" {
  let failure = try {
    ignore(parse("graph TD\nA-->B\nB --> [oops]"))
    None
  } catch {
    @errors.PeleError(failure) => Some(failure)
  }
  guard failure is Some(failure) else { fail("no error") }
  inspect(failure.line, content="3")
  inspect(failure.column, content="7")
  inspect(failure.message.contains("got 'SQS'"), content="true")
}

///|
/// Mermaid skips this spec because its parser needs minutes for it.
test "parses the huge diagram from the Mermaid specs" {
  let body = "A-->B;B-->A;".repeat(415) + "A-->B;"
  let source = "graph LR;" + body.repeat(57) + "A-->B;B-->A;".repeat(275)
  let db = parse(source)
  inspect(db.edges[0].kind.unwrap_or("-"), content="arrow_point")
  inspect(db.edges.length(), content="47917")
  inspect(db.nodes.length(), content="2")
}

///|
test "honours an edge limit when one is set" {
  let db = @flowchart.FlowDb::new(max_edges=2)
  let message = try {
    @flowchart.parse_flowchart("graph TD\nA-->B-->C-->D", db)
    ""
  } catch {
    @errors.PeleError(failure) => failure.message
  }
  inspect(message.has_prefix("Edge limit exceeded"), content="true")
}
