///|
fn drawn(
  source : String,
  max_width? : Double,
) -> @types.RenderResult raise @errors.PeleError {
  let options = { ..@types.RenderOptions::default(), max_width, }
  @core.render([@eventmodeling.eventmodeling], source, options)
}

///|
fn svg(source : String, max_width? : Double) -> String raise @errors.PeleError {
  drawn(source, max_width?).svg
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
/// The value of the first attribute `name` at or after `from`.
fn attr_from(text : String, from : Int32, name : String) -> Double {
  let prefix = " \{name}=\""
  let start = @util.index_of(text, prefix, from~) + prefix.length()
  @util.parse_float(
    @util.slice(text, start, end=@util.index_of(text, "\"", from=start)),
  )
}

///|
/// The left and right edges of the box of a frame.
fn box_span(svg : String, id : String) -> (Double, Double) {
  let at = @util.index_of(svg, "data-id=\"\{id}\"><rect")
  let x = attr_from(svg, at, "x")
  (x, x + attr_from(svg, at, "width"))
}

///|
test "a lane per kind of entity, a box per frame, and the inferred flow" {
  let out = svg(BASIC)
  inspect(drawn(BASIC).width, content="385")
  inspect(drawn(BASIC).height, content="227")
  inspect(count(out, "class=\"pele-cluster pele-em-lane\""), content="3")
  for
    label in [
      "UI/Automation", "Command/Read Model", "Events", "CartUI", "AddItem", "ItemAdded",
    ] {
    inspect(out.contains(">\{label}<"), content="true")
  }
  inspect(
    out.contains("class=\"pele-node pele-em-ui\" data-id=\"01\""),
    content="true",
  )
  inspect(
    out.contains("class=\"pele-node pele-em-command\" data-id=\"02\""),
    content="true",
  )
  inspect(
    out.contains("class=\"pele-node pele-em-event\" data-id=\"03\""),
    content="true",
  )
  inspect(count(out, "class=\"pele-edge\""), content="2")
  inspect(count(out, "class=\"pele-marker\""), content="2")
  inspect(out.contains("data-id=\"01-02\""), content="true")
  inspect(out.contains("NaN"), content="false")
}

///|
test "an arrow between lanes drops straight down from the end of one frame to the next" {
  let out = svg(BASIC)
  inspect(out.contains("d=\"M244.13,61V86\""), content="true")
  inspect(out.contains("d=\"M292.13,134V159\""), content="true")
}

///|
test "each kind is colored from its own series slot and a UI is left plain" {
  let out = svg(
    "eventmodeling\ntf 01 ui A\ntf 02 cmd B\ntf 03 evt C\ntf 04 rmo D\ntf 05 pcr E\n",
  )
  for slot in [1, 2, 3, 7] {
    inspect(out.contains("var(--pele-series-\{slot},"), content="true")
  }
  inspect(count(out, "fill-opacity=\"0.22\""), content="4")
}

///|
test "time moves to the right and the frames of a lane do not overlap" {
  let out = svg(
    "eventmodeling\ntf 01 cmd A\ntf 02 evt B\ntf 03 cmd C\ntf 04 cmd D\ntf 05 evt E\n",
  )
  for pair in [("01", "02"), ("02", "03"), ("03", "04"), ("04", "05")] {
    inspect(box_span(out, pair.1).0 > box_span(out, pair.0).0, content="true")
  }
  inspect(box_span(out, "03").0 > box_span(out, "01").1, content="true")
  inspect(box_span(out, "04").0 > box_span(out, "03").1, content="true")
  inspect(box_span(out, "05").0 > box_span(out, "02").1, content="true")
}

///|
test "frames of one lane are joined along the lane" {
  let out = svg("eventmodeling\ntf 01 evt A\ntf 02 evt B ->> 01\n")
  let (_, right) = box_span(out, "01")
  inspect(out.contains("d=\"M\{@svg.num(right)},"), content="true")
}

///|
test "each namespace gets its own lane, shared by its frames" {
  let out = svg(
    "eventmodeling\ntf 01 cmd Cart.Add\ntf 02 evt Cart.Added\ntf 03 cmd Cart.Remove\ntf 04 evt Other.Seen\ntf 05 evt Plain\ntf 06 evt a.b.c\n",
  )
  inspect(count(out, "class=\"pele-cluster pele-em-lane\""), content="4")
  for label in ["C/RM: Cart", "Events", "Stream: Cart", "Stream: Other"] {
    inspect(out.contains("data-id=\"\{label}\""), content="true")
  }
}

///|
test "inline data and data blocks are shown, a block winning over inline data" {
  let out = svg(
    "eventmodeling\ntf 01 cmd A { productId: 7 }\ntf 02 evt B [[Payload]] { ignored: true }\ntf 03 evt C \"{ \"a\": 1 }\"\ntf 04 evt D [[Missing]]\ntf 05 evt E {x}\ndata Payload {\n  description: string\n    nested: true\n}\n",
  )
  inspect(out.contains(">productId: 7</tspan>"), content="true")
  inspect(out.contains(">  nested: true</tspan>"), content="true")
  inspect(out.contains("ignored"), content="false")
  inspect(count(out, "class=\"pele-em-data\""), content="4")
}

///|
test "long data is wrapped at 48 columns" {
  let out = svg("eventmodeling\ntf 01 evt A { " + "x".repeat(100) + " }\n")
  inspect(out.contains(">" + "x".repeat(48) + "</tspan>"), content="true")
  inspect(out.contains(">" + "x".repeat(4) + "</tspan>"), content="true")
}

///|
test "comment lines inside data blocks are kept, as Mermaid does" {
  let out = svg(
    "eventmodeling\n%% a real comment\ntf 01 evt A [[D]]\ndata D {\n  %% kept\n  a: 1\n}\n",
  )
  inspect(out.contains(">%% kept</tspan>"), content="true")
  inspect(out.contains("a real comment"), content="false")
}

///|
test "notes and specifications are listed under the lanes" {
  let out = svg(
    "eventmodeling\ntf 01 cmd Update\ntf 02 evt Updated\nentity Updated\nnote 02 `md` {\n  first line\n  second line\n}\ngwt 01\n given\n  evt Updated\n  evt Other\n when\n  cmd Update\n then\n  evt Updated\ngwt 02 given evt A then evt B\n",
  )
  inspect(count(out, "class=\"pele-em-note\""), content="1")
  inspect(count(out, "class=\"pele-em-specification\""), content="2")
  inspect(out.contains("Note · 02 Updated"), content="true")
  inspect(out.contains(">second line</tspan>"), content="true")
  inspect(out.contains(">Given  Updated, Other</tspan>"), content="true")
  inspect(out.contains(">When  Update</tspan>"), content="true")
  inspect(out.contains(">Then  B</tspan>"), content="true")
}

///|
test "titles are drawn and named for assistive technology" {
  let out = svg(
    "eventmodeling title Checkout\ntf 01 ui A accTitle: Acc\ntf 02 cmd B accDescr: Described\n",
  )
  inspect(out.contains(">Checkout<"), content="true")
  inspect(out.contains("<title id=\"pele-title\">Acc</title>"), content="true")
  inspect(
    out.contains("<desc id=\"pele-desc\">Described</desc>"),
    content="true",
  )
  inspect(
    svg("---\ntitle: Front\n---\neventmodeling\ntf 01 ui A\n").contains(
      ">Front<",
    ),
    content="true",
  )
}

///|
test "an empty model is drawn, and drawing is deterministic" {
  inspect(svg("eventmodeling").contains("<svg"), content="true")
  inspect(svg(BASIC) == svg(BASIC), content="true")
}

///|
test "what Mermaid rejects is rejected, with its message for a reused frame number" {
  try {
    ignore(
      svg(
        "eventmodeling\n  tf 01 ui UI\n  %% a comment line\n  rf 01 evt Event\n",
      ),
    )
    fail("accepted")
  } catch {
    @errors.PeleError(failure) => {
      inspect(
        failure.message,
        content="Duplicate event modeling frame ID \"01\" on line 4",
      )
      inspect(failure.line, content="4")
    }
    error => fail("\{error}")
  }
}

///|
const NARROW : String = "eventmodeling\ntf 01 ui CartUI\ntf 02 cmd AddItem { id: 7 }\ntf 03 evt ItemAdded\ntf 04 rmo View ->> 03 ->> 01\nnote 02 {\n hi\n}\ngwt 01 given evt A then evt B\n"

///|
test "a narrow width stacks the frames down, each under its lane heading" {
  let result = drawn(NARROW, max_width=400)
  inspect(result.width, content="400")
  inspect(result.height, content="601")
  let out = result.svg
  inspect(count(out, "class=\"pele-cluster pele-em-lane\""), content="4")
  inspect(
    out.contains(
      "<text class=\"pele-cluster-label\" font-size=\"14\" font-weight=\"var(--_hw)\" fill=\"var(--_m)\" x=\"20\" y=\"23.4\" text-anchor=\"start\" xml:space=\"preserve\">UI/Automation</text>",
    ),
    content="true",
  )
  inspect(
    out.contains(
      "<rect x=\"8\" y=\"41\" width=\"360\" height=\"41\" fill=\"var(--_bg)\" stroke=\"var(--_b)\"",
    ),
    content="true",
  )
}

///|
test "each card tells its frame number at its right" {
  let out = svg(NARROW, max_width=400)
  inspect(
    out.contains(
      "<text class=\"pele-em-frame\" x=\"356\" y=\"65\" text-anchor=\"end\" font-size=\"12\" fill=\"var(--_m)\">01</text>",
    ),
    content="true",
  )
  inspect(count(out, "class=\"pele-em-frame\""), content="4")
}

///|
test "neighbouring cards are joined straight down" {
  let out = svg(NARROW, max_width=400)
  inspect(out.contains("d=\"M188,82V136\""), content="true")
  inspect(out.contains("d=\"M188,208V262\""), content="true")
}

///|
test "a relation that skips a card runs down a rail beside the cards" {
  let out = svg(NARROW, max_width=400)
  inspect(out.contains("d=\"M368,56.5H380V396.5H375\""), content="true")
}

///|
test "data is wrapped to the card and notes follow the cards" {
  let out = svg(NARROW, max_width=400)
  inspect(out.contains(">id: 7</tspan>"), content="true")
  inspect(out.contains("Note · 02 AddItem"), content="true")
  inspect(out.contains(">Given  A</tspan>"), content="true")
}

///|
test "a width that leaves no room for a card is exceeded rather than squeezed" {
  let result = drawn(NARROW, max_width=100)
  inspect(result.width, content="176")
  inspect(result.height, content="727")
}
