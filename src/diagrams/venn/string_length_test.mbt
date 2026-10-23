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
