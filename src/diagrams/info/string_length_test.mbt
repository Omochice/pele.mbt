///|
fn options() -> @types.RenderOptions {
  { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
}

///|
fn failure_of(source : String) -> String {
  try {
    @core.render([@info.info], source, options()) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: draws over 300 million code units")
test "a title longer than a doubling StringBuilder holds is drawn" {
  let title = "&".repeat(60000000)
  let svg = @core.render([@info.info], "info\ntitle \{title}\n", options()).svg
  inspect(svg.length(), content="300000962")
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "a title outgrowing V8's longest string fails as nested too deeply" {
  let title = "\"".repeat(90000000)
  inspect(
    failure_of("info\ntitle \{title}\n"),
    content="limit: Diagram is nested too deeply. info info",
  )
}

///|
#skip("slow: draws over 300 million code units")
test "an accessible description longer than a doubling StringBuilder holds is drawn" {
  let descr = "&".repeat(60000000)
  let svg = @core.render([@info.info], "info\naccDescr: \{descr}\n", options()).svg
  inspect(svg.length(), content="300000827")
}

///|
#skip("slow: escapes over 536 million code units before it fails")
test "an accessible description outgrowing V8's longest string fails as nested too deeply" {
  let descr = "&".repeat(110000000)
  inspect(
    failure_of("info\naccDescr: \{descr}\n"),
    content="limit: Diagram is nested too deeply. info info",
  )
}

///|
#skip("slow: draws a title of 270 million characters")
test "a title of 2^28 or more plain letters is drawn" {
  let title = "a".repeat(270000000)
  let svg = @core.render([@info.info], "info\ntitle \{title}\n", options()).svg
  inspect(svg.length(), content="270000966")
}
