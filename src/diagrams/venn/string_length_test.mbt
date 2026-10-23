///|
#skip("slow: draws over 536 million code units before it fails")
test "texts outgrowing V8's longest string fail as nested too deeply" {
  let texts = Array::makei(2180, i => "  text T\{i}[\"\{"&".repeat(50000)}\"]").join(
    "\n",
  )
  let failure = try {
    @core.render([@venn.venn], "venn-beta\nset A\n\{texts}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. venn venn")
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@venn.venn], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "a text labelled by over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome_of("venn-beta\nset A\n  text T[\"\{"&".repeat(110000000)}\"]\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. venn venn",
  )
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "a set labelled by over a hundred million entities fails as nested too deeply" {
  inspect(
    outcome_of("venn-beta\nset A[\"\{"&".repeat(110000000)}\"]\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. venn venn",
  )
}
