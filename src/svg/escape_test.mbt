///|
fn ampersand_label(count : Int32, after : String) -> @text.Label {
  @text.layout_label(
    Some("&".repeat(count) + after),
    false,
    @text.metrics_measurer,
    16,
    200,
  )
}

///|
fn written_length(label : @text.Label) -> String {
  let out = @svg.Markup::new()
  try {
    @svg.write_label(out, label, 0, 0, "")
    out.length().to_string()
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message}"
  }
}

///|
#skip("slow: escapes 55 million characters")
test "a label escaped past what a doubling StringBuilder holds is written" {
  inspect(written_length(ampersand_label(55000000, "")), content="275000048")
}

///|
#skip("slow: escapes 55 million characters")
test "a line escaped past what a doubling StringBuilder holds is written" {
  inspect(
    written_length(ampersand_label(55000000, "<br/>a")),
    content="275000116",
  )
}

///|
#skip("slow: escapes 110 million characters before it fails")
test "a label escaped past V8's longest string fails as nested too deeply" {
  inspect(
    written_length(ampersand_label(110000000, "")),
    content="limit: Diagram is nested too deeply.",
  )
}
