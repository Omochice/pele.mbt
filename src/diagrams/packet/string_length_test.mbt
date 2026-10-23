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
