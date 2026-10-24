///|
fn draw(
  source : String,
  max_width? : Double,
) -> @types.RenderResult raise @errors.PeleError {
  let options = { ..@types.RenderOptions::default(), max_width, }
  @core.render([@radar.radar], source, options)
}

///|
fn svg(source : String, max_width? : Double) -> String {
  let result = draw(source, max_width?) catch {
    @errors.PeleError(failure) => return failure.message
  }
  result.svg
}

///|
fn size(source : String) -> (Double, Double) {
  let result = draw(source) catch { @errors.PeleError(_) => return (0, 0) }
  (result.width, result.height)
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
/// The text between the first `from` and the next `until` after it.
fn between(text : String, from : String, until : String) -> String {
  let start = @util.index_of(text, from) + from.length()
  let end = @util.index_of(text, until, from=start)
  @util.slice(text, start, end~)
}

///|
/// The part of `text` from the group of class `within` to its first closing tag.
fn group(text : String, within : String) -> String {
  let from = @util.index_of(text, "class=\"\{within}\"")
  if from == -1 {
    return ""
  }
  @util.slice(text, from, end=@util.index_of(text, "</g>", from~))
}

///|
const BASIC : String = "radar-beta\n  axis A, B, C, D\n  curve one[\"First\"]{1,2,3,4}\n  curve two{4,3,2,1}"

///|
fn config(radar : String, body : String) -> String {
  "---\nconfig:\n  radar:\n\{radar}\n---\n\{body}"
}

///|
test "a value is placed between the minimum and the maximum" {
  inspect(@radar.relative_radius(5, 0, 10, 100), content="50")
  inspect(@radar.relative_radius(0, 0, 10, 100), content="0")
  inspect(@radar.relative_radius(10, 0, 10, 100), content="100")
  inspect(@radar.relative_radius(-5, 0, 10, 100), content="0")
  inspect(@radar.relative_radius(15, 0, 10, 100), content="100")
  inspect(@radar.relative_radius(5, -10, 10, 100), content="75")
}

///|
test "a curve without tension is a polygon of degenerate segments" {
  let points : Array[@radar.Point] = [
    { x: 0, y: 0, },
    { x: 100, y: 0, },
    { x: 100, y: 100, },
    { x: 0, y: 100, },
  ]
  inspect(
    round_curve(points, 0),
    content="M0,0 C0,0 100,0 100,0 C100,0 100,100 100,100 C100,100 0,100 0,100 C0,100 0,0 0,0 Z",
  )
}

///|
test "a closed round curve passes through its points" {
  inspect(
    round_curve([{ x: 0, y: 0, }, { x: 100, y: 100, }], 0.5),
    content="M0,0 C0,0 100,100 100,100 C100,100 0,0 0,0 Z",
  )
  let points : Array[@radar.Point] = [
    { x: 0, y: 0, },
    { x: 100, y: 0, },
    { x: 100, y: 100, },
    { x: 0, y: 100, },
  ]
  inspect(
    round_curve(points, 0.5),
    content="M0,0 C50,-50 50,-50 100,0 C150,50 150,50 100,100 C50,150 50,150 0,100 C-50,50 -50,50 0,0 Z",
  )
}

///|
test "axes, labels, a graticule, curves and a legend are drawn" {
  let out = svg(BASIC)
  inspect(out.contains("aria-roledescription=\"radar\""), content="true")
  inspect(count(group(out, "pele-graticule"), "<circle"), content="5")
  inspect(count(out, "class=\"pele-axis-label\""), content="4")
  inspect(count(out, "<path class=\"pele-curve\""), content="2")
  inspect(count(out, "class=\"pele-legend-item\""), content="2")
  inspect(out.contains(">First<"), content="true")
  inspect(out.contains(">two<"), content="true")
  inspect(
    out.contains("data-id=\"one\" fill=\"var(--pele-series-1,"),
    content="true",
  )
  inspect(
    out.contains("data-id=\"two\" fill=\"var(--pele-series-2,"),
    content="true",
  )
  inspect(out.contains("fill-opacity=\"0.2\""), content="true")
  inspect(
    count(between(out, "class=\"pele-axes\" d=\"", "\""), "M0,0L"),
    content="4",
  )
}

///|
test "a polygon graticule draws polygons for the rings and the curves" {
  let out = svg(BASIC + "\n  graticule polygon\n  ticks 3")
  inspect(count(group(out, "pele-graticule"), "<polygon"), content="3")
  inspect(count(group(out, "pele-graticule"), "<circle"), content="0")
  inspect(count(out, "<polygon class=\"pele-curve\""), content="2")
  inspect(out.contains("<path class=\"pele-curve\""), content="false")
}

///|
test "showLegend false hides the legend and narrows the picture" {
  let shown = size(BASIC)
  let hidden = size(BASIC + "\n  showLegend false")
  inspect(
    svg(BASIC + "\n  showLegend false").contains("pele-legend"),
    content="false",
  )
  inspect(hidden.0 < shown.0, content="true")
}

///|
fn top(source : String) -> String {
  let out = svg(source + "\n graticule polygon")
  let curve = between(out, "<polygon class=\"pele-curve\"", "/>")
  between(curve, "points=\"0,", " ")
}

///|
test "values are scaled between min and max and clipped to them" {
  let body = "radar-beta\n axis A, B, C\n curve c{50, 0, 0}"
  inspect(top(body), content="-160")
  inspect(top(body + "\n max 100"), content="-80")
  inspect(top(body + "\n max 100\n min 20"), content="-60")
  inspect(top(body + "\n max 25"), content="-160")
  inspect(top(body + "\n min 60\n max 100"), content="0")
}

///|
test "width, height, margins and the axis factors are honoured" {
  let plain = BASIC + "\n showLegend false"
  let base = size(plain)
  let large = size(config("    width: 600\n    height: 600", plain))
  inspect(large.0 - base.0 >= 280 && large.0 - base.0 < 300, content="true")
  inspect(large.1 - base.1 >= 280, content="true")
  let roomy = size(config("    marginTop: 100\n    marginLeft: 120", plain))
  inspect(roomy.1 > base.1 && roomy.0 > base.0, content="true")
  inspect(
    svg(config("    axisScaleFactor: 0.5", BASIC)).contains("M0,0L0,-80"),
    content="true",
  )
  inspect(svg(BASIC).contains("M0,0L0,-160"), content="true")
  let far = size(config("    axisLabelFactor: 1.5", BASIC))
  inspect(far.1 > size(BASIC).1, content="true")
}

///|
test "curveTension rounds the curves" {
  let straight = svg(config("    curveTension: 0", BASIC))
  let round = svg(config("    curveTension: 0.5", BASIC))
  inspect(straight == round, content="false")
  inspect(
    between(
      straight, "data-id=\"one\" fill=\"var(--pele-series-1,#4c78a8)\" stroke=\"var(--pele-series-1,#4c78a8)\" d=\"",
      "\"",
    ).has_prefix("M0,-40 C0,-40 80,0 80,0 "),
    content="true",
  )
}

///|
test "a curve without a value for every axis is left out but stays in the legend" {
  let out = svg(
    "radar-beta\n axis A, B, C\n curve full{1,2,3}\n curve short{1,2}",
  )
  inspect(count(out, "class=\"pele-curve\""), content="1")
  inspect(count(out, "class=\"pele-legend-item\""), content="2")
}

///|
test "model errors surface as render errors" {
  inspect(
    svg("radar-beta\n axis A[\"Alpha\"], B\n curve c{ B: 2 }"),
    content="Missing entry for axis Alpha",
  )
  inspect(
    svg("radar-beta\n curve c{ B: 2 }"),
    content="Axes must be populated before curves for reference entries",
  )
}

///|
test "the title is drawn above, from the diagram or the front matter" {
  inspect(
    svg("---\ntitle: From front matter\n---\n" + BASIC).contains(
      ">From front matter<",
    ),
    content="true",
  )
  let own = svg("---\ntitle: From front matter\n---\n" + BASIC + "\n title Own")
  inspect(own.contains(">Own<"), content="true")
  inspect(own.contains("From front matter"), content="false")
}

///|
test "every label stays inside the picture" {
  let source = "radar-beta\n axis a[\"Top\"], b[\"A very long label on the right side\"], c[\"Bottom\"], d[\"A very long label on the left side\"]\n curve c{1,2,3,4}"
  let result = draw(source)
  inspect(
    result.svg.contains("viewBox=\"0 0 \{result.width} \{result.height}\""),
    content="true",
  )
  inspect(result.width > 320 + 2 * 200, content="true")
}

///|
test "degenerate charts render without NaN or infinity" {
  let sources = [
    "radar-beta",
    "radar-beta\n axis A, B, C",
    "radar-beta\n axis A\n curve c{5}",
    "radar-beta\n curve c{1,2,3}",
    "radar-beta\n axis A, B\n curve c{1,1}\n min 1\n max 1",
    "radar-beta\n axis A, B\n curve c{1,2}\n min 9\n max 2",
    "radar-beta\n axis A, B\n curve c{0,0}",
    "radar-beta\n axis A, B\n curve c{1,2}\n ticks 0",
    "radar-beta\n axis A, B\n curve c{1,2}\n ticks 0.3\n graticule polygon",
    "radar-beta\n axis A, B\n curve c{1,2}\n max " + "9".repeat(400),
    "radar-beta\n axis A, B\n curve c{" + "9".repeat(400) + ",2}",
    config(
      "    width: -5\n    height: \"tall\"\n    curveTension: 99\n    marginTop: -1",
      BASIC,
    ),
  ]
  for source in sources {
    let out = svg(source)
    inspect(
      (out.contains("NaN") ||
      out.contains("Infinity") ||
      out.contains("undefined")).to_string(),
      content="false",
    )
  }
}

///|
test "names and labels are escaped" {
  let out = svg(
    "radar-beta\n axis a[\"<script>x</script>\"], b[\"\\\"q\\\" & co\"]\n curve c[\"<img src=x>\"]{1,2}",
  )
  inspect(out.contains("<script"), content="false")
  inspect(out.contains("<img"), content="false")
  inspect(out.contains("&quot;q&quot; &amp; co"), content="true")
}

///|
test "accessible names are written" {
  let out = svg(BASIC + "\n accTitle: Name\n accDescr: Text")
  inspect(out.contains("<title id=\"pele-title\">Name</title>"), content="true")
  inspect(out.contains("<desc id=\"pele-desc\">Text</desc>"), content="true")
}

///|
test "a chart wider than maxWidth stacks its legend below" {
  let wide = draw(BASIC)
  let narrow = draw(BASIC, max_width=400) catch {
    @errors.PeleError(failure) => fail(failure.message)
  }
  inspect(wide.width > 400, content="true")
  inspect(narrow.width <= 400, content="true")
  inspect(narrow.height > wide.height, content="true")
}

///|
/// The path `write_closed_round_curve` writes through `points`.
fn round_curve(points : Array[@radar.Point], tension : Double) -> String {
  let d = StringBuilder()
  @radar.write_closed_round_curve(points, tension, segment => {
    d.write_string(segment)
  })
  d.to_string()
}
