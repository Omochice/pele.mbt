///|
#skip("slow: draws over 536 million code units before it fails")
test "commit ids outgrowing V8's longest string fail as nested too deeply" {
  let entities = "&".repeat(540000)
  let commits = Array::makei(100, i => "commit id: \"c\{i}\{entities}\"").join(
    "\n",
  )
  let failure = try {
    @core.render([@git.git], "gitGraph\n\{commits}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. gitGraph gitGraph",
  )
}

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

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@git.git],
      "gitGraph\ntitle \{"\"".repeat(90000000)}\ncommit\n",
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
    content="limit: Diagram is nested too deeply. gitGraph gitGraph",
  )
}
