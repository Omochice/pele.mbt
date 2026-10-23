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
fn document_of(content : @svg.Markup) -> String raise @errors.PeleError {
  @svg.markup_document(
    "pie",
    10,
    20,
    16,
    @types.RenderOptions::default(),
    None,
    None,
    content,
  )
}

///|
test "text escaped in pieces is written as it is escaped whole, with the aliases it names" {
  let text = "&".repeat(1048572) + "var(--_w)" + "<\u{1}\"".repeat(400000)
  let whole = @svg.Markup::new()
  whole.write(@svg.esc(text))
  let pieces = @svg.Markup::new()
  @svg.write_esc(pieces, text)
  let document = document_of(pieces)
  inspect(document == document_of(whole), content="true")
  inspect(document.contains("--_w:"), content="true")
}

///|
test "text escaped in pieces keeps a heading weight alias whole" {
  let text = "&".repeat(1048568) + "var(--_hw)" + "<\u{1}\"".repeat(400000)
  let whole = @svg.Markup::new()
  whole.write(@svg.esc(text))
  let pieces = @svg.Markup::new()
  @svg.write_esc(pieces, text)
  let document = document_of(pieces)
  inspect(document == document_of(whole), content="true")
  inspect(document.contains("--_hw:"), content="true")
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

///|
test "a data-id is written as an escaped attribute" {
  let out = @svg.Markup::new()
  @svg.write_data_id(out, "a&amp;<b>")
  inspect(out.to_string(), content=" data-id=\"a&amp;&lt;b&gt;\"")
}
