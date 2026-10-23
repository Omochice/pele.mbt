///|
fn failure_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@flowchart.flowchart], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
fn names(prefix : String, count : Int32) -> Array[String] {
  Array::makei(count, i => "\{prefix}\{i}")
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "edges outgrowing V8's longest string fail as nested too deeply under the default options" {
  let stroke = "a".repeat(49000)
  let left = names("a", 60).join(" & ")
  let right = names("b", 61).join(" & ")
  inspect(
    failure_of(
      "graph TD\nlinkStyle default stroke:#\{stroke}\n\{left} <--> \{right}\n",
      @types.RenderOptions::default(),
    ),
    content="limit: Diagram is nested too deeply. flowchart flowchart-v2",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "nodes outgrowing V8's longest string fail as nested too deeply" {
  let fill = "a".repeat(50000)
  let nodes = names("n", 10700).map(name => name + ":::c").join(";")
  inspect(
    failure_of("graph TD\nclassDef c fill:#\{fill}\n\{nodes}\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
    }),
    content="limit: Diagram is nested too deeply. flowchart flowchart-v2",
  )
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "nodes and edges that outgrow V8's longest string only together fail as nested too deeply" {
  let style = "a".repeat(50000)
  inspect(
    failure_of(
      "graph TD\nclassDef default fill:#\{style}\nlinkStyle default stroke:#\{style}\n\{names("n", 3600).join("-->")}\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    ),
    content="limit: Diagram is nested too deeply. flowchart flowchart-v2",
  )
}

///|
/// Options under which the host draws the icon `fa:fa-x` as a path of 100 thousand code units,
/// with no limit on the source or the output.
fn icon_options() -> @types.RenderOptions {
  let drawing = "<path d=\"\{"M0 0".repeat(25000)}\"/>"
  {
    ..@types.RenderOptions::default(),
    limit: Some(1.0 / 0.0),
    output_limit: Some(1.0 / 0.0),
    icons: Some(name => if name == "fa:fa-x" { Some(drawing) } else { None }),
  }
}

///|
fn icon_label(count : Int32) -> String {
  "graph TD\nA[\"\{Array::make(count, "fa:fa-x").join(" ")}\"]\n"
}

///|
#skip("slow: draws over 536 million code units before it fails")
test "a node label drawing a host icon in each of thousands of spans fails as nested too deeply" {
  inspect(
    failure_of(icon_label(5400), icon_options()),
    content="limit: Diagram is nested too deeply. flowchart flowchart-v2",
  )
}

///|
#skip("slow: draws over 300 million code units")
test "a node label longer than a doubling StringBuilder holds is drawn" {
  let svg = @core.render(
      [@flowchart.flowchart],
      icon_label(3000),
      icon_options(),
    ).svg
  inspect(svg.length(), content="300835316")
}
