///|
#skip("slow: draws over 536 million code units before it fails")
test "services drawing host icons past V8's longest string fail as nested too deeply" {
  let icon = "<path d=\"M0,0\{"H1".repeat(25000)}\"/>"
  let services = Array::makei(10700, i => "service s\{i}(big)[x]").join("\n")
  let failure = try {
    @core.render(
      [@architecture.architecture],
      "architecture-beta\n\{services}\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        icons: Some(name => if name == "big" { Some(icon) } else { None }),
      },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. architecture architecture",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a service label drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  let icons = Array::make(5400, "fa:fa-x").join(" ")
  let failure = try {
    @core.render(
      [@architecture.architecture],
      "architecture-beta\nservice s(server)[\{icons}]\n",
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
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. architecture architecture",
  )
}

///|
/// The outcome of rendering `source` with no limit on the source or the output, or the error it fails with.
fn backtrack_outcome(source : String) -> String {
  try {
    @core.render([@architecture.architecture], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) => {
      let detail = if failure.code is Limit {
        failure.message
      } else {
        "line \{failure.line}"
      }
      "\{failure.code.to_string()}: \{detail} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
    }
  }
}

///|
test "a string of millions of characters the grammar has no place for is a syntax error" {
  inspect(
    backtrack_outcome("architecture-beta\n\"\{"a".repeat(5000000)}\"\n"),
    content="syntax: line 2 architecture architecture",
  )
}

///|
test "a quoted service label of millions of characters is drawn" {
  inspect(
    backtrack_outcome(
      "architecture-beta\nservice s(server)[\"\{"a".repeat(5000000)}\"]\n",
    ),
    content="rendered",
  )
}

///|
test "a quoted service label of millions of characters not closed by its bracket is drawn" {
  inspect(
    backtrack_outcome(
      "architecture-beta\nservice s(server)[\"\{"a".repeat(5000000)}\"x]\n",
    ),
    content="rendered",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@architecture.architecture],
      "architecture-beta\ntitle \{"\"".repeat(90000000)}\nservice s(server)[x]\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. architecture architecture",
  )
}
