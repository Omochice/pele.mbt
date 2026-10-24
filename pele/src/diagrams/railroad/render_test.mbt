///|
struct Drawn {
  svg : String
  width : Double
  height : Double
}

///|
fn draw(
  source : String,
  max_width? : Double,
  font_size? : Double,
  responsive? : Bool,
  config? : Map[String, Json],
) -> Drawn {
  let options = {
    ..@types.RenderOptions::default(),
    max_width,
    font_size,
    responsive,
    config,
  }
  let result = @core.render([@railroad.railroad], source, options) catch {
    @errors.PeleError(failure) =>
      return { svg: failure.message, width: 0, height: 0, }
  }
  { svg: result.svg, width: result.width, height: result.height, }
}

///|
fn ebnf_drawing(rules : String) -> Drawn {
  draw("railroad-ebnf-beta\n" + rules)
}

///|
fn count(text : String, needle : String) -> Int32 {
  text.split(needle).collect().length() - 1
}

///|
fn has(text : String, needle : String) -> Bool {
  text.find(needle) is Some(_)
}

///|
test "the four keywords draw the same diagram" {
  let sources = [
    "railroad-beta\nr = terminal(\"a\") ;", "railroad-ebnf-beta\nr = \"a\" ;", "railroad-abnf-beta\nr = \"a\" ;",
    "railroad-peg-beta\nr <- \"a\" ;",
  ]
  let first = draw(sources[0]).svg
  for source in sources {
    let drawn = draw(source)
    inspect(has(drawn.svg, "class=\"pele pele-railroad\""), content="true")
    inspect(count(drawn.svg, "class=\"pele-node pele-terminal\""), content="1")
    inspect(drawn.svg == first, content="true")
  }
}

///|
test "a keyword in another case is detected and then rejected" {
  inspect(
    has(
      draw("RAILROAD-BETA\nr = terminal(\"a\") ;").svg,
      "Expecting token of type 'railroad-beta'",
    ),
    content="true",
  )
}

///|
test "one diagram per rule with a heading, markers, and a track" {
  let drawn = ebnf_drawing("first = \"a\" b ;\nsecond = c ;")
  inspect(count(drawn.svg, "<g class=\"pele-rule\""), content="2")
  inspect(
    has(drawn.svg, "<g class=\"pele-rule\" data-id=\"first\">"),
    content="true",
  )
  inspect(
    has(
      drawn.svg,
      "font-weight=\"var(--_hw)\" text-anchor=\"start\">first</text>",
    ),
    content="true",
  )
  inspect(count(drawn.svg, "class=\"pele-marker pele-start\""), content="2")
  inspect(count(drawn.svg, "class=\"pele-marker pele-end\""), content="2")
  inspect(count(drawn.svg, "class=\"pele-edge pele-track\""), content="2")
}

///|
test "terminals are pills and non-terminals are boxes that name their rule" {
  let svg = ebnf_drawing("r = \"lit\" name ;").svg
  inspect(
    has(svg, "<g class=\"pele-node pele-terminal\"><rect"),
    content="true",
  )
  inspect(has(svg, " rx=\"15\" fill=\"var(--_s)\""), content="true")
  inspect(
    has(svg, "<g class=\"pele-node pele-nonterminal\" data-id=\"name\"><rect"),
    content="true",
  )
  inspect(has(svg, " style=\"rx:var(--_r)\"/>"), content="true")
  inspect(has(svg, "font-family=\"var(--_fm)\">lit</text>"), content="true")
}

///|
test "the first alternative stays on the track and the rest stack below it" {
  let one = ebnf_drawing("r = a ;")
  let many = ebnf_drawing("r = a | bb | \"c\" ;")
  inspect(many.height > one.height, content="true")
  inspect(count(many.svg, "a10,10 0 0 1 10,10"), content="1")
  inspect(count(many.svg, "a10,10 0 0 0 10,10"), content="2")
}

///|
test "an optional element has a bypass over it" {
  let plain = ebnf_drawing("r = a ;")
  let optional = ebnf_drawing("r = [ a ] ;")
  inspect(optional.svg == ebnf_drawing("r = a? ;").svg, content="true")
  inspect(optional.width == plain.width + 40, content="true")
  inspect(optional.height > plain.height, content="true")
  inspect(has(optional.svg, "class=\"pele-marker\" d="), content="false")
}

///|
test "repetition loops back under the element, with a bypass when it may be skipped" {
  let plain = ebnf_drawing("r = a ;")
  let more = ebnf_drawing("r = a+ ;")
  let any = ebnf_drawing("r = a* ;")
  inspect(more.width == plain.width + 20, content="true")
  inspect(more.height > plain.height, content="true")
  inspect(count(more.svg, "class=\"pele-marker\" d=\"M"), content="1")
  inspect(any.svg == ebnf_drawing("r = { a } ;").svg, content="true")
  inspect(any.width == more.width + 40, content="true")
}

///|
test "ABNF repeat counts are written on the loop" {
  let abnf = fn(rule : String) { draw("railroad-abnf-beta\n" + rule).svg }
  inspect(has(abnf("r = 3a ;"), ">3×</text>"), content="true")
  inspect(has(abnf("r = 2*4a ;"), ">2–4×</text>"), content="true")
  inspect(has(abnf("r = 2*a ;"), ">≥2×</text>"), content="true")
  inspect(has(abnf("r = *5a ;"), ">≤5×</text>"), content="true")
  inspect(
    has(abnf("r = " + "9".repeat(400) + "a ;"), ">∞×</text>"),
    content="true",
  )
  inspect(has(abnf("r = *a ;"), "pele-count"), content="false")
  inspect(has(abnf("r = 1*a ;"), "pele-count"), content="false")
  inspect(abnf("r = 1a ;") == abnf("r = a ;"), content="true")
  inspect(abnf("r = 0*1a ;") == abnf("r = [ a ] ;"), content="true")
}

///|
test "special sequences are dashed, and exceptions and predicates follow Mermaid's model" {
  let special = ebnf_drawing("r = ? any character ? ;").svg
  inspect(has(special, " stroke-dasharray=\"4 3\""), content="true")
  inspect(
    has(
      special, "<tspan fill=\"var(--_m)\">? </tspan>any character<tspan fill=\"var(--_m)\"> ?</tspan>",
    ),
    content="true",
  )
  let exception = ebnf_drawing("r = letter - \"x\" ;").svg
  inspect(count(exception, "pele-terminal"), content="2")
  inspect(has(exception, ">-</text>"), content="true")
  let peg = draw("railroad-peg-beta\nR <- !Keyword &\"k\" . !( a b ) ;").svg
  inspect(count(peg, "pele-special"), content="4")
  inspect(has(peg, ">!Keyword<"), content="true")
  inspect(has(peg, ">&amp;&quot;k&quot;<"), content="true")
  inspect(has(peg, ">!(...)<"), content="true")
}

///|
test "text is shown as written" {
  let svg = draw(
      "railroad-beta\nr = sequence(terminal(\"<br>\"), terminal(\"*a*\"), terminal(\"#35;\"), terminal(\"&lt;\"), terminal(\" \"), terminal(\"a  b\"), terminal(\"\\n\\t\"), nonterminal(\"fa:fa-user\")) ;",
    ).svg
  inspect(has(svg, ">&lt;br&gt;</text>"), content="true")
  inspect(has(svg, ">*a*</text>"), content="true")
  inspect(has(svg, ">#</text>"), content="true")
  inspect(has(svg, ">&amp;lt;</text>"), content="true")
  inspect(has(svg, ">␣</text>"), content="true")
  inspect(
    has(svg, " xml:space=\"preserve\" font-family=\"var(--_fm)\">a  b</text>"),
    content="true",
  )
  inspect(has(svg, ">\\n\\t</text>"), content="true")
  inspect(has(svg, ">fa:fa-user</text>"), content="true")
}

///|
test "the title comes from the diagram or else from front matter" {
  let own = ebnf_drawing("title \"Quoted \\\"title\\\"\"\nr = a ;").svg
  inspect(
    has(own, "class=\"pele-title\" font-weight=\"var(--_tw)\""),
    content="true",
  )
  inspect(has(own, ">Quoted &quot;title&quot;<"), content="true")
  inspect(
    has(
      draw("---\ntitle: From front matter\n---\nrailroad-peg-beta\nR <- a ;").svg,
      ">From front matter<",
    ),
    content="true",
  )
  let shadowed = draw(
      "---\ntitle: From front matter\n---\nrailroad-abnf-beta\ntitle Own\nr = a ;",
    ).svg
  inspect(has(shadowed, ">Own<"), content="true")
  inspect(has(shadowed, "From front matter"), content="false")
  inspect(has(ebnf_drawing("r = a ;").svg, "pele-title"), content="false")
}

///|
test "the drawing is named for assistive technology" {
  let svg = ebnf_drawing(
      "accTitle: Grammar\naccDescr {\n  Two\n  lines\n}\nr = a ;",
    ).svg
  inspect(has(svg, "<title id=\"pele-title\">Grammar</title>"), content="true")
  inspect(has(svg, "<desc id=\"pele-desc\">Two\nlines</desc>"), content="true")
}

///|
test "the railroad config keys that have a meaning here are honoured" {
  let source = "railroad-ebnf-beta\nr = a ( b | c )* [ d ] ;\ns = e ;"
  let with_config = fn(config : String) {
    draw("---\nconfig:\n  railroad:\n\{config}\n---\n\{source}")
  }
  let plain = draw(source)
  inspect(with_config("    arcRadius: 20").width > plain.width, content="true")
  inspect(
    has(with_config("    arcRadius: 20").svg, "a20,20 0 0 1 20,20"),
    content="true",
  )
  inspect(with_config("    padding: 20").width > plain.width, content="true")
  inspect(with_config("    padding: 20").height > plain.height, content="true")
  inspect(
    with_config("    horizontalSeparation: 40").width == plain.width + 2 * 24,
    content="true",
  )
  inspect(
    with_config("    horizontalSeparation: 40").height == plain.height,
    content="true",
  )
  inspect(
    with_config("    verticalSeparation: 30").height > plain.height,
    content="true",
  )
  inspect(
    with_config("    verticalSeparation: 30").width == plain.width,
    content="true",
  )
  inspect(
    has(
      with_config("    fontSize: 20").svg,
      "<g class=\"pele-rules\" transform=\"translate(0.5,0.5)\" font-size=\"20\"",
    ),
    content="true",
  )
  inspect(with_config("    fontSize: 20").width > plain.width, content="true")
  inspect(
    has(
      with_config("    strokeWidth: 2").svg,
      "stroke=\"var(--_l)\" stroke-width=\"2\"",
    ),
    content="true",
  )
  inspect(has(plain.svg, "stroke-width"), content="false")
  inspect(
    has(with_config("    markerRadius: 8").svg, "r=\"8\""),
    content="true",
  )
  inspect(
    has(with_config("    showMarkers: false").svg, "<circle"),
    content="false",
  )
  inspect(
    with_config("    showMarkers: false").width == plain.width - 16,
    content="true",
  )
  inspect(
    with_config("    arcRadius: wide\n    padding: -4\n    fontSize: \"x\"").svg ==
    plain.svg,
    content="true",
  )
}

///|
test "a name defined again is drawn again" {
  let svg = ebnf_drawing("r = a ;\nr = b ;").svg
  inspect(count(svg, "<g class=\"pele-rule\" data-id=\"r\">"), content="2")
}

///|
test "a grammar with no rules is drawn" {
  let empty = draw("railroad-beta").svg
  inspect(has(empty, "<svg"), content="true")
  inspect(has(empty, "pele-rule"), content="false")
  inspect(
    has(draw("railroad-ebnf-beta\ntitle Only a title").svg, ">Only a title<"),
    content="true",
  )
}

///|
test "the drawing scales with the font size and is the same every time" {
  let source = "railroad-ebnf-beta\nr = a ( b | \"c\" )+ ;"
  inspect(draw(source).svg == draw(source).svg, content="true")
  inspect(draw(source, font_size=24).width > draw(source).width, content="true")
  inspect(has(draw(source).svg, "max-width:100%;height:auto;"), content="true")
  inspect(has(draw(source, responsive=false).svg, "max-width"), content="false")
}

///|
test "a narrow host width draws the diagram tightly" {
  let source = "railroad-ebnf-beta\nr = aaaa bbbb cccc dddd eeee ffff gggg hhhh iiii jjjj kkkk ;"
  let loose = draw(source)
  let tight = draw(source, max_width=300)
  inspect(tight.width < loose.width, content="true")
}
