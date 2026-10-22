///|
fn render(
  source : String,
  max_width? : Double,
) -> @types.RenderResult raise @errors.PeleError {
  let options = { ..@types.RenderOptions::default(), max_width, }
  @core.render([@timeline.timeline], source, options)
}

///|
fn svg(source : String) -> String raise @errors.PeleError {
  render(source).svg
}

///|
/// How many times a text occurs in another.
fn occurrences(text : String, part : String) -> Int32 {
  let mut n = 0
  let mut at = @util.index_of(text, part)
  while at != -1 {
    n += 1
    at = @util.index_of(text, part, from=at + part.length())
  }
  n
}

///|
fn count(svg : String, cls : String) -> Int32 {
  occurrences(svg, "class=\"\{cls}\"")
}

///|
/// The text between a `>` and the next `<` wherever it is not empty, as `/>([^<>]+)</g` finds it.
fn texts(svg : String) -> Array[String] {
  let out = []
  let mut i = 0
  while true {
    let a = @util.index_of(svg, ">", from=i)
    if a == -1 {
      break
    }
    let b = @util.index_of(svg, "<", from=a + 1)
    if b == -1 {
      break
    }
    let inner = @util.slice(svg, a + 1, end=b)
    if inner != "" && !inner.contains(">") {
      out.push(inner)
    }
    i = b + 1
  }
  out
}

///|
/// The opening tags of one element name, in document order.
fn tags(svg : String, name : String) -> Array[String] {
  let out = []
  let open = "<\{name} "
  let mut at = @util.index_of(svg, open)
  while at != -1 {
    let end = @util.index_of(svg, ">", from=at)
    out.push(@util.slice(svg, at, end=end + 1))
    at = @util.index_of(svg, open, from=end)
  }
  out
}

///|
fn attr(tag : String, name : String) -> String {
  let key = " \{name}=\""
  let at = @util.index_of(tag, key)
  guard at != -1 else { return "" }
  let start = at + key.length()
  @util.slice(tag, start, end=@util.index_of(tag, "\"", from=start))
}

///|
fn number(tag : String, name : String) -> Double {
  @util.parse_float(attr(tag, name))
}

///|
const SOCIAL : String = "timeline\n  title History of Social Media\n  2002 : LinkedIn\n  2004 : Facebook : Google\n  2005 : YouTube\n"

///|
test "a title, a period per time period, and its events beneath are drawn" {
  let result = render(SOCIAL)
  let svg = result.svg
  assert_eq(result.kind, "timeline")
  assert_eq(result.links.length(), 0)
  assert_true(svg.contains("class=\"pele pele-timeline\""))
  assert_true(svg.contains(">History of Social Media<"))
  assert_eq(count(svg, "pele-node pele-period"), 3)
  assert_eq(count(svg, "pele-node pele-event"), 4)
  assert_eq(count(svg, "pele-dot"), 3)
  assert_eq(count(svg, "pele-axis"), 1)
  assert_eq(count(svg, "pele-marker"), 1)
  assert_eq(texts(svg), [
    "History of Social Media", "2002", "LinkedIn", "2004", "Facebook", "Google",
    "2005", "YouTube",
  ])
  assert_true(svg.contains("data-id=\"2004\""))
}

///|
test "periods run left to right and events sit below their period" {
  let rects = tags(svg(SOCIAL), "rect")
  let x = rects.map(r => number(r, "x"))
  let y = rects.map(r => number(r, "y"))
  // 2002, LinkedIn, 2004, Facebook, Google, 2005, YouTube
  assert_eq(x[0], x[1])
  assert_true(x[2] > x[0])
  assert_eq(x[3], x[2])
  assert_eq(x[4], x[2])
  assert_true(x[5] > x[2])
  assert_eq(y[2], y[0])
  assert_true(y[1] > y[0])
  assert_true(y[4] > y[3])
}

///|
test "each period has its own series color, or one color with disableMulticolor" {
  let multi = svg(SOCIAL)
  assert_true(multi.contains("var(--pele-series-1,"))
  assert_true(multi.contains("var(--pele-series-2,"))
  assert_true(multi.contains("var(--pele-series-3,"))
  let single = svg(
    "---\nconfig:\n  timeline:\n    disableMulticolor: true\n---\n" + SOCIAL,
  )
  assert_true(single.contains("var(--pele-series-1,"))
  assert_false(single.contains("var(--pele-series-2,"))
  let directive = svg(
    "%%{init: {\"timeline\": {\"disableMulticolor\": true}}}%%\n" + SOCIAL,
  )
  let config : Map[String, Json] = { "timeline": { "disableMulticolor": true } }
  let options = { ..@types.RenderOptions::default(), config: Some(config), }
  assert_eq(directive, @core.render([@timeline.timeline], SOCIAL, options).svg)
  assert_false(directive.contains("var(--pele-series-2,"))
}

///|
test "sections color their periods and get a header" {
  let svg = svg(
    "timeline\n  section One\n    A : a\n    B : b\n  section Two\n    C : c\n",
  )
  assert_eq(count(svg, "pele-cluster pele-section"), 2)
  assert_true(svg.contains("data-id=\"One\""))
  assert_true(svg.contains(">One<"))
  assert_false(svg.contains("var(--pele-series-3,"))
  let rects = tags(svg, "rect")
  let header = rects[0]
  let a = rects[1]
  let b = rects[3]
  assert_eq(number(header, "x"), number(a, "x"))
  assert_eq(
    number(header, "width"),
    number(b, "x") + number(b, "width") - number(a, "x"),
  )
  assert_eq(attr(a, "fill"), attr(header, "fill"))
  assert_eq(attr(b, "fill"), attr(header, "fill"))
}

///|
test "periods before the first section are kept, and each section keeps its own periods" {
  let svg = svg(
    "timeline\n  Early : e\n  section Same\n    A\n  section Empty\n  section Same\n    B\n",
  )
  assert_eq(count(svg, "pele-node pele-period"), 3)
  assert_eq(count(svg, "pele-cluster pele-section"), 3)
  assert_true(svg.contains("fill=\"var(--_m)\""))
  assert_true(@util.index_of(svg, ">Early<") < @util.index_of(svg, ">Same<"))
}

///|
test "TD runs top to bottom" {
  let lr = render(SOCIAL)
  let td = render(SOCIAL.replace(old="timeline", new="timeline TD"))
  assert_eq(
    render(SOCIAL.replace(old="timeline", new="timeline LR")).svg,
    lr.svg,
  )
  assert_true(td.height > lr.height)
  assert_true(td.width < lr.width)
  assert_eq(count(td.svg, "pele-node pele-period"), 3)
  assert_eq(count(td.svg, "pele-node pele-event"), 4)
  let rects = tags(td.svg, "rect")
  assert_true(number(rects[2], "y") > number(rects[0], "y"))
  assert_true(number(rects[1], "x") > number(rects[0], "x"))
}

///|
/// The y of each `M x,y H` stub in a path.
fn stub_ys(d : String) -> Array[Double] {
  let out = []
  let segments : Array[String] = d.split("M").map(s => s.to_owned()).collect()
  for segment in segments {
    let comma = @util.index_of(segment, ",")
    guard comma != -1 else { continue }
    let mut end = comma + 1
    while @util.is_digit(@util.code_at(segment, end)) ||
          @util.code_at(segment, end) == '.' {
      end += 1
    }
    if end > comma + 1 && @util.code_at(segment, end) == 'H' {
      out.push(@util.parse_float(@util.slice(segment, comma + 1, end~)))
    }
  }
  out
}

///|
test "TD runs the line from a period to its first event straight, whichever box is taller" {
  let source = "timeline TD\n  2002 : LinkedIn\n  2004 : Facebook : Google\n  2005<br>and on<br>and on : YouTube\n  2006 : first<br>second<br>third<br>fourth\n"
  let svg = svg(source)
  let rows : Array[String] = svg
    .split("<g class=\"pele-node pele-period\"")
    .map(s => s.to_owned())
    .collect()
  assert_eq(rows.length() - 1, 4)
  let mut above = 0.0
  for row in rows[1:] {
    let boxes = tags(row, "rect")
    let top = boxes.map(b => number(b, "y"))
    let bottom = boxes.map(b => number(b, "y") + number(b, "height"))
    let middle = boxes.map(b => number(b, "y") + number(b, "height") / 2)
    assert_eq(middle[1], middle[0])
    let edge = @util.index_of(row, "class=\"pele-edge\" d=\"")
    let d_start = edge + "class=\"pele-edge\" d=\"".length()
    let d = @util.slice(
      row,
      d_start,
      end=@util.index_of(row, "\"", from=d_start),
    )
    let stubs = stub_ys(d)
    assert_eq(stubs[0], middle[0])
    assert_eq(stubs[1], middle[0])
    let mut least = top[0]
    let mut most = bottom[0]
    for i in 1..<boxes.length() {
      least = @util.js_min(least, top[i])
      most = @util.js_max(most, bottom[i])
    }
    assert_true(least > above)
    above = most
  }
}

///|
test "lines break at <br> and long text wraps to the column" {
  let one = render("timeline\n  2001 : first second\n")
  let two = render("timeline\n  2001 : first<br>second\n")
  assert_true(two.height > one.height)
  assert_eq(two.width, one.width)
  assert_eq(texts(two.svg), ["2001", "first", "second"])
  assert_eq(texts(svg("timeline\n  2001 : a<br/>b<br />c\n")), [
    "2001", "a", "b", "c",
  ])
  let long = render(
    "timeline\n  2001 : " + "several words that go on ".repeat(6) + "\n",
  )
  assert_eq(long.width, one.width)
  assert_true(texts(long.svg).length() > 6)
  for line in texts(long.svg) {
    assert_true(@text.metrics_measurer.width(line, 14, 0) <= 152)
  }
}

///|
test "columns widen for a long word, then the word is cut" {
  let base = render("timeline\n  2001 : short\n")
  let word = "Supercalifragilisticexpiali"
  assert_true(@text.metrics_measurer.width(word, 14, 0) > 152)
  assert_true(@text.metrics_measurer.width(word, 14, 0) < 216)
  let wider = render("timeline\n  2001 : \{word}\n")
  let cut = render("timeline\n  2001 : " + "x".repeat(300) + "\n")
  assert_true(wider.width > base.width)
  assert_eq(texts(wider.svg), ["2001", word])
  assert_true(cut.width <= base.width + 64)
  assert_eq(
    texts(cut.svg)[1:].iter().fold(init="", (a, b) => a + b),
    "x".repeat(300),
  )
  let rect = tags(cut.svg, "rect")[1]
  for line in texts(cut.svg)[1:] {
    assert_true(
      @text.metrics_measurer.width(line, 14, 0) <= number(rect, "width") - 24,
    )
  }
}

///|
test "entities are decoded, and tags, links and icon names are shown as written" {
  let svg = svg(
    "timeline\n  2001 : #35;1 &amp; <b>bold</b> [link](http://example.com) fa:fa-check a<T>\n",
  )
  assert_eq(
    texts(svg)[1:].join(" "),
    "#1 &amp; &lt;b&gt;bold&lt;/b&gt; [link](http://example.com) fa:fa-check a&lt;T&gt;",
  )
  assert_false(svg.contains("<a"))
  assert_false(svg.contains("pele-icon"))
}

///|
test "the title comes from front matter unless the diagram sets one" {
  assert_true(
    svg("---\ntitle: From front matter\n---\ntimeline\n  2001\n").contains(
      ">From front matter<",
    ),
  )
  let own = svg(
    "---\ntitle: From front matter\n---\ntimeline\n  title Own\n  2001\n",
  )
  assert_true(own.contains(">Own<"))
  assert_false(own.contains("From front matter"))
}

///|
test "accessible names are written" {
  let svg = svg(
    "timeline\n  accTitle: Short name\n  accDescr {\n    A longer\n    description\n  }\n  2001\n",
  )
  assert_true(svg.contains("<title id=\"pele-title\">Short name</title>"))
  assert_true(
    svg.contains("<desc id=\"pele-desc\">A longer\ndescription</desc>"),
  )
}

///|
test "an empty timeline, a lone title and sections without periods are drawn" {
  for
    source in [
      "timeline", "timeline TD", "timeline\n  title Only", "timeline\n  section S",
      "timeline TD\n  section S\n  section T",
    ] {
    let result = render(source)
    assert_false(result.svg.contains("NaN"))
    assert_false(result.svg.contains("Infinity"))
    assert_false(result.svg.contains("undefined"))
    assert_true(result.width > 0)
    assert_true(result.height > 0)
    assert_eq(count(result.svg, "pele-axis"), 0)
  }
}

///|
test "what Mermaid rejects is rejected" {
  let failures = [
    "timeline\n  : orphan event\n", "timeline\n  2001 :no space\n", "timeline\n  Timeline of things : x\n",
    "timeline\n  accDescr {\n  never closed\n",
  ]
  for source in failures {
    let rejected = try render(source) catch {
      @errors.PeleError(_) => true
    } noraise {
      _ => false
    }
    assert_true(rejected, msg=source)
  }
}

///|
test "markup in any position is shown as escaped text" {
  let svg = svg(
    "timeline\n  title <script>alert(1)</script>\n  section \"><img src=x onerror=alert(1)>\n  <svg onload=alert(1)> : </text><script>x</script>",
  )
  assert_false(svg.contains("<script"))
  assert_false(svg.contains("<img"))
  assert_true(svg.contains("&lt;script&gt;"))
  assert_true(
    svg.contains("data-id=\"&quot;&gt;&lt;img src=x onerror=alert(1)&gt;\""),
  )
}

///|
test "rendering is deterministic" {
  assert_eq(svg(SOCIAL), svg(SOCIAL))
}
