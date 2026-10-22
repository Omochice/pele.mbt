///|
/// Renders `source` with the host's size limit lifted, and returns the SVG or the error message.
fn big(source : String) -> String {
  let options = {
    ..@types.RenderOptions::default(),
    limit: Some(1.0e12),
    output_limit: Some(1.0e12),
  }
  (@core.render([@kanban.kanban], source, options) catch {
    @errors.PeleError(failure) => return "error: " + failure.message
  }).svg
}

///|
test "many cards in one column are drawn" {
  let out = big("kanban\ntodo\n" + " a\n".repeat(16000))
  assert_true(count(out, "class=\"pele-node pele-card\"") == 16000)
}

///|
test "many columns are drawn" {
  let out = big("kanban\n" + "a\n".repeat(16000))
  inspect(count(out, "pele-cluster pele-column"), content="16000")
}

///|
test "a misplaced card after many cards is reported" {
  inspect(
    big("kanban\n todo\n" + "  a\n".repeat(16000) + "b\nc\n"),
    content="error: Items without section detected, found section (\"b\")",
  )
}

///|
test "metadata with many keys is read" {
  let keys = StringBuilder()
  for i in 0..<7000 {
    keys.write_string("k\{i}: 1, ")
  }
  let out = big("kanban\ntodo\n a@{ " + keys.to_string() + "label: x }")
  assert_true(has(out, ">x</text>"))
}

///|
test "deeply bracketed metadata is an error and not a crash" {
  let out = big("kanban\ntodo\n a@{ a: " + "[".repeat(20000) + " }\n")
  assert_true(out.has_prefix("error: ") || has(out, "<svg"))
}

///|
test "a ticket of many characters is drawn" {
  let out = big("kanban\ntodo\n a@{ ticket: \"" + "T".repeat(50000) + "\" }")
  assert_true(has(out, "pele-ticket"))
}
