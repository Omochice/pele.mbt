// Ported from pele v1.8.0, tests/render/er.test.ts; the snapshots were taken from pele's render.

///|
fn drawn(
  source : String,
  max_width? : Double,
  monospace? : Array[String],
) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), max_width, monospace, }
  Ok(@core.render([@er.er], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn svg_of(source : String) -> String {
  match drawn(source) {
    Ok(result) => result.svg
    Err(failure) => failure.message
  }
}

///|
/// The document without its opening tag, which differs between snapshots only in size.
fn body(svg : String) -> String {
  let at = @util.index_of(svg, ">")
  @util.slice(svg, at + 1)
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
/// The text between `open` and the first `close` after it.
fn between(text : String, open : String, close : String) -> String {
  let at = @util.index_of(text, open)
  if at == -1 {
    return ""
  }
  let start = at + open.length()
  @util.slice(text, start, end=@util.index_of(text, close, from=start))
}

///|
/// The markers of the first edge, as the element names they are drawn with.
fn marker_shapes(source : String) -> String {
  let edge = between(svg_of(source), "<g class=\"pele-edge ", "</g>")
  let shapes = []
  let mut at = 0
  while true {
    let path = @util.index_of(edge, "<path class=\"pele-marker\"", from=at)
    let circle = @util.index_of(edge, "<circle class=\"pele-marker\"", from=at)
    if path == -1 && circle == -1 {
      break
    }
    if circle == -1 || (path != -1 && path < circle) {
      shapes.push("path")
      at = path + 1
    } else {
      shapes.push("circle")
      at = circle + 1
    }
  }
  shapes.join(",")
}

///|
test "is detected and drawn as an er document" {
  let result = drawn("erDiagram\n  A ||--o{ B : has").unwrap()
  inspect(result.kind, content="er")
  inspect(
    result.svg.has_prefix(
      "<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-er\"",
    ),
    content="true",
  )
  inspect(
    result.svg.contains("viewBox=\"0 0 \{result.width} \{result.height}\""),
    content="true",
  )
}

///|
test "lays out along the declared direction" {
  let tall = drawn("erDiagram\n  A ||--o{ B : x\n  B ||--o{ C : y").unwrap()
  let wide = drawn(
    "erDiagram\n  direction LR\n  A ||--o{ B : x\n  B ||--o{ C : y",
  ).unwrap()
  inspect(tall.height > tall.width, content="true")
  inspect(wide.width > wide.height, content="true")
}

///|
test "draws an entity without attributes as a plain box" {
  let svg = svg_of("erDiagram\n  ISLAND")
  inspect(count(svg, "<rect"), content="1")
  inspect(
    svg.contains("<g class=\"pele-node pele-entity\" data-id=\"ISLAND\""),
    content="true",
  )
  inspect(svg.contains(">ISLAND</text>"), content="true")
  inspect(svg.contains("pele-er-attributes"), content="false")
}

///|
test "draws every cell of the attribute table" {
  let svg = svg_of(
    "erDiagram\n  CAR {\n    string registrationNumber PK \"The plate\"\n    int wheels\n    string(99) make FK, UK\n    float? price \"In euros\"\n  }",
  )
  for
    text in [
      ">string</text>", ">registrationNumber</text>", ">PK</text>", ">FK, UK</text>",
      ">The plate</text>", ">float?</text>", ">string(99)</text>",
    ] {
    inspect(svg.contains(text), content="true")
  }
  inspect(count(svg, "<text class=\"pele-er-type\""), content="4")
}

///|
fn mono_of(source : String, monospace : Array[String]) -> String {
  match drawn(source, monospace~) {
    Ok(result) => result.svg
    Err(failure) => failure.message
  }
}

///|
/// The opening tag of the first text element of class `cls`.
fn text_tag(svg : String, cls : String) -> String {
  let at = @util.index_of(svg, "<text class=\"\{cls}\"")
  @util.slice(svg, at, end=@util.index_of(svg, ">", from=at) + 1)
}

///|
/// The width of the box of the entity `name`.
fn box_width(svg : String, name : String) -> Double {
  let at = @util.index_of(svg, "data-id=\"\{name}\" transform=")
  let from = @util.index_of(svg, " width=\"", from=at) + 8
  @util.parse_float(
    @util.slice(svg, from, end=@util.index_of(svg, "\"", from~)),
  )
}

///|
test "measures attribute types, names and keys in the monospace font when monospace lists attributes" {
  let src = "erDiagram\n  CAR {\n    string registrationNumber PK \"The plate number, as issued by the registration office of the country\"\n    int wheels FK, UK\n  }"
  let plain = svg_of(src)
  let mono = mono_of(src, ["attributes"])
  let comment = (svg : String) => {
    let at = @util.index_of(svg, "<text class=\"pele-er-comment\"")
    @util.slice(svg, at, end=@util.index_of(svg, "</text>", from=at) + 7)
  }
  let without_x = (text : String) => {
    let out = StringBuilder()
    let mut last = 0
    let mut at = @util.index_of(text, " x=\"")
    while at != -1 {
      out.write_string(@util.slice(text, last, end=at))
      last = @util.index_of(text, "\"", from=at + 4) + 1
      at = @util.index_of(text, " x=\"", from=last)
    }
    out.write_string(@util.slice(text, last))
    out.to_string()
  }
  for cls in ["pele-er-type", "pele-er-name", "pele-er-keys"] {
    inspect(
      text_tag(mono, cls).contains(" font-family=\"var(--_fm)\""),
      content="true",
    )
  }
  inspect(plain.contains("font-family=\"var(--_fm)\""), content="false")
  inspect(comment(mono).contains("font-family"), content="false")
  assert_eq(without_x(comment(mono)), without_x(comment(plain)))
  inspect(count(comment(mono), "<tspan"), content="2")
  inspect(box_width(mono, "CAR") > box_width(plain, "CAR"), content="true")
  for name in ["`a  b`", "`<code>a  b</code>`"] {
    let spaced = mono_of("erDiagram\n  A {\n    string \{name}\n  }", [
      "attributes",
    ])
    let head = "<text class=\"pele-er-name\" font-family=\"var(--_fm)\" xml:space=\"preserve\"><tspan"
    let at = @util.index_of(spaced, head)
    inspect(at != -1, content="true")
    let open = @util.index_of(spaced, ">", from=at + head.length()) + 1
    inspect(
      @util.slice(
        spaced,
        open,
        end=@util.index_of(spaced, "</tspan>", from=open),
      ),
      content="a  b",
    )
  }
}

///|
test "ignores monospace values that do not list attributes" {
  let src = "erDiagram\n  CAR {\n    string registrationNumber PK \"The plate\"\n  }"
  let plain = svg_of(src)
  for monospace in [[], ["attribute"], ["members"]] {
    assert_eq(mono_of(src, monospace), plain)
  }
}

///|
test "keeps an entity's own font-family on its attributes when monospace lists them" {
  let attributes = (svg : String) => {
    let at = @util.index_of(
      svg,
      "<g class=\"pele-er-attributes\"",
      from=@util.index_of(svg, "data-id=\"A\""),
    )
    @util.slice(svg, at, end=@util.index_of(svg, "</g>", from=at) + 4)
  }
  for
    rule in [
      "style A color:black,font-family:serif", "classDef serif color:black,font-family:serif\n  class A serif",
    ] {
    let src = "erDiagram\n  A {\n    string name PK\n  }\n  B {\n    string name PK\n  }\n  \{rule}"
    let svg = mono_of(src, ["attributes"])
    assert_eq(attributes(svg), attributes(svg_of(src)))
    inspect(
      @util.slice(svg, @util.index_of(svg, "data-id=\"B\"")).contains(
        "font-family=\"var(--_fm)\"",
      ),
      content="true",
    )
  }
}

///|
test "shades alternate rows and rounds the last one with the box" {
  let three = between(
    svg_of("erDiagram\n  A {\n int a\n int b\n int c\n }"),
    "<g class=\"pele-er-stripes\" fill=\"var(--_bg)\">",
    "</g>",
  )
  inspect(count(three, "<rect"), content="3")
  inspect(count(three, "rx:var(--_r)"), content="1")
  let two = between(
    svg_of("erDiagram\n  A {\n int a\n int b\n }"),
    "<g class=\"pele-er-stripes\" fill=\"var(--_bg)\">",
    "</g>",
  )
  inspect(count(two, "<rect"), content="1")
}

///|
/// The entity `id`, up to the end tag of its stripes' group.
fn entity_of(svg : String, id : String) -> String {
  between(svg, "data-id=\"\{id}\"", "</g></g>")
}

///|
test "picks a contrasting text color on fills a style sets" {
  let svg = svg_of(
    "erDiagram\n A { int id PK \"key\" }\n B { int id }\n C { int id }\n D { int id }\n subgraph G\n  E\n end\n style A fill:navy\n style B fill:#BBDEFB\n style C fill:#BBDEFB,color:#333\n style G fill:#FFF9C4",
  )
  let dark = " fill=\"var(--pele-fg-on-dark,#fff)\""
  let a = entity_of(svg, "A")
  assert_true(
    a.contains(
      "<g class=\"pele-er-stripes\" fill=\"var(--pele-fg-on-light,#1f1f1f)\" opacity=\"0.6\">",
    ),
  )
  for
    cell in [
      "pele-label", "pele-er-type", "pele-er-name", "pele-er-keys", "pele-er-comment",
    ] {
    assert_true(text_tag(a, cell).contains(dark), msg=cell)
  }
  let b = entity_of(svg, "B")
  assert_true(
    b.contains(
      "<text class=\"pele-label\" fill=\"var(--pele-fg-on-light,#1f1f1f)\"",
    ),
  )
  assert_true(
    b.contains(
      "<g class=\"pele-er-stripes\" fill=\"var(--pele-fg-on-dark,#fff)\" opacity=\"0.6\">",
    ),
  )
  let c = entity_of(svg, "C")
  assert_false(c.contains("--pele-fg-on-light"))
  assert_true(
    c.contains(
      "<text class=\"pele-er-type\" fill=\"var(--_m)\" style=\"fill:#333;\"",
    ),
  )
  let d = entity_of(svg, "D")
  assert_true(d.contains("<g class=\"pele-er-stripes\" fill=\"var(--_bg)\">"))
  assert_false(d.contains("--pele-fg-on"))
  assert_true(
    between(svg, "data-id=\"G\">", "</g>").contains(
      "<text class=\"pele-cluster-label\" fill=\"var(--pele-fg-on-light,#1f1f1f)\"",
    ),
  )
}

///|
test "shows the alias in place of the name" {
  let svg = svg_of(
    "erDiagram\n  p[Person] {\n string name\n }\n  a[\"Customer Account\"]\n  p ||--o| a : has",
  )
  inspect(svg.contains(">Person</text>"), content="true")
  inspect(svg.contains(">Customer Account</text>"), content="true")
  inspect(svg.contains(">p</text>"), content="false")
  inspect(svg.contains("data-id=\"p\""), content="true")
}

///|
test "draws a marker for each cardinality" {
  inspect(marker_shapes("erDiagram\n A ||--|| B : x"), content="path,path")
  inspect(
    marker_shapes("erDiagram\n A |o--o| B : x"),
    content="path,circle,path,circle",
  )
  inspect(
    marker_shapes("erDiagram\n A }o--o{ B : x"),
    content="path,circle,path,circle",
  )
  inspect(marker_shapes("erDiagram\n A }|--|{ B : x"), content="path,path")
  inspect(
    marker_shapes("erDiagram\n A ||--o{ B : x"),
    content="path,path,circle",
  )
  inspect(marker_shapes("erDiagram\n A u--|| B : x"), content="path,path")
}

///|
test "gives the word aliases the same markers as the symbols" {
  let markers = (source : String) => {
    between(svg_of(source), "<g class=\"pele-edges\"", "</g></g>")
  }
  let pairs = [
    ("A one or zero to one or more B : x", "A |o--|{ B : x"),
    ("A only one to zero or many B : x", "A ||--o{ B : x"),
    ("A 1 optionally to many(1) B : x", "A ||..|{ B : x"),
    ("A zero or one to 0+ B : x", "A |o--o{ B : x"),
    ("A 1+ to many(0) B : x", "A }|--o{ B : x"),
  ]
  for pair in pairs {
    let (words, symbols) = pair
    inspect(
      markers("erDiagram\n " + words) == markers("erDiagram\n " + symbols),
      content="true",
    )
  }
}

///|
test "draws identifying lines solid and non-identifying lines dashed" {
  let solid = svg_of("erDiagram\n A ||--|| B : x")
  let dashed = svg_of("erDiagram\n A ||..|| B : x")
  inspect(
    solid.contains("class=\"pele-edge pele-er-identifying\""),
    content="true",
  )
  inspect(solid.contains("stroke-dasharray"), content="false")
  inspect(
    dashed.contains("class=\"pele-edge pele-er-non-identifying\""),
    content="true",
  )
  inspect(count(dashed, "stroke-dasharray"), content="1")
}

///|
test "labels relationships and leaves an empty label out" {
  let svg = svg_of(
    "erDiagram\n A ||--o{ B : \"places an order\"\n B ||--o{ C : \"\"",
  )
  inspect(count(svg, "<g class=\"pele-edge-label\""), content="1")
  inspect(svg.contains(">places an order</text>"), content="true")
  inspect(count(svg, "<g class=\"pele-edge "), content="2")
}

///|
test "draws a relationship from an entity to itself with both markers" {
  let svg = svg_of("erDiagram\n EMPLOYEE ||--o{ EMPLOYEE : manages")
  inspect(count(svg, "class=\"pele-marker\""), content="3")
  inspect(svg.contains(">manages</text>"), content="true")
}

///|
test "reads tildes in attribute text as generic brackets" {
  inspect(
    svg_of("erDiagram\n A {\n List~string~ tags\n }").contains(
      ">List&lt;string&gt;</text>",
    ),
    content="true",
  )
}

///|
test "draws a subgraph fill the author sets at full opacity" {
  let svg = svg_of(
    "erDiagram\n subgraph g\n  A\n end\n subgraph h\n  B\n end\n style g fill:#fee",
  )
  let rect = (id : String) => between(svg, "data-id=\"\{id}\"><rect ", "/>")
  assert_true(rect("g").contains("fill=\"var(--_a)\" stroke="))
  assert_true(rect("h").contains("fill-opacity=\"0.5\""))
}

///|
test "connects a relationship written before its subgraph to that subgraph" {
  let svg = svg_of("erDiagram\n g ||--o{ X : early\n subgraph g\n  A\n end")
  inspect(count(svg, "<g class=\"pele-edge "), content="1")
  inspect(svg.contains("data-id=\"g\" transform"), content="false")
}

///|
test "honors spacing set in the configuration" {
  let tight = drawn("erDiagram\n A ||--o{ B : x").unwrap()
  let loose = drawn(
    "---\nconfig:\n  er:\n    rankSpacing: 200\n---\nerDiagram\n A ||--o{ B : x",
  ).unwrap()
  inspect(loose.height > tight.height + 100, content="true")
}

///|
test "rejects what Mermaid rejects" {
  inspect(drawn("erDiagram\n A ||--o{ B") is Err(_), content="true")
  inspect(
    svg_of("erDiagram\n A { int }").contains("Expecting 'ATTRIBUTE_WORD'"),
    content="true",
  )
  inspect(
    svg_of("erDiagram\n style A fill:rgb(1,2,3)\n").contains("Lexical error"),
    content="true",
  )
  inspect(drawn("erDiagram\n subgraph g\n A") is Err(_), content="true")
}

///|
test "turns a diagram that runs across to fit a narrow host" {
  let source = "erDiagram\n direction LR\n A ||--o{ B : x\n B ||--o{ C : y\n C ||--o{ D : z"
  let wide = drawn(source).unwrap()
  let narrow = drawn(source, max_width=200).unwrap()
  inspect(wide.width > wide.height, content="true")
  inspect(narrow.height > narrow.width, content="true")
}

///|
test "a relationship between an entity with attributes and a plain one" {
  let result = drawn("erDiagram\n  A ||--o{ B : has\n  A { int id PK \"c\" }").unwrap()
  inspect("\{result.width}x\{result.height}", content="137x225")
  inspect(
    body(result.svg),
    content=(
      #|<g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round"><g class="pele-edge pele-er-identifying" data-id="id_entity-A-0_entity-B-1_0"><path d="M68.34,80L68.34,169"/><path class="pele-marker" d="M63.34,86L73.34,86M63.34,90L73.34,90"/><path class="pele-marker" d="M74.34,169L68.34,159L62.34,169"/><circle class="pele-marker" cx="68.34" cy="155" r="3.5" fill="var(--_bg)"/></g></g><g class="pele-edge-labels" font-size="14"><g class="pele-edge-label" data-id="id_entity-A-0_entity-B-1_0"><rect x="53.06" y="114" width="30.57" height="21" rx="3" fill="var(--_bg)"/><text x="68.34" y="129.4" text-anchor="middle">has</text></g></g><g class="pele-nodes"><g class="pele-node pele-entity" data-id="A" transform="translate(68.34,44)"><rect x="-60.34" y="-36" width="120.68" height="72" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><g class="pele-er-stripes" fill="var(--_bg)"><rect x="-60.34" width="120.68" y="6" height="30" style="rx:var(--_r)"/><rect x="-60.34" width="120.68" y="6" height="15"/></g><path class="pele-er-divider" d="M-60.34,6H60.34" stroke="var(--_b)"/><rect x="-60.34" y="-36" width="120.68" height="72" fill="none" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="-9.4" text-anchor="middle">A</text><g class="pele-er-attributes" font-size="14"><text class="pele-er-type" fill="var(--_m)" x="-48.34" y="25.9">int</text><text class="pele-er-name" x="-17.56" y="25.9">id</text><text class="pele-er-keys" font-size="12" fill="var(--_m)" x="9.33" y="25.9">PK</text><text class="pele-er-comment" fill="var(--_m)" x="41.34" y="25.9">c</text></g></g><g class="pele-node pele-entity" data-id="B" transform="translate(68.34,193)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">B</text></g></g></svg>
    ),
  )
}

///|
test "a formatted comment is written as spans that start at its column" {
  let result = drawn("erDiagram\n T {\n string x \"a *b* c\"\n }").unwrap()
  inspect("\{result.width}x\{result.height}", content="144x88")
  inspect(
    body(result.svg),
    content=(
      #|<g class="pele-nodes"><g class="pele-node pele-entity" data-id="T" transform="translate(71.79,44)"><rect x="-63.79" y="-36" width="127.58" height="72" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><g class="pele-er-stripes" fill="var(--_bg)"><rect x="-63.79" width="127.58" y="6" height="30" style="rx:var(--_r)"/><rect x="-63.79" width="127.58" y="6" height="15"/></g><path class="pele-er-divider" d="M-63.79,6H63.79" stroke="var(--_b)"/><rect x="-63.79" y="-36" width="127.58" height="72" fill="none" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="-9.4" text-anchor="middle">T</text><g class="pele-er-attributes" font-size="14"><text class="pele-er-type" fill="var(--_m)" x="-51.79" y="25.9">string</text><text class="pele-er-name" x="-1.56" y="25.9">x</text><text class="pele-er-comment" fill="var(--_m)" xml:space="preserve"><tspan x="21.44" y="25.9">a </tspan><tspan font-style="italic">b</tspan><tspan> c</tspan></text></g></g></g></svg>
    ),
  )
}

///|
test "a loop leaves by the bottom when ranks run across" {
  let result = drawn(
    "erDiagram\n direction LR\n A ||--o{ A : self\n A ||--o{ B : x",
  ).unwrap()
  inspect("\{result.width}x\{result.height}", content="291x204")
  inspect(
    body(result.svg),
    content=(
      #|<g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round"><g class="pele-edge pele-er-identifying" data-id="id_entity-A-0_entity-A-0_0"><path d="M43,126V144C43,172 69,172 69,144V126"/><path class="pele-marker" d="M38,132L48,132M38,136L48,136"/><path class="pele-marker" d="M63,126L69,136L75,126"/><circle class="pele-marker" cx="69" cy="140" r="3.5" fill="var(--_bg)"/></g><g class="pele-edge pele-er-identifying" data-id="id_entity-A-0_entity-B-1_1"><path d="M104,102L187,102"/><path class="pele-marker" d="M110,107L110,97M114,107L114,97"/><path class="pele-marker" d="M187,96L177,102L187,108"/><circle class="pele-marker" cx="173" cy="102" r="3.5" fill="var(--_bg)"/></g></g><g class="pele-edge-labels" font-size="14"><g class="pele-edge-label" data-id="id_entity-A-0_entity-A-0_0"><rect x="41.11" y="171" width="29.78" height="21" rx="3" fill="var(--_bg)"/><text x="56" y="186.4" text-anchor="middle">self</text></g><g class="pele-edge-label" data-id="id_entity-A-0_entity-B-1_1"><rect x="138" y="91.5" width="15" height="21" rx="3" fill="var(--_bg)"/><text x="145.5" y="106.9" text-anchor="middle">x</text></g></g><g class="pele-nodes"><g class="pele-node pele-entity" data-id="A" transform="translate(56,102)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">A</text></g><g class="pele-node pele-entity" data-id="B" transform="translate(235,102)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">B</text></g></g></svg>
    ),
  )
}

///|
test "an internal link wraps the name and is reported" {
  let result = drawn(
    "erDiagram\n Note:::internal-link { string body }\n p[\"My page\"]:::internal-link",
  ).unwrap()
  inspect("\{result.width}x\{result.height}", content="266x88")
  inspect(
    body(result.svg),
    content=(
      #|<g class="pele-nodes"><g class="pele-node pele-entity internal-link" data-id="Note" transform="translate(60.29,44)"><rect x="-52.29" y="-36" width="104.58" height="72" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><g class="pele-er-stripes" fill="var(--_bg)"><rect x="-52.29" width="104.58" y="6" height="30" style="rx:var(--_r)"/><rect x="-52.29" width="104.58" y="6" height="15"/></g><path class="pele-er-divider" d="M-52.29,6H52.29" stroke="var(--_b)"/><rect x="-52.29" y="-36" width="104.58" height="72" fill="none" stroke="var(--_b)" style="rx:var(--_r)"/><a class="internal-link" href="Note" rel="noopener" data-href="Note"><text class="pele-label" x="0" y="-9.4" text-anchor="middle">Note</text></a><g class="pele-er-attributes" font-size="14"><text class="pele-er-type" fill="var(--_m)" x="-40.29" y="25.9">string</text><text class="pele-er-name" x="9.94" y="25.9">body</text></g></g><g class="pele-node pele-entity internal-link" data-id="p" transform="translate(209.26,44)"><rect x="-48.68" y="-24" width="97.36" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><a class="internal-link" href="My page" rel="noopener" data-href="My page"><text class="pele-label" x="0" y="5.6" text-anchor="middle">My page</text></a></g></g></svg>
    ),
  )
  inspect(
    result.links.map(l => "\{l.id} \{l.href} \{l.internal}").join("\n"),
    content=(
      #|Note Note true
      #|p My page true
    ),
  )
}

///|
test "style, classDef, class and the shorthand reach boxes, lines and text" {
  let result = drawn(
    "erDiagram\n A:::hot { int id }\n B\n C\n class B hot\n classDef hot fill:#f96,stroke:#333\n style C fill:#bbf,color:#fff\n classDef default stroke-width:2px",
  ).unwrap()
  inspect("\{result.width}x\{result.height}", content="400x88")
  inspect(
    body(result.svg),
    content=(
      #|<g class="pele-nodes"><g class="pele-node pele-entity hot" data-id="A" transform="translate(56,44)"><rect x="-48" y="-36" width="96" height="72" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r);stroke-width:2px;fill:#f96;stroke:#333;"/><g class="pele-er-stripes" fill="var(--pele-fg-on-dark,#fff)" opacity="0.6"><rect x="-48" width="96" y="6" height="30" style="rx:var(--_r)"/><rect x="-48" width="96" y="6" height="15"/></g><path class="pele-er-divider" d="M-48,6H48" stroke="#333"/><rect x="-48" y="-36" width="96" height="72" fill="none" stroke="var(--_b)" style="rx:var(--_r);stroke-width:2px;stroke:#333;"/><text class="pele-label" fill="var(--pele-fg-on-light,#1f1f1f)" x="0" y="-9.4" text-anchor="middle">A</text><g class="pele-er-attributes" font-size="14"><text class="pele-er-type" fill="var(--pele-fg-on-light,#1f1f1f)" x="-36" y="25.9">int</text><text class="pele-er-name" fill="var(--pele-fg-on-light,#1f1f1f)" x="9.95" y="25.9">id</text></g></g><g class="pele-node pele-entity hot" data-id="B" transform="translate(200,44)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r);stroke-width:2px;fill:#f96;stroke:#333;"/><text class="pele-label" fill="var(--pele-fg-on-light,#1f1f1f)" x="0" y="5.6" text-anchor="middle">B</text></g><g class="pele-node pele-entity" data-id="C" transform="translate(344,44)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r);stroke-width:2px;fill:#bbf;"/><text class="pele-label" style="fill:#fff;" x="0" y="5.6" text-anchor="middle">C</text></g></g></svg>
    ),
  )
}

///|
test "markdown in names and labels, and unicode kept as is" {
  let result = drawn(
    "erDiagram\n \"This **is** _Markdown_\" ||--o{ \"Ünïcödé ❤ 日本語\" : \"**bold** label\"",
  ).unwrap()
  inspect("\{result.width}x\{result.height}", content="182x201")
  inspect(
    body(result.svg),
    content=(
      #|<g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round"><g class="pele-edge pele-er-identifying" data-id="id_entity-This **is** _Markdown_-0_entity-Ünïcödé ❤ 日本語-1_0"><path d="M90.54,56L90.54,145"/><path class="pele-marker" d="M85.54,62L95.54,62M85.54,66L95.54,66"/><path class="pele-marker" d="M96.54,145L90.54,135L84.54,145"/><circle class="pele-marker" cx="90.54" cy="131" r="3.5" fill="var(--_bg)"/></g></g><g class="pele-edge-labels" font-size="14"><g class="pele-edge-label" data-id="id_entity-This **is** _Markdown_-0_entity-Ünïcödé ❤ 日本語-1_0"><rect x="55.04" y="90" width="71.01" height="21" rx="3" fill="var(--_bg)"/><text text-anchor="middle" xml:space="preserve"><tspan x="90.54" y="105.4" font-weight="var(--_w)">bold</tspan><tspan> label</tspan></text></g></g><g class="pele-nodes"><g class="pele-node pele-entity" data-id="This **is** _Markdown_" transform="translate(90.54,32)"><rect x="-81.13" y="-24" width="162.26" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">This </tspan><tspan font-weight="var(--_w)">is</tspan><tspan> </tspan><tspan font-style="italic">Markdown</tspan></text></g><g class="pele-node pele-entity" data-id="Ünïcödé ❤ 日本語" transform="translate(90.54,169)"><rect x="-82.54" y="-24" width="165.09" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">Ünïcödé ❤ 日本語</text></g></g></svg>
    ),
  )
}

///|
test "a styled subgraph sets its own direction" {
  let result = drawn(
    "erDiagram\n subgraph g\n  direction LR\n  A ||--|| B : x\n end\n style g fill:#fee\n classDef k stroke:#c33\n class g k",
  ).unwrap()
  inspect("\{result.width}x\{result.height}", content="331x124")
  inspect(
    body(result.svg),
    content=(
      #|<g class="pele-clusters"><g class="pele-cluster k" data-id="g"><rect x="8" y="8" width="315" height="108" fill="var(--_a)" stroke="var(--_b)" style="rx:var(--_r);stroke:#c33;fill:#fee;"/><text class="pele-cluster-label" fill="var(--pele-fg-on-light,#1f1f1f)" x="26.45" y="33.6" text-anchor="middle">g</text></g></g><g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round"><g class="pele-edge pele-er-identifying" data-id="id_entity-A-0_entity-B-1_0"><path d="M124,72L207,72"/><path class="pele-marker" d="M130,77L130,67M134,77L134,67"/><path class="pele-marker" d="M201,67L201,77M197,67L197,77"/></g></g><g class="pele-edge-labels" font-size="14"><g class="pele-edge-label" data-id="id_entity-A-0_entity-B-1_0"><rect x="158" y="61.5" width="15" height="21" rx="3" fill="var(--_bg)"/><text x="165.5" y="76.9" text-anchor="middle">x</text></g></g><g class="pele-nodes"><g class="pele-node pele-entity" data-id="A" transform="translate(76,72)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">A</text></g><g class="pele-node pele-entity" data-id="B" transform="translate(255,72)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">B</text></g></g></svg>
    ),
  )
}

///|
test "the title and the accessible title and description" {
  let result = drawn(
    "---\ntitle: Order example\n---\nerDiagram\n accTitle: Orders\n accDescr: How orders relate\n A ||--o{ B : x",
  ).unwrap()
  inspect("\{result.width}x\{result.height}", content="129x237")
  inspect(
    body(result.svg),
    content=(
      #|<title id="pele-title">Orders</title><desc id="pele-desc">How orders relate</desc><text class="pele-title" font-weight="var(--_tw)" text-anchor="middle" xml:space="preserve"><tspan x="64.5" y="25.6">Order example</tspan></text><g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round"><g class="pele-edge pele-er-identifying" data-id="id_entity-A-0_entity-B-1_0"><path d="M64.02,92L64.02,181"/><path class="pele-marker" d="M59.02,98L69.02,98M59.02,102L69.02,102"/><path class="pele-marker" d="M70.02,181L64.02,171L58.02,181"/><circle class="pele-marker" cx="64.02" cy="167" r="3.5" fill="var(--_bg)"/></g></g><g class="pele-edge-labels" font-size="14"><g class="pele-edge-label" data-id="id_entity-A-0_entity-B-1_0"><rect x="56.52" y="126" width="15" height="21" rx="3" fill="var(--_bg)"/><text x="64.02" y="141.4" text-anchor="middle">x</text></g></g><g class="pele-nodes"><g class="pele-node pele-entity" data-id="A" transform="translate(64.02,68)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">A</text></g><g class="pele-node pele-entity" data-id="B" transform="translate(64.02,205)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">B</text></g></g></svg>
    ),
  )
}

///|
test "two loops share the right side of a box" {
  let result = drawn("erDiagram\n A ||--o{ A : first\n A |o--|| A : second").unwrap()
  inspect("\{result.width}x\{result.height}", content="301x100")
  inspect(
    body(result.svg),
    content=(
      #|<g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round"><g class="pele-edge pele-er-identifying" data-id="id_entity-A-0_entity-A-0_0"><path d="M198.14,18H216.14C244.14,18 244.14,44 216.14,44H198.14"/><path class="pele-marker" d="M204.14,23L204.14,13M208.14,23L208.14,13"/><path class="pele-marker" d="M198.14,50L208.14,44L198.14,38"/><circle class="pele-marker" cx="212.14" cy="44" r="3.5" fill="var(--_bg)"/></g><g class="pele-edge pele-er-identifying" data-id="id_entity-A-0_entity-A-0_1"><path d="M198.14,56H216.14C244.14,56 244.14,82 216.14,82H198.14"/><path class="pele-marker" d="M204.14,61L204.14,51"/><circle class="pele-marker" cx="211.64" cy="56" r="3.5" fill="var(--_bg)"/><path class="pele-marker" d="M204.14,87L204.14,77M208.14,87L208.14,77"/></g></g><g class="pele-edge-labels" font-size="14"><g class="pele-edge-label" data-id="id_entity-A-0_entity-A-0_0"><rect x="239.14" y="20.5" width="30.55" height="21" rx="3" fill="var(--_bg)"/><text x="254.41" y="35.9" text-anchor="middle">first</text></g><g class="pele-edge-label" data-id="id_entity-A-0_entity-A-0_1"><rect x="239.14" y="58.5" width="53.14" height="21" rx="3" fill="var(--_bg)"/><text x="265.7" y="73.9" text-anchor="middle">second</text></g></g><g class="pele-nodes"><g class="pele-node pele-entity" data-id="A" transform="translate(150.14,50)"><rect x="-48" y="-42" width="96" height="84" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">A</text></g></g></svg>
    ),
  )
}

///|
test "lines meeting one side are spread along it" {
  let result = drawn(
    "erDiagram\n A ||--o{ B : x\n A ||--o{ C : y\n A ||--o{ D : z",
  ).unwrap()
  inspect("\{result.width}x\{result.height}", content="400x201")
  inspect(
    body(result.svg),
    content=(
      #|<g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round"><g class="pele-edge pele-er-identifying" data-id="id_entity-A-0_entity-B-1_0"><path d="M182,56L182,74L182,77.5C182,81 56,84.5 56,88L56,127L56,145"/><path class="pele-marker" d="M177,62L187,62M177,66L187,66"/><path class="pele-marker" d="M62,145L56,135L50,145"/><circle class="pele-marker" cx="56" cy="131" r="3.5" fill="var(--_bg)"/></g><g class="pele-edge pele-er-identifying" data-id="id_entity-A-0_entity-C-2_1"><path d="M200,56L200,145"/><path class="pele-marker" d="M195,62L205,62M195,66L205,66"/><path class="pele-marker" d="M206,145L200,135L194,145"/><circle class="pele-marker" cx="200" cy="131" r="3.5" fill="var(--_bg)"/></g><g class="pele-edge pele-er-identifying" data-id="id_entity-A-0_entity-D-3_2"><path d="M218,56L218,74L218,77.5C218,81 344,84.5 344,88L344,127L344,145"/><path class="pele-marker" d="M213,62L223,62M213,66L223,66"/><path class="pele-marker" d="M350,145L344,135L338,145"/><circle class="pele-marker" cx="344" cy="131" r="3.5" fill="var(--_bg)"/></g></g><g class="pele-edge-labels" font-size="14"><g class="pele-edge-label" data-id="id_entity-A-0_entity-B-1_0"><rect x="48.5" y="90" width="15" height="21" rx="3" fill="var(--_bg)"/><text x="56" y="105.4" text-anchor="middle">x</text></g><g class="pele-edge-label" data-id="id_entity-A-0_entity-C-2_1"><rect x="192.5" y="90" width="15" height="21" rx="3" fill="var(--_bg)"/><text x="200" y="105.4" text-anchor="middle">y</text></g><g class="pele-edge-label" data-id="id_entity-A-0_entity-D-3_2"><rect x="336.5" y="90" width="15" height="21" rx="3" fill="var(--_bg)"/><text x="344" y="105.4" text-anchor="middle">z</text></g></g><g class="pele-nodes"><g class="pele-node pele-entity" data-id="A" transform="translate(200,32)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">A</text></g><g class="pele-node pele-entity" data-id="B" transform="translate(56,169)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">B</text></g><g class="pele-node pele-entity" data-id="C" transform="translate(200,169)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">C</text></g><g class="pele-node pele-entity" data-id="D" transform="translate(344,169)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">D</text></g></g></svg>
    ),
  )
}

///|
test "nested subgraphs with relationships to them" {
  let result = drawn(
    "erDiagram\n subgraph outer [Outer title]\n  A\n  subgraph inner\n   B { int id }\n  end\n end\n subgraph \"Empty One\"\n end\n outer ||--o{ C : links\n C ||--|| inner : x",
  ).unwrap()
  inspect("\{result.width}x\{result.height}", content="493x369")
  inspect(
    body(result.svg),
    content=(
      #|<g class="pele-clusters"><g class="pele-cluster" data-id="Empty One"><rect x="8" y="86" width="108.03" height="60" fill="var(--_a)" fill-opacity="0.5" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-cluster-label" fill="var(--_m)" x="62.02" y="111.6" text-anchor="middle">Empty One</text></g><g class="pele-cluster" data-id="outer"><rect x="164.03" y="8" width="320" height="216" fill="var(--_a)" fill-opacity="0.5" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-cluster-label" fill="var(--_m)" x="212.71" y="33.6" text-anchor="middle">Outer title</text></g><g class="pele-cluster" data-id="inner"><rect x="328.03" y="48" width="136" height="132" fill="var(--_a)" fill-opacity="0.5" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-cluster-label" fill="var(--_m)" x="359.82" y="73.6" text-anchor="middle">inner</text></g></g><g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round"><g class="pele-edge pele-er-identifying" data-id="id_outer_entity-C-3_0"><path d="M324.03,224L324.03,242L324.03,281C324.03,286.25 351.03,286.25 351.03,291.5L351.03,295L351.03,313"/><path class="pele-marker" d="M319.03,230L329.03,230M319.03,234L329.03,234"/><path class="pele-marker" d="M357.03,313L351.03,303L345.03,313"/><circle class="pele-marker" cx="351.03" cy="299" r="3.5" fill="var(--_bg)"/></g><g class="pele-edge pele-er-identifying" data-id="id_entity-C-3_inner_1"><path d="M369.03,313L369.03,295L369.03,291.5C369.03,286.25 384.78,286.25 384.78,281L384.78,256C384.78,240 396.03,240 396.03,224L396.03,198L396.03,180"/><path class="pele-marker" d="M374.03,307L364.03,307M374.03,303L364.03,303"/><path class="pele-marker" d="M391.03,186L401.03,186M391.03,190L401.03,190"/></g></g><g class="pele-edge-labels" font-size="14"><g class="pele-edge-label" data-id="id_outer_entity-C-3_0"><rect x="306.03" y="258" width="36" height="21" rx="3" fill="var(--_bg)"/><text x="324.03" y="273.4" text-anchor="middle">links</text></g><g class="pele-edge-label" data-id="id_entity-C-3_inner_1"><rect x="377.28" y="258" width="15" height="21" rx="3" fill="var(--_bg)"/><text x="384.78" y="273.4" text-anchor="middle">x</text></g></g><g class="pele-nodes"><g class="pele-node pele-entity" data-id="A" transform="translate(232.03,114)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">A</text></g><g class="pele-node pele-entity" data-id="B" transform="translate(396.03,124)"><rect x="-48" y="-36" width="96" height="72" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><g class="pele-er-stripes" fill="var(--_bg)"><rect x="-48" width="96" y="6" height="30" style="rx:var(--_r)"/><rect x="-48" width="96" y="6" height="15"/></g><path class="pele-er-divider" d="M-48,6H48" stroke="var(--_b)"/><rect x="-48" y="-36" width="96" height="72" fill="none" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="-9.4" text-anchor="middle">B</text><g class="pele-er-attributes" font-size="14"><text class="pele-er-type" fill="var(--_m)" x="-36" y="25.9">int</text><text class="pele-er-name" x="9.95" y="25.9">id</text></g></g><g class="pele-node pele-entity" data-id="C" transform="translate(360.03,337)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">C</text></g></g></svg>
    ),
  )
}

///|
test "a generic type and a long comment that wraps" {
  let result = drawn(
    "erDiagram\n A {\n List~string~ tags \"a comment long enough that it has to wrap onto a second line of the cell\"\n string? alias UK, FK\n }",
  ).unwrap()
  inspect(
    "\{result.width}x\{result.height}",
    content=(
      #|459x133
    ),
  )
  inspect(
    body(result.svg),
    content=(
      #|<g class="pele-nodes"><g class="pele-node pele-entity" data-id="A" transform="translate(229.09,66.5)"><rect x="-221.09" y="-58.5" width="442.18" height="117" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><g class="pele-er-stripes" fill="var(--_bg)"><rect x="-221.09" width="442.18" y="-16.5" height="45"/></g><path class="pele-er-divider" d="M-221.09,-16.5H221.09" stroke="var(--_b)"/><rect x="-221.09" y="-58.5" width="442.18" height="117" fill="none" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="-31.9" text-anchor="middle">A</text><g class="pele-er-attributes" font-size="14"><text class="pele-er-type" fill="var(--_m)" x="-209.09" y="3.4">List&lt;string&gt;</text><text class="pele-er-name" x="-120.72" y="3.4">tags</text><text class="pele-er-comment" fill="var(--_m)" xml:space="preserve"><tspan x="-21.26" y="3.4">a comment long enough that it has to</tspan><tspan x="-21.26" y="21.4">wrap onto a second line of the cell</tspan></text><text class="pele-er-type" fill="var(--_m)" x="-209.09" y="48.4">string?</text><text class="pele-er-name" x="-120.72" y="48.4">alias</text><text class="pele-er-keys" font-size="12" fill="var(--_m)" x="-75.94" y="48.4">UK, FK</text></g></g></g></svg>
    ),
  )
}

///|
test "a curved relationship stops short of each box" {
  let result = drawn(
    "erDiagram\n A ||--o{ B : x\n A ||--o{ C : y\n B ||--|| D : z\n C ||--|| D : w\n A }|..|| D : far",
  ).unwrap()
  inspect("\{result.width}x\{result.height}", content="319x338")
  inspect(
    body(result.svg),
    content=(
      #|<g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round"><g class="pele-edge pele-er-identifying" data-id="id_entity-A-0_entity-B-1_0"><path d="M182,56L182,74L182,77.5C182,81 56,84.5 56,88L56,127L56,145"/><path class="pele-marker" d="M177,62L187,62M177,66L187,66"/><path class="pele-marker" d="M62,145L56,135L50,145"/><circle class="pele-marker" cx="56" cy="131" r="3.5" fill="var(--_bg)"/></g><g class="pele-edge pele-er-identifying" data-id="id_entity-A-0_entity-C-2_1"><path d="M200,56L200,145"/><path class="pele-marker" d="M195,62L205,62M195,66L205,66"/><path class="pele-marker" d="M206,145L200,135L194,145"/><circle class="pele-marker" cx="200" cy="131" r="3.5" fill="var(--_bg)"/></g><g class="pele-edge pele-er-identifying" data-id="id_entity-B-1_entity-D-3_2"><path d="M56,193L56,211L56,250C56,253.5 182,257 182,260.5L182,264L182,282"/><path class="pele-marker" d="M51,199L61,199M51,203L61,203"/><path class="pele-marker" d="M187,276L177,276M187,272L177,272"/></g><g class="pele-edge pele-er-identifying" data-id="id_entity-C-2_entity-D-3_3"><path d="M200,193L200,282"/><path class="pele-marker" d="M195,199L205,199M195,203L205,203"/><path class="pele-marker" d="M205,276L195,276M205,272L195,272"/></g><g class="pele-edge pele-er-non-identifying" data-id="id_entity-A-0_entity-D-3_4"><path d="M218,56L218,74L218,79.06C218,86.66 296.17,86.66 296.17,94.25L296.17,243.75C296.17,251.34 218,251.34 218,258.94L218,264L218,282" stroke-dasharray="4 3"/><path class="pele-marker" d="M212,56L218,66L224,56M213,69.5L223,69.5"/><path class="pele-marker" d="M223,276L213,276M223,272L213,272"/></g></g><g class="pele-edge-labels" font-size="14"><g class="pele-edge-label" data-id="id_entity-A-0_entity-B-1_0"><rect x="48.5" y="90" width="15" height="21" rx="3" fill="var(--_bg)"/><text x="56" y="105.4" text-anchor="middle">x</text></g><g class="pele-edge-label" data-id="id_entity-A-0_entity-C-2_1"><rect x="192.5" y="90" width="15" height="21" rx="3" fill="var(--_bg)"/><text x="200" y="105.4" text-anchor="middle">y</text></g><g class="pele-edge-label" data-id="id_entity-B-1_entity-D-3_2"><rect x="48.5" y="227" width="15" height="21" rx="3" fill="var(--_bg)"/><text x="56" y="242.4" text-anchor="middle">z</text></g><g class="pele-edge-label" data-id="id_entity-C-2_entity-D-3_3"><rect x="190.95" y="227" width="18.11" height="21" rx="3" fill="var(--_bg)"/><text x="200" y="242.4" text-anchor="middle">w</text></g><g class="pele-edge-label" data-id="id_entity-A-0_entity-D-3_4"><rect x="284" y="158.5" width="24.34" height="21" rx="3" fill="var(--_bg)"/><text x="296.17" y="173.9" text-anchor="middle">far</text></g></g><g class="pele-nodes"><g class="pele-node pele-entity" data-id="A" transform="translate(200,32)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">A</text></g><g class="pele-node pele-entity" data-id="B" transform="translate(56,169)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">B</text></g><g class="pele-node pele-entity" data-id="C" transform="translate(200,169)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">C</text></g><g class="pele-node pele-entity" data-id="D" transform="translate(200,306)"><rect x="-48" y="-24" width="96" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">D</text></g></g></svg>
    ),
  )
}
