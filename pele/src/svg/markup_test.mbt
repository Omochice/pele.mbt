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
test "a document past the port's hold limit is left unheld rather than failed, since it may only be measured" {
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
  inspect(@svg.is_held_document(document), content="false")
  inspect(document.length() < 100, content="true")
  inspect(@svg.document_length(document), content="400000668")
}

///|
test "a held document is as long as the drawing it stands for" {
  let content = markup_of(1000)
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
  inspect(@svg.is_held_document(document), content="true")
  assert_eq(@svg.document_length(document), document.length())
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
test "a document of markup puts the root element and the accessible name around it" {
  let options = @types.RenderOptions::default()
  let content = "<text font-weight=\"var(--_tw)\" style=\"rx:var(--_r)\">a</text>"
  let markup = @svg.Markup::new()
  markup.write(content)
  inspect(
    @svg.markup_document("pie", 10, 20, 16, options, Some("t"), None, markup),
    content=(
      #|<svg xmlns="http://www.w3.org/2000/svg" class="pele pele-pie" viewBox="0 0 10 20" width="10" height="20" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)" role="graphics-document document" aria-roledescription="pie" aria-labelledby="pele-title"><title id="pele-title">t</title><text font-weight="var(--_tw)" style="rx:var(--_r)">a</text></svg>
    ),
  )
}

///|
test "escaped text in markup is the text esc escapes, across many pieces" {
  let text = "a&b<c>\"d\u{1}e".repeat(30000)
  let markup = @svg.Markup::new()
  markup.write_esc(text)
  assert_eq(markup.to_string(), @svg.esc(text))
  inspect(markup.length(), content="720000")
}

///|
test "escaped text in markup keeps the aliases it names across its pieces" {
  let options = @types.RenderOptions::default()
  for split in [("var(", "--_tw)"), ("var(--\u{1}_", "tw)")] {
    let (before, after) = split
    let text = "a".repeat(65536 - before.length()) + before + after
    let markup = @svg.Markup::new()
    markup.write_esc(text)
    let whole = @svg.Markup::new()
    whole.write(@svg.esc(text))
    assert_eq(
      @svg.markup_document("pie", 10, 20, 16, options, None, None, markup),
      @svg.markup_document("pie", 10, 20, 16, options, None, None, whole),
    )
  }
}

///|
test "a document of markup writes its accessible text as the document of its string" {
  let options = @types.RenderOptions::default()
  let title = "&amp; <t>".repeat(20000)
  let descr = "\"d\" & e\n".repeat(20000)
  let markup = @svg.Markup::new()
  markup.write("<g/>")
  let document = @svg.markup_document(
    "pie",
    10,
    20,
    16,
    options,
    Some(title),
    Some(descr),
    markup,
  )
  assert_true(
    document.has_suffix(
      "<title id=\"pele-title\">\{@svg.esc_text(title)}</title><desc id=\"pele-desc\">\{@svg.esc_text(descr)}</desc><g/></svg>",
    ),
  )
}

///|
test "a document whose accessible text and content pass the hold limit together is left unheld" {
  let descr = "&".repeat(20000000)
  let document = @svg.markup_document(
    "pie",
    10,
    20,
    16,
    @types.RenderOptions::default(),
    None,
    Some(descr),
    markup_of(@svg.HOLD_LIMIT - 50000000),
  )
  inspect(@svg.is_held_document(document), content="false")
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
