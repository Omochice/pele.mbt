///|
fn render_svg(source : String) -> String {
  let result = @core.render(
    [@venn.venn],
    source,
    @types.RenderOptions::default(),
  ) catch {
    @errors.PeleError(failure) => return "error: " + failure.message
  }
  result.svg
}

///|
fn count(text : String, needle : String) -> Int32 {
  let mut found = 0
  let mut at = @util.index_of(text, needle)
  while at != -1 {
    found += 1
    at = @util.index_of(text, needle, from=at + needle.length())
  }
  found
}

///|
fn svg_of(body : String) -> String {
  render_svg("venn-beta\n" + body)
}

///|
test "the diagram is typed venn and the viewBox matches its size" {
  let result = @core.render(
    [@venn.venn],
    "venn-beta\n  set A\n  set B\n  union A,B",
    @types.RenderOptions::default(),
  )
  inspect(result.kind, content="venn")
  assert_true(
    result.svg.has_prefix(
      "<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-venn\"",
    ),
  )
  assert_true(
    result.svg.contains("viewBox=\"0 0 \{result.width} \{result.height}\""),
  )
}

///|
test "each set gets the next series color" {
  let svg = svg_of("set A\nset B\nset C")
  assert_true(svg.contains("data-id=\"A\" cx"))
  for k in 1..<=3 {
    inspect(count(svg, "fill=\"var(--pele-series-\{k},"), content="1")
  }
}

///|
test "a set is a circle with its name in the middle" {
  let svg = svg_of("set Only")
  inspect(count(svg, "<circle class=\"pele-venn-set\""), content="1")
  assert_true(
    svg.contains(
      "fill=\"var(--pele-series-1,#4c78a8)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-1,#4c78a8)\"",
    ),
  )
  assert_true(svg.contains("<g class=\"pele-venn-region\" data-id=\"Only\">"))
}

///|
test "styles apply to a set, an overlap and a text" {
  let svg = svg_of(
    "set A\n  text A1[\"React\"]\nset B\nunion A,B[\"AB\"]\nstyle A fill:#ff6b6b, stroke-width:3\nstyle A,B color:#333\nstyle A1 color:red\nstyle B fill-opacity:0.5\nstyle A stroke:black",
  )
  assert_true(
    svg.contains(
      "data-id=\"A\" cx=\"108\" cy=\"108\" r=\"100\" fill=\"var(--pele-series-1,#4c78a8)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-1,#4c78a8)\" style=\"fill:#ff6b6b;stroke-width:3;stroke:black;\"/>",
    ),
  )
  assert_true(svg.contains("style=\"fill-opacity:0.5;\"/>"))
  assert_true(
    svg.contains(
      "<text class=\"pele-label\" font-size=\"14\" style=\"fill:#333;\"",
    ),
  )
  assert_true(
    svg.contains(
      "data-id=\"A1\" font-size=\"13\" fill=\"var(--_m)\" style=\"fill:red;\"",
    ),
  )
  assert_false(svg.contains("pele-venn-overlap"))
}

///|
test "an overlap given a fill is drawn as the shape the circles share" {
  let svg = svg_of(
    "set A\nset B\nset C\nunion A,B[\"ab\"]\nunion A,B,C[\"abc\"]\nstyle A,B fill:gold\nstyle A,B,C fill:#333",
  )
  inspect(count(svg, "<path class=\"pele-venn-overlap\""), content="2")
  assert_true(svg.contains("data-id=\"A|B\""))
  assert_true(svg.contains("data-id=\"A|B|C\""))
  assert_true(svg.contains(" fill=\"none\" style=\"fill:gold;\"/>"))
}

///|
test "titles lose their quotes and the diagram's own wins" {
  assert_true(
    render_svg("venn-beta\ntitle \"Team overlap\"\nset A").contains(
      ">Team overlap</tspan>",
    ),
  )
  assert_true(
    render_svg("---\ntitle: From the front matter\n---\nvenn-beta\nset A").contains(
      ">From the front matter</tspan>",
    ),
  )
  let both = render_svg(
    "---\ntitle: Front\n---\nvenn-beta\ntitle Inside\nset A",
  )
  assert_true(both.contains(">Inside</tspan>"))
  assert_false(both.contains("Front"))
}

///|
test "the last statement about a set wins" {
  let svg = svg_of("set A[\"first\"]:10\nset B:10\nset A[\"second\"]:40")
  inspect(count(svg, "<circle"), content="2")
  assert_true(svg.contains(">second</text>"))
  assert_false(svg.contains(">first</text>"))
}

///|
test "a text whose sets were never stated together is left out" {
  let svg = svg_of("set A\nset B\ntext A,B orphan\ntext A kept")
  assert_false(svg.contains("orphan"))
  assert_true(svg.contains(">kept</text>"))
}

///|
test "texts are written under the label of their region" {
  let svg = svg_of(
    "set A[\"Frontend\"]\n  text A1[\"React\"]\n  text A2\nset B\nunion A,B[\"Shared\"]\n  text AB1[\"OpenAPI\"]",
  )
  assert_true(
    svg.contains(
      "<text class=\"pele-venn-text\" data-id=\"A1\" font-size=\"13\" fill=\"var(--_m)\"",
    ),
  )
  assert_true(svg.contains(">React</text>"))
  assert_true(svg.contains(">A2</text>"))
  assert_true(svg.contains(">OpenAPI</text>"))
}

///|
test "a label wider than its region is wrapped" {
  let svg = svg_of(
    "set A[\"A very long label for a set that goes on and on\"]\nset B\nunion A,B[\"An intersection with a long label\"]",
  )
  assert_true(count(svg, "<tspan") > 3)
}

///|
test "what is shown is escaped" {
  let svg = svg_of(
    "title <img src=x onerror=alert(1)>\nset \"<script>a&b</script>\"\n  text \"</text><script>alert(1)</script>\"\nset B[<svg onload=alert(1)>]\nstyle B fill:\"url(javascript:alert(1))\", stroke:\"red' onload='alert(1)\"",
  )
  assert_false(svg.contains("<img"))
  assert_false(svg.contains("<script"))
  assert_false(svg.contains("<svg onload"))
  assert_false(svg.contains("javascript:"))
  assert_true(svg.contains("data-id=\"&lt;script&gt;a&amp;b&lt;/script&gt;\""))
  assert_true(
    svg.contains("&lt;/text&gt;&lt;script&gt;alert(1)&lt;/script&gt;"),
  )
}

///|
test "no sets leave only the frame" {
  let svg = render_svg("venn-beta\n")
  assert_true(svg.contains("<g class=\"pele-venn-sets\"></g>"))
}

///|
test "sizes that make no sense give finite output" {
  let nines = "9".repeat(400)
  let zeros = "0".repeat(300)
  let svg = svg_of(
    "set A:0\nset B:-1000000000\nset C:\{nines}\nset D:.\{zeros}1\nunion A,B:\{nines}\nunion C,D:-5\nunion A,B,C,D[\"x\"]:0\n",
  )
  assert_false(svg.contains("NaN"))
  assert_false(svg.contains("Infinity"))
  assert_false(svg.contains("undefined"))
}

///|
test "what Mermaid rejects is rejected with its message" {
  inspect(
    render_svg("venn-beta\nunion A"),
    content="error: union requires multiple identifiers",
  )
  inspect(
    render_svg("venn-beta\nset A\nunion A,B"),
    content="error: unknown set identifier: B",
  )
  inspect(
    render_svg("venn-beta\nset A\nunion A,\"B#35;x\""),
    content="error: unknown set identifier: B#x",
  )
  inspect(
    render_svg("venn-beta\nset \"B#x\"\nset A\nunion A,\"B#35;x\""),
    content="error: unknown set identifier: B#x",
  )
  inspect(
    render_svg("venn-beta\nset A,B"),
    content="error: Parse error on line 2:\nset A,B\n-----^\nExpecting 'EOF', 'NEWLINE', 'TITLE', 'SET', 'UNION', 'TEXT', 'INDENT_TEXT', 'STYLE', got 'COMMA'",
  )
  inspect(
    render_svg("venn-beta\nset A $"),
    content="error: Lexical error on line 2. Unrecognized text.\nset A $\n------^",
  )
}
