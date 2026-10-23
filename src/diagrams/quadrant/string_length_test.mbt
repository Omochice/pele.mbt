///|
#skip("slow: draws over 536 million code units before it fails")
test "points outgrowing V8's longest string fail as nested too deeply" {
  let points = Array::makei(1100, i => "P\{i}\{"&".repeat(50000)}: [0.5, 0.5]").join(
    "\n",
  )
  let failure = try {
    @core.render([@quadrant.quadrant], "quadrantChart\n\{points}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. quadrantChart quadrantChart",
  )
}
