///|
let basic : String = "treemap-beta\n\"Category A\"\n    \"Item A1\": 10\n    \"Item A2\": 20\n\"Category B\"\n    \"Item B1\": 15\n    \"Item B2\": 25\n"

///|
fn with_config(treemap : String, body : String) -> String {
  "---\nconfig:\n  treemap:\n\{treemap}\n---\n\{body}"
}

///|
/// The value of the attribute `name` on the rect drawn for the node `id`, or an empty string.
fn attr_of(svg : String, id : String, name : String) -> String {
  let at = rect_at(svg, id)
  let end = @util.index_of(svg, "/>", from=at)
  let element = @util.slice(svg, at, end~)
  quoted_after(element, " \{name}=\"")
}

///|
fn area(svg : String, id : String) -> Double {
  let (_, _, w, h) = box_of(svg, id)
  w * h
}

///|
test "sections are drawn with a header and leaves with a name and a value" {
  let result = drawn(basic)
  inspect(result.kind, content="treemap")
  inspect("\{result.width}x\{result.height}", content="656x416")
  inspect(count(result.svg, "class=\"pele-node pele-section\""), content="2")
  inspect(count(result.svg, "class=\"pele-node pele-leaf\""), content="4")
  inspect(
    result.svg.contains("font-weight=\"var(--_hw)\">Category A<"),
    content="true",
  )
  inspect(result.svg.contains(">Item B2<"), content="true")
  inspect(result.svg.contains(">25<"), content="true")
  // The value of a section is the sum of its leaves.
  inspect(result.svg.contains("fill=\"var(--_m)\">40<"), content="true")
}

///|
test "a top-level section and what is inside it share one series color" {
  let svg = drawn(basic).svg
  inspect(
    attr_of(svg, "Category A", "fill"),
    content="var(--pele-series-1,#4c78a8)",
  )
  inspect(
    attr_of(svg, "Item A1", "fill"),
    content=attr_of(svg, "Category A", "fill"),
  )
  inspect(
    attr_of(svg, "Category B", "fill"),
    content="var(--pele-series-2,#f58518)",
  )
  inspect(
    attr_of(svg, "Item B2", "fill"),
    content=attr_of(svg, "Category B", "fill"),
  )
  inspect(attr_of(svg, "Category A", "fill-opacity"), content="0.12")
  inspect(attr_of(svg, "Item A1", "fill-opacity"), content="")
}

///|
test "leaves are sized by value and kept inside their section" {
  let svg = drawn(basic).svg
  inspect(area(svg, "Item B2") > area(svg, "Item B1"), content="true")
  inspect(area(svg, "Category B") > area(svg, "Category A"), content="true")
  let (sx, sy, sw, sh) = box_of(svg, "Category A")
  for id in ["Item A1", "Item A2"] {
    let (x, y, w, h) = box_of(svg, id)
    inspect(
      x > sx && y >= sy + 28 && x + w < sx + sw && y + h < sy + sh,
      content="true",
    )
  }
}

///|
test "showValues false leaves the values out" {
  let svg = drawn(with_config("    showValues: false", basic)).svg
  inspect(svg.contains("pele-value"), content="false")
  inspect(svg.contains(">Item A1<"), content="true")
}

///|
test "nodeWidth and nodeHeight size the treemap, ten times each" {
  let sized = drawn(with_config("    nodeWidth: 30\n    nodeHeight: 20", basic))
  inspect("\{sized.width}x\{sized.height}", content="316x216")
}

///|
test "diagramPadding surrounds the treemap unless the host sets a padding" {
  let base = drawn(basic)
  let padded = drawn(with_config("    diagramPadding: 50", basic))
  inspect(padded.width - base.width, content="84")
  inspect(
    drawn(with_config("    diagramPadding: 50", basic), padding=0).width,
    content="640",
  )
}

///|
test "padding is the gap between boxes" {
  let gap = (svg : String) => {
    let (ax, _, aw, _) = box_of(svg, "Category B")
    let (bx, _, _, _) = box_of(svg, "Category A")
    bx - (ax + aw)
  }
  inspect(gap(drawn(basic).svg), content="4")
  inspect(gap(drawn(with_config("    padding: 20", basic)).svg), content="20")
}

///|
test "valueFormat writes the values of leaves and sections" {
  let money = drawn(
      with_config(
        "    valueFormat: '$0,0'", "treemap\n\"Budget\"\n  \"Salaries\": 700000\n  \"Equipment\": 200000",
      ),
    ).svg
  inspect(money.contains(">$700,000<"), content="true")
  inspect(money.contains(">$900,000<"), content="true")
}

///|
test "a value format cannot write markup" {
  let svg = drawn(
      with_config("    valueFormat: \"<b>\"", "treemap\n\"a\": 1234"),
    ).svg
  inspect(svg.contains(">1,234<"), content="true")
}

///|
test "a title is drawn above, from the front matter or the treemap" {
  let titled = drawn("---\ntitle: From front matter\n---\n" + basic)
  inspect(titled.svg.contains(">From front matter<"), content="true")
  inspect(titled.height > 416, content="true")
  let own = drawn(
      "---\ntitle: From front matter\n---\ntreemap\ntitle Own\n\"a\": 1",
    ).svg
  inspect(own.contains(">Own<"), content="true")
  inspect(own.contains("From front matter"), content="false")
}

///|
test "nothing to size still draws a document, without a box" {
  let sources = [
    "treemap",
    "treemap\n\"Only a section\"",
    "treemap\n\"a\": 0\n\"b\": .",
    "treemap\n\"a\": " + "9".repeat(400),
  ]
  for source in sources {
    let svg = drawn(source).svg
    inspect(svg.contains("<svg"), content="true")
    inspect(
      svg.contains("NaN") ||
      svg.contains("Infinity") ||
      svg.contains("pele-node"),
      content="false",
    )
  }
}

///|
test "unusable config is ignored" {
  let svg = drawn(
      with_config(
        "    nodeWidth: -3\n    nodeHeight: \"x\"\n    padding: 100000\n    valueFormat: 7",
        basic,
      ),
    ).svg
  inspect(
    svg.contains("NaN") || svg.contains("Infinity") || svg.contains("width=\"-"),
    content="false",
  )
}

///|
test "a box that is too small for its text still shows, and names it in a tooltip" {
  let svg = drawn(
      "treemap\n\"A section with a very long name indeed\"\n  \"big\": 1000\n  \"A leaf with quite a long name\": 60\n  \"tiny\": 12\n\"other\": 3000",
    ).svg
  inspect(svg.contains("\">tiny<"), content="false")
  inspect(svg.contains("data-id=\"tiny\""), content="true")
  inspect(svg.contains("<title>tiny</title>"), content="true")
  inspect(
    svg.contains("<title>A section with a very long name indeed</title>"),
    content="true",
  )
  inspect(svg.contains("<title>other</title>"), content="false")
}

///|
test "a section drawn without a header is named in the tooltips of what covers it" {
  let svg = drawn(
      with_config(
        "    nodeHeight: 3", "treemap\n\"A & B\"\n  \"Inner\"\n    \"Leaf\": 1",
      ),
    ).svg
  inspect(svg.contains("<title>A &amp; B › Inner</title>"), content="true")
  inspect(
    svg.contains("<title>A &amp; B › Inner › Leaf</title>"),
    content="true",
  )
  inspect(drawn(basic).svg.contains("<title>"), content="false")
  let unprintable = drawn(
      with_config("    nodeHeight: 3", "treemap\n\"#1;\"\n  \"Leaf\": 1"),
    ).svg
  inspect(unprintable.contains("<title>"), content="false")
}

///|
test "a crowded treemap is spaced more tightly, with one gap throughout" {
  let boxes = drawn_boxes(drawn(deep_tree()).svg)
  let named = (prefix : String) => boxes.filter(b => b.id.has_prefix(prefix))
  let top = named("top 0")[0]
  let mut left = @double.infinity
  for b in named("mid 0.") {
    left = @util.js_min(left, b.x)
  }
  inspect(left - top.x, content="3")
  let gaps = [smallest_gap(named("top "))]
  for i in 0..<6 {
    gaps.push(smallest_gap(named("mid \{i}.")))
    for j in 0..<8 {
      gaps.push(smallest_gap(named("leaf \{i}.\{j}.")))
    }
  }
  let finite = gaps.filter(gap => !gap.is_inf())
  inspect(finite.length() > 0, content="true")
  for gap in finite {
    inspect(gap, content="2")
  }
}

///|
test "a roomy treemap keeps its spacing" {
  let boxes = drawn_boxes(drawn(budget).svg)
  let id = (name : String) => boxes.filter(b => b.id == name)[0]
  inspect(id("Operations").x - id("Budget").x, content="6")
  inspect(id("Operations").y - id("Budget").y, content="28")
  inspect(
    smallest_gap(["Salaries", "Equipment", "Supplies"].map(id)),
    content="4",
  )
  inspect(smallest_gap(["Operations", "Marketing"].map(id)), content="4")
}

///|
test "the padding an author sets is the gap" {
  let crowded = drawn_boxes(
    drawn(with_config("    padding: 6", deep_tree())).svg,
  )
  inspect(
    smallest_gap(crowded.filter(b => b.id.has_prefix("top "))),
    content="6",
  )
  let roomy = drawn_boxes(drawn(with_config("    padding: 1", budget)).svg)
  inspect(
    smallest_gap(
      roomy.filter(b => ["Salaries", "Equipment", "Supplies"].contains(b.id)),
    ),
    content="1",
  )
}

///|
test "a section without a header draws no box" {
  let svg = drawn(
      with_config("    nodeHeight: 3", "treemap\n\"Section\"\n  \"Leaf\": 1"),
    ).svg
  inspect(
    svg.contains(
      "data-id=\"Section\"><title>Section</title><rect x=\"8\" y=\"8\" width=\"640\" height=\"30\" fill=\"none\"/></g>",
    ),
    content="true",
  )
}

///|
test "a small section gets a short header" {
  let svg = drawn(
      with_config("    nodeHeight: 4", "treemap\n\"Section\"\n  \"Leaf\": 1"),
    ).svg
  inspect(svg.contains("font-size=\"12\">Section<"), content="true")
  let (_, leaf_y, _, _) = box_of(svg, "Leaf")
  let (_, section_y, _, _) = box_of(svg, "Section")
  inspect(leaf_y - section_y, content="18")
  let tall = drawn(
      with_config(
        "    nodeHeight: 4", "treemap\n\"Section\":::big\n  \"Leaf\": 1\nclassDef big font-size:14.4px",
      ),
    ).svg
  inspect(tall.contains("\">Section<"), content="false")
}

///|
test "the corners of a small box stay within a quarter of its shorter side" {
  let svg = drawn("treemap\n\"big\": 1000\n\"small\": 4").svg
  let (_, _, w, h) = box_of(svg, "small")
  inspect(
    attr_of(svg, "small", "style"),
    content="rx:min(var(--_r),\{@svg.num(@util.js_min(w, h) / 4)}px)",
  )
  inspect(attr_of(svg, "big", "style"), content="rx:var(--_r)")
}

///|
test "every node of a large, deep tree is drawn" {
  let source = StringBuilder()
  source.write_string("treemap\n")
  let mut leaves = 0
  let mut sections = 0
  for i in 0..<6 {
    source.write_string("\"top \{i}\"\n")
    sections += 1
    for j in 0..<8 {
      source.write_string("  \"mid \{i}.\{j}\"\n    \"inner \{i}.\{j}\"\n")
      sections += 2
      for k in 0..<8 {
        let n = 1 + (i * 64 + j * 8 + k) % 37
        source.write_string("      \"leaf \{i}.\{j}.\{k}\": \{n * n * n}\n")
        leaves += 1
      }
    }
  }
  let svg = drawn(source.to_string()).svg
  inspect(count(svg, "class=\"pele-node pele-leaf\"") == leaves, content="true")
  inspect(
    count(svg, "class=\"pele-node pele-section\"") == sections,
    content="true",
  )
}

///|
test "text is fitted at the font size a class sets" {
  let svg = drawn(
      "treemap\n\"A section with a long name\":::head\n  \"A leaf with a fairly long name\": 30:::big\n  \"Another leaf with a long name\": 20:::big\n  \"rest\": 400\nclassDef big font-size:20px\nclassDef head font-size:18px",
    ).svg
  let measurer = @types.RenderOptions::default().text_measurer()
  let checked = [
    ("pele-section head", "A section with a long name", 18.0, @text.STYLE_BOLD),
    ("pele-leaf big", "A leaf with a fairly long name", 20.0, 0),
    ("pele-leaf big", "Another leaf with a long name", 20.0, 0),
  ]
  for item in checked {
    let (kind, id, size, style) = item
    let at = @util.index_of(
      svg,
      "class=\"pele-node \{kind}\" data-id=\"\{id}\">",
    )
    let body = @util.slice(svg, at, end=@util.index_of(svg, "</g>", from=at))
    let (_, _, w, _) = box_of(svg, id)
    let texts = texts_in(body)
    inspect(texts.length() > 0, content="true")
    for text in texts {
      inspect(measurer.width(text, size, style) <= w - 8, content="true")
    }
  }
}

///|
test "a section name at a large font size is kept while it fits the header" {
  let tree = "treemap\n\"Section\"\n  \"Leaf\": 1"
  let classed = (size : String) => {
    "treemap\n\"Section\":::big\n  \"Leaf\": 1\nclassDef big font-size:\{size}px"
  }
  inspect(drawn(tree, font_size=24).svg.contains("\">Section<"), content="true")
  inspect(drawn(classed("20")).svg.contains("\">Section<"), content="true")
  let tall = drawn(classed("32")).svg
  inspect(tall.contains("\">Section<"), content="false")
  inspect(tall.contains("<title>Section</title>"), content="true")
}

///|
test "a label is drawn at a fractional class font size when it fits" {
  let svg = drawn(
      with_config(
        "    nodeHeight: 2", "treemap\n\"Label\": 1:::frac\nclassDef frac font-size:12.5px",
      ),
    ).svg
  inspect(svg.contains("\">Label<"), content="true")
}
