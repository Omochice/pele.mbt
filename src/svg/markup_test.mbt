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
fn failure(run : () -> Unit raise @errors.PeleError) -> String {
  try {
    run()
    "written"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message}"
  }
}

///|
test "markup holds what is written to it" {
  let markup = @svg.Markup::new()
  inspect(markup.is_empty(), content="true")
  markup.write("<g>")
  let inner = @svg.Markup::new()
  inner.write("<rect/>")
  markup.write_markup(inner)
  markup.write("</g>")
  inspect(markup.to_string(), content="<g><rect/></g>")
  inspect(markup.length(), content="14")
}

///|
test "markup grows to V8's longest string and fails one code unit past it" {
  let markup = markup_of(@svg.MAX_STRING_LENGTH)
  inspect(markup.length(), content="536870888")
  inspect(
    failure(() => markup.write("a")),
    content="limit: Diagram is nested too deeply.",
  )
  inspect(markup.length(), content="536870888")
}

///|
test "markup longer than a doubling StringBuilder can grow to turns into a string" {
  let markup = markup_of(268435456 + 3)
  markup.write("<g>")
  let text = markup.to_string()
  inspect(text.length(), content="268435462")
  inspect(@util.slice(text, 268435456), content="aaa<g>")
}

///|
test "a document up to the port's hold limit turns into a string" {
  let document = @svg.markup_document(
    "pie",
    10,
    20,
    16,
    @types.RenderOptions::default(),
    None,
    None,
    markup_of(@svg.HOLD_LIMIT),
  )
  inspect(document.length() > @svg.HOLD_LIMIT, content="true")
  inspect(@util.slice(document, document.length() - 9), content="aaa</svg>")
}

///|
test "a document past the port's hold limit is left empty rather than failed, since it may only be measured" {
  let content = markup_of(@svg.HOLD_LIMIT + 1)
  inspect(content.length(), content="400000001")
  let document = @svg.markup_document(
    "pie",
    10,
    20,
    16,
    @types.RenderOptions::default(),
    None,
    None,
    content,
  )
  inspect(document.length(), content="0")
}

///|
test "markup fails when other markup appended to it would make it longer than V8's longest string" {
  let half = @svg.MAX_STRING_LENGTH / 2
  let markup = markup_of(half)
  inspect(
    failure(() => markup.write_markup(markup_of(half + 1))),
    content="limit: Diagram is nested too deeply.",
  )
}

///|
test "a document of markup is the document of its string" {
  let options = @types.RenderOptions::default()
  let content = "<text font-weight=\"var(--_tw)\" style=\"rx:var(--_r)\">a</text>"
  let markup = @svg.Markup::new()
  markup.write(content)
  assert_eq(
    @svg.markup_document("pie", 10, 20, 16, options, Some("t"), None, markup),
    @svg.svg_document("pie", 10, 20, 16, options, Some("t"), None, content),
  )
}

///|
test "a document fails when its start and end would make it longer than V8's longest string" {
  let content = markup_of(@svg.MAX_STRING_LENGTH - 10)
  inspect(
    failure(() => {
      @svg.markup_document(
        "pie",
        10,
        20,
        16,
        @types.RenderOptions::default(),
        None,
        None,
        content,
      )
      |> ignore
    }),
    content="limit: Diagram is nested too deeply.",
  )
}
