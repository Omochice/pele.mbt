///|
#skip("slow: draws over 536 million code units before it fails")
test "anchors outgrowing V8's longest string fail as nested too deeply" {
  let fragment = "<path d=\"M\{"1".repeat(50000)}\"/>"
  let anchors = Array::makei(10700, i => "anchor \"fa:fa-a \{i}\" [0.5, 0.5]").join(
    "\n",
  )
  let failure = try {
    @core.render([@wardley.wardley], "wardley-beta\n\{anchors}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      icons: Some(name => if name == "fa:fa-a" { Some(fragment) } else { None }),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. wardley wardley",
  )
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@wardley.wardley], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
/// Options under which the host draws the icon `fa:fa-x` as a path of 100 thousand code units,
/// with no limit on the source.
fn label_icon_options() -> @types.RenderOptions {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  {
    ..@types.RenderOptions::default(),
    limit: Some(1.0 / 0.0),
    icons: Some(name => if name == "fa:fa-x" { Some(drawing) } else { None }),
  }
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "an anchor label drawing a host icon in each of thousands of spans fails as nested too deeply" {
  inspect(
    outcome_of(
      "wardley-beta\nanchor \"\{Array::make(5400, "fa:fa-x").join(" ")}\" [0.5, 0.5]\n",
      label_icon_options(),
    ),
    content="limit: Diagram is nested too deeply. wardley wardley",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a link label drawing a host icon in each of thousands of spans fails as nested too deeply" {
  inspect(
    outcome_of(
      "wardley-beta\ncomponent A [0.2, 0.2]\ncomponent B [0.8, 0.8]\nA->B; \{Array::make(5400, "fa:fa-x").join(" ")}\n",
      label_icon_options(),
    ),
    content="limit: Diagram is nested too deeply. wardley wardley",
  )
}

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
#skip("slow: draws an anchor label of four million characters")
test "an anchor label fails as nested too deeply where pele's pattern runs out of V8's backtracking stack" {
  inspect(
    backtrack_outcome(
      "wardley-beta\nanchor \"\{"a".repeat(4194294)}\" [0.5, 0.5]\n",
    ),
    content="rendered",
  )
  inspect(
    backtrack_outcome(
      "wardley-beta\nanchor \"\{"a".repeat(4194295)}\" [0.5, 0.5]\n",
    ),
    content="limit: Diagram is nested too deeply. wardley wardley",
  )
}

///|
#skip("slow: draws a component name of eight million characters")
test "a component name fails as nested too deeply where pele's pattern runs out of V8's backtracking stack" {
  inspect(
    backtrack_outcome(
      "wardley-beta\ncomponent \{"a".repeat(8388590)} [0.5, 0.5]\n",
    ),
    content="rendered",
  )
  inspect(
    backtrack_outcome(
      "wardley-beta\ncomponent \{"a".repeat(8388591)} [0.5, 0.5]\n",
    ),
    content="limit: Diagram is nested too deeply. wardley wardley",
  )
  inspect(
    backtrack_outcome(
      "wardley-beta\ncomponent a\{" a".repeat(3355435)} [0.5, 0.5]\n",
    ),
    content="rendered",
  )
  inspect(
    backtrack_outcome(
      "wardley-beta\ncomponent a\{" a".repeat(3355436)} [0.5, 0.5]\n",
    ),
    content="limit: Diagram is nested too deeply. wardley wardley",
  )
}
