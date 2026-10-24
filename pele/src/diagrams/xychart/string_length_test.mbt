///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@xychart.xychart], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: draws over 300 million code units")
test "a category drawn past what a doubling StringBuilder holds is drawn" {
  inspect(
    outcome_of("xychart\nx-axis [\"\{"&".repeat(60000000)}\"]\nbar [1]\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
    }),
    content="rendered",
  )
}

///|
#skip("slow, and moon test runs wasm's allocator unmended, which can give a block of 512 MiB or more a smaller one; check-string-length checks it through the mended plugin")
test "a category of 2^28 or more letters is drawn" {
  let svg = @core.render(
      [@xychart.xychart],
      "xychart\nx-axis [\{"a".repeat(270000000)}]\nbar [1]\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        output_limit: Some(1.0 / 0.0),
      },
    ).svg
  inspect(svg.length(), content="270001610")
}
