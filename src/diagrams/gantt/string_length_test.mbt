///|
#skip("slow: draws over 536 million code units before it fails")
test "sections drawing host icons past V8's longest string fail as nested too deeply" {
  let icon = "<path d=\"M0,0\{"H1".repeat(25000)}\"/>"
  let sections = Array::makei(10700, i => {
    "section fa:fa-big s\{i}\nts\{i} :2026-01-01, 1d"
  }).join("\n")
  let failure = try {
    @core.render(
      [@gantt.gantt],
      "gantt\ndateFormat YYYY-MM-DD\n\{sections}\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        icons: Some(name => if name == "fa:fa-big" { Some(icon) } else { None }),
      },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. gantt gantt")
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a section label drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  let icons = Array::make(5400, "fa:fa-x").join(" ")
  let failure = try {
    @core.render(
      [@gantt.gantt],
      "gantt\ndateFormat YYYY-MM-DD\nsection \{icons}\nt :2026-01-01, 1d\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        icons: Some(name => if name == "fa:fa-x" { Some(drawing) } else { None }),
      },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. gantt gantt")
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@gantt.gantt],
      "gantt\ndateFormat YYYY-MM-DD\ntitle \{"\"".repeat(90000000)}\nsection s\nt :2026-01-01, 1d\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. gantt gantt")
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title over no tasks outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render([@gantt.gantt], "gantt\ntitle \{"\"".repeat(90000000)}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. gantt gantt")
}

///|
#skip("slow: draws over 280 million code units")
test "a title over no tasks longer than a doubling StringBuilder holds is drawn whole" {
  let svg = @core.render(
      [@gantt.gantt],
      "gantt\ntitle \{"<".repeat(70000000)}\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        output_limit: Some(1.0 / 0.0),
      },
    ).svg
  inspect(svg.length(), content="280000858")
  let start = svg.find("&lt;").unwrap()
  inspect(
    svg[start:start + 280000000] == "&lt;".repeat(70000000),
    content="true",
  )
}
