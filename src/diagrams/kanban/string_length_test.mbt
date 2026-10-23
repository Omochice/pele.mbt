///|
#skip("slow: draws over 536 million code units before it fails")
test "cards outgrowing V8's longest string fail as nested too deeply" {
  let markup = "<path d=\"\{"M0 0".repeat(12500)}\"/>"
  let cards = Array::makei(10700, i => "  k\{i}[fa:fa-a]").join("\n")
  let failure = try {
    @core.render([@kanban.kanban], "kanban\nc[Col]\n\{cards}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      icons: Some(name => if name == "fa:fa-a" { Some(markup) } else { None }),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. kanban kanban")
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a card line drawing host math in each of thousands of spans fails as nested too deeply" {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  let maths = "$$x$$".repeat(5400)
  let failure = try {
    @core.render([@kanban.kanban], "kanban\nc[Col]\n  k[\{maths}]\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      math: Some((tex, size) => {
        if tex == "x" && size == 14 {
          Some({ "svg": drawing, "width": 0.001, "height": 10 })
        } else {
          None
        }
      }),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. kanban kanban")
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a front matter title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@kanban.kanban],
      "---\ntitle: x\{"\"".repeat(90000000)}\n---\nkanban\nc[Col]\n  k[x]\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. kanban kanban")
}
