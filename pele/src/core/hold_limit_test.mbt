///|
const MEBI : Int32 = 1048576

///|
/// Markup of `length` code units, made of shared pieces so that the test holds little besides the markup.
fn markup_of(length : Int32) -> @svg.Markup raise @errors.PeleError {
  let markup = @svg.Markup::new()
  let piece = "a".repeat(MEBI)
  for _ in 0..<(length / MEBI) {
    markup.write(piece)
  }
  markup.write("a".repeat(length % MEBI))
  markup
}

///|
/// A pie drawn across, and down for a narrow host, as the diagrams that turn to fit are: across
/// it is `across` code units of content and `across_width` wide, down `down` and `down_width`.
fn turning(
  across : Int32,
  across_width : Double,
  down : Int32,
  down_width : Double,
) -> @types.Diagram {
  {
    kind: "pie",
    section: None,
    keep_comments: false,
    math: false,
    parse: (_, _, _, _, _) => {
      render: (_, options) => {
        @common.turn_to_fit(options, turned => {
          let (length, width) = if turned {
            (down, down_width)
          } else {
            (across, across_width)
          }
          {
            svg: @svg.markup_document(
              "pie",
              width,
              1,
              16,
              options,
              None,
              None,
              markup_of(length),
            ),
            width,
            height: 1,
            links: [],
          }
        })
      },
    },
  }
}

///|
/// The outcome of rendering a turning pie for a host 300 wide, with no output limit unless one is
/// given: the SVG's length and width, or the error.
fn turned_outcome(
  diagram : @types.Diagram,
  output_limit~ : Double? = Some(1.0 / 0.0),
) -> String {
  try {
    let rendered = @core.render([diagram], "pie\n", {
      ..@types.RenderOptions::default(),
      output_limit,
      max_width: Some(300),
    })
    "\{rendered.svg.length()} wide \{rendered.width}"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")} \{failure.mermaid_type.unwrap_or("null")}"
  }
}

///|
test "a drawing past the hold limit that is only measured does not keep the narrower drawing from being drawn" {
  inspect(
    turned_outcome(turning(@svg.HOLD_LIMIT + 1, 900, 1000, 300)),
    content="1667 wide 300",
  )
}

///|
test "a drawing past the hold limit that is only measured does not keep the next drawing from failing as nested too deeply" {
  inspect(
    turned_outcome(
      turning(@svg.HOLD_LIMIT + 1, 900, @svg.MAX_STRING_LENGTH, 300),
    ),
    content="limit: Diagram is nested too deeply. pie pie",
  )
}

///|
test "a drawing past the hold limit that is answered with fails with the port's limit" {
  inspect(
    turned_outcome(turning(@svg.HOLD_LIMIT + 1, 900, 1000, 950)),
    content="limit: Diagram output is too large for the wasm port: it would hold more than 400000000 code units, the most the port can hold at once. pie pie",
  )
}

///|
test "a drawing past the hold limit that is answered with fails with pele's output limit under the default output limit" {
  inspect(
    turned_outcome(
      turning(@svg.HOLD_LIMIT + 1, 900, 1000, 950),
      output_limit=None,
    ),
    content="limit: Diagram output is longer than the limit of 4000000 characters. pie pie",
  )
}

///|
test "a drawing past the hold limit that is answered with fails with pele's output limit under any output limit below its length" {
  inspect(
    turned_outcome(
      turning(@svg.HOLD_LIMIT + 1, 900, 1000, 950),
      output_limit=Some(@svg.HOLD_LIMIT.to_double()),
    ),
    content="limit: Diagram output is longer than the limit of 400000000 characters. pie pie",
  )
}

///|
test "a drawing past the hold limit that an output limit allows fails with the port's limit" {
  inspect(
    turned_outcome(
      turning(@svg.HOLD_LIMIT + 1, 900, 1000, 950),
      output_limit=Some(@svg.MAX_STRING_LENGTH.to_double()),
    ),
    content="limit: Diagram output is too large for the wasm port: it would hold more than 400000000 code units, the most the port can hold at once. pie pie",
  )
}
