// Ported from pele v1.8.0, tests/render/state.test.ts.

///|
fn drawn(
  source : String,
  max_width? : Double,
) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), max_width, }
  Ok(@core.render([@state.state], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
/// The drawing of a diagram with the given body, or the message it fails with.
fn draw(body : String) -> String {
  match drawn("stateDiagram-v2\n" + body) {
    Ok(result) => result.svg
    Err(failure) => failure.message
  }
}

///|
fn count(text : String, needle : String) -> Int32 {
  let mut n = 0
  let mut at = @util.index_of(text, needle)
  while at != -1 {
    n += 1
    at = @util.index_of(text, needle, from=at + needle.length())
  }
  n
}

///|
/// The text from `open` up to the first `close` after it, or "" without `open`.
fn between(text : String, open : String, close : String) -> String {
  let at = @util.index_of(text, open)
  if at == -1 {
    return ""
  }
  let start = at + open.length()
  let end = @util.index_of(text, close, from=start)
  @util.slice(text, start, end=if end == -1 { text.length() } else { end })
}

///|
/// The translate() of the group that carries a data-id.
fn place(svg : String, id : String) -> (Double, Double) {
  let at = between(svg, "data-id=\"\{id}\" transform=\"translate(", ")")
  let comma = @util.index_of(at, ",")
  (
    @util.parse_float(@util.slice(at, 0, end=comma)),
    @util.parse_float(@util.slice(at, comma + 1)),
  )
}

///|
/// The size of the first rect after a data-id.
fn rect_of(svg : String, id : String) -> (Double, Double) {
  let rest = @util.slice(svg, @util.index_of(svg, "data-id=\"\{id}\""))
  let rect = between(rest, "<rect ", "/>")
  (
    @util.parse_float(between(rect, "width=\"", "\"")),
    @util.parse_float(between(rect, "height=\"", "\"")),
  )
}

///|
/// The group that carries a data-id, up to its first closing tag.
fn group_of(svg : String, id : String) -> String {
  between(svg, "data-id=\"\{id}\"", "</g>")
}

///|
/// The y of the label that reads `text`.
fn label_y(svg : String, text : String) -> Double {
  let end = @util.index_of(svg, "\" text-anchor=\"middle\">\{text}<")
  let start = @util.last_index_of(svg, "y=\"", from=end) + 3
  @util.parse_float(@util.slice(svg, start, end~))
}

///|
/// The x, y pairs that follow each `marker` in the text.
fn points_after(svg : String, marker : String) -> Array[(Double, Double)] {
  let out = []
  let mut at = @util.index_of(svg, marker)
  while at != -1 {
    let from = at + marker.length()
    let comma = @util.index_of(svg, ",", from~)
    let mut end = comma + 1
    while end < svg.length() &&
          (
            @util.is_digit(@util.code_at(svg, end)) ||
            @util.code_at(svg, end) == '.'.to_int() ||
            @util.code_at(svg, end) == '-'.to_int()
          ) {
      end += 1
    }
    out.push(
      (
        @util.parse_float(@util.slice(svg, from, end=comma)),
        @util.parse_float(@util.slice(svg, comma + 1, end~)),
      ),
    )
    at = @util.index_of(svg, marker, from~)
  }
  out
}

///|
/// Every value of an attribute in the document, outside the root element.
fn attribute_values(svg : String, name : String) -> Array[String] {
  let body = @util.slice(svg, @util.index_of(svg, ">") + 1)
  let out = []
  let needle = " \{name}=\""
  let mut at = @util.index_of(body, needle)
  while at != -1 {
    let from = at + needle.length()
    let end = @util.index_of(body, "\"", from~)
    out.push(@util.slice(body, from, end~))
    at = @util.index_of(body, needle, from=end)
  }
  out
}

///|
test "detects both keywords and reports size and type" {
  inspect(drawn("stateDiagram\n a --> b").unwrap().kind, content="state")
  let result = drawn("stateDiagram-v2\n a --> b").unwrap()
  inspect(result.kind, content="state")
  inspect(
    result.svg.has_prefix(
      "<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-state\"",
    ),
    content="true",
  )
  inspect(
    result.svg.contains("viewBox=\"0 0 \{result.width} \{result.height}\""),
    content="true",
  )
  inspect(result.height > result.width, content="true")
}

///|
test "themes through custom properties and uses only the shared tokens" {
  let svg = draw(
    "[*] --> a\n state a {\n x --> y : go\n }\n note right of a : n\n a --> [*]",
  )
  inspect(svg.contains("<style"), content="false")
  let allowed = [
    "none", "var(--_bg)", "var(--_fg)", "var(--_m)", "var(--_l)", "var(--_s)", "var(--_a)",
    "var(--_b)", "var(--_c)",
  ]
  let odd = []
  for name in ["fill", "stroke"] {
    for value in attribute_values(svg, name) {
      if !allowed.contains(value) {
        odd.push(value)
      }
    }
  }
  inspect(odd.join(" "), content="")
}

///|
test "lays out along the declared direction" {
  let tall = drawn("stateDiagram-v2\n a --> b\n b --> c").unwrap()
  let wide = drawn("stateDiagram-v2\n direction LR\n a --> b\n b --> c").unwrap()
  inspect(tall.height > tall.width, content="true")
  inspect(wide.width > wide.height, content="true")
  let up = draw("direction BT\n a --> b")
  inspect(place(up, "a").1 > place(up, "b").1, content="true")
  let leftward = draw("direction RL\n a --> b")
  inspect(place(leftward, "a").0 > place(leftward, "b").0, content="true")
}

///|
test "draws a state with its id, its description, or a title over description lines" {
  inspect(draw("s1").contains(">s1</text>"), content="true")
  let described = draw("state \"A long name\" as s1\n s2 : Other")
  inspect(described.contains(">A long name</text>"), content="true")
  inspect(described.contains(">Other</text>"), content="true")
  inspect(described.contains(">s1</text>"), content="false")
  let lines = draw("s1 : Title\n s1 : first\n s1 : second")
  inspect(lines.contains(">Title</text>"), content="true")
  inspect(count(lines, "class=\"pele-state-description\""), content="2")
  inspect(
    rect_of(lines, "s1").1 > rect_of(draw("s1 : Title"), "s1").1 + 30,
    content="true",
  )
}

///|
test "draws [*] as a start dot or an end ring, separately in each composite" {
  let svg = draw(
    "[*] --> a\n a --> [*]\n state a {\n [*] --> b\n b --> [*]\n }",
  )
  inspect(count(svg, "pele-state-start"), content="2")
  inspect(count(svg, "pele-state-end"), content="2")
  for id in ["root_start", "root_end", "a_start", "a_end"] {
    inspect(svg.contains("data-id=\"\{id}\""), content="true")
  }
  inspect(count(svg, "class=\"pele-edge pele-transition\""), content="4")
}

///|
test "draws [*] with ids scoped to its parent under the stateDiagram header and any state config" {
  let body = "[*] --> a\n a --> [*]\n state a {\n [*] --> b\n b --> [*]\n }"
  let legacy = drawn("stateDiagram\n" + body).unwrap().svg
  inspect(
    legacy == drawn("stateDiagram-v2\n" + body).unwrap().svg,
    content="true",
  )
  let configured = drawn(
    "---\nconfig:\n  state:\n    defaultRenderer: dagre-d3\n---\nstateDiagram\n" +
    body,
  ).unwrap()
  inspect(configured.svg == legacy, content="true")
  for id in ["root_start", "root_end", "a_start", "a_end"] {
    inspect(legacy.contains("data-id=\"\{id}\""), content="true")
  }
}

///|
test "keeps a transition that arrives apart from one that leaves on the same side of a state" {
  let svg = drawn("stateDiagram-v2\n  Still --> Moving\n  Moving --> Still").unwrap().svg
  let tips = points_after(svg, "class=\"pele-marker\" d=\"M")
  let starts = points_after(
      svg, "<g class=\"pele-edge pele-transition\" data-id=\"edge0\"><path d=\"M",
    ) +
    points_after(
      svg, "<g class=\"pele-edge pele-transition\" data-id=\"edge1\"><path d=\"M",
    )
  inspect(tips.length(), content="2")
  inspect(starts.length(), content="2")
  for tip in tips {
    let beside = starts.filter(start => (start.1 - tip.1).abs() < 1)
    inspect(beside.length() > 0, content="true")
    inspect((beside[0].0 - tip.0).abs() >= 12, content="true")
  }
}

///|
test "draws a choice as a diamond and fork and join as bars across the flow" {
  let body = "state c <<choice>>\n state f <<fork>>\n state j <<join>>\n [*] --> f\n f --> x\n f --> y\n x --> j\n y --> j\n j --> c\n c --> p : yes\n c --> q : no"
  let down = draw(body)
  inspect(
    between(down, "pele-state-choice\" data-id=\"c\"", "/>").contains(
      "><polygon",
    ),
    content="true",
  )
  inspect(down.contains(">c</text>"), content="false")
  let (fw, fh) = rect_of(down, "f")
  inspect(fw > fh * 4, content="true")
  inspect(down.contains("pele-state-join\" data-id=\"j\""), content="true")
  let across = draw("direction LR\n" + body)
  let (aw, ah) = rect_of(across, "f")
  inspect(ah > aw * 4, content="true")
  inspect(
    draw("state f [[fork]]\n f --> x").contains("pele-state-fork"),
    content="true",
  )
}

///|
test "draws a composite as a titled cluster around its states, to any depth" {
  let svg = draw(
    "[*] --> A\n state A {\n state B {\n state \"Deep name\" as C {\n x --> y\n }\n }\n }",
  )
  inspect(count(svg, "pele-state-composite"), content="3")
  inspect(svg.contains("class=\"pele-cluster-label\""), content="true")
  inspect(svg.contains(">Deep name</text>"), content="true")
  let a = rect_of(svg, "A")
  let b = rect_of(svg, "B")
  let c = rect_of(svg, "C")
  inspect(a.0 > b.0 && b.0 > c.0 && a.1 > b.1, content="true")
  inspect(
    @util.index_of(svg, "data-id=\"A\"") < @util.index_of(svg, "data-id=\"B\""),
    content="true",
  )
}

///|
test "gives each composite its own direction" {
  let svg = draw(
    "state A {\n direction LR\n a1 --> a2\n }\n state B {\n b1 --> b2\n }\n A --> B",
  )
  inspect(place(svg, "a1").1 == place(svg, "a2").1, content="true")
  inspect(place(svg, "a1").0 < place(svg, "a2").0, content="true")
  inspect(place(svg, "b1").0 == place(svg, "b2").0, content="true")
  // As in Mermaid, a composite does not take the direction of what surrounds it.
  let around = draw("direction LR\n state A {\n a1 --> a2\n }\n A --> z")
  inspect(place(around, "a1").0 == place(around, "a2").0, content="true")
  inspect(place(around, "a1").1 < place(around, "a2").1, content="true")
  inspect(place(around, "z").1 > place(around, "a1").1, content="true")
  inspect(place(around, "z").1 < place(around, "a2").1, content="true")
}

///|
test "splits a composite into regions with a dashed divider between them" {
  let svg = draw(
    "state A {\n [*] --> a1\n --\n [*] --> b1\n --\n [*] --> c1\n }",
  )
  inspect(count(svg, "class=\"pele-divider\""), content="2")
  inspect(svg.contains("stroke-dasharray=\"4 4\""), content="true")
  inspect(count(svg, "pele-state-start"), content="3")
  inspect(place(svg, "a1").0 < place(svg, "b1").0, content="true")
  inspect(place(svg, "b1").0 < place(svg, "c1").0, content="true")
  inspect(
    between(svg, "class=\"pele-divider\" d=\"M", "\"").contains("V"),
    content="true",
  )
  // A transition from one region to the next puts them in a stack, divided the other way.
  let stacked = draw("state A {\n a1\n --\n b1\n }\n a1 --> b1")
  inspect(
    between(stacked, "class=\"pele-divider\" d=\"M", "\"").contains("H"),
    content="true",
  )
  inspect(place(stacked, "a1").1 < place(stacked, "b1").1, content="true")
  // Mermaid fails to draw a composite whose last statement is a divider.
  let trailing = draw("state A {\n x\n --\n y\n --\n }")
  inspect(count(trailing, "class=\"pele-divider\""), content="1")
  inspect(place(trailing, "x").0 < place(trailing, "y").0, content="true")
}

///|
test "draws notes beside their state, joined by a dashed line" {
  let svg = draw(
    "a --> b\n note right of a : on the right\n note left of b\n first line\n second line\n end note",
  )
  inspect(count(svg, "class=\"pele-note\""), content="2")
  inspect(count(svg, "pele-note-edge"), content="2")
  inspect(svg.contains(">on the right</text>"), content="true")
  inspect(svg.contains(">first line</tspan>"), content="true")
  inspect(svg.contains(">second line</tspan>"), content="true")
  inspect(place(svg, "a----note-1").0 > place(svg, "a").0, content="true")
  inspect(place(svg, "a----note-1").1 == place(svg, "a").1, content="true")
  inspect(place(svg, "b----note-2").0 < place(svg, "b").0, content="true")
  inspect(place(svg, "a").0 == place(svg, "b").0, content="true")
  let across = draw(
    "direction LR\n a --> b\n note right of a : below\n note left of b : above",
  )
  inspect(place(across, "a----note-1").1 > place(across, "a").1, content="true")
  inspect(place(across, "b----note-2").1 < place(across, "b").1, content="true")
  let on_composite = draw("state A {\n x --> y\n }\n note right of A : about A")
  inspect(on_composite.contains(">about A</text>"), content="true")
  inspect(count(on_composite, "pele-note-edge"), content="1")
}

///|
test "labels transitions, including those to self and across composite borders" {
  let svg = draw(
    "state A {\n in1 --> in2 : inner\n in2 --> in2 : again\n }\n out --> in1 : cross\n A --> A : whole\n A --> in1 : enter\n in2 --> A : leave",
  )
  for text in ["inner", "again", "cross", "whole", "enter", "leave"] {
    inspect(svg.contains(">\{text}</text>"), content="true")
  }
  inspect(count(svg, "class=\"pele-edge-label\""), content="6")
  inspect(count(svg, "class=\"pele-edge pele-transition\""), content="6")
  inspect(count(svg, "class=\"pele-marker\""), content="6")
  inspect(svg.contains("NaN"), content="false")
}

///|
test "keeps the labels of several self-transitions apart" {
  let down = draw("a --> a : one\n a --> a : two\n a --> b")
  inspect(label_y(down, "two") - label_y(down, "one") >= 20, content="true")
  let across = draw("direction LR\n a --> a : one\n a --> a : two\n a --> b")
  inspect(label_y(across, "two") - label_y(across, "one") >= 20, content="true")
  inspect(label_y(across, "one") > place(across, "a").1 + 22, content="true")
}

///|
test "starts the flow at the initial state even when other states are declared first" {
  let svg = draw("state c <<choice>>\n [*] --> a\n a --> c\n c --> b\n b --> a")
  inspect(place(svg, "root_start").1 < place(svg, "a").1, content="true")
  inspect(place(svg, "a").1 < place(svg, "c").1, content="true")
  inspect(place(svg, "c").1 < place(svg, "b").1, content="true")
}

///|
test "applies classDef, class, ::: and style to states" {
  let svg = draw(
    "classDef hot fill:#f00,color:white,font-weight:bold\n classDef cool stroke:#00f\n a:::cool --> b\n class b hot\n style c fill:#0f0,stroke-width:4px\n b --> c\n state G {\n g1\n }\n class G cool",
  )
  inspect(
    svg.contains("class=\"pele-node pele-state cool\" data-id=\"a\""),
    content="true",
  )
  inspect(
    between(group_of(svg, "a"), "<rect", "/>").contains(
      " style=\"stroke:#00f;\"",
    ),
    content="true",
  )
  inspect(
    svg.contains("class=\"pele-node pele-state hot\" data-id=\"b\""),
    content="true",
  )
  inspect(
    between(group_of(svg, "b"), "<rect", "/>").contains(" style=\"fill:#f00;\""),
    content="true",
  )
  inspect(
    group_of(svg, "b").contains(
      "/><text class=\"pele-label\" style=\"fill:white;font-weight:bold;\"",
    ),
    content="true",
  )
  inspect(
    between(group_of(svg, "c"), "<rect", "/>").contains(
      " style=\"fill:#0f0;stroke-width:4px;\"",
    ),
    content="true",
  )
  inspect(
    svg.contains(
      "class=\"pele-cluster pele-state-composite cool\" data-id=\"G\"><rect",
    ),
    content="true",
  )
  inspect(
    between(group_of(svg, "G"), "<rect", "/>").contains(
      " style=\"stroke:#00f;\"",
    ),
    content="true",
  )
}

///|
test "turns click statements into links, with the URL sanitized" {
  let result = drawn(
    "stateDiagram-v2\n a --> b\n b --> c\n click a \"https://example.com/x\" \"Go there\"\n click b href \"https://example.org\"\n click c \"javascript:alert(1)\" \"no\"\n",
  ).unwrap()
  inspect(
    result.svg.contains(
      "<a href=\"https://example.com/x\" target=\"_blank\" rel=\"noopener\"><title>Go there</title>",
    ),
    content="true",
  )
  inspect(
    result.svg.contains(
      "<a href=\"https://example.org/\" target=\"_blank\" rel=\"noopener\">",
    ),
    content="true",
  )
  inspect(count(result.svg, "<a "), content="2")
  inspect(result.svg.contains("<title>no</title>"), content="true")
  inspect(
    result.links.map(l => "\{l.id} \{l.href} \{l.internal}").join("\n"),
    content=(
      #|a https://example.com/x false
      #|b https://example.org/ false
    ),
  )
}

///|
test "writes the accessible title and description" {
  let svg = draw("accTitle: The title\n accDescr: The description\n a --> b")
  inspect(
    svg.contains("<title id=\"pele-title\">The title</title>"),
    content="true",
  )
  inspect(
    svg.contains("<desc id=\"pele-desc\">The description</desc>"),
    content="true",
  )
  inspect(
    draw("accDescr {\n several\n lines\n }\n a --> b").contains(
      "<desc id=\"pele-desc\">several\nlines</desc>",
    ),
    content="true",
  )
}

///|
test "accepts the statements that change nothing: hide empty description, scale, comments" {
  let plain = draw("a --> b")
  inspect(
    draw("hide empty description\n scale 350 width\n a --> b") == plain,
    content="true",
  )
  inspect(draw("%% a comment\n a --> b %% trailing") == plain, content="true")
}

///|
test "reads labels as markdown with entities and line breaks" {
  let svg = draw(
    "a : **bold** and *italic*\n a --> b : one<br>two\n b : x #35; y",
  )
  inspect(
    svg.contains("font-weight=\"var(--_w)\">bold</tspan>"),
    content="true",
  )
  inspect(svg.contains("font-style=\"italic\">italic</tspan>"), content="true")
  inspect(svg.contains(">one</tspan>"), content="true")
  inspect(svg.contains(">x # y</text>"), content="true")
}

///|
test "keeps Mermaid quirks that change what is drawn" {
  // A bare `state name` declares nothing in Mermaid's grammar.
  inspect(draw("state lonely\n a --> b").contains("lonely"), content="false")
  // A stereotype given after the state's first use is ignored.
  inspect(
    draw("a --> c\n state c <<choice>>").contains(">c</text>"),
    content="true",
  )
}

///|
test "rejects what Mermaid rejects" {
  inspect(
    draw("state two words {\n a\n }").has_prefix(
      "Error: State name must be a single word.",
    ),
    content="true",
  )
  inspect(
    draw("state A {\n x\n }\n A : one\n A : two").has_prefix(
      "Group nodes can only have label.",
    ),
    content="true",
  )
  inspect(drawn("stateDiagram-v2\na --> b --> c") is Err(_), content="true")
  inspect(
    drawn("stateDiagram-v2\nclassDef default fill:red") is Err(_),
    content="true",
  )
  inspect(
    draw("state A {\n x --> y").has_prefix("Parse error on line"),
    content="true",
  )
  inspect(
    draw("scale 350\n a --> b").has_prefix("Lexical error on line 2"),
    content="true",
  )
}
