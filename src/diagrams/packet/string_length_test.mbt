///|
#skip("slow: draws over 536 million code units before it fails")
test "fields outgrowing V8's longest string fail as nested too deeply" {
  let fields = Array::makei(2130000, i => "\{i}: \"a\"").join("\n")
  let failure = try {
    @core.render(
      [@packet.packet],
      "---\nconfig:\n  packet:\n    bitsPerRow: 4096\n---\npacket\n\{fields}\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. packet packet")
}

///|
#skip("slow: escapes 62 million characters before it fails")
test "a field of tens of millions of entities drawn down fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@packet.packet],
      "packet\n0-31: \"\{"&".repeat(62000000)}\"\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        max_width: Some(300),
      },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. packet packet")
}

///|
/// The outcome of rendering `source` with no limit on the source or the output, or the error it fails with.
fn backtrack_outcome(source : String) -> String {
  try {
    @core.render([@packet.packet], source, {
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
#skip("slow: lexes a field of four million characters")
test "a field label fails as nested too deeply where pele's pattern runs out of V8's backtracking stack" {
  inspect(
    backtrack_outcome("packet\n0-31: \"\{"a".repeat(4194294)}\"\n"),
    content="rendered",
  )
  inspect(
    backtrack_outcome("packet\n0-31: \"\{"a".repeat(4194295)}\"\n"),
    content="limit: Diagram is nested too deeply. packet packet",
  )
}


///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@packet.packet],
      "packet\ntitle \{"\"".repeat(90000000)}\n0-31: \"a\"\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. packet packet")
}

