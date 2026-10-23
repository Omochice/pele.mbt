///|
#skip("slow: draws over 536 million code units before it fails")
test "items drawing host icons past V8's longest string fail as nested too deeply" {
  let icon = "<path d=\"M0,0\{"H1".repeat(25000)}\"/>"
  let items = Array::makei(10700, i => "  \"fa:fa-big i\{i}\"").join("\n")
  let failure = try {
    @core.render([@cynefin.cynefin], "cynefin-beta\ncomplex\n\{items}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      icons: Some(name => if name == "fa:fa-big" { Some(icon) } else { None }),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
  inspect(
    failure,
    content="limit: Diagram is nested too deeply. cynefin cynefin",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "an item drawing a host icon in each of thousands of spans fails as nested too deeply" {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  let icons = Array::make(5400, "fa:fa-x").join(" ")
  let failure = try {
    @core.render(
      [@cynefin.cynefin],
      "cynefin-beta\ncomplex\n  \"\{icons}\"\n",
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
    content="limit: Diagram is nested too deeply. cynefin cynefin",
  )
}
