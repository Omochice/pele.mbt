///|
fn failure_of(text : String) -> String {
  try {
    @core.render(text, @types.RenderOptions::default()) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind} \{failure.mermaid_type}"
  }
}

///|
test "text that names no diagram is rejected as unsupported" {
  inspect(
    failure_of("should handle simple pie"),
    content="unsupported-diagram: No diagram type detected for the given text. None None",
  )
}

///|
test "text longer than the limit is rejected before detection" {
  let options = { ..@types.RenderOptions::default(), limit: Some(3), }
  inspect(
    try {
      @core.render("pie\n", options) |> ignore
      "rendered"
    } catch {
      @errors.PeleError(failure) =>
        "\{failure.code.to_string()}: \{failure.message}"
    },
    content="limit: Diagram source is longer than the limit of 3 characters.",
  )
}
