///|
const BASE : String = "---\nconfig:\n  kanban:\n    ticketBaseUrl: 'https://example.com/browse/#TICKET#'\n---\n"

///|
fn render(
  source : String,
  max_width? : Double,
  icons? : @types.IconResolver,
) -> @types.RenderResult raise @errors.PeleError {
  let options = { ..@types.RenderOptions::default(), max_width, icons, }
  @core.render([@kanban.kanban], source, options)
}

///|
fn svg(
  source : String,
  max_width? : Double,
  icons? : @types.IconResolver,
) -> String {
  (render(source, max_width?, icons?) catch {
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

///|
/// A host that has exactly the icons in `pairs`, by name.
fn host(pairs : Array[(String, String)]) -> @types.IconResolver {
  let icons = Map::from_array(pairs)
  name => icons.get(name)
}

///|
test "columns and cards make room for the icons the host has and draw them" {
  inspect(
    svg(
      "---\nconfig:\n  kanban:\n    ticketBaseUrl: 'https://example.com/browse/#TICKET#'\n---\nkanban\n  todo[fa:fa-car To do with a rather long column title]\n  ::icon(star)\n    a[fa:fa-car First card with a long label that wraps around]@{ icon: star, ticket: fa:fa-car T-1, assigned: 'fa:fa-car bob' }\n    b[Second]@{ icon: missing }\n  done[Done]\n  ::icon(blank)\n    c[Supercalifragilisticexpialidocious fa:fa-car fa:fa-car]@{ ticket: T-2 }\n",
      icons=host([
        ("star", "<path id=\"star\"/>"),
        ("fa:fa-car", "<path id=\"car\"/>"),
        ("blank", ""),
      ]),
    ),
    content="<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-kanban\" viewBox=\"0 0 428 269\" width=\"428\" height=\"269\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"kanban\"><g class=\"pele-cluster pele-column\" data-id=\"todo\" transform=\"translate(8,8)\"><rect width=\"200\" height=\"253\" fill=\"var(--_s)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"32\" y=\"25.6\" text-anchor=\"start\"> To do with a</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"12\" y=\"11.2\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg><text class=\"pele-cluster-label\" font-weight=\"var(--_hw)\" x=\"12\" y=\"49.6\">rather long</text><text class=\"pele-cluster-label\" font-weight=\"var(--_hw)\" x=\"12\" y=\"73.6\">column title</text><text class=\"pele-count\" x=\"188\" y=\"24.9\" text-anchor=\"end\" font-size=\"14\" fill=\"var(--_m)\">2</text><svg class=\"pele-icon\" data-icon=\"star\" x=\"156.72\" y=\"11.25\" width=\"17.5\" height=\"17.5\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"star\"/></svg><g class=\"pele-node pele-card\" data-id=\"a\" transform=\"translate(8,88)\" font-size=\"14\"><rect width=\"184\" height=\"108\" fill=\"var(--_bg)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"27.5\" y=\"25.4\" text-anchor=\"start\"> First card with a</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"10\" y=\"12.8\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg><text class=\"pele-label\" x=\"10\" y=\"46.4\">long label that wraps</text><text class=\"pele-label\" x=\"10\" y=\"67.4\">around</text><svg class=\"pele-icon\" data-icon=\"star\" x=\"156.5\" y=\"11.75\" width=\"17.5\" height=\"17.5\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"star\"/></svg><a href=\"https://example.com/browse/fa:fa-car T-1\" target=\"_blank\" rel=\"noopener\"><text class=\"pele-ticket\" fill=\"var(--_c)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"27.5\" y=\"92.4\" text-anchor=\"start\"> T-1</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"10\" y=\"79.8\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></a><text class=\"pele-assigned\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"146.76\" y=\"92.4\" text-anchor=\"start\"> bob</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"129.26\" y=\"79.8\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g><g class=\"pele-node pele-card\" data-id=\"b\" transform=\"translate(8,204)\" font-size=\"14\"><rect width=\"184\" height=\"41\" fill=\"var(--_bg)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"10\" y=\"25.4\">Second</text></g></g><g class=\"pele-cluster pele-column\" data-id=\"done\" transform=\"translate(220,8)\"><rect width=\"200\" height=\"253\" fill=\"var(--_s)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" font-weight=\"var(--_hw)\" x=\"12\" y=\"25.6\">Done</text><text class=\"pele-count\" x=\"188\" y=\"24.9\" text-anchor=\"end\" font-size=\"14\" fill=\"var(--_m)\">1</text><g class=\"pele-node pele-card\" data-id=\"c\" transform=\"translate(8,88)\" font-size=\"14\"><rect width=\"184\" height=\"108\" fill=\"var(--_bg)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"10\" y=\"25.4\">Supercalifragilisticexpialid</text><text class=\"pele-label\" x=\"10\" y=\"46.4\">ocious</text><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"27.5\" y=\"67.4\" text-anchor=\"start\"> </tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"10\" y=\"54.8\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"31.39\" y=\"54.8\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg><a href=\"https://example.com/browse/T-2\" target=\"_blank\" rel=\"noopener\"><text class=\"pele-ticket\" fill=\"var(--_c)\" x=\"10\" y=\"92.4\">T-2</text></a></g></g></svg>",
  )
}

///|
test "a ticket without a link draws the host's icons" {
  inspect(
    svg(
      "kanban\n  todo[To do]\n    a[A card]@{ icon: star, ticket: fa:fa-car T-1 }\n",
      icons=host([
        ("star", "<path id=\"star\"/>"),
        ("fa:fa-car", "<path id=\"car\"/>"),
      ]),
    ),
    content="<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-kanban\" viewBox=\"0 0 216 130\" width=\"216\" height=\"130\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"kanban\"><g class=\"pele-cluster pele-column\" data-id=\"todo\" transform=\"translate(8,8)\"><rect width=\"200\" height=\"114\" fill=\"var(--_s)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" font-weight=\"var(--_hw)\" x=\"12\" y=\"25.6\">To do</text><text class=\"pele-count\" x=\"188\" y=\"24.9\" text-anchor=\"end\" font-size=\"14\" fill=\"var(--_m)\">1</text><g class=\"pele-node pele-card\" data-id=\"a\" transform=\"translate(8,40)\" font-size=\"14\"><rect width=\"184\" height=\"66\" fill=\"var(--_bg)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"10\" y=\"25.4\">A card</text><svg class=\"pele-icon\" data-icon=\"star\" x=\"156.5\" y=\"11.75\" width=\"17.5\" height=\"17.5\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"star\"/></svg><text class=\"pele-ticket\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"27.5\" y=\"50.4\" text-anchor=\"start\"> T-1</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"10\" y=\"37.8\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g></svg>",
  )
}
