///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@quadrant.quadrant], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: lexes 110 million tokens before it fails")
test "a point color followed by 110 million - fails on the color alone" {
  inspect(
    outcome_of(
      "quadrantChart\nP: [0.5, 0.5] color: x:\{"-".repeat(110000000)}\n",
      { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), },
    ),
    content="semantic: value for color x is invalid, please use a valid hex code quadrantChart quadrantChart",
  )
}
