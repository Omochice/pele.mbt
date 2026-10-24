///|
#skip("slow: draws over 536 million code units before it fails")
test "agents outgrowing V8's longest string fail as nested too deeply" {
  let fill = "a".repeat(50000)
  let items = Array::makei(10700, i => "a\{i}:::c").join("\n")
  let failure = try {
    @core.render(
      [@agentflow.agentflow],
      "agentflow-beta TB\nclassDef c fill:#\{fill}\n\{items}\n",
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
    content="limit: Diagram is nested too deeply. agentflow agentflow",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "an agent label drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  let icons = Array::make(5400, "fa:fa-x").join(" ")
  let failure = try {
    @core.render(
      [@agentflow.agentflow],
      "agentflow-beta TB\n  a[\"\{icons}\"]\n",
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
    content="limit: Diagram is nested too deeply. agentflow agentflow",
  )
}

///|
/// The outcome of rendering `source` with no limit on the source, or the error it fails with.
fn backtrack_outcome(source : String) -> String {
  try {
    @core.render([@agentflow.agentflow], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
test "millions of line breaks after the keyword are skipped" {
  inspect(
    backtrack_outcome("agentflow-beta\{"\n".repeat(9000000)}a\n"),
    content="rendered",
  )
  inspect(
    backtrack_outcome("agentflow-beta\{"\n".repeat(9000000)} \na\n"),
    content="rendered",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a front matter title outgrowing V8's longest string fails as nested too deeply" {
  let failure = try {
    @core.render(
      [@agentflow.agentflow],
      "---\ntitle: x\{"\"".repeat(90000000)}\n---\nagentflow-beta TB\n  a\n",
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
    content="limit: Diagram is nested too deeply. agentflow agentflow",
  )
}

///|
/// The outcome of rendering `source` with no source or output limit: the SVG's length, or the error.
fn drawn_or_failed(source : String) -> String {
  try {
    let rendered = @core.render([@agentflow.agentflow], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
    })
    rendered.svg.length().to_string()
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: draws over 270 million code units")
test "a tooltip escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "agentflow-beta TB\n  a\n  click a callback \"\{"&".repeat(54000000)}\"\n",
    ),
    content="270001049",
  )
}

///|
#skip("slow: draws over 270 million code units")
test "a link escaped past what a doubling StringBuilder holds is drawn as pele draws it" {
  inspect(
    drawn_or_failed(
      "agentflow-beta TB\n  a\n  click a href \"\{"&".repeat(54000000)}\"\n",
    ),
    content="270001064",
  )
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "an internal link escaped past V8's longest string fails as nested too deeply" {
  inspect(
    drawn_or_failed(
      "agentflow-beta TB\n  a[\"\{"&".repeat(54000000)}\"]\n  class a internal-link\n",
    ),
    content="limit: Diagram is nested too deeply. agentflow agentflow",
  )
}

///|
/// The outcome of rendering `source` with no source limit, with an error's message cut to its
/// length unless it is the limit error.
fn token_outcome(source : String) -> String {
  try {
    @core.render([@agentflow.agentflow], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) => {
      let message = if failure.code is Limit {
        failure.message
      } else {
        failure.message.length().to_string()
      }
      "\{failure.code.to_string()}: \{message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
    }
  }
}

///|
#skip("slow: lexes 33 million tokens")
test "a style of more than 2^25 tokens is lexed to its end" {
  inspect(
    token_outcome(
      "agentflow-beta TB\n  a\nstyle a fill:\{"&".repeat(33554417)}\n",
    ),
    content=(
      #|syntax: 33554525 agentflow agentflow
    ),
  )
  inspect(
    token_outcome(
      "agentflow-beta TB\n  a\nlinkStyle 0 stroke:\{"&".repeat(33554417)}\n",
    ),
    content=(
      #|semantic: 162 agentflow agentflow
    ),
  )
}

///|
#skip("slow, and moon test runs wasm's allocator unmended, which can give a block of 512 MiB or more a smaller one; check-string-length checks it through the mended plugin")
test "an agent named by 2^28 or more letters, written twice, fails as nested too deeply" {
  inspect(
    token_outcome("agentflow-beta TB\n  \{"a".repeat(270000000)}\n"),
    content="limit: Diagram is nested too deeply. agentflow agentflow",
  )
}
