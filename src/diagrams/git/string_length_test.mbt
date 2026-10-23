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
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@git.git], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "a commit id of tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("gitGraph\ncommit id: \"\{"&".repeat(54000000)}\"\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
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
#skip("slow: draws a commit id of four million characters")
test "a double-quoted commit id fails as nested too deeply where pele's pattern runs out of V8's backtracking stack" {
  inspect(
    backtrack_outcome("gitGraph\ncommit id: \"\{"a".repeat(4194294)}\"\n"),
    content="rendered",
  )
  inspect(
    backtrack_outcome("gitGraph\ncommit id: \"\{"a".repeat(4194295)}\"\n"),
    content="limit: Diagram is nested too deeply. gitGraph gitGraph",
  )
}

///|
#skip("slow: draws a commit id of four million characters")
test "a single-quoted commit id runs one more character before V8's backtracking stack runs out" {
  inspect(
    backtrack_outcome("gitGraph\ncommit id: '\{"a".repeat(4194295)}'\n"),
    content="rendered",
  )
  inspect(
    backtrack_outcome("gitGraph\ncommit id: '\{"a".repeat(4194296)}'\n"),
    content="limit: Diagram is nested too deeply. gitGraph gitGraph",
  )
}

///|
#skip("slow: lexes four million characters")
test "an unclosed commit id counts every character to the end against V8's backtracking stack" {
  inspect(
    backtrack_outcome("gitGraph\ncommit id: \"\{"a".repeat(4194293)}\n"),
    content="syntax: line 2 gitGraph gitGraph",
  )
  inspect(
    backtrack_outcome("gitGraph\ncommit id: \"\{"a".repeat(4194294)}\n"),
    content="limit: Diagram is nested too deeply. gitGraph gitGraph",
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

