///|
fn failure_of(text : String) -> String {
  try {
    @core.render([], text, @types.RenderOptions::default()) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
test "text that names no diagram is rejected as unsupported" {
  inspect(
    failure_of("should handle simple pie"),
    content="unsupported-diagram: No diagram type detected for the given text. null null",
  )
}

///|
test "text longer than the limit is rejected before detection" {
  let options = { ..@types.RenderOptions::default(), limit: Some(3), }
  inspect(
    try {
      @core.render([], "pie\n", options) |> ignore
      "rendered"
    } catch {
      @errors.PeleError(failure) =>
        "\{failure.code.to_string()}: \{failure.message}"
    },
    content="limit: Diagram source is longer than the limit of 3 characters.",
  )
}

///|
fn pie_failure(text : String) -> String {
  try {
    @core.render([@pie.pie], text, @types.RenderOptions::default()) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
test "a pie with a negative value is a semantic error of type pie" {
  inspect(
    pie_failure(
      "pie title Default text position: Animal adoption\n        accTitle: simple pie char demo\n        accDescr: pie chart with 3 sections: dogs, cats, rats. Most are dogs.\n         \"dogs\" : -60.67\n        \"rats\" : 40.12\n    ",
    ),
    content="semantic: \"dogs\" has invalid value: -60.67. Negative values are not allowed in pie charts. All slice values must be >= 0. pie pie",
  )
}

///|
test "a syntax error is tagged with the detected type" {
  inspect(
    pie_failure("pie\n\"a\" 1"),
    content="syntax: Parse error on line 2:\n\"a\" 1\n----^\nExpecting token of type ':' but found `1`. pie pie",
  )
}

///|
test "a type that is not registered is unsupported" {
  inspect(
    pie_failure("graph TD"),
    content="unsupported-diagram: Diagram type \"flowchart\" is not supported yet. flowchart flowchart-v2",
  )
}
