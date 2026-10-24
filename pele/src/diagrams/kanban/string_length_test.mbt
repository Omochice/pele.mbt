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
