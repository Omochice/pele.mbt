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

///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn outcome(source : String, now? : Double) -> String {
  try {
    let rendered = @core.render([@gantt.gantt], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
      now,
    })
    rendered.svg.length().to_string()
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: draws over 270 million code units")
test "a task id escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    outcome(
      "gantt\ndateFormat YYYY-MM-DD\nsection s\nt :\{"&".repeat(54000000)}, 2026-01-01, 1d\n",
    ),
    content="270001671",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a vertical marker id escaped twice past V8's longest string fails as nested too deeply" {
  inspect(
    outcome(
      "gantt\ndateFormat YYYY-MM-DD\nsection s\nt :2026-01-01, 3d\nv :vert, \{"&".repeat(54000000)}, 2026-01-02, 0d\n",
    ),
    content="limit: Diagram is nested too deeply. gantt gantt",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a section escaped twice past V8's longest string fails as nested too deeply" {
  inspect(
    outcome(
      "gantt\ndateFormat YYYY-MM-DD\nsection \{"&".repeat(54000000)}\nt :2026-01-01, 1d\n",
    ),
    content="limit: Diagram is nested too deeply. gantt gantt",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "an axis format escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    outcome(
      "gantt\ndateFormat YYYY-MM-DD\naxisFormat \{"&".repeat(54000000)}\nsection s\nt :2026-01-01, 1d\n",
    ),
    content="270001579",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "an axis format escaped on both axes past V8's longest string fails as nested too deeply" {
  inspect(
    outcome(
      "gantt\ndateFormat YYYY-MM-DD\naxisFormat \{"&".repeat(54000000)}\ntopAxis\nsection s\nt :2026-01-01, 1d\n",
    ),
    content="limit: Diagram is nested too deeply. gantt gantt",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "a today marker style escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    outcome(
      "gantt\ndateFormat YYYY-MM-DD\ntodayMarker stroke:\{"&".repeat(54000000)}\nsection s\nt :2026-01-01, 3d\n",
      now=1767312000000,
    ),
    content="270001895",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "a task link escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    outcome(
      "gantt\ndateFormat YYYY-MM-DD\nsection s\nt :a, 2026-01-01, 1d\nclick a href \"\{"&".repeat(54000000)}\"\n",
    ),
    content="270001717",
  )
}

///|
#skip("slow: formats over 270 million code units")
test "an axis label formatted past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    outcome(
      "gantt\ndateFormat YYYY-MM-DD\naxisFormat \{"%c".repeat(13000000)}\nsection s\nt :2026-01-01, 1d\n",
    ),
    content="273001582",
  )
}

///|
#skip("slow: formats over 536 million code units before it fails")
test "an axis label formatted past V8's longest string fails as nested too deeply" {
  inspect(
    outcome(
      "gantt\ndateFormat YYYY-MM-DD\naxisFormat \{"%c".repeat(30000000)}\nsection s\nt :2026-01-01, 1d\n",
    ),
    content="limit: Diagram is nested too deeply. gantt gantt",
  )
}
