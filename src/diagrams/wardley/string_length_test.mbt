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
