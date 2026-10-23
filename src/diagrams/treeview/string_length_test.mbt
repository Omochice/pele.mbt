///|
#skip("slow: draws over 536 million code units before it fails")
test "icons outgrowing V8's longest string fail as nested too deeply" {
  let fragment = "<path d=\"M\{"1".repeat(50000)}\"/>"
  let rows = Array::makei(10700, i => "  f\{i} icon(x:a)").join("\n")
  let failure = try {
    @core.render([@treeview.treeview], "treeView-beta\n\{rows}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      icons: Some(name => if name == "x:a" { Some(fragment) } else { None }),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. treeView treeView",
  )
}
