///|
/// An event model of `frames` time frames that all show one long data block.
fn shared_data(frames : Int32) -> String {
  let lines = Array::makei(frames, i => "tf \{i + 1} evt E [[D]]").join("\n")
  "eventmodeling\n\{lines}\ndata D {\n  f: '\{"&".repeat(94000)}'\n}\n"
}

///|
/// The outcome of rendering `source` with no source limit: the SVG's length and width, or the error.
fn outcome(source : String, max_width? : Double) -> String {
  try {
    let rendered = @core.render([@eventmodeling.eventmodeling], source, {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
      max_width,
    })
    "\{rendered.svg.length()} wide \{rendered.width}"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: draws over 300 million code units twice")
test "data drawn down past what a StringBuilder grows to is drawn as pele draws it" {
  inspect(
    outcome(shared_data(549), max_width=300),
    content="317617910 wide 300",
  )
}

///|
fn outcome_of(source : String, options : @types.RenderOptions) -> String {
  try {
    @core.render([@eventmodeling.eventmodeling], source, options) |> ignore
    "rendered"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
#skip("slow: draws over 349 million code units")
test "a frame with data drawn past what a doubling StringBuilder holds is drawn" {
  inspect(
    outcome_of("eventmodeling\ntf 01 evt E \"\{"&".repeat(60000000)}\"\n", {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
    }),
    content="rendered",
  )
}

///|
#skip("slow, and moon test runs wasm's allocator unmended, which can give a block of 512 MiB or more a smaller one; check-string-length checks it through the mended plugin")
test "a frame's entity named by 2^28 or more letters is drawn" {
  let svg = @core.render(
      [@eventmodeling.eventmodeling],
      "eventmodeling\ntf 01 evt \{"a".repeat(270000000)}\n",
      {
        ..@types.RenderOptions::default(),
        limit: Some(1.0 / 0.0),
        output_limit: Some(1.0 / 0.0),
      },
    ).svg
  inspect(svg.length(), content="270001570")
}
