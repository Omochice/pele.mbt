///|
const CHART : String =
  #|xychart
  #|  title "Sales Revenue"
  #|  x-axis "Month" [jan, feb, mar]
  #|  y-axis "Revenue (in $)" 4000 --> 10000
  #|  bar "2024" [5000, 6000, 7500]
  #|  line "2025" [5500, 7000, 9000]

///|
fn drawn(
  source : String,
  max_width? : Double,
) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), max_width, }
  Ok(@core.render([@xychart.xychart], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn svg(source : String, max_width? : Double) -> String {
  match drawn(source, max_width?) {
    Ok(result) => result.svg
    Err(failure) => failure.message
  }
}

///|
fn configured(body : String, chart : String) -> String {
  "---\nconfig:\n  xyChart:\n\{body}\n---\n\{chart}"
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
/// The text between the first `from` and the `to` that follows it.
fn between(text : String, from : String, to : String) -> String {
  let start = @util.index_of(text, from)
  if start == -1 {
    return ""
  }
  let end = @util.index_of(text, to, from=start + from.length())
  @util.slice(text, start + from.length(), end~)
}

///|
/// The inside of each start tag called `name`.
fn tags(svg : String, name : String) -> Array[String] {
  let found = []
  let open = "<\{name}"
  let mut at = @util.index_of(svg, open)
  while at != -1 {
    let start = at + open.length()
    let end = @util.index_of(svg, ">", from=start)
    found.push(@util.slice(svg, start, end~))
    at = @util.index_of(svg, open, from=end)
  }
  found
}

///|
fn attribute(tag : String, name : String) -> String {
  between(tag, " \{name}=\"", "\"")
}

///|
fn numbers(
  svg : String,
  name : String,
  keys : Array[String],
) -> Array[Array[Double]] {
  tags(svg, name).map(tag => {
    keys.map(key => @util.parse_float(attribute(tag, key)))
  })
}

///|
fn boxes(svg : String) -> Array[Array[Double]] {
  numbers(svg, "rect", ["x", "y", "width", "height"])
}

///|
/// The text of every `text` element, as it reads.
fn texts(svg : String) -> Array[String] {
  let found = []
  let mut at = @util.index_of(svg, "<text")
  while at != -1 {
    let mut start = @util.index_of(svg, ">", from=at) + 1
    if @util.starts_with_at(svg, "<tspan", start) {
      start = @util.index_of(svg, ">", from=start) + 1
    }
    let end = @util.index_of(svg, "<", from=start)
    found.push(@util.slice(svg, start, end~))
    at = @util.index_of(svg, "<text", from=end)
  }
  found
}

///|
fn close(actual : Double, expected : Double) -> Bool {
  (actual - expected).abs() < 0.05
}

///|
test "draws the title, axes, grid, a bar series, a line series and a legend" {
  let result = drawn(CHART).unwrap()
  inspect(result.kind, content="xychart")
  inspect("\{result.width}x\{result.height}", content="700x500")
  let out = result.svg
  assert_true(out.contains("class=\"pele pele-xychart\""))
  assert_true(out.contains("class=\"pele-grid\""))
  assert_true(out.contains("class=\"pele-axis\""))
  let bars = between(
    out, "<g class=\"pele-series pele-bars\" data-id=\"2024\" fill=\"", "</g>",
  )
  assert_true(bars.has_prefix("var(--pele-series-1"))
  inspect(count(bars, "<rect"), content="3")
  let line = between(
    out, "<g class=\"pele-series pele-line\" data-id=\"2025\" fill=\"", "</g>",
  )
  assert_true(line.has_prefix("var(--pele-series-2"))
  inspect(count(line, "<circle"), content="3")
  inspect(count(line, "L"), content="2")
  assert_true(line.contains("fill=\"none\""))
  let written = texts(out)
  for
    text in [
      "Sales Revenue", "Month", "Revenue (in $)", "jan", "feb", "mar", "4000", "7000",
      "10000", "2024", "2025",
    ] {
    assert_true(written.contains(text))
  }
  inspect(count(out, "class=\"pele-legend-item\""), content="2")
}

///|
test "draws lines over bars, and colors each series by its place in the source" {
  let out = svg("xychart\n line [1, 2]\n bar [2, 1]\n line [3, 3]\n bar [1, 1]")
  let order = []
  let mut at = @util.index_of(out, "<g class=\"pele-series pele-")
  while at != -1 {
    let start = at + "<g class=\"pele-series pele-".length()
    let kind = @util.slice(
      out,
      start,
      end=@util.index_of(out, "\"", from=start),
    )
    let color = between(out[at:].to_owned(), "fill=\"var(--pele-series-", ",")
    order.push(kind + color)
    at = @util.index_of(out, "<g class=\"pele-series pele-", from=start)
  }
  inspect(order.join(" "), content="bars2 bars4 line1 line3")
}

///|
test "scales bars to the range and sets them side by side" {
  let out = svg(
    "xychart\n x-axis [a, b]\n y-axis 0 --> 100\n bar [50, 100]\n bar [25, 75]",
  )
  let rects = boxes(out)
  inspect(rects.length(), content="4")
  let a1 = rects[0]
  let b1 = rects[1]
  let a2 = rects[2]
  let b2 = rects[3]
  assert_true(close(b1[3], a1[3] * 2))
  assert_true(close(a2[3], a1[3] / 2))
  assert_true(close(b2[3], a1[3] * 1.5))
  assert_true(close(a1[1] + a1[3], b2[1] + b2[3]))
  assert_true(a2[0] >= a1[0] + a1[2])
  assert_true(b1[0] > a2[0] + a2[2])
}

///|
test "stands bars on zero when the range comes from the data" {
  let heights = boxes(svg("xychart\n bar [5000, 10000]")).map(r => r[3])
  assert_true(close(heights[1], heights[0] * 2))
  // Mermaid starts the axis at the smallest value, which leaves that bar with no height.
  assert_true(heights[0] > 100)
  let mixed = boxes(svg("xychart\n bar [4, -4]")).map(r => r[1])
  assert_true(mixed[1] > mixed[0])
}

///|
test "keeps an explicit range as written and cuts what falls outside it" {
  let out = svg(
    "xychart\n x-axis [a, b, c]\n y-axis 10 --> 20\n bar [5, 15, 40]\n line [0, 15, 30]",
  )
  let written = texts(out)
  assert_true(written.contains("10"))
  assert_true(written.contains("20"))
  assert_true(!written.contains("0"))
  assert_true(!written.contains("40"))
  let rects = boxes(out)
  inspect(rects.map(r => r[3]).length(), content="3")
  inspect(rects[0][3], content="0")
  assert_true(close(rects[2][3], rects[1][3] * 2))
  inspect(count(out, "<circle"), content="1")
}

///|
test "spreads values over a numeric x axis" {
  let out = svg("xychart\n x-axis \"t\" 0 --> 10\n line [1, 2, 3]")
  let xs = numbers(out, "circle", ["cx"]).map(c => c[0])
  assert_true(close(xs[1] - xs[0], xs[2] - xs[1]))
  for tick in ["0", "5", "10"] {
    assert_true(texts(out).contains(tick))
  }
  let auto = svg("xychart\n line [5, 6, 7, 8]")
  for tick in ["1", "2", "3", "4"] {
    assert_true(texts(auto).contains(tick))
  }
}

///|
test "leaves out values beyond the categories and categories without a value" {
  inspect(
    count(svg("xychart\n x-axis [a, b]\n bar [1, 2, 3, 4]"), "<rect"),
    content="2",
  )
  let short = svg("xychart\n x-axis [a, b, c, d]\n bar [1, 2]\n line [1, 2]")
  inspect(count(short, "<rect"), content="2")
  inspect(count(short, "<circle"), content="2")
  assert_true(!short.contains("NaN"))
  let late = drawn("xychart\n line [1, 2, 3, 4, 5, 6]\n x-axis [a, b]").unwrap()
  let xs = numbers(late.svg, "circle", ["cx"]).map(c => c[0])
  inspect(xs.length(), content="2")
  assert_true(xs[1] < late.width)
}

///|
test "turns the chart on its side for the horizontal orientation" {
  let body = "x-axis [a, b]\n y-axis 0 --> 10\n bar [5, 10]"
  let upright = boxes(svg("xychart\n \{body}"))
  let a = upright[0]
  let b = upright[1]
  assert_true(close(b[3], a[3] * 2))
  inspect(b[2] == a[2], content="true")
  assert_true(b[0] > a[0])
  let sideways = boxes(svg("xychart horizontal\n \{body}"))
  let c = sideways[0]
  let d = sideways[1]
  assert_true(close(d[2], c[2] * 2))
  inspect(d[3] == c[3], content="true")
  inspect(d[0] == c[0], content="true")
  assert_true(d[1] > c[1])
  let from_config = svg(
    configured("    chartOrientation: horizontal", "xychart\n \{body}"),
  )
  inspect(from_config == svg("xychart horizontal\n \{body}"), content="true")
  let overridden = svg(
    configured("    chartOrientation: horizontal", "xychart vertical\n \{body}"),
  )
  inspect(overridden == svg("xychart\n \{body}"), content="true")
}

///|
test "labels the points of a line" {
  let out = svg(
    "xychart\n x-axis [Q1, Q2, Q3]\n line [25 \"Launch\", 45, 72 \"Target\"]\n bar [1 \"ignored\", 2, 3]",
  )
  let labels = between(out, "<g class=\"pele-point-labels\"", "</g>")
  inspect(texts(labels).join(" "), content="Launch Target")
  assert_true(!out.contains("ignored"))
}

///|
test "honours the size and the show settings" {
  let plain = svg(CHART)
  let sized = drawn(configured("    width: 900\n    height: 400", CHART)).unwrap()
  inspect("\{sized.width}x\{sized.height}", content="900x400")
  assert_true(
    !svg(configured("    showTitle: false", CHART)).contains("Sales Revenue"),
  )
  assert_true(
    !svg(configured("    showLegend: false", CHART)).contains("pele-legend"),
  )
  let no_x = texts(
    svg(
      configured(
        "    xAxis:\n      showLabel: false\n      showTitle: false",
        CHART,
      ),
    ),
  )
  assert_true(!no_x.contains("jan"))
  assert_true(!no_x.contains("Month"))
  assert_true(no_x.contains("7000"))
  let no_y = texts(
    svg(
      configured(
        "    yAxis:\n      showLabel: false\n      showTitle: false",
        CHART,
      ),
    ),
  )
  assert_true(!no_y.contains("7000"))
  assert_true(!no_y.contains("Revenue (in $)"))
  assert_true(no_y.contains("jan"))
  fn axis(out : String) -> String {
    between(out, "class=\"pele-axis\" d=\"", "\"")
  }

  fn marks(body : String) -> String {
    axis(svg(configured(body, CHART)))
  }

  assert_true(
    marks("    xAxis:\n      showTick: false").length() < axis(plain).length(),
  )
  assert_true(
    marks("    yAxis:\n      showTick: false").length() < axis(plain).length(),
  )
  assert_true(!marks("    xAxis:\n      showAxisLine: false").contains("H"))
  assert_true(!marks("    yAxis:\n      showAxisLine: false").contains("V"))
  let bare = "    xAxis:\n      showTick: false\n      showAxisLine: false\n    yAxis:\n      showTick: false\n      showAxisLine: false"
  assert_true(!svg(configured(bare, CHART)).contains("pele-axis\""))
  inspect(
    svg(configured("    width: wide\n    showTitle: 3", CHART)) == plain,
    content="true",
  )
}

///|
test "writes the value of each bar with showDataLabel" {
  let chart = "xychart\n x-axis [a, b, c]\n y-axis 0 --> 30\n bar [12, 2, 25]\n bar [7, 30, 1]"
  assert_true(!svg(chart).contains("pele-data-labels"))
  let out = svg(configured("    showDataLabel: true", chart))
  let values = texts(between(out, "<g class=\"pele-data-labels\"", "</g>"))
  values.sort()
  inspect(values.join(" "), content="1 2 7 12 25 30")
  // They are written past the end of the bars in the text color, whichever way Mermaid's setting is.
  assert_true(!out.contains("fill=\"var(--_bg)\""))
  for outside in ["true", "false"] {
    inspect(
      svg(
        configured(
          "    showDataLabel: true\n    showDataLabelOutsideBar: \{outside}",
          chart,
        ),
      ) ==
      out,
      content="true",
    )
  }
}

///|
test "thins out category labels that would run into each other" {
  let names = Array::makei(200, i => "category\{i}")
  let values = Array::makei(200, i => i.to_string())
  let out = svg(
    "xychart\n x-axis [\{names.join(", ")}]\n bar [\{values.join(", ")}]",
  )
  let shown = texts(out).filter(t => t.has_prefix("category"))
  assert_true(shown.length() > 3)
  assert_true(shown.length() < 15)
  inspect(count(out, "<rect"), content="200")
}

///|
test "refuses a chart with no series, as Mermaid does" {
  inspect(
    svg("xychart\n title \"Empty\""),
    content="No Plot to render, please provide a plot with some data",
  )
  assert_true(drawn("xychart\n line [1, 2") is Err(_))
  assert_true(drawn("xychart\n x-axis [é]\n line [1]") is Err(_))
}

///|
test "takes the title from front matter unless the chart sets one" {
  assert_true(
    svg("---\ntitle: From front matter\n---\nxychart\n line [1, 2]").contains(
      "From front matter",
    ),
  )
  assert_true(
    svg("---\ntitle: From front matter\n---\nxychart\n title Own\n line [1, 2]").contains(
      ">Own<",
    ),
  )
}

///|
test "names the chart for assistive technology" {
  let out = svg("xychart\n accTitle: Sales\n accDescr: By month\n line [1, 2]")
  assert_true(out.contains("<title id=\"pele-title\">Sales</title>"))
  assert_true(out.contains("<desc id=\"pele-desc\">By month</desc>"))
}

///|
test "gives the same output for the same input" {
  inspect(svg(CHART) == svg(CHART), content="true")
}
