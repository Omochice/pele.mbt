///|
fn draw(source : String, max_width? : Double) -> @types.RenderResult {
  let options = { ..@types.RenderOptions::default(), max_width, }
  @core.render([@journey.journey], source, options) catch {
    @errors.PeleError(failure) => abort(failure.message)
  }
}

///|
fn message(source : String) -> String {
  let _ = @core.render(
    [@journey.journey],
    source,
    @types.RenderOptions::default(),
  ) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "rendered"
}

///|
fn occurrences(text : String, needle : String) -> Int32 {
  let mut count = 0
  let mut from = 0
  while true {
    let at = @util.index_of(text, needle, from~)
    if at == -1 {
      break
    }
    count += 1
    from = at + needle.length()
  }
  count
}

///|
fn count(svg : String, class_name : String) -> Int32 {
  occurrences(svg, "class=\"\{class_name}\"")
}

///|
fn is_number_char(c : Int32) -> Bool {
  c == '-'.to_int() || c == '.'.to_int() || @util.is_digit(c)
}

///|
/// The number that starts at `from` and the index after it.
fn read_number(text : String, from : Int32) -> (Double, Int32) {
  let mut end = from
  while is_number_char(@util.code_at(text, end)) {
    end += 1
  }
  (@util.parse_float(@util.slice(text, from, end~)), end)
}

///|
/// The numbers that follow each occurrence of `prefix`.
fn numbers_after(svg : String, prefix : String) -> Array[Double] {
  let out = []
  let mut from = 0
  while true {
    let at = @util.index_of(svg, prefix, from~)
    if at == -1 {
      break
    }
    let (value, end) = read_number(svg, at + prefix.length())
    out.push(value)
    from = end
  }
  out
}

///|
fn moods(svg : String) -> String {
  let prefix = "class=\"pele-face pele-face-"
  let out = []
  let mut from = 0
  while true {
    let at = @util.index_of(svg, prefix, from~)
    if at == -1 {
      break
    }
    let start = at + prefix.length()
    let end = @util.index_of(svg, "\"", from=start)
    out.push(@util.slice(svg, start, end~))
    from = end
  }
  out.join(",")
}

///|
fn face_ys(svg : String) -> Array[Double] {
  let prefix = "class=\"pele-face pele-face-"
  let out = []
  let mut from = 0
  while true {
    let at = @util.index_of(svg, prefix, from~)
    if at == -1 {
      break
    }
    let open = @util.index_of(svg, "translate(", from=at) + 10
    let (_, comma) = read_number(svg, open)
    let (y, end) = read_number(svg, comma + 1)
    out.push(y)
    from = end
  }
  out
}

///|
/// The digit of the series color that follows the first occurrence of `marker`.
fn series_after(svg : String, marker : String) -> String {
  let at = @util.index_of(svg, marker)
  let series = @util.index_of(svg, "pele-series-", from=at) + 12
  @util.slice(svg, series, end=series + 1)
}

///|
test "a title, section bands, a card and a face per task, and a legend of actors" {
  let day = "journey\n  title My working day\n  section Go to work\n    Make tea: 5: Me\n    Go upstairs: 3: Me\n    Do work: 1: Me, Cat\n  section Go home\n    Go downstairs: 5: Me\n    Sit down: 5: Me\n"
  let result = draw(day)
  let svg = result.svg
  inspect(result.kind, content="journey")
  inspect(svg.contains("class=\"pele pele-journey\""), content="true")
  inspect(svg.contains(">My working day<"), content="true")
  inspect(count(svg, "pele-cluster pele-section"), content="2")
  inspect(count(svg, "pele-node pele-task"), content="5")
  inspect(moods(svg), content="happy,neutral,sad,happy,happy")
  inspect(count(svg, "pele-actor"), content="6")
  inspect(count(svg, "pele-legend-item"), content="2")
  inspect(svg.contains("data-id=\"Go to work\""), content="true")
  inspect(svg.contains("data-id=\"Make tea\""), content="true")
  inspect(svg.contains(">Do work<"), content="true")
  inspect(result.links.length(), content="0")
  inspect(draw(day).svg == svg, content="true")
}

///|
test "each face is placed by its score" {
  let ys = face_ys(
    draw("journey\n  a: 5\n  b: 4\n  c: 3\n  d: 2\n  e: 1\n").svg,
  )
  inspect(ys.length(), content="5")
  for i in 1..<5 {
    inspect(ys[i] - ys[i - 1] == ys[1] - ys[0], content="true")
  }
  inspect(ys[1] > ys[0], content="true")
}

///|
test "odd scores stay on the scale: out of range is clamped, not a number is neutral" {
  let svg = draw(
      "journey\n  top: 5\n  mid: 3\n  low: 1\n  big: 100\n  neg: -7\n  zero: 0\n  word: abc\n  blank: \n  half: 3.5\n  inf: Infinity\n",
    ).svg
  let ys = face_ys(svg)
  let top = ys[0]
  let mid = ys[1]
  let low = ys[2]
  let expected = [
    top,
    low,
    low,
    mid,
    low,
    (top + mid) / 2 + (mid - top) / 4,
    top,
  ]
  inspect(ys[3:].to_owned() == expected, content="true")
  inspect(
    moods(svg),
    content="happy,neutral,sad,happy,sad,sad,neutral,sad,happy,happy",
  )
  inspect(svg.contains("NaN") || svg.contains("Infinity"), content="false")
}

///|
test "a face is a pair of circles and a mouth drawn as a path" {
  let svg = draw("journey\n  a: 5\n  b: 3\n  c: 1\n").svg
  inspect(svg.contains("<path d=\"M-5,2A6,6 0 0 0 5,2\""), content="true")
  inspect(svg.contains("<path d=\"M-4.5,4.5H4.5\""), content="true")
  inspect(svg.contains("<path d=\"M-5,6.5A6,6 0 0 1 5,6.5\""), content="true")
  inspect(svg.contains("<polygon") || svg.contains("<ellipse"), content="false")
}

///|
test "actors are colored by their place in the sorted list and marked on each task" {
  let svg = draw(
      "journey\n  title My working day\n  section Go to work\n    Make tea: 5: Me\n    Go upstairs: 3: Me\n    Do work: 1: Me, Cat\n  section Go home\n    Go downstairs: 5: Me\n    Sit down: 5: Me\n",
    ).svg
  inspect(
    series_after(svg, "class=\"pele-legend-item\" data-id=\"Cat\""),
    content="1",
  )
  inspect(
    series_after(svg, "class=\"pele-legend-item\" data-id=\"Me\""),
    content="2",
  )
  inspect(series_after(svg, "<title>Cat</title>"), content="2")
}

///|
test "a task that ends in a colon names no actor" {
  let svg = draw("journey\n  a: 5:\n  b: 3: , Real,\n").svg
  inspect(count(svg, "pele-actor"), content="1")
  inspect(count(svg, "pele-legend-item"), content="1")
  inspect(
    draw("journey\n  a: 5:\n").svg.contains("pele-legend"),
    content="false",
  )
}

///|
test "a section band spans its run of tasks, and empty or missing sections draw no band" {
  let svg = draw(
      "journey\n  first: 3\n  section A\n  section B\n    b1: 3\n    b2: 3\n  section C\n    c1: 3\n  section D\n",
    ).svg
  inspect(count(svg, "pele-cluster pele-section"), content="2")
  inspect(svg.contains(">A<"), content="false")
  inspect(svg.contains(">D<"), content="false")
  // The rects are, in order: first, band B, b1, b2, band C, c1.
  let xs = numbers_after(svg, "<rect x=\"")
  let ys = numbers_after(svg, "\" y=\"")
  let widths = numbers_after(svg, "\" width=\"")
  inspect(xs[1] == xs[2], content="true")
  inspect(xs[1] + widths[1] == xs[3] + widths[3], content="true")
  inspect(ys[1] < ys[2], content="true")
  inspect(ys[0] == ys[2], content="true")
}

///|
test "consecutive sections of the same name are merged into one band" {
  let svg = draw(
      "journey\n  section A\n    a: 3\n  section A\n    b: 3\n  section B\n    c: 3\n  section A\n    d: 3\n",
    ).svg
  inspect(count(svg, "pele-cluster pele-section"), content="3")
}

///|
test "lines break at <br>, long names wrap, and long words are cut" {
  let one = draw("journey\n  first second: 3\n")
  let two = draw("journey\n  first<br>second: 3\n")
  inspect(two.height > one.height, content="true")
  inspect(
    two.svg.contains(">first<") && two.svg.contains(">second<"),
    content="true",
  )
  let long = draw(
    "journey\n  " + "several words that go on ".repeat(4) + ": 3\n",
  )
  inspect(long.width == one.width, content="true")
  let cut = draw("journey\n  " + "x".repeat(200) + ": 3\n")
  inspect(cut.width <= one.width + 80, content="true")
  let card = numbers_after(cut.svg, "<rect x=\"")
  let card_width = numbers_after(cut.svg, "\" width=\"")[0]
  inspect(card.length() > 0 && card_width <= 224, content="true")
  inspect(cut.svg.contains("x".repeat(200)), content="false")
}

///|
test "tags and icon names are shown as written" {
  let svg = draw(
      "journey\n  title fa:fa-check <u>T</u>\n  <b>bold</b> a<T>: 3: <i>Me</i>\n",
    ).svg
  inspect(svg.contains("&lt;u&gt;T&lt;/u&gt;"), content="true")
  inspect(svg.contains("&lt;b&gt;bold&lt;/b&gt;"), content="true")
  inspect(svg.contains("fa:fa-check"), content="true")
  inspect(svg.contains("a&lt;T&gt;"), content="true")
  inspect(svg.contains(">&lt;i&gt;Me&lt;/i&gt;<"), content="true")
  inspect(svg.contains("pele-icon"), content="false")
}

///|
test "many actors stay inside their card" {
  let names = []
  for i in 0..<60 {
    names.push("p\{i}")
  }
  let svg = draw("journey\n  crowd: 3: " + names.join(",") + "\n").svg
  let x0 = numbers_after(svg, "<rect x=\"")[0]
  let x1 = x0 + numbers_after(svg, "\" width=\"")[0]
  let dots = numbers_after(svg, "class=\"pele-actor\" cx=\"")
  inspect(dots.length(), content="60")
  inspect(dots.iter().all(cx => cx - 5 >= x0 && cx + 5 <= x1), content="true")
}

///|
test "the legend stays inside the drawing" {
  let names = []
  for i in 0..<40 {
    names.push("Person number \{i}")
  }
  let result = draw("journey\n  one: 3: " + names.join(",") + "\n")
  let cx = numbers_after(result.svg, "<circle cx=\"")
  let legend = cx.filter(x => x > 0.0)
  inspect(legend.iter().all(x => x < result.width), content="true")
  let rows = numbers_after(result.svg, "\" cy=\"")
  inspect(rows.length() > 40, content="true")
}

///|
test "the title comes from front matter unless the diagram sets one" {
  inspect(
    draw("---\ntitle: From front matter\n---\njourney\n  a: 3\n").svg.contains(
      ">From front matter<",
    ),
    content="true",
  )
  let own = draw(
      "---\ntitle: From front matter\n---\njourney\n  title Own\n  a: 3\n",
    ).svg
  inspect(own.contains(">Own<"), content="true")
  inspect(own.contains("From front matter"), content="false")
}

///|
test "an empty journey, a lone title, and sections without tasks are drawn" {
  for
    source in [
      "journey", "journey\n  title Only", "journey\n  section S\n  section T",
    ] {
    let result = draw(source)
    inspect(
      result.svg.contains("NaN") ||
      result.svg.contains("Infinity") ||
      result.svg.contains("undefined"),
      content="false",
    )
    inspect(result.width > 0.0 && result.height > 0.0, content="true")
    inspect(count(result.svg, "pele-grid"), content="0")
  }
}

///|
test "what Mermaid rejects is rejected" {
  inspect(
    message("journey\n  A task\n").contains(
      "Expecting 'taskData', got 'NEWLINE'",
    ),
    content="true",
  )
  inspect(message("journey\n  A task:\n").contains("got ':'"), content="true")
  inspect(
    message("journey\n  A; B: 3\n").contains("got 'INVALID'"),
    content="true",
  )
  inspect(message("journey\n  : 5\n").contains("Parse error"), content="true")
  inspect(
    message("journey\n  accDescr {\n  never closed\n").contains("Parse error"),
    content="true",
  )
}

///|
test "names that are special in JavaScript are ordinary names" {
  let svg = draw(
      "journey\n  section __proto__\n  constructor: 5: __proto__, constructor, toString, hasOwnProperty\n  __proto__: 1: valueOf\n",
    ).svg
  inspect(count(svg, "pele-legend-item"), content="5")
  inspect(svg.contains("data-id=\"__proto__\""), content="true")
}

///|
test "markup is shown as escaped text" {
  let svg = draw(
      "journey\n  title <script>alert(1)</script>\n  section \"><img src=x onerror=alert(1)>\n  <svg onload=alert(1)>: 5: </text><script>x</script>, \"onload=\"alert(1)",
    ).svg
  inspect(svg.contains("<script"), content="false")
  inspect(svg.contains("<img"), content="false")
  inspect(svg.contains("&lt;script&gt;alert(1)&lt;/script&gt;"), content="true")
  inspect(
    svg.contains("data-id=\"&quot;&gt;&lt;img src=x onerror=alert(1)&gt;\""),
    content="true",
  )
  inspect(
    svg.contains("<title>&lt;/text&gt;&lt;script&gt;x&lt;/script&gt;</title>"),
    content="true",
  )
  inspect(
    svg.contains("data-id=\"&quot;onload=&quot;alert(1)\""),
    content="true",
  )
}
