///|
/// The lines of a label with each span's text, style and width, then its size.
fn describe(label : @text.Label) -> String {
  let lines = label.lines.map(line => {
    line.map(span => "\{span.text}:\{span.style}:\{span.width}").join(" ")
  })
  lines.join(" / ") +
  " | \{label.width} x \{label.height} size \{label.size} line \{label.line_height}"
}

///|
test "title_label sets a diagram title in bold" {
  inspect(
    describe(@svg.title_label(Some("Sales"), @text.metrics_measurer, 16, 4000)),
    content="Sales:1:41.808 | 41.808 x 24 size 16 line 24",
  )
}

///|
test "title_label keeps markup and math as text, as Mermaid does" {
  inspect(
    describe(
      @svg.title_label(
        Some("A **bold** $$x^2$$ title"),
        @text.metrics_measurer,
        16,
        4000,
      ),
    ),
    content="A **bold** $$x^2$$ title:1:174.736 | 174.736 x 24 size 16 line 24",
  )
}

///|
test "title_label wraps a title wider than the room for it" {
  inspect(
    describe(
      @svg.title_label(
        Some("a title long enough to wrap across lines"),
        @text.metrics_measurer,
        18,
        120,
      ),
    ),
    content="a title long:1:90.018 / enough to:1:86.994 / wrap across:1:105.048 / lines:1:41.022 | 105.048 x 108 size 18 line 27",
  )
}

///|
test "title_label is empty without a title" {
  inspect(
    describe(@svg.title_label(Some(""), @text.metrics_measurer, 16, 4000)),
    content=" | 0 x 0 size 0 line 0",
  )
  inspect(
    describe(@svg.title_label(None, @text.metrics_measurer, 16, 4000)),
    content=" | 0 x 0 size 0 line 0",
  )
}

///|
test "with_title puts the title above the content and centers both" {
  let titled = @svg.with_title(
    Some("Sales"),
    @text.metrics_measurer,
    16,
    8,
    200,
    100,
    "<g/>",
  )
  inspect(
    "\{titled.width} x \{titled.height}\n\{titled.content}",
    content=(
      #|200 x 136
      #|<text class="pele-title" font-weight="var(--_tw)" text-anchor="middle" xml:space="preserve"><tspan x="100" y="25.6">Sales</tspan></text><g transform="translate(0,36)"><g/></g>
    ),
  )
}

///|
test "with_title widens the diagram for a title wider than its content" {
  let titled = @svg.with_title(
    Some("A very long title that is wider than the content"),
    @text.metrics_measurer,
    16,
    8,
    50.5,
    40.25,
    "<g/>",
  )
  inspect(
    "\{titled.width} x \{titled.height}\n\{titled.content}",
    content=(
      #|363 x 77
      #|<text class="pele-title" font-weight="var(--_tw)" text-anchor="middle" xml:space="preserve"><tspan x="181.5" y="25.6">A very long title that is wider than the content</tspan></text><g transform="translate(156.25,36)"><g/></g>
    ),
  )
}

///|
test "with_title leaves the content alone without a title" {
  for title in [None, Some("")] {
    let titled = @svg.with_title(
      title, @text.metrics_measurer, 16, 8, 50, 40, "<g/>",
    )
    inspect(
      "\{titled.width} x \{titled.height} \{titled.content}",
      content="50 x 40 <g/>",
    )
  }
}
