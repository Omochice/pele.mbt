///|
const BASE : String = "---\nconfig:\n  kanban:\n    ticketBaseUrl: 'https://example.com/browse/#TICKET#'\n---\n"

///|
fn render(
  source : String,
  max_width? : Double,
) -> @types.RenderResult raise @errors.PeleError {
  let options = { ..@types.RenderOptions::default(), max_width, }
  @core.render([@kanban.kanban], source, options)
}

///|
fn svg(source : String, max_width? : Double) -> String {
  (render(source, max_width?) catch {
    @errors.PeleError(failure) => return failure.message
  }).svg
}

///|
fn count(text : String, part : String) -> Int32 {
  let mut n = 0
  let mut at = @util.index_of(text, part)
  while at != -1 {
    n += 1
    at = @util.index_of(text, part, from=at + part.length())
  }
  n
}

///|
fn has(text : String, part : String) -> Bool {
  text.contains(part)
}

///|
test "a column is drawn for each section and a card for each item, with counts" {
  let out = svg(
    "kanban\n  todo[To do]\n    a[First]\n    b[Second]\n  done[Done]\n    c[Third]\n  later[Later]",
  )
  inspect(count(out, "class=\"pele-cluster pele-column\""), content="3")
  inspect(count(out, "class=\"pele-node pele-card\""), content="3")
  for text in ["To do", "First", "Second", "Done", "Third", "Later"] {
    assert_true(has(out, ">\{text}</text>"))
  }
  inspect(has(out, "class=\"pele-count\" x=\"188\""), content="true")
  assert_true(
    has(out, "text-anchor=\"end\" font-size=\"14\" fill=\"var(--_m)\">2</text>"),
  )
  assert_true(has(out, "fill=\"var(--_m)\">1</text>"))
  assert_true(has(out, "fill=\"var(--_m)\">0</text>"))
  assert_true(has(out, "data-id=\"todo\""))
  assert_true(has(out, "data-id=\"a\""))
}

///|
test "every column is as wide as the others and as tall as the tallest" {
  let out = svg("kanban\n  a\n    one\n    two\n    three\n  b\n    four\n  c")
  inspect(count(out, "<rect width=\"200\" height=\"187\""), content="3")
  let wide = render(
    "---\nconfig:\n  kanban:\n    sectionWidth: 320\n---\nkanban\n  a\n    one\n  b",
  )
  assert_true(has(wide.svg, "<rect width=\"320\""))
  assert_true(wide.width > 640)
}

///|
test "the ticket and the assignee are shown without a link by default" {
  let out = svg(
    "kanban\n  todo\n    a[Task]@{ ticket: MC-1, assigned: 'knsv' }",
  )
  assert_true(has(out, "class=\"pele-ticket\" fill=\"var(--_m)\""))
  assert_true(has(out, ">MC-1</text>"))
  assert_true(has(out, "class=\"pele-assigned\" fill=\"var(--_m)\""))
  assert_true(has(out, "text-anchor=\"end\">knsv</text>"))
  assert_false(has(out, "<a "))
}

///|
test "a ticket links through ticketBaseUrl" {
  let result = render(
    BASE +
    "kanban\n  todo\n    a[Task]@{ ticket: MC-1 }\n    b[Other]@{ ticket: \"$&\" }",
  )
  assert_true(
    has(
      result.svg,
      "<a href=\"https://example.com/browse/MC-1\" target=\"_blank\" rel=\"noopener\">",
    ),
  )
  inspect(
    result.links
    .map(link => "\{link.id} \{link.href} \{link.internal}")
    .join(" | "),
    content="a https://example.com/browse/MC-1 false | b https://example.com/browse/$& false",
  )
}

///|
test "a ticket link that is not a safe URL is dropped" {
  let unsafe_base = render(
    "---\nconfig:\n  kanban:\n    ticketBaseUrl: 'javascript:alert(#TICKET#)'\n---\nkanban\n  todo\n    a[Task]@{ ticket: MC-1 }",
  )
  assert_false(has(unsafe_base.svg, "<a "))
  assert_true(has(unsafe_base.svg, ">MC-1<"))
  inspect(unsafe_base.links.length(), content="0")
  let whole = svg(
    "---\nconfig:\n  kanban:\n    ticketBaseUrl: '#TICKET#'\n---\nkanban\n  todo\n    a[Task]@{ ticket: 'javascript:alert(1)' }",
  )
  assert_false(has(whole, "<a "))
}

///|
test "priority marks a card with a colored edge" {
  let out = svg(
    "kanban\n  todo\n    a[A]@{ priority: 'Very High' }\n    b[B]@{ priority: High }\n    c[C]@{ priority: Medium }\n    d[D]@{ priority: 'Low' }\n    e[E]@{ priority: 'Very Low' }\n    f[F]@{ priority: high }\n    g[G]@{ priority: whenever }",
  )
  let red = "stroke=\"var(--pele-critical,#e45756)\""
  let grey = "stroke=\"var(--_m)\""
  let faint = " opacity=\"0.5\""
  let edges = ["a", "b", "c", "d", "e", "f", "g"].map(id => {
    let from = @util.index_of(out, "data-id=\"\{id}\"")
    let card = @util.slice(out, from, end=@util.index_of(out, "</g>", from~))
    let edge = @util.index_of(card, "<path class=\"pele-priority\"")
    if edge == -1 {
      "-"
    } else {
      let start = @util.index_of(card, "fill=\"none\" ", from=edge) + 12
      @util.slice(
        card,
        start,
        end=@util.index_of(card, " stroke-width", from=start),
      )
    }
  })
  inspect(
    edges.join(" | "),
    content="\{red} | \{red}\{faint} | - | \{grey}\{faint} | \{grey} | \{red}\{faint} | -",
  )
  assert_false(has(out, "--pele-series-"))
  assert_true(
    has(
      out, "class=\"pele-node pele-card pele-priority-very-high\" data-id=\"a\"",
    ),
  )
  assert_true(has(out, "class=\"pele-node pele-card\" data-id=\"g\""))
}

///|
test "classes are applied to columns and cards" {
  let out = svg(
    "kanban\n  todo[To do]\n  :::wide\n    a[Task]\n    :::urgent large",
  )
  assert_true(
    has(out, "class=\"pele-cluster pele-column wide\" data-id=\"todo\""),
  )
  assert_true(
    has(out, "class=\"pele-node pele-card urgent large\" data-id=\"a\""),
  )
}

///|
test "card text wraps and a word longer than the card is broken" {
  let short = render("kanban\n  todo\n    a[Short]")
  let long = render(
    "kanban\n  todo\n    a[" + "several words that wrap ".repeat(4) + "]",
  )
  let word = render("kanban\n  todo\n    a[" + "x".repeat(120) + "]")
  assert_true(long.height > short.height)
  inspect(long.width == short.width, content="true")
  inspect(word.width == short.width, content="true")
  assert_true(count(word.svg, "class=\"pele-label\"") > 3)
}

///|
test "a very long word stays inside its card" {
  let result = render("kanban\ntodo\n a[" + "w".repeat(5000) + "]")
  inspect(result.width, content="216")
  assert_true(count(result.svg, "class=\"pele-label\"") > 100)
}

///|
test "a label from metadata is formatted as markdown" {
  let out = svg("kanban\n  todo\n    a[Old]@{ label: \"New **bold** text\" }")
  assert_false(has(out, "Old"))
  assert_true(has(out, "font-weight=\"var(--_w)\">bold</tspan>"))
}

///|
test "the front matter title is drawn above the board" {
  let plain = render("kanban\n  todo\n    a")
  let titled = render("---\ntitle: Sprint 12\n---\nkanban\n  todo\n    a")
  assert_true(
    has(titled.svg, "class=\"pele-title\" font-weight=\"var(--_tw)\""),
  )
  assert_true(has(titled.svg, ">Sprint 12<"))
  assert_true(titled.height > plain.height)
}

///|
test "a board with no columns is still an image" {
  assert_true(has(svg("kanban\n\n"), "<svg"))
}

///|
test "columns that do not fit the width fold into rows" {
  let src = "kanban\n  a\n    one\n  b\n    two\n  c\n    three"
  let wide = render(src)
  let narrow = render(src, max_width=400)
  assert_true(narrow.width < wide.width)
  assert_true(narrow.height > wide.height)
}

///|
test "the output has no non-finite number" {
  let out = svg(
    BASE +
    "kanban\n  Todo\n    [Create Documentation]\n  id9[Ready]\n    id8[Design grammar]@{ assigned: 'knsv', ticket: MC-1, priority: 'Low' }",
  )
  assert_false(has(out, "NaN"))
  assert_false(has(out, "Infinity"))
  assert_false(has(out, "undefined"))
}
