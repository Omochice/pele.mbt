///|
/// The outcome of rendering `source` with no limit on the source or the output, or the error it fails with.
fn backtrack_outcome(source : String) -> String {
  try {
    @core.render([@wardley.wardley], source, {
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
test "an anchor label of millions of characters is drawn" {
  inspect(
    backtrack_outcome(
      "wardley-beta\nanchor \"\{"a".repeat(5000000)}\" [0.5, 0.5]\n",
    ),
    content="rendered",
  )
}

///|
test "a component name of millions of characters is drawn" {
  inspect(
    backtrack_outcome(
      "wardley-beta\ncomponent \{"a".repeat(9000000)} [0.5, 0.5]\n",
    ),
    content="rendered",
  )
  inspect(
    backtrack_outcome(
      "wardley-beta\ncomponent a\{" a".repeat(4000000)} [0.5, 0.5]\n",
    ),
    content="rendered",
  )
}
