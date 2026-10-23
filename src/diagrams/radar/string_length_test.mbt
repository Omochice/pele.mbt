///|
#skip("slow: draws over 536 million code units before it fails")
test "graticule rings outgrowing V8's longest string fail as nested too deeply" {
  let axes = Array::makei(1050000, i => "a\{i}").join(", ")
  let failure = try {
    @core.render(
      [@radar.radar],
      "radar-beta\ngraticule polygon\nticks 32\naxis \{axes}\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    )
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(failure, content="limit: Diagram is nested too deeply. radar radar")
}
