///|
let basic : String = "sankey\na,b,5\na,c,3\nb,d,4\nc,d,1.239\n"

///|
fn render(
  source : String,
  max_width? : Double,
  font_size? : Double,
  id_prefix? : String,
) -> @types.RenderResult raise @errors.PeleError {
  let options = {
    ..@types.RenderOptions::default(),
    max_width,
    font_size,
    id_prefix,
  }
  @core.render([@sankey.sankey], source, options)
}

///|
fn configured(sankey : String, body~ : String = basic) -> String {
  let lines = sankey.split("\n").map(line => "    " + line.to_owned())
  "---\nconfig:\n  sankey:\n\{lines.join("\n")}\n---\n\{body}"
}

///|
fn count(svg : String, needle : String) -> Int32 {
  let mut total = 0
  let mut at = @util.index_of(svg, needle)
  while at != -1 {
    total += 1
    at = @util.index_of(svg, needle, from=at + needle.length())
  }
  total
}

///|
/// The value of an attribute of the bar of node `id`.
fn attr(svg : String, id : String, name : String) -> String {
  let head = "class=\"pele-sankey-node\" data-id=\"\{id}\""
  let at = @util.index_of(svg, head)
  let tag_end = @util.index_of(svg, "/>", from=at)
  let key = " \{name}=\""
  let found = @util.index_of(svg, key, from=at)
  if at == -1 || found == -1 || found > tag_end {
    return ""
  }
  let from = found + key.length()
  @util.slice(svg, from, end=@util.index_of(svg, "\"", from~))
}

///|
fn attr_number(svg : String, id : String, name : String) -> Double {
  @util.parse_float(attr(svg, id, name))
}

///|
fn failure_of(source : String) -> String {
  try render(source) catch {
    @errors.PeleError(failure) => failure.message
  } noraise {
    _ => "rendered"
  }
}

///|
test "a bar and a label per node and a band per link" {
  let result = render(basic)
  let svg = result.svg
  inspect(result.kind, content="sankey")
  assert_true(
    svg.has_prefix(
      "<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-sankey\"",
    ),
  )
  inspect(count(svg, "class=\"pele-sankey-node\""), content="4")
  inspect(count(svg, "class=\"pele-sankey-link\""), content="4")
  inspect(count(svg, "class=\"pele-label\""), content="4")
  assert_true(svg.contains("data-id=\"a-&gt;b\""))
  assert_true(svg.contains("<title>a → b: 5</title>"))
}

///|
test "bars are colored by series in the order nodes first appear" {
  let svg = render(basic).svg
  inspect(attr(svg, "a", "fill"), content="var(--pele-series-1,#4c78a8)")
  inspect(attr(svg, "b", "fill"), content="var(--pele-series-2,#f58518)")
  inspect(attr(svg, "d", "fill"), content="var(--pele-series-4,#e45756)")
}

///|
test "the default size is 600 by 400 plus padding" {
  let result = render(basic)
  inspect(result.width, content="616")
  inspect(result.height, content="416")
}

///|
test "width and height are configurable" {
  let result = render(configured("width: 300\nheight: 150"))
  inspect(result.width, content="316")
  inspect(result.height, content="166")
  inspect(attr_number(result.svg, "d", "x"), content="290")
}

///|
test "values show two decimals, a prefix and a suffix, unless showValues is off" {
  let shown = render(basic).svg
  assert_true(
    shown.contains(
      ">a <tspan class=\"pele-sankey-value\" fill=\"var(--_m)\">8</tspan><",
    ),
  )
  assert_true(shown.contains(">5.24</tspan>"))
  let money = render(configured("prefix: \"$\"\nsuffix: \" M\"")).svg
  assert_true(money.contains(">$8 M</tspan>"))
  assert_true(money.contains("<title>a → b: $5 M</title>"))
  let hidden = render(configured("showValues: false")).svg
  assert_true(!hidden.contains("pele-sankey-value"))
  assert_true(hidden.contains(">a</text>"))
  let coded = render(
      configured(
        "prefix: \"&euro;\"\nsuffix: \" &amp;lt;\"\nlabelStyle: outlined",
      ),
    ).svg
  assert_true(coded.contains(">€8 &amp;lt;</tspan>"))
  assert_true(coded.contains("<title>a → b: €5 &amp;lt;</title>"))
}

///|
test "nodes get more room when values are shown, as Mermaid does" {
  let body = "sankey\na,b,1\na,c,1\na,d,1\n"
  let gap = (svg : String) => {
    attr_number(svg, "c", "y") -
    attr_number(svg, "b", "y") -
    attr_number(svg, "b", "height")
  }
  assert_true((gap(render(body).svg) - 27).abs() < 0.05)
  assert_true(gap(render(configured("showValues: false", body~)).svg) >= 12)
  assert_true(
    (gap(render(configured("showValues: false\nnodePadding: 40", body~)).svg) -
    40).abs() <
    0.05,
  )
}

///|
test "nodeAlignment moves nodes between columns" {
  let body = "sankey\na,b,4\nb,c,3\nc,d,3\nx,d,2\na,y,1\n"
  let x = (alignment : String, id : String) => {
    attr_number(
      render(configured("nodeAlignment: \{alignment}", body~)).svg,
      id,
      "x",
    )
  }
  let third = 590.0 / 3.0
  assert_true(x("justify", "y") == 590)
  assert_true((x("left", "y") - third).abs() < 0.05)
  assert_true(x("left", "x") == 0)
  assert_true((x("right", "x") - third * 2).abs() < 0.05)
  assert_true((x("center", "x") - third * 2).abs() < 0.05)
  assert_true((x("center", "y") - third).abs() < 0.05)
  assert_true(x("nonsense", "y") == 590)
}

///|
test "linkColor picks the band color" {
  let link = (svg : String) => {
    let at = @util.index_of(
      svg, "class=\"pele-sankey-link\" data-id=\"a-&gt;b\"",
    )
    @util.slice(svg, at, end=@util.index_of(svg, "><title>", from=at))
  }
  // A gradient needs definitions, which the output never has, so it takes the source's color.
  let source_fill = "fill=\"var(--pele-series-1,#4c78a8)\""
  assert_true(link(render(basic).svg).contains(source_fill))
  assert_true(
    link(render(configured("linkColor: gradient")).svg).contains(source_fill),
  )
  assert_true(
    link(render(configured("linkColor: source")).svg).contains(source_fill),
  )
  assert_true(
    link(render(configured("linkColor: target")).svg).contains(
      "fill=\"var(--pele-series-2,#f58518)\"",
    ),
  )
  assert_true(
    link(render(configured("linkColor: \"#a1a1a1\"")).svg).contains(
      "style=\"fill:#a1a1a1;\"",
    ),
  )
  assert_true(
    !link(render(configured("linkColor: \"url(#x)\"")).svg).contains("style="),
  )
  let plain = render(basic).svg
  assert_true(!plain.contains("<defs") && !plain.contains("url("))
  assert_true(
    plain.contains("class=\"pele-sankey-links\" fill-opacity=\"0.4\""),
  )
}

///|
/// The opening tag of the band from `from` to `to`.
fn link_tag(svg : String, from : String, to : String) -> String {
  let at = @util.index_of(
    svg,
    "class=\"pele-sankey-link\" data-id=\"\{from}-&gt;\{to}\"",
  )
  @util.slice(svg, at, end=@util.index_of(svg, ">", from=at))
}

///|
/// The ids of the gradients `svg` defines, in order.
fn gradient_ids(svg : String) -> Array[String] {
  let ids = []
  let head = "<linearGradient id=\""
  let mut at = @util.index_of(svg, head)
  while at != -1 {
    let from = at + head.length()
    ids.push(@util.slice(svg, from, end=@util.index_of(svg, "\"", from~)))
    at = @util.index_of(svg, head, from~)
  }
  ids
}

///|
test "links are filled with gradients when there is an idPrefix" {
  let svg = render(basic, id_prefix="p1").svg
  assert_eq(count(svg, "<linearGradient "), 4)
  let id = gradient_ids(svg)[0]
  inspect(
    "\{link_tag(svg, "a", "b")}\n\{@util.slice(svg, @util.index_of(svg, "<defs>"), end=@util.index_of(svg, "</linearGradient>") + 17)}",
    content=(
      #|class="pele-sankey-link" data-id="a-&gt;b" d="M10,10.13C152.5,10.13 152.5,0 295,0L295,233.13C152.5,233.13 152.5,243.25 10,243.25Z" fill="url(#p1-sankey-qlqzf51b0vo2l) var(--pele-series-1,#4c78a8)"
      #|<defs><linearGradient id="p1-sankey-qlqzf51b0vo2l" gradientUnits="userSpaceOnUse" x1="10" x2="295"><stop offset="0" stop-color="var(--pele-series-1,#4c78a8)"/><stop offset="1" stop-color="var(--pele-series-2,#f58518)"/></linearGradient>
    ),
  )
  assert_true(link_tag(svg, "a", "b").contains("fill=\"url(#\{id}) "))
  assert_eq(render(basic, id_prefix="p1").svg, svg)
  let other = gradient_ids(render("sankey\nx,y,2\n", id_prefix="p1").svg)
  assert_true(other.iter().all(id => !gradient_ids(svg).contains(id)))
  for color in ["source", "target", "\"#a1a1a1\""] {
    let flat = render(configured("linkColor: \{color}"), id_prefix="p1").svg
    assert_true(!flat.contains("<defs") && !flat.contains("url("))
  }
}

///|
test "gradient colours come from nodeColors" {
  let svg = render(
      configured("nodeColors:\n  a: \"#123456\"\n  b: \"url(#x)\""),
      id_prefix="p_1",
    ).svg
  assert_true(
    svg.contains(
      "<stop offset=\"0\" stop-color=\"#123456\"/><stop offset=\"1\" stop-color=\"var(--pele-series-2,#f58518)\"/>",
    ),
  )
  inspect(
    link_tag(svg, "a", "b"),
    content=(
      #|class="pele-sankey-link" data-id="a-&gt;b" d="M10,10.13C152.5,10.13 152.5,0 295,0L295,233.13C152.5,233.13 152.5,243.25 10,243.25Z" fill="url(#p_1-sankey-1ogh1b31g8mi0n) #123456"
    ),
  )
  assert_true(!svg.contains("url(#x)"))
}

///|
test "escaped nodeColors stay whole in gradients" {
  let svg = render(
      configured("nodeColors:\n  a: 'red&blue'\n  b: 'x\"y'"),
      id_prefix="p1",
    ).svg
  assert_true(
    svg.contains(
      "<stop offset=\"0\" stop-color=\"red&amp;blue\"/><stop offset=\"1\" stop-color=\"x&quot;y\"/>",
    ),
  )
  inspect(
    link_tag(svg, "a", "b"),
    content=(
      #|class="pele-sankey-link" data-id="a-&gt;b" d="M10,10.13C152.5,10.13 152.5,0 295,0L295,233.13C152.5,233.13 152.5,243.25 10,243.25Z" fill="url(#p1-sankey-s71to11x5awcr) red&amp;blue"
    ),
  )
}

///|
test "links stay flat when the idPrefix could not appear in a url()" {
  for id_prefix in ["p\"1", "p)1", "p 1", ""] {
    let svg = render(basic, id_prefix~).svg
    assert_true(!svg.contains("<defs") && !svg.contains("url("))
    assert_true(
      link_tag(svg, "a", "b").contains(" fill=\"var(--pele-series-1,#4c78a8)\""),
    )
  }
}

///|
test "nodeWidth, nodeColors and labelStyle are honoured" {
  inspect(
    attr(render(configured("nodeWidth: 24")).svg, "a", "width"),
    content="24",
  )
  let colored = render(
      configured(
        "linkColor: source\nnodeColors:\n  a: \"#123456\"\n  d: \"url(#x)\"\n  __proto__: red",
      ),
    ).svg
  assert_true(colored.contains("data-id=\"a\" x=\"0\""))
  inspect(attr(colored, "a", "style"), content="fill:#123456;")
  inspect(attr(colored, "d", "style"), content="")
  assert_true(!colored.contains("url("))
  let outlined = render(configured("labelStyle: outlined"))
  assert_true(outlined.width > 616)
  assert_true(
    outlined.svg.contains(
      "data-id=\"d\"><text x=\"606\" y=\"144.45\" text-anchor=\"start\" fill=\"none\" stroke=\"var(--_bg)\"",
    ),
  )
  assert_true(
    render(basic).svg.contains(
      "data-id=\"d\"><text x=\"584\" y=\"144.45\" text-anchor=\"end\">",
    ),
  )
}

///|
test "a label sits on the side of its bar that faces the middle" {
  let svg = render(basic).svg
  assert_true(
    svg.contains(
      "data-id=\"a\"><text x=\"16\" y=\"201.53\" text-anchor=\"start\"",
    ),
  )
  assert_true(
    svg.contains(
      "data-id=\"d\"><text x=\"584\" y=\"144.45\" text-anchor=\"end\"",
    ),
  )
}

///|
/// The position and anchor of the label of node `id`.
fn label_at(svg : String, id : String) -> String {
  let head = "data-id=\"\{id}\"><text "
  let from = @util.index_of(svg, head) + head.length()
  @util.slice(svg, from, end=@util.index_of(svg, ">", from~))
}

///|
let funnel : String = "sankey-beta\nVisitors,Signed up,3200\nVisitors,Bounced,9800\nSigned up,Opened a folder,2100\nSigned up,Never returned,1100\nOpened a folder,Ran Agency,1450\nOpened a folder,Write-only,650\nRan Agency,Upgraded to Pro,380\nRan Agency,Stayed free,1070\nUpgraded to Pro,Upgraded to Team,96\nUpgraded to Pro,Stayed on Pro,284"

///|
test "labels in adjacent columns are kept apart without moving the bars" {
  let shown = []
  for font_size in [14.0, 16.0] {
    let svg = render(funnel, font_size~, max_width=664).svg
    let hidden = render(
        configured("showValues: false", body=funnel),
        font_size~,
      ).svg
    let ids = [
      "Visitors", "Signed up", "Bounced", "Opened a folder", "Never returned", "Ran Agency",
      "Write-only", "Upgraded to Pro", "Stayed free", "Upgraded to Team", "Stayed on Pro",
    ]
    assert_eq(
      ids.map(id => attr(svg, id, "x")),
      ids.map(id => attr(hidden, id, "x")),
    )
    assert_true(svg.contains(">1450</tspan>"))
    shown.push(
      "\{font_size}: \{label_at(svg, "Opened a folder")} | \{label_at(svg, "Ran Agency")}",
    )
  }
  inspect(
    shown.join("\n"),
    content=(
      #|14: x="252" y="248.66" text-anchor="start" | x="348" y="276.7" text-anchor="end"
      #|16: x="252" y="246.36" text-anchor="start" | x="348" y="277.4" text-anchor="end"
    ),
  )
}

///|
test "a moved label stays nearer its own bar than any other in the column" {
  let svg = render(
      configured(
        "showValues: false",
        body="sankey\nA,B,1\nC,D,200\nE,F,1\nF,G,600\nG,D,200\nB,D,1\n",
      ),
    ).svg
  inspect(
    "\{label_at(svg, "E")} | E \{attr(svg, "E", "y")}+\{attr(svg, "E", "height")} | C \{attr(svg, "C", "y")}+\{attr(svg, "C", "height")}",
    content=(
      #|x="16" y="23.05" text-anchor="start" | E 17.83+1 | C 32.2+127.97
    ),
  )
}

///|
test "labels shrink in narrow or crowded charts, down to 10px" {
  let label_size = (svg : String) => {
    let head = "class=\"pele-labels\" font-size=\""
    let from = @util.index_of(svg, head) + head.length()
    @util.slice(svg, from, end=@util.index_of(svg, "\"", from~))
  }
  let fan = (n : Int32) => {
    "sankey\n" + Array::makei(n, i => "s\{i},t,1\n").join("")
  }
  inspect(
    [
      label_size(render(basic).svg),
      label_size(render(fan(20)).svg),
      label_size(render(fan(60)).svg),
      label_size(render(basic, max_width=320).svg),
      label_size(render(fan(20), font_size=32).svg),
    ].join(" "),
    content="14 11 10 10 20",
  )
}

///|
test "the picture grows to hold labels that reach outside the chart" {
  let result = render(
    configured(
      "labelStyle: outlined",
      body="sankey\nA,Somewhere with a very long name indeed,1\n",
    ),
  )
  assert_true(result.width > 800)
  assert_true(result.svg.contains("viewBox=\"0 0 \{result.width} "))
}

///|
test "quoted names are shown with their quotes and escaped" {
  let svg = render(
      "sankey\n\"Heating, \"\"homes\"\"\",Lighting & appliances,1\n",
    ).svg
  assert_true(svg.contains(">Heating, &quot;homes&quot; <tspan"))
  assert_true(svg.contains(">Lighting &amp; appliances <tspan"))
}

///|
test "comments, blank lines, and both keywords are accepted" {
  let first = render(
      "sankey-beta\n\n%% source,target,value\na,b,1\n\n\nb,c,2\n",
    ).svg
  let second = render("sankey\na,b,1\nb,c,2").svg
  assert_true(first == second)
}

///|
test "the front matter title is drawn" {
  let plain = render(basic)
  let titled = render("---\ntitle: Energy flows\n---\n" + basic)
  assert_true(titled.svg.contains("class=\"pele-title\""))
  assert_true(titled.svg.contains(">Energy flows<"))
  assert_true(titled.height > plain.height)
  inspect(titled.height, content="452")
}

///|
test "circular links are rejected at render time" {
  inspect(
    failure_of("sankey\na,b,1\nb,c,1\nc,a,1\n"),
    content="Sankey diagrams cannot have circular links, and \"a\" is part of one.",
  )
  inspect(
    failure_of("sankey\na,a,1\n"),
    content="Sankey diagrams cannot have circular links, and \"a\" is part of one.",
  )
}

///|
test "what Mermaid rejects is rejected" {
  for
    source in [
      "sankey\n", "sankey\na,b\n", "sankey\na,b,1,2\n", "sankey\na,,1\n", "sankey\n\"\",b,1\n",
      "sankey x\na,b,1\n",
    ] {
    assert_true(failure_of(source) != "rendered")
  }
  inspect(
    failure_of("sankey\na,b\n"),
    content="Parse error on line 2:\na,b\n---^\nExpecting 'COMMA', 'NEWLINE', 'EOF', got 'EOF'",
  )
}

///|
test "values are read up to where they stop being numbers, and the rest are refused" {
  assert_true(
    render("sankey\na,b,50%\nb,c, 2e1 kWh\n").svg.contains(
      "<title>b → c: 20</title>",
    ),
  )
  for value in ["abc", "", "Infinity", "1e400", "-"] {
    let failure = try {
      render("sankey\na,b,1\nb,c,\{value}\n") |> ignore
      None
    } catch {
      @errors.PeleError(failure) => Some(failure)
    }
    guard failure is Some(failure) else { fail("accepted \{value}") }
    inspect(
      "\{failure.code.to_string()} \{failure.line} \{failure.column}",
      content="syntax 3 5",
    )
  }
}

///|
test "non-positive values are drawn as empty flows" {
  let svg = render("sankey\na,b,0\na,c,-3\nb,d,0\nc,d,2\n").svg
  assert_true(!svg.contains("NaN"))
  inspect(count(svg, "class=\"pele-sankey-link\""), content="4")
  assert_true(svg.contains("<title>a → b: 0</title>"))
  inspect(render("sankey\na,b,0\na,c,-3\nb,d,0\nc,d,2\n").height, content="427")
}

///|
test "a diagram wider than maxWidth is drawn narrower" {
  let result = render(basic, max_width=400)
  inspect(result.width, content="400")
  inspect(attr_number(result.svg, "d", "x"), content="374")
}

///|
test "configured colors are written as inline styles" {
  inspect(
    render(
      configured(
        "linkColor: \"#a1a1a1\"\nnodeColors:\n  a: \"#123456\"",
        body="sankey\na,b,1\n",
      ),
    ).svg,
    content="<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-sankey\" viewBox=\"0 0 616 416\" width=\"616\" height=\"416\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"sankey\"><g transform=\"translate(8,8)\"><g class=\"pele-sankey-links\" fill-opacity=\"0.4\"><path class=\"pele-sankey-link\" data-id=\"a-&gt;b\" d=\"M10,0C300,0 300,0 590,0L590,400C300,400 300,400 10,400Z\" fill=\"var(--pele-series-1,#4c78a8)\" style=\"fill:#a1a1a1;\"><title>a → b: 1</title></path></g><g class=\"pele-sankey-nodes\"><rect class=\"pele-sankey-node\" data-id=\"a\" x=\"0\" y=\"0\" width=\"10\" height=\"400\" rx=\"2\" fill=\"var(--pele-series-1,#4c78a8)\" style=\"fill:#123456;\"/><rect class=\"pele-sankey-node\" data-id=\"b\" x=\"590\" y=\"0\" width=\"10\" height=\"400\" rx=\"2\" fill=\"var(--pele-series-2,#f58518)\"/></g><g class=\"pele-labels\" font-size=\"14\"><g class=\"pele-label\" data-id=\"a\"><text x=\"16\" y=\"204.9\" text-anchor=\"start\">a <tspan class=\"pele-sankey-value\" fill=\"var(--_m)\">1</tspan></text></g><g class=\"pele-label\" data-id=\"b\"><text x=\"584\" y=\"204.9\" text-anchor=\"end\">b <tspan class=\"pele-sankey-value\" fill=\"var(--_m)\">1</tspan></text></g></g></g></svg>",
  )
}

///|
test "Unicode names are drawn and escaped" {
  let svg = render(
      "sankey\n\"<script>Доход 🏠</script>\",\"収入\"\" onload=\"\"alert(1)\",1\nCafé,☀️,2\n",
    ).svg
  assert_true(
    svg.contains("data-id=\"&lt;script&gt;Доход 🏠&lt;/script&gt;\""),
  )
  assert_true(svg.contains("data-id=\"収入&quot; onload=&quot;alert(1)\""))
  assert_true(svg.contains(">Café <tspan"))
  assert_true(svg.contains(">☀️ <tspan"))
}

///|
test "entity codes in names are decoded in labels" {
  for style in ["normal", "outlined"] {
    let svg = render(
        configured(
          "labelStyle: \{style}",
          body="sankey\n\"Доход #35; #amp; #34;чистый#34;\",Расходы,1\n",
        ),
      ).svg
    assert_true(
      svg.contains(">Доход # &amp; &quot;чистый&quot; <tspan"),
    )
    assert_true(
      svg.contains("data-id=\"Доход # &amp; &quot;чистый&quot;\""),
    )
    assert_true(
      svg.contains(
        "<title>Доход # &amp; &quot;чистый&quot; → Расходы: 1</title>",
      ),
    )
  }
  assert_true(
    render("sankey\na#amp;#35;xFFFE;,b,1\n").svg.contains(
      ">a&amp;#xFFFE; <tspan",
    ),
  )
}

///|
test "a name that decodes to a character XML forbids is rejected for every label style" {
  let shown = []
  for style in ["normal", "outlined"] {
    for entity in ["#65534;", "#65535;", "#1;"] {
      for row in ["a\{entity},b,1", "b,\"a\{entity}\",1"] {
        shown.push(
          failure_of(
            configured("labelStyle: \{style}", body="sankey\n\{row}\n"),
          ),
        )
      }
    }
  }
  inspect(
    shown.join("\n"),
    content=(
      #|Parse error on line 7:
      #|a#65534;,b,1
      #|^
      #|Invalid XML character in node name
      #|Parse error on line 7:
      #|b,"a#65534;",1
      #|--^
      #|Invalid XML character in node name
      #|Parse error on line 7:
      #|a#65535;,b,1
      #|^
      #|Invalid XML character in node name
      #|Parse error on line 7:
      #|b,"a#65535;",1
      #|--^
      #|Invalid XML character in node name
      #|Parse error on line 7:
      #|a#1;,b,1
      #|^
      #|Invalid XML character in node name
      #|Parse error on line 7:
      #|b,"a#1;",1
      #|--^
      #|Invalid XML character in node name
      #|Parse error on line 7:
      #|a#65534;,b,1
      #|^
      #|Invalid XML character in node name
      #|Parse error on line 7:
      #|b,"a#65534;",1
      #|--^
      #|Invalid XML character in node name
      #|Parse error on line 7:
      #|a#65535;,b,1
      #|^
      #|Invalid XML character in node name
      #|Parse error on line 7:
      #|b,"a#65535;",1
      #|--^
      #|Invalid XML character in node name
      #|Parse error on line 7:
      #|a#1;,b,1
      #|^
      #|Invalid XML character in node name
      #|Parse error on line 7:
      #|b,"a#1;",1
      #|--^
      #|Invalid XML character in node name
    ),
  )
}

///|
test "an error after blank lines reports its line in the source as written" {
  let failure = try {
    render("sankey\n\na,b,1\n\nb,c,abc") |> ignore
    None
  } catch {
    @errors.PeleError(failure) => Some(failure)
  }
  guard failure is Some(failure) else { fail("accepted") }
  inspect("\{failure.line}:\{failure.column}", content="5:5")
  assert_true(failure.message.has_prefix("Parse error on line 5:\nb,c,abc\n"))
}
