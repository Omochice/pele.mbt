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
test "a double-quoted terminal of millions of characters is drawn" {
  inspect(
    backtrack_outcome("railroad-peg-beta\nr <- \"\{"a".repeat(5000000)}\" ;\n"),
    content="rendered",
  )
  inspect(
    backtrack_outcome("railroad-ebnf-beta\nr = \"\{"a".repeat(5000000)}\" ;\n"),
    content="rendered",
  )
  inspect(
    backtrack_outcome(
      "railroad-beta\nr = terminal(\"\{"a".repeat(5000000)}\") ;\n",
    ),
    content="rendered",
  )
}

///|
test "a single-quoted terminal of millions of characters is drawn" {
  inspect(
    backtrack_outcome("railroad-peg-beta\nr <- '\{"a".repeat(5000000)}' ;\n"),
    content="rendered",
  )
}

///|
test "a numeric value of millions of parts is drawn" {
  inspect(
    backtrack_outcome("railroad-abnf-beta\nr = %x1\{".1".repeat(4000000)} ;\n"),
    content="rendered",
  )
}

///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn length_outcome(source : String) -> String {
  try {
    let rendered = @core.render([@railroad.railroad], source, {
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
test "a special sequence with a code and tens of millions of entities is drawn as pele draws it" {
  inspect(
    length_outcome(
      "railroad-ebnf-beta\nr = ? #35;\{"&".repeat(54000000)} ? ;\n",
    ),
    content="270001561",
  )
}

///|
#skip("slow: quotes a line of 140 million characters")
test "a special sequence of 140 million tabs fails with its whole line quoted" {
  let tabs = "\t".repeat(140000000)
  let failure = try {
    @core.render(
      [@railroad.railroad],
      "railroad-ebnf-beta\nr = ? \{tabs} ? ;\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) => {
      assert_eq(
        failure.message,
        "Parse error on line 2:\nr = ? \{tabs} ? ;\n----^\nExpecting a terminal, a name, or an opening bracket but found `?`.",
      )
      "\{failure.code.to_string()}: \{failure.message.length()} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
    }
  }
  inspect(failure, content="syntax: 140000106 railroad railroadEbnf")
}
