///|
/// The outcome of rendering `source` with no source limit, or the error it fails with.
fn outcome(source : String) -> String {
  try {
    @core.render([@railroad.railroad], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
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
test "rules outgrowing V8's longest string fail as nested too deeply" {
  let rules = Array::makei(880000, i => "r\{i} <- \"a\" ;").join("\n")
  inspect(
    outcome("railroad-peg-beta\n\{rules}\n"),
    content="limit: Diagram is nested too deeply. railroad railroadPeg",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a rule outgrowing V8's longest string fails as nested too deeply" {
  let items = Array::make(2600000, "\"a\"").join(" ")
  inspect(
    outcome("railroad-peg-beta\nr <- \{items} ;\n"),
    content="limit: Diagram is nested too deeply. railroad railroadPeg",
  )
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@railroad.railroad], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "a special sequence of over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome_of("railroad-ebnf-beta\nr = ? \{"&".repeat(110000000)} ? ;\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. railroad railroadEbnf",
  )
}

///|
/// The outcome of rendering `source` with no limit on the source or the output, or the error it fails with.
fn backtrack_outcome(source : String) -> String {
  try {
    @core.render([@railroad.railroad], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: draws a terminal of four million characters")
test "a double-quoted terminal fails as nested too deeply where pele's pattern runs out of V8's backtracking stack" {
  inspect(
    backtrack_outcome("railroad-peg-beta\nr <- \"\{"a".repeat(4194294)}\" ;\n"),
    content="rendered",
  )
  inspect(
    backtrack_outcome("railroad-peg-beta\nr <- \"\{"a".repeat(4194295)}\" ;\n"),
    content="limit: Diagram is nested too deeply. railroad railroadPeg",
  )
  inspect(
    backtrack_outcome("railroad-ebnf-beta\nr = \"\{"a".repeat(4194294)}\" ;\n"),
    content="rendered",
  )
  inspect(
    backtrack_outcome("railroad-ebnf-beta\nr = \"\{"a".repeat(4194295)}\" ;\n"),
    content="limit: Diagram is nested too deeply. railroad railroadEbnf",
  )
  inspect(
    backtrack_outcome(
      "railroad-beta\nr = terminal(\"\{"a".repeat(4194294)}\") ;\n",
    ),
    content="rendered",
  )
  inspect(
    backtrack_outcome(
      "railroad-beta\nr = terminal(\"\{"a".repeat(4194295)}\") ;\n",
    ),
    content="limit: Diagram is nested too deeply. railroad railroad",
  )
}

///|
#skip("slow: draws a terminal of four million characters")
test "a single-quoted terminal runs one more character before V8's backtracking stack runs out" {
  inspect(
    backtrack_outcome("railroad-peg-beta\nr <- '\{"a".repeat(4194295)}' ;\n"),
    content="rendered",
  )
  inspect(
    backtrack_outcome("railroad-peg-beta\nr <- '\{"a".repeat(4194296)}' ;\n"),
    content="limit: Diagram is nested too deeply. railroad railroadPeg",
  )
}

///|
#skip("slow: draws a value of three million parts")
test "a numeric value fails as nested too deeply where pele's pattern runs out of V8's backtracking stack" {
  inspect(
    backtrack_outcome("railroad-abnf-beta\nr = %x1\{".1".repeat(3355435)} ;\n"),
    content="rendered",
  )
  inspect(
    backtrack_outcome("railroad-abnf-beta\nr = %x1\{"-1".repeat(3355436)} ;\n"),
    content="limit: Diagram is nested too deeply. railroad railroadAbnf",
  )
}
