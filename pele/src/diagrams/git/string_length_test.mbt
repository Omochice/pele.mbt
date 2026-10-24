///|
/// The outcome of rendering `source` with no limit on the source or the output, or the error it fails with.
fn backtrack_outcome(source : String) -> String {
  try {
    @core.render([@git.git], source, {
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
test "a double-quoted commit id of millions of characters is drawn" {
  inspect(
    backtrack_outcome("gitGraph\ncommit id: \"\{"a".repeat(5000000)}\"\n"),
    content="rendered",
  )
}

///|
test "a single-quoted commit id of millions of characters is drawn" {
  inspect(
    backtrack_outcome("gitGraph\ncommit id: '\{"a".repeat(5000000)}'\n"),
    content="rendered",
  )
}

///|
test "an unclosed commit id of millions of characters is a syntax error" {
  inspect(
    backtrack_outcome("gitGraph\ncommit id: \"\{"a".repeat(5000000)}\n"),
    content="syntax: line 2 gitGraph gitGraph",
  )
}
