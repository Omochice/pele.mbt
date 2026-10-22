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
