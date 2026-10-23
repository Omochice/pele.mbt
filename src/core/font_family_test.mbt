///|
/// The outcome of rendering a pie with `options` and no limit on the output, or the error it fails with.
fn pie_outcome(options : @types.RenderOptions) -> String {
  try {
    @core.render([@pie.pie], "pie\n\"a\": 1\n", {
      ..options,
      output_limit: Some(1.0 / 0.0),
    })
    |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
/// A list of `count` fonts after the first, each one letter long.
fn font_list(count : Int32) -> String {
  "a" + ",a".repeat(count)
}

///|
test "a font list fails as nested too deeply where pele's pattern runs out of V8's backtracking stack" {
  let options = @types.RenderOptions::default()
  inspect(
    pie_outcome({ ..options, font_family: Some(font_list(1525197)), }),
    content="rendered",
  )
  inspect(
    pie_outcome({ ..options, font_family: Some(font_list(1525198)), }),
    content="limit: Diagram is nested too deeply. pie pie",
  )
  inspect(
    pie_outcome({ ..options, font_family_mono: Some(font_list(1525197)), }),
    content="rendered",
  )
  inspect(
    pie_outcome({ ..options, font_family_mono: Some(font_list(1525198)), }),
    content="limit: Diagram is nested too deeply. pie pie",
  )
}

///|
test "a font list counts the fonts read before one that is not a font against V8's backtracking stack" {
  let options = @types.RenderOptions::default()
  inspect(
    pie_outcome({ ..options, font_family: Some(font_list(1525197) + ";a"), }),
    content="rendered",
  )
  inspect(
    pie_outcome({
      ..options,
      font_family: Some(font_list(1525198) + ";" + font_list(9)),
    }),
    content="limit: Diagram is nested too deeply. pie pie",
  )
  inspect(
    pie_outcome({
      ..options,
      font_family: Some("\"a\"" + ", 'b c'".repeat(1525198)),
    }),
    content="limit: Diagram is nested too deeply. pie pie",
  )
}
