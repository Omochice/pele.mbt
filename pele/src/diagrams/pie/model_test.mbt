///|
fn model(source : String) -> String {
  let built = @pie.build_pie(@pie.parse_pie(source + "\n"), Some("front")) catch {
    @errors.PeleError(failure) =>
      return "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")}"
  }
  let sections = built.sections.map(s => "\{s.0}:\{s.1}")
  "title=\{built.title.unwrap_or("-")} sections=\{sections.join(",")}"
}

///|
test "a negative value is rejected" {
  inspect(
    model("pie\n        \"ash\" : -60.67\n        \"bat\" : 40.12\n"),
    content="semantic: \"ash\" has invalid value: -60.67. Negative values are not allowed in pie charts. All slice values must be >= 0. pie",
  )
}

///|
test "negative zero is not negative" {
  inspect(model("pie\n\"a\":-0"), content="title=front sections=a:0")
}

///|
test "a repeated label keeps its first value" {
  inspect(model("pie\n\"a\":1\n\"a\":2"), content="title=front sections=a:1")
}

///|
test "the chart's own title wins over the front matter title" {
  inspect(model("pie title own\n\"a\":1"), content="title=own sections=a:1")
}
