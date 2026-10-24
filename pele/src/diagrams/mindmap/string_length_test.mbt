///|
/// The outcome of rendering `source` with no source or output limit under a host that draws the
/// icon `icon`: the SVG's length, or the error.
fn length_with_icon(source : String, icon : String) -> String {
  try {
    let rendered = @core.render([@mindmap.mindmap], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
      icons: Some(name => if name == icon { Some("<path/>") } else { None }),
    })
    "\{rendered.svg.length()}"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: escapes 54 million characters into over 268 million code units")
test "an icon named by tens of millions of entities is drawn as pele draws it" {
  let name = "&".repeat(54000000)
  inspect(
    length_with_icon("mindmap\nroot\n  A\n  ::icon(\{name})\n", name),
    content="270001541",
  )
}
