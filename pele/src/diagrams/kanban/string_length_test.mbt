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

///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn outcome(source : String, options : @types.RenderOptions) -> String {
  try {
    let rendered = @core.render([@kanban.kanban], source, {
      ..options,
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
    })
    "\{rendered.svg.length()}"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a card named by tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome(
      "kanban\nc[Col]\n  \{"&".repeat(54000000)}[x]\n",
      @types.RenderOptions::default(),
    ),
    content="270001302",
  )
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "a card named by over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome(
      "kanban\nc[Col]\n  \{"&".repeat(110000000)}[x]\n",
      @types.RenderOptions::default(),
    ),
    content="limit: Diagram is nested too deeply. kanban kanban",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a column named by tens of millions of entities is drawn as pele draws it" {
  inspect(
    outcome(
      "kanban\n\{"&".repeat(54000000)}[Col]\n  k[x]\n",
      @types.RenderOptions::default(),
    ),
    content="270001302",
  )
}

///|
#skip("slow: escapes 54 million characters twice before it fails")
test "a ticket of tens of millions of entities linked fails as nested too deeply" {
  inspect(
    outcome(
      "---\nconfig:\n  kanban:\n    ticketBaseUrl: \"https://x/#TICKET#\"\n---\nkanban\nc[Col]\n  k[x]@{ ticket: \"\{"&".repeat(54000000)}\" }\n",
      @types.RenderOptions::default(),
    ),
    content="limit: Diagram is nested too deeply. kanban kanban",
  )
}

///|
/// Options under which `$$x$$` is typeset as wide as tens of millions of entities, so that a card
/// beside it holds them on one line.
fn wide_math() -> @types.RenderOptions {
  {
    ..@types.RenderOptions::default(),
    math: Some((tex, size) => {
      if tex == "x" && size == 14 {
        Some({ "svg": "<path/>", "width": 10000000000, "height": 10 })
      } else {
        None
      }
    }),
  }
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a card line of tens of millions of entities beside wide math is drawn as pele draws it" {
  inspect(
    outcome(
      "kanban\nc[Col]\n  m[$$x$$]\n  k[\{"&".repeat(54000000)}]\n",
      wide_math(),
    ),
    content="270001707",
  )
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "a card line of over a hundred million entities beside wide math fails as nested too deeply" {
  inspect(
    outcome(
      "kanban\nc[Col]\n  m[$$x$$]\n  k[\{"&".repeat(110000000)}]\n",
      wide_math(),
    ),
    content="limit: Diagram is nested too deeply. kanban kanban",
  )
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "a card icon named by tens of millions of entities is drawn as pele draws it" {
  let name = "&".repeat(54000000)
  inspect(
    outcome("kanban\nc[Col]\n  k[x]@{ icon: \"\{name}\" }\n", {
      ..@types.RenderOptions::default(),
      icons: Some(icon => if icon == name { Some("<path/>") } else { None }),
    }),
    content="270001517",
  )
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "a card icon named by over a hundred million entities fails as nested too deeply" {
  let name = "&".repeat(110000000)
  inspect(
    outcome("kanban\nc[Col]\n  k[x]@{ icon: \"\{name}\" }\n", {
      ..@types.RenderOptions::default(),
      icons: Some(icon => if icon == name { Some("<path/>") } else { None }),
    }),
    content="limit: Diagram is nested too deeply. kanban kanban",
  )
}
