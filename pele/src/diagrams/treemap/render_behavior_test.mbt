///|
let basic : String = "treemap-beta\n\"Category A\"\n    \"Item A1\": 10\n    \"Item A2\": 20\n\"Category B\"\n    \"Item B1\": 15\n    \"Item B2\": 25\n"

///|
fn with_config(treemap : String, body : String) -> String {
  "---\nconfig:\n  treemap:\n\{treemap}\n---\n\{body}"
}

///|
/// The value of the attribute `name` on the rect drawn for the node `id`, or an empty string.
fn attr_of(svg : String, id : String, name : String) -> String {
  let at = @util.index_of(svg, "data-id=\"\{id}\"><rect ")
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
test "a box that is too small for text still shows, without it" {
  let svg = drawn(
      "treemap\n\"A section with a very long name indeed\"\n  \"big\": 1000\n  \"A leaf with quite a long name\": 60\n  \"tiny\": 12\n\"other\": 3000",
    ).svg
  inspect(svg.contains(">tiny<"), content="false")
  inspect(svg.contains("data-id=\"tiny\""), content="true")
}
