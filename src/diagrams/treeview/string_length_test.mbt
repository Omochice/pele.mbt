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

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@treeview.treeview], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "an entry named by tens of millions of entities fails as nested too deeply" {
  inspect(
    outcome_of("treeView-beta\n  \"\{"&".repeat(54000000)}\"\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. treeView treeView",
  )
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "an entry described by over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome_of("treeView-beta\n  a \"\{"&".repeat(110000000)}\"\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. treeView treeView",
  )
}
