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
test "a font list of millions of fonts is drawn" {
  let options = @types.RenderOptions::default()
  inspect(
    pie_outcome({ ..options, font_family: Some(font_list(2000000)), }),
    content="rendered",
  )
  inspect(
    pie_outcome({ ..options, font_family_mono: Some(font_list(2000000)), }),
    content="rendered",
  )
  inspect(
    pie_outcome({ ..options, font_family: Some("Ā" + ",a".repeat(5000000)), }),
    content="rendered",
  )
  inspect(
    pie_outcome({
      ..options,
      font_family: Some("Ā,\"" + "a".repeat(9000000) + "\""),
    }),
    content="rendered",
  )
}

///|
test "a font list of millions of fonts followed by one that is not a font falls back to the generic family" {
  let style = (list : String) => {
    @svg.font_style(16, Some(list), None).has_suffix(
      "var(--pele-font,sans-serif)",
    )
  }
  inspect(style(font_list(2000000) + ";a"), content="true")
  inspect(style(font_list(2000000)), content="false")
}
