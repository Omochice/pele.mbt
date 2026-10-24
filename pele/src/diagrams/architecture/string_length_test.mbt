///|
/// The outcome of rendering `source` with no limit on the source or the output, or the error it fails with.
fn backtrack_outcome(source : String) -> String {
  try {
    @core.render([@architecture.architecture], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) => {
      let detail = if failure.code is Limit {
        failure.message
      } else {
        "line \{failure.line}"
      }
      "\{failure.code.to_string()}: \{detail} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
    }
  }
}

///|
test "a string of millions of characters the grammar has no place for is a syntax error" {
  inspect(
    backtrack_outcome("architecture-beta\n\"\{"a".repeat(5000000)}\"\n"),
    content="syntax: line 2 architecture architecture",
  )
}

///|
test "a quoted service label of millions of characters is drawn" {
  inspect(
    backtrack_outcome(
      "architecture-beta\nservice s(server)[\"\{"a".repeat(5000000)}\"]\n",
    ),
    content="rendered",
  )
}

///|
test "a quoted service label of millions of characters not closed by its bracket is drawn" {
  inspect(
    backtrack_outcome(
      "architecture-beta\nservice s(server)[\"\{"a".repeat(5000000)}\"x]\n",
    ),
    content="rendered",
  )
}
