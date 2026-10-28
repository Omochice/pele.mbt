// Ported from pele v1.8.0, tests/render/sequence.test.ts; the snapshots were taken from pele's render.

///|
fn drawn(
  source : String,
  max_width? : Double,
  responsive? : Bool,
  monospace? : Array[String],
) -> Result[@types.RenderResult, @errors.Failure] {
  let options = {
    ..@types.RenderOptions::default(),
    max_width,
    responsive,
    monospace,
  }
  Ok(@core.render([@sequence.sequence], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn svg_of(
  source : String,
  max_width? : Double,
  monospace? : Array[String],
) -> String {
  match drawn(source, max_width?, monospace?) {
    Ok(result) => result.svg
    Err(failure) => failure.message
  }
}

///|
/// The source with `settings` as its `sequence` config in front matter, each setting on its own line.
fn configured(settings : String, source : String) -> String {
  "---\nconfig:\n  sequence:\n    " + settings + "\n---\n" + source
}

///|
/// The size and the drawing without its opening tag, one element per line.
fn snapshot(source : String, max_width? : Double) -> String {
  match drawn(source, max_width?) {
    Ok(result) => {
      let svg = result.svg
      let body = @util.slice(svg, @util.index_of(svg, ">") + 1)
      let lines = StringBuilder()
      let mut last = 0
      let mut at = @util.index_of(body, "><")
      while at != -1 {
        lines.write_string(@util.slice(body, last, end=at + 1))
        lines.write_char('\n')
        last = at + 1
        at = @util.index_of(body, "><", from=last)
      }
      lines.write_string(@util.slice(body, last))
      "\{result.width}x\{result.height}\n\{lines}"
    }
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
/// The number that starts at `at`, as far as it runs.
fn number_at(text : String, at : Int32) -> Double {
  let mut end = at
  while end < text.length() {
    let c = @util.code_at(text, end)
    if !(@util.is_digit(c) || c == '.'.to_int() || c == '-'.to_int()) {
      break
    }
    end += 1
  }
  @util.to_number(@util.slice(text, at, end~))
}

///|
/// The id and x position of every lifeline, in drawing order.
fn lifelines(svg : String) -> Array[(String, Double)] {
  let out = []
  let open = "<path class=\"pele-lifeline\" data-id=\""
  let mut at = @util.index_of(svg, open)
  while at != -1 {
    let start = at + open.length()
    let quote = @util.index_of(svg, "\"", from=start)
    let id = @util.slice(svg, start, end=quote)
    out.push((id, number_at(svg, quote + "\" d=\"M".length())))
    at = @util.index_of(svg, open, from=quote)
  }
  out
}

///|
fn lifeline(svg : String, id : String) -> Double {
  for entry in lifelines(svg) {
    if entry.0 == id {
      return entry.1
    }
  }
  @double.not_a_number
}

///|
fn ids(svg : String) -> String {
  lifelines(svg).map(entry => entry.0).join(",")
}

///|
/// The first message line drawn, between its opening tag and the end of its group.
fn message_line(arrow : String) -> String {
  between(
    svg_of("sequenceDiagram\n  A\{arrow}B: x"),
    "<g class=\"pele-edge pele-message\" data-id=\"i0\">",
    "</g>",
  )
}

///|
/// The texts of the elements that start with `open`, in order.
fn texts_of(svg : String, open : String) -> Array[String] {
  let out = []
  let mut at = @util.index_of(svg, open)
  while at != -1 {
    let start = @util.index_of(svg, ">", from=at) + 1
    let end = @util.index_of(svg, "<", from=start)
    out.push(@util.slice(svg, start, end~))
    at = @util.index_of(svg, open, from=end)
  }
  out
}

///|
test "reports size and type" {
  let result = drawn("sequenceDiagram\n  Alice->>Bob: Hello").unwrap()
  inspect(result.kind, content="sequence")
  inspect(result.width > 100 && result.height > 100, content="true")
  inspect(result.links.length(), content="0")
  inspect(
    result.svg.contains("viewBox=\"0 0 \{result.width} \{result.height}\""),
    content="true",
  )
  inspect(
    result.svg.has_prefix(
      "<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-sequence\"",
    ),
    content="true",
  )
}

///|
test "renders an empty diagram and a lone participant" {
  inspect(drawn("sequenceDiagram").unwrap().width > 0, content="true")
  inspect(
    count(
      svg_of("sequenceDiagram\n participant Solo"),
      "class=\"pele-node pele-actor",
    ),
    content="2",
  )
}

///|
test "themes through custom properties with fallbacks and no style element" {
  let svg = svg_of(
    "sequenceDiagram\n  Alice->>+Bob: Hi\n  Note over Alice: n\n  Bob-->>-Alice: Yo",
  )
  for
    token in [
      "--pele-bg", "--pele-fg", "--pele-line", "--pele-surface", "--pele-border",
      "--pele-font",
    ] {
    inspect(svg.contains("var(\{token},"), content="true")
  }
  inspect(svg.contains("<style"), content="false")
  inspect(svg.contains("<marker"), content="false")
  inspect(svg.contains("<defs"), content="false")
}

///|
test "mirrors participants at the bottom unless told not to" {
  let source = "sequenceDiagram\n  Alice->>Bob: Hi"
  let mirrored = drawn(source).unwrap()
  let single = drawn(configured("mirrorActors: false", source)).unwrap()
  inspect(count(mirrored.svg, "class=\"pele-node pele-actor"), content="4")
  inspect(count(mirrored.svg, "pele-actor-footer"), content="2")
  inspect(count(single.svg, "class=\"pele-node pele-actor"), content="2")
  inspect(single.height < mirrored.height, content="true")
  let directive = svg_of(
    "%%{init: {\"sequence\": {\"mirrorActors\": false}}}%%\n" + source,
  )
  inspect(count(directive, "pele-actor-footer"), content="0")
}

///|
test "keeps participants in order of appearance and spaces them by their text" {
  let short = svg_of("sequenceDiagram\n  A->>B: hi\n  B->>C: hi")
  let long = svg_of(
    "sequenceDiagram\n  A->>B: a considerably longer message than before\n  B->>C: hi",
  )
  inspect(ids(short), content="A,B,C")
  inspect(
    lifeline(short, "A") < lifeline(short, "B") &&
    lifeline(short, "B") < lifeline(short, "C"),
    content="true",
  )
  inspect(
    lifeline(long, "B") - lifeline(long, "A") >
    lifeline(short, "B") - lifeline(short, "A") + 100,
    content="true",
  )
  inspect(
    (lifeline(long, "C") -
    lifeline(long, "B") -
    (lifeline(short, "C") - lifeline(short, "B"))).abs() <
    0.05,
    content="true",
  )
}

///|
test "shares the width a long message needs among the gaps it crosses" {
  let svg = svg_of(
    "sequenceDiagram\n  participant A\n  participant B\n  participant C\n  A->>C: a message that is far too long for two default gaps to hold",
  )
  let ab = lifeline(svg, "B") - lifeline(svg, "A")
  let bc = lifeline(svg, "C") - lifeline(svg, "B")
  inspect((ab - bc).abs() < 0.05, content="true")
  inspect(lifeline(svg, "C") - lifeline(svg, "A") > 360, content="true")
}

///|
test "widens a participant to its label and honors actorMargin" {
  let source = "sequenceDiagram\n  participant A\n  participant B"
  let tight = svg_of(source)
  let wide = svg_of(configured("actorMargin: 200", source))
  inspect(
    lifeline(wide, "B") - lifeline(wide, "A") ==
    lifeline(tight, "B") - lifeline(tight, "A") + 160,
    content="true",
  )
  let labelled = svg_of(
    "sequenceDiagram\n  participant A as A participant with a long description\n  participant B",
  )
  inspect(
    lifeline(labelled, "B") - lifeline(labelled, "A") >
    lifeline(tight, "B") - lifeline(tight, "A") + 80,
    content="true",
  )
}

///|
test "draws each arrow type with its line and heads" {
  inspect(message_line("->").contains("pele-marker"), content="false")
  inspect(message_line("->").contains("stroke-dasharray"), content="false")
  inspect(message_line("-->").contains("stroke-dasharray"), content="true")
  inspect(count(message_line("->>"), "pele-marker"), content="1")
  inspect(message_line("-->>").contains("stroke-dasharray"), content="true")
  inspect(count(message_line("<<->>"), "pele-marker"), content="2")
  inspect(count(message_line("<<-->>"), "pele-marker"), content="2")
  let cross = between(message_line("-x"), "pele-marker\" d=\"M", "\"")
  inspect(cross.contains("M"), content="true")
  inspect(
    message_line("-)").contains("stroke-linejoin=\"round\""),
    content="true",
  )
  inspect(message_line("-)").contains("fill=\"var(--_l)\""), content="false")
  for half in ["-|\\", "-|/", "-\\\\", "-//"] {
    inspect(count(message_line(half), "pele-marker"), content="1")
    inspect(
      message_line("-" + half).contains("stroke-dasharray"),
      content="true",
    )
  }
  for half in ["/|-", "\\|-", "//-", "\\\\-"] {
    inspect(count(message_line(half), "pele-marker"), content="1")
    inspect(
      message_line(half + "-").contains("stroke-dasharray"),
      content="true",
    )
  }
}

///|
test "puts a half head above or below the line as its name says" {
  let head = (arrow : String) => {
    let d = between(
      svg_of("sequenceDiagram\n  A\{arrow}B: x"),
      "pele-marker\" d=\"",
      "\"",
    )
    let ys = []
    let mut at = @util.index_of(d, ",")
    while at != -1 {
      ys.push(number_at(d, at + 1))
      at = @util.index_of(d, ",", from=at + 1)
    }
    ys
  }
  let top = head("-|\\")
  let bottom = head("-|/")
  let low = (ys : Array[Double]) => ys.fold(init=ys[0], @util.js_min)
  let high = (ys : Array[Double]) => ys.fold(init=ys[0], @util.js_max)
  inspect(low(top) < top[0] && high(top) == top[0], content="true")
  inspect(high(bottom) > bottom[0] && low(bottom) == bottom[0], content="true")
}

///|
test "runs a message between the lifelines of its participants, in order from the top" {
  let svg = svg_of("sequenceDiagram\n  A->>B: one\n  B-->>A: two")
  let first = between(svg, "data-id=\"i0\"><path d=\"M", "\"")
  let second = between(svg, "data-id=\"i1\"><path d=\"M", "\"")
  let parts = (d : String) => {
    let comma = @util.index_of(d, ",")
    let h = @util.index_of(d, "H")
    (number_at(d, 0), number_at(d, comma + 1), number_at(d, h + 1))
  }
  let (x0, y0, end0) = parts(first)
  let (x1, y1, _) = parts(second)
  inspect(x0 == lifeline(svg, "A"), content="true")
  inspect(
    end0 < lifeline(svg, "B") && end0 > lifeline(svg, "B") - 10,
    content="true",
  )
  inspect(x1 == lifeline(svg, "B"), content="true")
  inspect(y1 > y0, content="true")
}

///|
test "loops a message to self back to its own lifeline" {
  let svg = svg_of("sequenceDiagram\n  A->>A: think\n  A->>B: tell")
  let d = between(svg, "data-id=\"i0\"><path d=\"", "\"")
  inspect(d.contains("A6,6"), content="true")
  inspect(number_at(d, 1) == lifeline(svg, "A"), content="true")
  let square = svg_of(
    configured("rightAngles: true", "sequenceDiagram\n  A->>A: think"),
  )
  inspect(
    between(square, "data-id=\"i0\"><path d=\"", "\"").contains("A6,6"),
    content="false",
  )
}

///|
test "starts the next row below a message to self whose label is taller than its loop" {
  let baselines = (svg : String, id : String) => {
    let label = between(
      svg,
      "<g class=\"pele-edge-label\" data-id=\"\{id}\">",
      "</g>",
    )
    let ys = []
    let mut at = @util.index_of(label, " y=\"")
    while at != -1 {
      ys.push(number_at(label, at + 4))
      at = @util.index_of(label, " y=\"", from=at + 4)
    }
    ys
  }
  let step = (svg : String) => {
    let own = baselines(svg, "i0")
    baselines(svg, "i1")[0] - own[own.length() - 1]
  }
  let broken = svg_of(
    "sequenceDiagram\n  A->>A: one<br/>two<br/>three\n  A->>B: next",
  )
  let own = baselines(broken, "i0")
  inspect(own.length(), content="3")
  inspect(step(broken) >= own[1] - own[0], content="true")
  let wrapped = svg_of(
    "sequenceDiagram\n  A->>A: a message to self long enough to wrap onto several lines\n  A->>B: next",
    max_width=200,
  )
  inspect(baselines(wrapped, "i0").length() > 1, content="true")
  inspect(step(wrapped) >= own[1] - own[0], content="true")
}

///|
test "widens gaps within maxWidth before wrapping a message" {
  let lines = (svg : String, id : String) => {
    let label = between(
      svg,
      "<g class=\"pele-edge-label\" data-id=\"\{id}\">",
      "</g>",
    )
    let spans = count(label, "<tspan")
    if spans == 0 {
      1
    } else {
      spans
    }
  }
  let reported = "sequenceDiagram\n  participant U as UE\n  participant M as MeNB (LTE anchor)\n  participant S as SgNB (5G, NR leg)\n" +
    "  M->>S: SgNB Addition Request (DRB-ID, CG-ConfigInfo)\n  M->>U: RRCConnectionReconfiguration (carries the NR SCG config)\n  U->>M: RRCConnectionReconfigurationComplete"
  let long = "thisIsAnExtremelyLongMessageIdentifierThatShouldHaveRoomToFit"
  let cases : Array[(String, String, Double, Array[String]?)] = [
    (reported, "i2", 760, None),
    (reported, "i2", 760.5, None),
    (reported, "i2", 760, Some(["messages"])),
    (reported, "i2", 400, None),
    (
      "sequenceDiagram\n  participant A\n  participant B\n  participant C\n  B->>A: \{"x".repeat(168)}\n  C->>A: \{"x".repeat(89)}",
      "i1",
      709,
      None,
    ),
    ("sequenceDiagram\n  A->>B: \{long}", "i0", 300.25, None),
    (
      "sequenceDiagram\n  participant A\n  participant B\n  participant C\n  participant D\n  A->>D: \{long}",
      "i0",
      450,
      None,
    ),
    (
      "sequenceDiagram\n  A->>+B: \{long}\n  Note right of B: note\n  B-->>-A: ok",
      "i0",
      400,
      None,
    ),
  ]
  let drawn_lines = cases.map(case => {
    let (source, id, max_width, monospace) = case
    guard drawn(source, max_width~, monospace?) is Ok(result) else {
      return "failed"
    }
    "\{result.width <= max_width} \{lines(result.svg, id)}"
  })
  inspect(
    drawn_lines.join(" | "),
    content=(
      #|true 1 | true 1 | true 1 | true 2 | true 1 | true 3 | true 2 | true 2
    ),
  )
}

///|
test "measures messages in the monospace font when monospace lists them" {
  let src = "sequenceDiagram\n  A->>B: a message in the monospace font\n  B->>B: a message to itself\n  Note over A,B: a note"
  let plain = drawn(src).unwrap()
  let mono = drawn(src, monospace=["messages"]).unwrap()
  inspect(
    mono.svg.contains(
      "<g class=\"pele-edge-labels\" font-size=\"14\" font-family=\"var(--_fm)\">",
    ),
    content="true",
  )
  inspect(plain.svg.contains("font-family=\"var(--_fm)\""), content="false")
  inspect(count(mono.svg, "font-family=\"var(--_fm)\""), content="1")
  let gap = (svg : String) => lifeline(svg, "B") - lifeline(svg, "A")
  inspect(gap(mono.svg) > gap(plain.svg), content="true")
  inspect(
    mono.width - gap(mono.svg) > plain.width - gap(plain.svg),
    content="true",
  )
  for monospace in [[], ["message"], ["members"]] {
    assert_eq(svg_of(src, monospace~), plain.svg)
  }
}

///|
test "widens gaps within maxWidth for messages measured in the monospace font" {
  let source = "sequenceDiagram\n  participant UE\n  participant gNB\n  participant AMF\n  gNB->>UE: RRCConnectionReconfigurationComplete\n  UE->>gNB: ok"
  let mono = drawn(source, max_width=760, monospace=["messages"]).unwrap()
  inspect(mono.width <= 760, content="true")
  inspect(
    mono.width > drawn(source, max_width=760).unwrap().width,
    content="true",
  )
  inspect(
    mono.svg.contains(">RRCConnectionReconfigurationComplete<"),
    content="true",
  )
}

///|
test "draws activations, nested ones offset, and ends arrows at their edges" {
  let svg = svg_of(
    "sequenceDiagram\n  A->>+B: one\n  A->>+B: two\n  B-->>-A: three\n  B-->>-A: four",
  )
  let b = lifeline(svg, "B")
  let open = "<rect class=\"pele-activation\" data-id=\"B\" x=\""
  let first = @util.index_of(svg, open)
  let second = @util.index_of(svg, open, from=first + 1)
  inspect(count(svg, open), content="2")
  inspect(number_at(svg, first + open.length()) == b - 5, content="true")
  inspect(number_at(svg, second + open.length()) == b - 1, content="true")
  let height = (at : Int32) => {
    number_at(
      svg,
      @util.index_of(svg, "height=\"", from=at) + "height=\"".length(),
    )
  }
  inspect(height(first) > height(second), content="true")
  let d = between(svg, "data-id=\"i0\"><path d=\"M", "\"")
  inspect(number_at(d, @util.index_of(d, "H") + 1) == b - 5 - 7, content="true")
}

///|
test "accepts explicit activate and deactivate, and keeps an unclosed activation to the end" {
  let closed = svg_of(
    "sequenceDiagram\n  A->>B: go\n  activate B\n  B-->>A: done\n  deactivate B",
  )
  inspect(count(closed, "pele-activation\""), content="1")
  let open = svg_of("sequenceDiagram\n  activate A\n  A->>B: go")
  inspect(count(open, "pele-activation\""), content="1")
}

///|
test "rejects deactivating a participant that is not active" {
  inspect(
    svg_of("sequenceDiagram\n  A->>B: go\n  deactivate B"),
    content="Trying to inactivate an inactive participant (B)",
  )
  inspect(drawn("sequenceDiagram\n  A->>-B: go") is Err(_), content="true")
}

///|
test "places notes left of, right of, and over participants" {
  let svg = svg_of(
    "sequenceDiagram\n  participant A\n  participant B\n  Note left of A: L\n  Note right of B: R\n  Note over A: O\n  Note over A,B: AB",
  )
  let a = lifeline(svg, "A")
  let b = lifeline(svg, "B")
  let notes = []
  let open = "<g class=\"pele-note\" data-id=\"i"
  let mut at = @util.index_of(svg, open)
  while at != -1 {
    let x = @util.index_of(svg, "<rect x=\"", from=at) + "<rect x=\"".length()
    let y = @util.index_of(svg, " y=\"", from=x) + " y=\"".length()
    let w = @util.index_of(svg, " width=\"", from=y) + " width=\"".length()
    let left = number_at(svg, x)
    notes.push((left, left + number_at(svg, w), number_at(svg, y)))
    at = @util.index_of(svg, open, from=w)
  }
  inspect(notes.length(), content="4")
  inspect(notes[0].1 < a, content="true")
  inspect(notes[1].0 > b, content="true")
  inspect(((notes[2].0 + notes[2].1) / 2 - a).abs() < 0.05, content="true")
  inspect(notes[3].0 < a && notes[3].1 > b, content="true")
  for i in 1..<notes.length() {
    inspect(notes[i].2 > notes[i - 1].2, content="true")
  }
}

///|
test "frames loop, alt, opt, par, critical, and break blocks with their titles and sections" {
  let svg = svg_of(
    "sequenceDiagram\n  loop Every minute\n  A->>B: a\n  end\n  alt ok\n  A->>B: b\n  else bad\n  A->>B: c\n  else\n  A->>B: d\n  end\n" +
    "  opt maybe\n  A->>B: e\n  end\n  par one\n  A->>B: f\n  and two\n  A->>B: g\n  end\n  par_over three\n  A->>B: h\n  end\n" +
    "  critical must\n  A->>B: i\n  option fail\n  A->>B: j\n  end\n  break stop\n  A->>B: k\n  end",
  )
  for kind in ["loop", "alt", "opt", "par", "critical", "break"] {
    inspect(
      svg.contains("class=\"pele-frame pele-frame-\{kind}\"") &&
      svg.contains(">\{kind}</text>"),
      content="true",
    )
  }
  inspect(count(svg, "class=\"pele-frame pele-frame-par\""), content="2")
  for
    title in [
      "[Every minute]", "[ok]", "[bad]", "[maybe]", "[one]", "[two]", "[three]",
      "[must]", "[fail]", "[stop]",
    ] {
    inspect(svg.contains(">\{title}</text>"), content="true")
  }
  let alt = between(svg, "<g class=\"pele-frame pele-frame-alt\">", "</g>")
  inspect(count(alt, "stroke-dasharray"), content="2")
}

///|
test "nests blocks inside one another" {
  let svg = svg_of(
    "sequenceDiagram\n  loop outer\n  alt inner\n  A->>B: x\n  end\n  end",
  )
  let frame = (kind : String) => {
    let rect = between(svg, "pele-frame-\{kind}\"><rect ", "/>")
    let value = (name : String) => {
      number_at(rect, @util.index_of(rect, name + "=\"") + name.length() + 2)
    }
    (value("x"), value("y"), value("width"), value("height"))
  }
  let (ox, oy, ow, oh) = frame("loop")
  let (ix, iy, iw, ih) = frame("alt")
  inspect(ix > ox && iy > oy, content="true")
  inspect(ix + iw < ox + ow && iy + ih < oy + oh, content="true")
}

///|
test "shades rect blocks with the given color, the inner one on top" {
  let svg = svg_of(
    "sequenceDiagram\n  rect rgb(191, 223, 255)\n  A->>B: x\n  rect rgba(0, 0, 255, .1)\n  B->>A: y\n  end\n  end\n  rect\n  A->>B: z\n  end",
  )
  inspect(count(svg, "<rect class=\"pele-rect\""), content="3")
  inspect(
    svg.contains("style=\"rx:var(--_r);fill:rgb(191, 223, 255);\""),
    content="true",
  )
  inspect(
    svg.contains("style=\"rx:var(--_r);fill:rgba(0, 0, 255, .1);\""),
    content="true",
  )
  inspect(
    @util.index_of(svg, "rgb(191, 223, 255)") <
    @util.index_of(svg, "rgba(0, 0, 255, .1)"),
    content="true",
  )
  inspect(
    @util.index_of(svg, "class=\"pele-rects\"") <
    @util.index_of(svg, "class=\"pele-lifelines\""),
    content="true",
  )
}

///|
test "groups participants in boxes, with color and title" {
  let svg = svg_of(
    "sequenceDiagram\n  box Aqua Group One\n  participant A\n  participant B\n  end\n  box Group Two\n  participant C\n  end\n  box rgb(1, 2, 3)\n  participant D\n  end\n  A->>D: x",
  )
  inspect(count(svg, "class=\"pele-cluster pele-box\""), content="3")
  inspect(svg.contains("style=\"rx:var(--_r);fill:Aqua;\""), content="true")
  inspect(svg.contains(">Group One</text>"), content="true")
  inspect(svg.contains(">Group Two</text>"), content="true")
  let plain = svg_of(
    "sequenceDiagram\n  participant A\n  participant B\n  participant C\n  participant D\n  A->>D: x",
  )
  inspect(
    lifeline(svg, "C") - lifeline(svg, "B") >
    lifeline(plain, "C") - lifeline(plain, "B"),
    content="true",
  )
  inspect(
    lifeline(svg, "B") - lifeline(svg, "A") ==
    lifeline(plain, "B") - lifeline(plain, "A"),
    content="true",
  )
}

///|
test "refuses a participant declared in two boxes" {
  inspect(
    svg_of(
      "sequenceDiagram\n  box One\n  participant A\n  end\n  box Two\n  participant A\n  end",
    ).contains("should only be defined in one Box"),
    content="true",
  )
}

///|
test "numbers messages with autonumber, its start and step, and the config switch" {
  let numbers = (svg : String) => {
    texts_of(svg, "<g class=\"pele-sequence-number\"><rect").length()
  }
  let badges = (svg : String) => {
    let out = []
    let open = "<g class=\"pele-sequence-number\">"
    let mut at = @util.index_of(svg, open)
    while at != -1 {
      let text = @util.index_of(svg, "<text", from=at)
      let start = @util.index_of(svg, ">", from=text) + 1
      out.push(
        @util.slice(svg, start, end=@util.index_of(svg, "<", from=start)),
      )
      at = @util.index_of(svg, open, from=start)
    }
    out.join(",")
  }
  let source = "sequenceDiagram\n  A->>B: one\n  B-->>A: two\n  A->>A: three"
  let with_line = (line : String) => {
    "sequenceDiagram\n  " +
    line +
    "\n  A->>B: one\n  B-->>A: two\n  A->>A: three"
  }
  inspect(numbers(svg_of(source)), content="0")
  inspect(badges(svg_of(with_line("autonumber"))), content="1,2,3")
  inspect(badges(svg_of(with_line("autonumber 10 5"))), content="10,15,20")
  inspect(
    badges(svg_of(with_line("autonumber 10.01 .01"))),
    content="10.01,10.02,10.03",
  )
  inspect(
    badges(svg_of(configured("showSequenceNumbers: true", source))),
    content="1,2,3",
  )
  inspect(
    badges(
      svg_of(
        "sequenceDiagram\n  autonumber\n  A->>B: one\n  autonumber off\n  B-->>A: two\n  autonumber\n  A->>B: three",
      ),
    ),
    content="1,3",
  )
  inspect(
    drawn("sequenceDiagram\n  autonumber 10.001\n  A->>B: one") is Err(_),
    content="true",
  )
}

///|
test "draws each participant kind, with figures above their labels" {
  let kinds = [
    "actor", "boundary", "control", "entity", "database", "collections", "queue",
  ]
  let source = StringBuilder()
  source.write_string("sequenceDiagram\n  participant P\n  actor A\n")
  for kind in kinds {
    if kind == "actor" {
      continue
    }
    source.write_string("  participant \{kind}@{ \"type\": \"\{kind}\" }\n")
  }
  let svg = svg_of(configured("mirrorActors: false", source.to_string()))
  for kind in ["participant"] {
    inspect(count(svg, "pele-actor-\{kind}\""), content="1")
  }
  for kind in kinds {
    inspect(count(svg, "pele-actor-\{kind}\""), content="1")
  }
  inspect(
    svg_of("sequenceDiagram\n  participant X@{ \"type\": \"nonsense\" }").contains(
      "pele-actor-participant\"",
    ),
    content="true",
  )
}

///|
test "rejects a config object that is not valid YAML" {
  inspect(
    drawn(
      "sequenceDiagram\n  participant C@{ \"type\" \"control\" }\n  C->>C: x",
    )
    is Err(_),
    content="true",
  )
  inspect(
    drawn("sequenceDiagram\n  participant C@{ \"type: \"control\" }") is Err(_),
    content="true",
  )
}

///|
test "creates a participant at its first message and ends a destroyed one with a cross" {
  let svg = svg_of(
    "sequenceDiagram\n  A->>B: hi\n  create participant C\n  A->>C: make\n  destroy C\n  A-xC: end\n  B->>A: bye",
  )
  let top = (id : String) => {
    let open = "pele-actor-participant\" data-id=\"\{id}\"><rect x=\""
    let at = @util.index_of(svg, open)
    number_at(svg, @util.index_of(svg, " y=\"", from=at) + 4)
  }
  inspect(top("C") > top("A") + 40, content="true")
  inspect(count(svg, "class=\"pele-destroy\" data-id=\"C\""), content="1")
  inspect(count(svg, "pele-actor-footer\" data-id=\"C\""), content="0")
  inspect(count(svg, "pele-actor-footer\" data-id=\"A\""), content="1")
  let life = (id : String) => {
    let d = between(svg, "pele-lifeline\" data-id=\"\{id}\" d=\"M", "\"")
    (
      number_at(d, @util.index_of(d, ",") + 1),
      number_at(d, @util.index_of(d, "V") + 1),
    )
  }
  inspect(life("C").0 > top("C"), content="true")
  inspect(life("C").1 < life("A").1, content="true")
}

///|
test "enforces the rules of create and destroy" {
  inspect(
    svg_of("sequenceDiagram\n  A->>B: hi\n  create participant A\n  B->>A: x").contains(
      "same id",
    ),
    content="true",
  )
  inspect(
    svg_of("sequenceDiagram\n  create participant C\n  A->>B: x").contains(
      "created participant C",
    ),
    content="true",
  )
  inspect(
    svg_of("sequenceDiagram\n  A->>B: hi\n  destroy B\n  A->>C: x").contains(
      "destroyed participant B",
    ),
    content="true",
  )
}

///|
test "marks central connections with a circle on the lifeline" {
  let svg = svg_of(
    "sequenceDiagram\n  A->>()B: to\n  A()->>B: from\n  A()->>()B: both",
  )
  let circles = (id : Int32) => {
    count(between(svg, "data-id=\"i\{id}\">", "</g>"), "pele-central")
  }
  inspect(
    [0, 1, 2, 3, 4, 5, 6].map(i => circles(i).to_string()).join(","),
    content="1,0,1,0,2,0,0",
  )
}

///|
test "breaks lines at <br> and wraps only when asked" {
  let lines = (svg : String, id : Int32) => {
    let g = between(
      svg,
      "<g class=\"pele-edge-label\" data-id=\"i\{id}\">",
      "</g>",
    )
    let n = count(g, "<tspan x=")
    if n > 1 {
      n
    } else {
      1
    }
  }
  let long = "a message long enough that it would be wrapped if wrapping were switched on for it"
  let svg = svg_of(
    "sequenceDiagram\n  A->>B: one<br/>two<br>three\n  A->>B: \{long}\n  A->>B: nowrap: \{long}",
  )
  inspect(lines(svg, 0), content="3")
  inspect(lines(svg, 1), content="1")
  inspect(lines(svg, 2), content="1")
  inspect(
    lines(svg_of("sequenceDiagram\n  A->>B: wrap: \{long}"), 0) > 2,
    content="true",
  )
  inspect(
    lines(
      svg_of("sequenceDiagram\n  A->>B: \{long}\n  A->>B: wrap: \{long}"),
      1,
    ),
    content="1",
  )
  let all = svg_of(
    configured("wrap: true", "sequenceDiagram\n  A->>B: \{long}"),
  )
  inspect(lines(all, 0) > 1, content="true")
  inspect(
    lines(
      svg_of(
        configured("wrap: true", "sequenceDiagram\n  A->>B: nowrap: \{long}"),
      ),
      0,
    ),
    content="1",
  )
  let directive = svg_of("%%{wrap}%%\nsequenceDiagram\n  A->>B: \{long}")
  inspect(lines(directive, 0) > 1, content="true")
}

///|
test "decodes entity codes and escapes text" {
  let svg = svg_of(
    "sequenceDiagram\n  A->>B: I #9829; you #lt;3 & <more>\n  Note over A: a \"quoted\" note",
  )
  inspect(svg.contains("I \u{2665} you &lt;3 &amp; "), content="true")
  inspect(svg.contains("a &quot;quoted&quot; note"), content="true")
}

///|
test "stores participant links, properties, and details without drawing anything interactive" {
  let svg = svg_of(
    "sequenceDiagram\n  participant A\n  participant B\n  links A: {\"Repo\": \"https://example.com/repo\", \"Docs\": \"https://example.com/docs\"}\n" +
    "  link A: Tests @ https://example.com/?a=1&b=2@x\n  properties B: {\"class\": \"external svc\", \"icon\": \"@clock\"}\n  details B: some-element\n  A->>B: hi",
  )
  inspect(svg.contains("<a"), content="false")
  inspect(svg.contains("example.com"), content="false")
  inspect(
    svg.contains("pele-actor-participant external svc\" data-id=\"B\""),
    content="true",
  )
}

///|
test "titles the diagram from a statement" {
  let svg = svg_of("sequenceDiagram\n  title My title\n  A->>B: x")
  inspect(
    svg.contains("<text class=\"pele-title\" font-weight=\"var(--_tw)\"") &&
    svg.contains(">My title</tspan></text>"),
    content="true",
  )
  inspect(
    drawn("sequenceDiagram\n  title My title\n  A->>B: x").unwrap().height >
    drawn("sequenceDiagram\n  A->>B: x").unwrap().height,
    content="true",
  )
}

///|
test "writes accessible title and description" {
  let svg = svg_of(
    "sequenceDiagram\n  accTitle: A title\n  accDescr: A description\n  A->>B: x",
  )
  inspect(
    svg.contains("<title id=\"pele-title\">A title</title>"),
    content="true",
  )
  inspect(
    svg.contains("<desc id=\"pele-desc\">A description</desc>"),
    content="true",
  )
}

///|
test "hides participants no message mentions when asked" {
  let source = "sequenceDiagram\n  participant A\n  participant Unused\n  participant B\n  A->>B: x"
  inspect(ids(svg_of(source)), content="A,Unused,B")
  inspect(
    ids(svg_of(configured("hideUnusedParticipants: true", source))),
    content="A,B",
  )
}

///|
test "spaces messages by messageMargin" {
  let source = "sequenceDiagram\n  A->>B: one\n  A->>B: two\n  A->>B: three"
  let base = drawn(source).unwrap().height
  let loose = drawn(configured("messageMargin: 75", source)).unwrap().height
  inspect(loose == base + 3 * 40, content="true")
}

///|
test "aligns message text as messageAlign says" {
  let source = "sequenceDiagram\n  A->>B: a message that sets the width\n  A->>B: hi"
  let text_x = (svg : String) => {
    number_at(
      svg,
      @util.index_of(svg, "data-id=\"i1\"><text x=\"") +
      "data-id=\"i1\"><text x=\"".length(),
    )
  }
  let center = text_x(svg_of(source))
  inspect(
    text_x(svg_of(configured("messageAlign: left", source))) < center - 50,
    content="true",
  )
  inspect(
    text_x(svg_of(configured("messageAlign: right", source))) > center + 50,
    content="true",
  )
}

///|
test "shrinks to its container unless told not to" {
  inspect(
    svg_of("sequenceDiagram\n  A->>B: x").contains(
      "max-width:100%;height:auto;",
    ),
    content="true",
  )
  inspect(
    drawn("sequenceDiagram\n  A->>B: x", responsive=false).unwrap().svg.contains(
      "max-width",
    ),
    content="false",
  )
}

///|
test "throws structured errors" {
  let failure = match drawn("sequenceDiagram\n  Alice->>Bob\n") {
    Err(failure) => failure
    Ok(_) => abort("expected an error")
  }
  inspect(failure.code.to_string(), content="syntax")
  inspect(failure.line, content="2")
  inspect(
    failure.message.contains("Expecting 'TXT', got 'NEWLINE'"),
    content="true",
  )
  inspect(
    svg_of("sequenceDiagram\n  participant\n").contains(
      "Lexical error on line 2",
    ),
    content="true",
  )
  inspect(
    drawn("sequenceDiagram\n  loop x\n  A->>B: y") is Err(_),
    content="true",
  )
}

///|
test "draws two participants and a message" {
  inspect(
    snapshot("sequenceDiagram\n  Alice->>Bob: Hello"),
    content=(
      #|187x167
      #|<g transform="translate(41.34,8)">
      #|<g class="pele-lifelines" fill="none" stroke="var(--_b)">
      #|<path class="pele-lifeline" data-id="Alice" d="M0,44V107"/>
      #|<path class="pele-lifeline" data-id="Bob" d="M105.34,44V107"/>
      #|</g>
      #|<g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round">
      #|<g class="pele-edge pele-message" data-id="i0">
      #|<path d="M0,87H98.34"/>
      #|<path class="pele-marker" d="M105.34,87L97.34,90.36L97.34,83.64Z" fill="var(--_l)" stroke="none"/>
      #|</g>
      #|</g>
      #|<g class="pele-edge-labels" font-size="14">
      #|<g class="pele-edge-label" data-id="i0">
      #|<text x="52.67" y="77.4" text-anchor="middle">Hello</text>
      #|</g>
      #|</g>
      #|<g class="pele-nodes">
      #|<g class="pele-node pele-actor pele-actor-participant pele-actor-footer" data-id="Alice">
      #|<rect x="-33.34" y="107" width="66.67" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="0" y="134.6" text-anchor="middle">Alice</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant pele-actor-footer" data-id="Bob">
      #|<rect x="73.34" y="107" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="105.34" y="134.6" text-anchor="middle">Bob</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant" data-id="Alice">
      #|<rect x="-33.34" y="0" width="66.67" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="0" y="27.6" text-anchor="middle">Alice</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant" data-id="Bob">
      #|<rect x="73.34" y="0" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="105.34" y="27.6" text-anchor="middle">Bob</text>
      #|</g>
      #|</g>
      #|</g>
      #|</svg>
    ),
  )
}

///|
test "draws activations, notes, and a reply" {
  inspect(
    snapshot(
      "sequenceDiagram\n  Alice->>+Bob: Hi\n  Note over Alice: n\n  Bob-->>-Alice: Yo",
    ),
    content=(
      #|187x247
      #|<g transform="translate(41.34,8)">
      #|<g class="pele-lifelines" fill="none" stroke="var(--_b)">
      #|<path class="pele-lifeline" data-id="Alice" d="M0,44V187"/>
      #|<path class="pele-lifeline" data-id="Bob" d="M105.34,44V187"/>
      #|</g>
      #|<g class="pele-activations" fill="var(--_s)" stroke="var(--_b)">
      #|<rect class="pele-activation" data-id="Bob" x="100.34" y="87" width="10" height="80" rx="2"/>
      #|</g>
      #|<g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round">
      #|<g class="pele-edge pele-message" data-id="i0">
      #|<path d="M0,87H93.34"/>
      #|<path class="pele-marker" d="M100.34,87L92.34,90.36L92.34,83.64Z" fill="var(--_l)" stroke="none"/>
      #|</g>
      #|<g class="pele-edge pele-message" data-id="i3">
      #|<path d="M100.34,167H7" stroke-dasharray="4 4"/>
      #|<path class="pele-marker" d="M0,167L8,163.64L8,170.36Z" fill="var(--_l)" stroke="none"/>
      #|</g>
      #|</g>
      #|<g class="pele-edge-labels" font-size="14">
      #|<g class="pele-edge-label" data-id="i0">
      #|<text x="50.17" y="77.4" text-anchor="middle">Hi</text>
      #|</g>
      #|<g class="pele-edge-label" data-id="i3">
      #|<text x="50.17" y="157.4" text-anchor="middle">Yo</text>
      #|</g>
      #|</g>
      #|<g class="pele-notes" font-size="14" fill="var(--_a)" stroke="var(--_b)">
      #|<g class="pele-note" data-id="i2">
      #|<rect x="-13.89" y="97" width="27.78" height="33" style="rx:var(--_r)"/>
      #|<text class="pele-label" stroke="none" fill="var(--_fg)" x="0" y="118.4" text-anchor="middle">n</text>
      #|</g>
      #|</g>
      #|<g class="pele-nodes">
      #|<g class="pele-node pele-actor pele-actor-participant pele-actor-footer" data-id="Alice">
      #|<rect x="-33.34" y="187" width="66.67" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="0" y="214.6" text-anchor="middle">Alice</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant pele-actor-footer" data-id="Bob">
      #|<rect x="73.34" y="187" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="105.34" y="214.6" text-anchor="middle">Bob</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant" data-id="Alice">
      #|<rect x="-33.34" y="0" width="66.67" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="0" y="27.6" text-anchor="middle">Alice</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant" data-id="Bob">
      #|<rect x="73.34" y="0" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="105.34" y="27.6" text-anchor="middle">Bob</text>
      #|</g>
      #|</g>
      #|</g>
      #|</svg>
    ),
  )
}

///|
test "draws blocks with sections, a shaded rect, and a box" {
  inspect(
    snapshot(
      "sequenceDiagram\n  box Aqua Team\n  participant A\n  actor B\n  end\n  participant C@{ \"type\": \"queue\" }\n  rect rgb(191, 223, 255)\n  loop Every minute\n  A->>B: a\n  end\n  end\n  alt ok\n  B->>C: b\n  else bad\n  C--xA: c\n  end\n  par one\n  A-)C: d\n  and two\n  C->>A: e\n  end",
    ),
    content=(
      #|296x623
      #|<g transform="translate(50,8)">
      #|<g class="pele-boxes" font-size="14">
      #|<g class="pele-cluster pele-box" data-id="Team">
      #|<rect x="-42" y="0" width="164" height="607" fill="var(--_a)" stroke="var(--_b)" style="rx:var(--_r);fill:Aqua;"/>
      #|<text class="pele-cluster-label" fill="var(--_m)" x="40" y="22.4" text-anchor="middle">Team</text>
      #|</g>
      #|</g>
      #|<g class="pele-rects" fill="var(--_a)">
      #|<rect class="pele-rect" x="-30" y="111" width="172.81" height="96" style="rx:var(--_r);fill:rgb(191, 223, 255);"/>
      #|</g>
      #|<g class="pele-lifelines" fill="none" stroke="var(--_b)">
      #|<path class="pele-lifeline" data-id="A" d="M0,97V535"/>
      #|<path class="pele-lifeline" data-id="B" d="M92,97V535"/>
      #|<path class="pele-lifeline" data-id="C" d="M200,97V535"/>
      #|</g>
      #|<g class="pele-frames" font-size="14" stroke="var(--_b)">
      #|<g class="pele-frame pele-frame-loop">
      #|<rect x="-20" y="123" width="152.81" height="72" fill="none" style="rx:var(--_r)"/>
      #|<rect x="-20" y="123" width="39.33" height="20" fill="var(--_s)" style="rx:var(--_r)"/>
      #|<text class="pele-frame-kind" x="-0.33" y="137.2" text-anchor="middle" font-size="12" font-weight="var(--_hw)" fill="var(--_m)" stroke="none">loop</text>
      #|<rect x="24.33" y="125" width="95.47" height="17" rx="3" fill="var(--_bg)" stroke="none"/>
      #|<text class="pele-frame-label" fill="var(--_m)" stroke="none" x="72.07" y="138.4" text-anchor="middle">[Every minute]</text>
      #|</g>
      #|<g class="pele-frame pele-frame-alt">
      #|<rect x="-20" y="219" width="240" height="142" fill="none" style="rx:var(--_r)"/>
      #|<path d="M-20,291H220" stroke-dasharray="4 4"/>
      #|<rect x="-15" y="295" width="37.14" height="17" rx="3" fill="var(--_bg)" stroke="none"/>
      #|<text class="pele-frame-label" fill="var(--_m)" stroke="none" x="3.57" y="308.4" text-anchor="middle">[bad]</text>
      #|<rect x="-20" y="219" width="28" height="20" fill="var(--_s)" style="rx:var(--_r)"/>
      #|<text class="pele-frame-kind" x="-6" y="233.2" text-anchor="middle" font-size="12" font-weight="var(--_hw)" fill="var(--_m)" stroke="none">alt</text>
      #|<text class="pele-frame-label" fill="var(--_m)" stroke="none" x="27.29" y="234.4" text-anchor="middle">[ok]</text>
      #|</g>
      #|<g class="pele-frame pele-frame-par">
      #|<rect x="-20" y="373" width="240" height="142" fill="none" style="rx:var(--_r)"/>
      #|<path d="M-20,445H220" stroke-dasharray="4 4"/>
      #|<rect x="-15" y="449" width="35.57" height="17" rx="3" fill="var(--_bg)" stroke="none"/>
      #|<text class="pele-frame-label" fill="var(--_m)" stroke="none" x="2.78" y="462.4" text-anchor="middle">[two]</text>
      #|<rect x="-20" y="373" width="32.67" height="20" fill="var(--_s)" style="rx:var(--_r)"/>
      #|<text class="pele-frame-kind" x="-3.66" y="387.2" text-anchor="middle" font-size="12" font-weight="var(--_hw)" fill="var(--_m)" stroke="none">par</text>
      #|<text class="pele-frame-label" fill="var(--_m)" stroke="none" x="36.24" y="388.4" text-anchor="middle">[one]</text>
      #|</g>
      #|</g>
      #|<g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round">
      #|<g class="pele-edge pele-message" data-id="i2">
      #|<path d="M0,183H85"/>
      #|<path class="pele-marker" d="M92,183L84,186.36L84,179.64Z" fill="var(--_l)" stroke="none"/>
      #|</g>
      #|<g class="pele-edge pele-message" data-id="i6">
      #|<path d="M92,279H193"/>
      #|<path class="pele-marker" d="M200,279L192,282.36L192,275.64Z" fill="var(--_l)" stroke="none"/>
      #|</g>
      #|<g class="pele-edge pele-message" data-id="i8">
      #|<path d="M200,349H4" stroke-dasharray="4 4"/>
      #|<path class="pele-marker" d="M7.5,352.5L0.5,345.5M7.5,345.5L0.5,352.5"/>
      #|</g>
      #|<g class="pele-edge pele-message" data-id="i11">
      #|<path d="M0,433H200"/>
      #|<path class="pele-marker" d="M192,428.5L200,433L192,437.5" stroke-linejoin="round"/>
      #|</g>
      #|<g class="pele-edge pele-message" data-id="i13">
      #|<path d="M200,503H7"/>
      #|<path class="pele-marker" d="M0,503L8,499.64L8,506.36Z" fill="var(--_l)" stroke="none"/>
      #|</g>
      #|</g>
      #|<g class="pele-edge-labels" font-size="14">
      #|<g class="pele-edge-label" data-id="i2">
      #|<text x="46" y="173.4" text-anchor="middle">a</text>
      #|</g>
      #|<g class="pele-edge-label" data-id="i6">
      #|<text x="146" y="269.4" text-anchor="middle">b</text>
      #|</g>
      #|<g class="pele-edge-label" data-id="i8">
      #|<text x="100" y="339.4" text-anchor="middle">c</text>
      #|</g>
      #|<g class="pele-edge-label" data-id="i11">
      #|<text x="100" y="423.4" text-anchor="middle">d</text>
      #|</g>
      #|<g class="pele-edge-label" data-id="i13">
      #|<text x="100" y="493.4" text-anchor="middle">e</text>
      #|</g>
      #|</g>
      #|<g class="pele-nodes">
      #|<g class="pele-node pele-actor pele-actor-participant pele-actor-footer" data-id="A">
      #|<rect x="-32" y="535" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="0" y="562.6" text-anchor="middle">A</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-actor pele-actor-footer" data-id="B">
      #|<circle cx="92" cy="542" r="6" fill="var(--_s)" stroke="var(--_b)"/>
      #|<path d="M92,548V559M82,552H102M84,569L92,559L100,569" fill="none" stroke="var(--_b)"/>
      #|<text class="pele-label" x="92" y="590.6" text-anchor="middle">B</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-queue pele-actor-footer" data-id="C">
      #|<path d="M168,535H232A6,22 0 0 1 232,579H168A6,22 0 0 1 168,535Z" fill="var(--_s)" stroke="var(--_b)"/>
      #|<path d="M232,535A6,22 0 0 0 232,579" fill="none" stroke="var(--_b)"/>
      #|<text class="pele-label" x="197" y="562.6" text-anchor="middle">C</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant" data-id="A">
      #|<rect x="-32" y="53" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="0" y="80.6" text-anchor="middle">A</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-actor" data-id="B">
      #|<circle cx="92" cy="42" r="6" fill="var(--_s)" stroke="var(--_b)"/>
      #|<path d="M92,48V59M82,52H102M84,69L92,59L100,69" fill="none" stroke="var(--_b)"/>
      #|<text class="pele-label" x="92" y="90.6" text-anchor="middle">B</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-queue" data-id="C">
      #|<path d="M168,53H232A6,22 0 0 1 232,97H168A6,22 0 0 1 168,53Z" fill="var(--_s)" stroke="var(--_b)"/>
      #|<path d="M232,53A6,22 0 0 0 232,97" fill="none" stroke="var(--_b)"/>
      #|<text class="pele-label" x="197" y="80.6" text-anchor="middle">C</text>
      #|</g>
      #|</g>
      #|</g>
      #|</svg>
    ),
  )
}

///|
test "draws numbers, self messages, central connections, and half arrows" {
  inspect(
    snapshot(
      "sequenceDiagram\n  autonumber\n  A->>A: think\n  A()->>()B: both\n  A-|\\B: top\n  B//-A: back\n  A<<->>B: both ways\n  Note left of A: left\n  Note right of B: right",
    ),
    content=(
      #|235x400
      #|<g transform="translate(56.68,8)">
      #|<g class="pele-lifelines" fill="none" stroke="var(--_b)">
      #|<path class="pele-lifeline" data-id="A" d="M0,44V340"/>
      #|<path class="pele-lifeline" data-id="B" d="M113.03,44V340"/>
      #|</g>
      #|<g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round">
      #|<g class="pele-edge pele-message" data-id="i1">
      #|<path d="M8,64H30A6,6 0 0 1 36,70V80A6,6 0 0 1 30,86H7"/>
      #|<path class="pele-marker" d="M0,86L8,82.64L8,89.36Z" fill="var(--_l)" stroke="none"/>
      #|<g class="pele-sequence-number">
      #|<rect x="-8" y="56" width="16" height="16" rx="8" fill="var(--_l)" stroke="none"/>
      #|<text x="0" y="68.2" text-anchor="middle" font-size="12" fill="var(--_bg)" stroke="none">1</text>
      #|</g>
      #|</g>
      #|<g class="pele-edge pele-message" data-id="i2">
      #|<path d="M22,123H102.03"/>
      #|<path class="pele-marker" d="M109.03,123L101.03,126.36L101.03,119.64Z" fill="var(--_l)" stroke="none"/>
      #|<circle class="pele-central" cx="0" cy="123" r="4" fill="var(--_l)" stroke="none"/>
      #|<circle class="pele-central" cx="113.03" cy="123" r="4" fill="var(--_l)" stroke="none"/>
      #|<g class="pele-sequence-number">
      #|<rect x="6" y="115" width="16" height="16" rx="8" fill="var(--_l)" stroke="none"/>
      #|<text x="14" y="127.2" text-anchor="middle" font-size="12" fill="var(--_bg)" stroke="none">2</text>
      #|</g>
      #|</g>
      #|<g class="pele-edge pele-message" data-id="i5">
      #|<path d="M8,160H113.03"/>
      #|<path class="pele-marker" d="M113.03,160L105.03,155.5V160Z" fill="var(--_l)" stroke="none"/>
      #|<g class="pele-sequence-number">
      #|<rect x="-8" y="152" width="16" height="16" rx="8" fill="var(--_l)" stroke="none"/>
      #|<text x="0" y="164.2" text-anchor="middle" font-size="12" fill="var(--_bg)" stroke="none">3</text>
      #|</g>
      #|</g>
      #|<g class="pele-edge pele-message" data-id="i6">
      #|<path d="M113.03,197H8"/>
      #|<path class="pele-marker" d="M113.03,197L105.03,202"/>
      #|<g class="pele-sequence-number">
      #|<rect x="-8" y="189" width="16" height="16" rx="8" fill="var(--_l)" stroke="none"/>
      #|<text x="0" y="201.2" text-anchor="middle" font-size="12" fill="var(--_bg)" stroke="none">4</text>
      #|</g>
      #|</g>
      #|<g class="pele-edge pele-message" data-id="i7">
      #|<path d="M15,234H106.03"/>
      #|<path class="pele-marker" d="M8,234L16,230.64L16,237.36Z" fill="var(--_l)" stroke="none"/>
      #|<path class="pele-marker" d="M113.03,234L105.03,237.36L105.03,230.64Z" fill="var(--_l)" stroke="none"/>
      #|<g class="pele-sequence-number">
      #|<rect x="-8" y="226" width="16" height="16" rx="8" fill="var(--_l)" stroke="none"/>
      #|<text x="0" y="238.2" text-anchor="middle" font-size="12" fill="var(--_bg)" stroke="none">5</text>
      #|</g>
      #|</g>
      #|</g>
      #|<g class="pele-edge-labels" font-size="14">
      #|<g class="pele-edge-label" data-id="i1">
      #|<text x="58.78" y="79.9" text-anchor="middle">think</text>
      #|</g>
      #|<g class="pele-edge-label" data-id="i2">
      #|<text x="65.51" y="113.4" text-anchor="middle">both</text>
      #|</g>
      #|<g class="pele-edge-label" data-id="i5">
      #|<text x="60.51" y="150.4" text-anchor="middle">top</text>
      #|</g>
      #|<g class="pele-edge-label" data-id="i6">
      #|<text x="60.51" y="187.4" text-anchor="middle">back</text>
      #|</g>
      #|<g class="pele-edge-label" data-id="i7">
      #|<text x="60.51" y="224.4" text-anchor="middle">both ways</text>
      #|</g>
      #|</g>
      #|<g class="pele-notes" font-size="14" fill="var(--_a)" stroke="var(--_b)">
      #|<g class="pele-note" data-id="i8">
      #|<rect x="-48.68" y="244" width="38.68" height="33" style="rx:var(--_r)"/>
      #|<text class="pele-label" stroke="none" fill="var(--_fg)" x="-29.34" y="265.4" text-anchor="middle">left</text>
      #|</g>
      #|<g class="pele-note" data-id="i9">
      #|<rect x="123.03" y="287" width="47.23" height="33" style="rx:var(--_r)"/>
      #|<text class="pele-label" stroke="none" fill="var(--_fg)" x="146.64" y="308.4" text-anchor="middle">right</text>
      #|</g>
      #|</g>
      #|<g class="pele-nodes">
      #|<g class="pele-node pele-actor pele-actor-participant pele-actor-footer" data-id="A">
      #|<rect x="-32" y="340" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="0" y="367.6" text-anchor="middle">A</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant pele-actor-footer" data-id="B">
      #|<rect x="81.03" y="340" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="113.03" y="367.6" text-anchor="middle">B</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant" data-id="A">
      #|<rect x="-32" y="0" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="0" y="27.6" text-anchor="middle">A</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant" data-id="B">
      #|<rect x="81.03" y="0" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="113.03" y="27.6" text-anchor="middle">B</text>
      #|</g>
      #|</g>
      #|</g>
      #|</svg>
    ),
  )
}

///|
test "draws a created and a destroyed participant" {
  inspect(
    snapshot(
      "sequenceDiagram\n  title Lifecycle\n  A->>B: hi\n  create participant C\n  A->>C: make\n  destroy C\n  A-xC: end\n  create actor D as Dee\n  B->>D: new\n  B->>A: bye",
    ),
    content=(
      #|368x432
      #|<g transform="translate(40,44)">
      #|<text class="pele-title" font-weight="var(--_tw)" text-anchor="middle" xml:space="preserve">
      #|<tspan x="144" y="-18.4">Lifecycle</tspan>
      #|</text>
      #|<g class="pele-lifelines" fill="none" stroke="var(--_b)">
      #|<path class="pele-lifeline" data-id="A" d="M0,44V318"/>
      #|<path class="pele-lifeline" data-id="B" d="M104,44V318"/>
      #|<path class="pele-lifeline" data-id="C" d="M208,146V193"/>
      #|<path class="pele-lifeline" data-id="D" d="M300,267V318"/>
      #|</g>
      #|<g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round">
      #|<g class="pele-edge pele-message" data-id="i0">
      #|<path d="M0,87H97"/>
      #|<path class="pele-marker" d="M104,87L96,90.36L96,83.64Z" fill="var(--_l)" stroke="none"/>
      #|</g>
      #|<g class="pele-edge pele-message" data-id="i1">
      #|<path d="M0,124H168"/>
      #|<path class="pele-marker" d="M175,124L167,127.36L167,120.64Z" fill="var(--_l)" stroke="none"/>
      #|</g>
      #|<g class="pele-edge pele-message" data-id="i2">
      #|<path d="M0,177H204"/>
      #|<path class="pele-marker" d="M200.5,173.5L207.5,180.5M200.5,180.5L207.5,173.5"/>
      #|</g>
      #|<g class="pele-edge pele-message" data-id="i3">
      #|<path d="M104,236H275"/>
      #|<path class="pele-marker" d="M282,236L274,239.36L274,232.64Z" fill="var(--_l)" stroke="none"/>
      #|</g>
      #|<g class="pele-edge pele-message" data-id="i4">
      #|<path d="M104,298H7"/>
      #|<path class="pele-marker" d="M0,298L8,294.64L8,301.36Z" fill="var(--_l)" stroke="none"/>
      #|</g>
      #|</g>
      #|<g class="pele-destroys" fill="none" stroke="var(--_l)" stroke-width="1.5" stroke-linecap="round">
      #|<path class="pele-destroy" data-id="C" d="M202,187L214,199M214,187L202,199"/>
      #|</g>
      #|<g class="pele-edge-labels" font-size="14">
      #|<g class="pele-edge-label" data-id="i0">
      #|<text x="52" y="77.4" text-anchor="middle">hi</text>
      #|</g>
      #|<g class="pele-edge-label" data-id="i1">
      #|<rect x="67.39" y="101" width="40.23" height="17" rx="3" fill="var(--_bg)" stroke="none"/>
      #|<text x="87.5" y="114.4" text-anchor="middle">make</text>
      #|</g>
      #|<g class="pele-edge-label" data-id="i2">
      #|<rect x="89.32" y="154" width="29.35" height="17" rx="3" fill="var(--_bg)" stroke="none"/>
      #|<text x="104" y="167.4" text-anchor="middle">end</text>
      #|</g>
      #|<g class="pele-edge-label" data-id="i3">
      #|<text x="193" y="226.4" text-anchor="middle">new</text>
      #|</g>
      #|<g class="pele-edge-label" data-id="i4">
      #|<text x="52" y="288.4" text-anchor="middle">bye</text>
      #|</g>
      #|</g>
      #|<g class="pele-nodes">
      #|<g class="pele-node pele-actor pele-actor-participant pele-actor-footer" data-id="A">
      #|<rect x="-32" y="318" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="0" y="345.6" text-anchor="middle">A</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant pele-actor-footer" data-id="B">
      #|<rect x="72" y="318" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="104" y="345.6" text-anchor="middle">B</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-actor pele-actor-footer" data-id="D">
      #|<circle cx="300" cy="325" r="6" fill="var(--_s)" stroke="var(--_b)"/>
      #|<path d="M300,331V342M290,335H310M292,352L300,342L308,352" fill="none" stroke="var(--_b)"/>
      #|<text class="pele-label" x="300" y="373.6" text-anchor="middle">Dee</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant" data-id="A">
      #|<rect x="-32" y="0" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="0" y="27.6" text-anchor="middle">A</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant" data-id="B">
      #|<rect x="72" y="0" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="104" y="27.6" text-anchor="middle">B</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant" data-id="C">
      #|<rect x="176" y="102" width="64" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="208" y="129.6" text-anchor="middle">C</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-actor" data-id="D">
      #|<circle cx="300" cy="212" r="6" fill="var(--_s)" stroke="var(--_b)"/>
      #|<path d="M300,218V229M290,222H310M292,239L300,229L308,239" fill="none" stroke="var(--_b)"/>
      #|<text class="pele-label" x="300" y="260.6" text-anchor="middle">Dee</text>
      #|</g>
      #|</g>
      #|</g>
      #|</svg>
    ),
  )
}

///|
test "fits a wide diagram to a narrow host" {
  inspect(
    snapshot(
      "sequenceDiagram\n  participant Alice\n  participant Bob\n  participant Carol\n  Alice->>Bob: a message that is far too long to fit the narrow width\n  Bob->>Carol: another long message that wraps in the narrow profile\n  Note over Alice,Carol: a note across all of them that is also long\n  loop retry the whole thing again\n  Carol-->>Alice: done\n  end",
      max_width=400,
    ),
    content=(
      #|400x393
      #|<g transform="translate(33.34,8)">
      #|<g class="pele-lifelines" fill="none" stroke="var(--_b)">
      #|<path class="pele-lifeline" data-id="Alice" d="M0,44V333"/>
      #|<path class="pele-lifeline" data-id="Bob" d="M165.5,44V333"/>
      #|<path class="pele-lifeline" data-id="Carol" d="M331,44V333"/>
      #|</g>
      #|<g class="pele-frames" font-size="14" stroke="var(--_b)">
      #|<g class="pele-frame pele-frame-loop">
      #|<rect x="-12" y="241" width="355" height="72" fill="none" style="rx:var(--_r)"/>
      #|<rect x="-12" y="241" width="39.33" height="20" fill="var(--_s)" style="rx:var(--_r)"/>
      #|<text class="pele-frame-kind" x="7.67" y="255.2" text-anchor="middle" font-size="12" font-weight="var(--_hw)" fill="var(--_m)" stroke="none">loop</text>
      #|<rect x="32.33" y="243" width="177.98" height="17" rx="3" fill="var(--_bg)" stroke="none"/>
      #|<text class="pele-frame-label" fill="var(--_m)" stroke="none" x="121.32" y="256.4" text-anchor="middle">[retry the whole thing again]</text>
      #|</g>
      #|</g>
      #|<g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round">
      #|<g class="pele-edge pele-message" data-id="i0">
      #|<path d="M0,120H158.5"/>
      #|<path class="pele-marker" d="M165.5,120L157.5,123.36L157.5,116.64Z" fill="var(--_l)" stroke="none"/>
      #|</g>
      #|<g class="pele-edge pele-message" data-id="i1">
      #|<path d="M165.5,190H324"/>
      #|<path class="pele-marker" d="M331,190L323,193.36L323,186.64Z" fill="var(--_l)" stroke="none"/>
      #|</g>
      #|<g class="pele-edge pele-message" data-id="i4">
      #|<path d="M331,301H7" stroke-dasharray="4 4"/>
      #|<path class="pele-marker" d="M0,301L8,297.64L8,304.36Z" fill="var(--_l)" stroke="none"/>
      #|</g>
      #|</g>
      #|<g class="pele-edge-labels" font-size="14">
      #|<g class="pele-edge-label" data-id="i0">
      #|<text text-anchor="middle" xml:space="preserve">
      #|<tspan x="82.75" y="75.9">a message that is far</tspan>
      #|<tspan x="82.75" y="93.9">too long to fit the</tspan>
      #|<tspan x="82.75" y="111.9">narrow width</tspan>
      #|</text>
      #|</g>
      #|<g class="pele-edge-label" data-id="i1">
      #|<text text-anchor="middle" xml:space="preserve">
      #|<tspan x="248.25" y="145.9">another long message</tspan>
      #|<tspan x="248.25" y="163.9">that wraps in the</tspan>
      #|<tspan x="248.25" y="181.9">narrow profile</tspan>
      #|</text>
      #|</g>
      #|<g class="pele-edge-label" data-id="i4">
      #|<rect x="146.93" y="278" width="37.14" height="17" rx="3" fill="var(--_bg)" stroke="none"/>
      #|<text x="165.5" y="291.4" text-anchor="middle">done</text>
      #|</g>
      #|</g>
      #|<g class="pele-notes" font-size="14" fill="var(--_a)" stroke="var(--_b)">
      #|<g class="pele-note" data-id="i2">
      #|<rect x="-8" y="200" width="347" height="29" style="rx:var(--_r)"/>
      #|<text class="pele-label" stroke="none" fill="var(--_fg)" x="165.5" y="219.4" text-anchor="middle">a note across all of them that is also long</text>
      #|</g>
      #|</g>
      #|<g class="pele-nodes">
      #|<g class="pele-node pele-actor pele-actor-participant pele-actor-footer" data-id="Alice">
      #|<rect x="-25.34" y="333" width="50.67" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="0" y="360.6" text-anchor="middle">Alice</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant pele-actor-footer" data-id="Bob">
      #|<rect x="141.5" y="333" width="48" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="165.5" y="360.6" text-anchor="middle">Bob</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant pele-actor-footer" data-id="Carol">
      #|<rect x="303.89" y="333" width="54.22" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="331" y="360.6" text-anchor="middle">Carol</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant" data-id="Alice">
      #|<rect x="-25.34" y="0" width="50.67" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="0" y="27.6" text-anchor="middle">Alice</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant" data-id="Bob">
      #|<rect x="141.5" y="0" width="48" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="165.5" y="27.6" text-anchor="middle">Bob</text>
      #|</g>
      #|<g class="pele-node pele-actor pele-actor-participant" data-id="Carol">
      #|<rect x="303.89" y="0" width="54.22" height="44" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
      #|<text class="pele-label" x="331" y="27.6" text-anchor="middle">Carol</text>
      #|</g>
      #|</g>
      #|</g>
      #|</svg>
    ),
  )
}

///|
test "a hinted message splits at its hints on a narrow screen" {
  let svg = svg_of(
    "sequenceDiagram\n  participant UE\n  participant gNB\n  participant AMF\n  gNB->>UE: RRCConnection\u{200b}Reconfiguration\u{200b}Complete\n  UE->>gNB: ok",
    max_width=360,
  )
  let spans = []
  let mut at = @util.index_of(svg, "<tspan")
  while at != -1 {
    let open = @util.index_of(svg, ">", from=at) + 1
    spans.push(
      @util.slice(svg, open, end=@util.index_of(svg, "<", from=open)).replace_all(
        old="\u{200b}",
        new="",
      ),
    )
    at = @util.index_of(svg, "<tspan", from=open)
  }
  inspect(
    spans.join(" | "),
    content=(
      #|RRCConnectionReconfiguration | Complete
    ),
  )
}
