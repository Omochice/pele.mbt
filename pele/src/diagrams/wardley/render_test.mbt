///|
const TEA : String = "wardley-beta\ntitle Tea Shop\nanchor Business [0.95, 0.63]\ncomponent Cup of Tea [0.79, 0.61]\ncomponent Tea [0.63, 0.81]\ncomponent Kettle [0.43, 0.35]\ncomponent Power [0.10, 0.70]\nBusiness -> Cup of Tea\nCup of Tea -> Tea\nCup of Tea -> Kettle\nKettle -> Power\nevolve Kettle 0.62\nevolve Power 0.89\nnote \"Standardising power\" [0.30, 0.49]\n"

///|
fn drawn(
  source : String,
  max_width? : Double,
) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), max_width, }
  Ok(@core.render([@wardley.wardley], source, options)) catch {
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
fn sized(source : String, max_width? : Double) -> String {
  match drawn(source, max_width?) {
    Ok(result) => "\{result.width}x\{result.height} \{result.svg}"
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
/// The text from right after `prefix` to the next `stop`.
fn value_after(
  text : String,
  prefix : String,
  from~ : Int32 = 0,
  stop~ : String = "\"",
) -> String {
  let start = @util.index_of(text, prefix, from~) + prefix.length()
  @util.slice(text, start, end=@util.index_of(text, stop, from=start))
}

///|
/// The center of the circle that starts the node with id `id`.
fn circle_at(source : String, id : String) -> (String, String) {
  let out = svg(source)
  let at = @util.index_of(out, "data-id=\"\{id}\"><circle cx=\"")
  (value_after(out, " cx=\"", from=at), value_after(out, " cy=\"", from=at))
}

///|
test "draws axes, stages, components, links, evolution, and notes" {
  let out = svg(TEA)
  assert_true(out.contains("class=\"pele-wardley-axis\""))
  assert_eq(count(out, "class=\"pele-wardley-stage\""), 3)
  for
    stage in [
      "Genesis", "Custom Built", "Product", "Commodity", "Evolution", "Visibility",
    ] {
    assert_true(out.contains(">\{stage}<"), msg=stage)
  }
  assert_eq(count(out, "class=\"pele-node pele-wardley-component\""), 4)
  assert_eq(count(out, "class=\"pele-node pele-wardley-anchor\""), 1)
  assert_eq(count(out, "class=\"pele-edge\""), 4)
  assert_eq(count(out, "class=\"pele-wardley-trend\""), 2)
  assert_true(out.contains("class=\"pele-wardley-note\""))
  assert_true(out.contains(">Tea Shop<"))
  assert_true(out.contains("data-id=\"Cup of Tea\""))
  assert_false(out.contains("NaN"))
  match drawn(TEA) {
    Ok(result) => assert_eq(result.kind, "wardley")
    Err(failure) => fail(failure.message)
  }
}

///|
test "places components by evolution across and visibility up" {
  let src = "wardley-beta\ncomponent Low [0.1, 0.2]\ncomponent High [0.9, 0.8]\ncomponent Percent [90.0, 80.0]\n"
  let (low_x, low_y) = circle_at(src, "Low")
  let (high_x, high_y) = circle_at(src, "High")
  assert_true(@util.to_number(high_x) > @util.to_number(low_x))
  assert_true(@util.to_number(high_y) < @util.to_number(low_y))
  assert_eq(circle_at(src, "Percent"), (high_x, high_y))
}

///|
test "exposes the model in percentages" {
  let m = @wardley.build_wardley(@wardley.parse_wardley(TEA), None)
  let kettle = m.nodes
    .search_by(n => n.id == "Kettle")
    .map(i => m.nodes[i])
    .unwrap()
  assert_eq((kettle.x, kettle.y, kettle.class_name), (35, 43, "component"))
  assert_eq((m.nodes[0].id, m.nodes[0].class_name), ("Business", "anchor"))
  assert_eq(m.links.length(), 4)
  assert_eq(m.trends.map(t => (t.node_id, t.target_x, t.target_y)), [
    ("Kettle", 62, 43),
    ("Power", 89, 10),
  ])
}

///|
test "draws custom stages, dual labels, and stage widths" {
  let out = svg(
    "wardley-beta\nevolution Genesis@0.3 / Concept -> Custom@0.5 -> Product@0.9 -> Utility@1.0\ncomponent A [0.5, 0.5]\n",
  )
  assert_true(out.contains("Genesis / Concept"))
  assert_true(out.contains(">Utility<"))
  let xs = []
  let prefix = "class=\"pele-wardley-stage\" d=\"M"
  let mut at = @util.index_of(out, prefix)
  while at != -1 {
    xs.push(@util.to_number(value_after(out, prefix, from=at, stop=",")))
    at = @util.index_of(out, prefix, from=at + 1)
  }
  assert_eq(xs.length(), 3)
  assert_true((xs[0] / xs[1] - 0.6).abs() < 0.000005)
}

///|
test "draws sourcing strategies and inertia" {
  let out = svg(
    "wardley-beta\ncomponent A [0.9, 0.1] (build)\ncomponent B [0.7, 0.4] (buy) inertia\ncomponent C [0.5, 0.7] (outsource)\ncomponent D [0.3, 0.9] (market) (inertia)\n",
  )
  for strategy in ["build", "buy", "outsource", "market"] {
    assert_true(
      out.contains("class=\"pele-wardley-\{strategy}\""),
      msg=strategy,
    )
  }
  assert_eq(count(out, "class=\"pele-wardley-inertia\""), 2)
}

///|
test "draws flows, dashed links, and link labels" {
  let out = svg(
    "wardley-beta\ncomponent A [0.9, 0.1]\ncomponent B [0.5, 0.5]\ncomponent C [0.1, 0.9]\nA +> B\nB +< C\nA +<> C\nA -.-> B; note here\nB +'cash'> C\nA -> Missing\nA -> A\n",
  )
  assert_eq(
    count(out, "class=\"pele-edge\"") + count(out, "class=\"pele-edge "),
    5,
  )
  assert_eq(count(out, "class=\"pele-marker\""), 5)
  assert_eq(count(out, "class=\"pele-edge pele-wardley-dashed\""), 1)
  assert_true(out.contains(">note here</text>"))
  assert_true(out.contains(">cash</text>"))
}

///|
test "draws pipelines around their components and moves the parent onto the box" {
  let out = svg(
    "wardley-beta\ncomponent Kettle [0.45, 0.57]\ncomponent Water [0.8, 0.8]\npipeline Kettle {\n  component Campfire Kettle [0.35]\n  component Electric Kettle [0.53]\n}\nWater -> Electric Kettle\nCampfire Kettle -> Kettle\n",
  )
  assert_eq(count(out, "class=\"pele-wardley-pipeline\""), 1)
  assert_eq(
    count(out, "class=\"pele-node pele-wardley-pipeline-component\""),
    2,
  )
  assert_eq(count(out, "class=\"pele-node pele-wardley-pipeline-parent\""), 1)
  assert_true(out.contains("data-id=\"Water-Kettle_Electric Kettle\""))
  assert_eq(count(out, "class=\"pele-edge\""), 1)
}

///|
test "draws annotations, listing their texts in the box or under the map" {
  let body = "annotation 2,[0.5, 0.5] \"Second\"\nannotation 1,[0.6, 0.65] \"First\"\n"
  let boxed = drawn("wardley-beta\nannotations [0.9, 0.1]\n" + body).unwrap()
  let below = drawn("wardley-beta\n" + body).unwrap()
  assert_eq(count(boxed.svg, "class=\"pele-wardley-annotation\""), 2)
  assert_true(
    @util.index_of(boxed.svg, "1. First") <
    @util.index_of(boxed.svg, "2. Second"),
  )
  assert_true(below.svg.contains("2. Second"))
  assert_true(below.height > boxed.height)
}

///|
test "moves a label out of the way of a link that leaves up and to the right" {
  let label_x = (src : String) => {
    let out = svg(src)
    let text = @util.index_of(
      out,
      "<text",
      from=@util.index_of(out, "data-id=\"A\">"),
    )
    @util.to_number(value_after(out, "<tspan x=\"", from=text))
  }
  let alone = label_x(
    "wardley-beta\ncomponent A [0.5, 0.5]\ncomponent B [0.2, 0.2]\nA -> B\n",
  )
  let blocked = label_x(
    "wardley-beta\ncomponent A [0.5, 0.5]\ncomponent B [0.8, 0.8]\ncomponent C [0.2, 0.8]\nA -> B\nA -> C\n",
  )
  let moved = label_x(
    "wardley-beta\ncomponent A [0.5, 0.5] label [30, 30]\ncomponent B [0.8, 0.8]\nA -> B\n",
  )
  assert_true(blocked < alone)
  assert_eq(moved, alone + 22)
}

///|
test "draws accelerators and deaccelerators" {
  let out = svg(
    "wardley-beta\naccelerator \"AI Adoption\" [0.55, 0.25]\ndeaccelerator Legacy [0.15, 0.75]\n",
  )
  assert_true(
    out.contains("class=\"pele-wardley-accelerator\" data-id=\"AI Adoption\""),
  )
  assert_true(
    out.contains("class=\"pele-wardley-deaccelerator\" data-id=\"Legacy\""),
  )
}

///|
test "honours size, label offsets, and the grid option, and keeps labels inside the picture" {
  let base = drawn("wardley-beta\ncomponent A [0.5, 0.5]\n").unwrap()
  let sized_map = drawn(
    "wardley-beta\nsize [1100, 800]\ncomponent A [0.5, 0.5]\n",
  ).unwrap()
  assert_eq(sized_map.width - base.width, 200)
  assert_eq(sized_map.height - base.height, 200)
  let edge = drawn(
    "wardley-beta\ncomponent A long label at the right edge [0.5, 1.0]\n",
  ).unwrap()
  assert_true(edge.width > base.width + 100)
  let moved = svg("wardley-beta\ncomponent A [0.5, 0.5] label [-40, 30]\n")
  assert_true(moved != base.svg)
  assert_true(
    svg(
      "---\nconfig:\n  wardley-beta:\n    showGrid: true\n---\nwardley-beta\ncomponent A [0.5, 0.5]\n",
    ).contains("pele-wardley-grid"),
  )
  assert_false(base.svg.contains("pele-wardley-grid"))
}

///|
test "draws titles and accessible names" {
  let out = svg(
    "---\ntitle: Front\n---\nwardley-beta\naccTitle: Acc\naccDescr: Described\n",
  )
  assert_true(out.contains(">Front<"))
  assert_true(out.contains("<title id=\"pele-title\">Acc</title>"))
  assert_true(out.contains("<desc id=\"pele-desc\">Described</desc>"))
  assert_true(
    svg("---\ntitle: Front\n---\nwardley-beta\ntitle Own\n").contains(">Own<"),
  )
}

///|
test "rejects what Mermaid rejects, with Mermaid's messages" {
  assert_eq(
    svg("wardley-beta\ncomponent A [150.5, 0.5]\n"),
    "Component \"A\" visibility must be between 0-1 (decimal) or 0-100 (percentage). Received: 150.5",
  )
  assert_eq(
    svg("wardley-beta\npipeline Nope {\n component A [0.5]\n}\n"),
    "Pipeline \"Nope\" must reference an existing component with coordinates.",
  )
  for
    src in [
      "wardley-beta\ncomponent market [0.1, 0.2]", "wardley-beta\ncomponent A [1, 2]",
      "wardley-beta\nA B", "wardley-beta\nnote text [0.1, 0.2]",
    ] {
    assert_true(drawn(src) is Err(_), msg=src)
  }
}

///|
test "the tea shop map is drawn as pele draws it, at its natural width and narrowed" {
  assert_eq(
    sized(TEA),
    "846x610 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-wardley\" viewBox=\"0 0 846 610\" width=\"846\" height=\"610\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_tw:var(--pele-title-weight,bold);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"wardley\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"436\" y=\"25.6\">Tea Shop</tspan></text><g transform=\"translate(34,44)\"><g class=\"pele-wardley-frame\" fill=\"none\"><path class=\"pele-wardley-stage\" d=\"M201,0V504\" stroke=\"var(--_b)\" stroke-dasharray=\"4 4\"/><path class=\"pele-wardley-stage\" d=\"M402,0V504\" stroke=\"var(--_b)\" stroke-dasharray=\"4 4\"/><path class=\"pele-wardley-stage\" d=\"M603,0V504\" stroke=\"var(--_b)\" stroke-dasharray=\"4 4\"/><path class=\"pele-wardley-axis\" d=\"M0,0V504H804\" stroke=\"var(--_l)\"/></g><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" x=\"100.5\" y=\"526.55\" text-anchor=\"middle\">Genesis</text><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" x=\"301.5\" y=\"526.55\" text-anchor=\"middle\">Custom Built</text><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" x=\"502.5\" y=\"526.55\" text-anchor=\"middle\">Product</text><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" x=\"703.5\" y=\"526.55\" text-anchor=\"middle\">Commodity</text><text class=\"pele-wardley-axis-label\" font-size=\"13\" font-weight=\"var(--_hw)\" x=\"402\" y=\"552.55\" text-anchor=\"middle\">Evolution</text><text class=\"pele-wardley-axis-label\" font-size=\"13\" font-weight=\"var(--_hw)\" transform=\"rotate(-90 -16 252)\" x=\"-16\" y=\"256.55\" text-anchor=\"middle\">Visibility</text><g class=\"pele-edges\" fill=\"none\"><g class=\"pele-edge\" data-id=\"Business-Cup of Tea\"><path d=\"M504.45,35.58L491.61,99.96\" stroke=\"var(--_l)\"/></g><g class=\"pele-edge\" data-id=\"Cup of Tea-Tea\"><path d=\"M495.8,108.53L645.88,183.79\" stroke=\"var(--_l)\"/></g><g class=\"pele-edge\" data-id=\"Cup of Tea-Kettle\"><path d=\"M485.91,109.77L285.93,283.35\" stroke=\"var(--_l)\"/></g><g class=\"pele-edge\" data-id=\"Kettle-Power\"><path d=\"M286.57,290.33L557.63,450.55\" stroke=\"var(--_l)\"/></g></g><g class=\"pele-wardley-trends\" fill=\"none\"><g class=\"pele-wardley-trend\" data-id=\"Kettle\"><path d=\"M287.4,287.28L483.48,287.28\" stroke=\"var(--_c)\" stroke-dasharray=\"4 4\"/><path class=\"pele-marker\" d=\"M490.48,287.28L482.48,290.64L482.48,283.92Z\" fill=\"var(--_c)\" stroke=\"none\"/><circle cx=\"498.48\" cy=\"287.28\" r=\"6\" fill=\"var(--_bg)\" stroke=\"var(--_c)\"/></g><g class=\"pele-wardley-trend\" data-id=\"Power\"><path d=\"M568.8,453.6L700.56,453.6\" stroke=\"var(--_c)\" stroke-dasharray=\"4 4\"/><path class=\"pele-marker\" d=\"M707.56,453.6L699.56,456.96L699.56,450.24Z\" fill=\"var(--_c)\" stroke=\"none\"/><circle cx=\"715.56\" cy=\"453.6\" r=\"6\" fill=\"var(--_bg)\" stroke=\"var(--_c)\"/></g></g><g class=\"pele-node pele-wardley-anchor\" data-id=\"Business\"><text class=\"pele-label\" font-size=\"13\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"506.52\" y=\"26.75\">Business</tspan></text></g><g class=\"pele-node pele-wardley-component\" data-id=\"Cup of Tea\"><circle cx=\"490.44\" cy=\"105.84\" r=\"6\" fill=\"var(--_bg)\" stroke=\"var(--_l)\"/><text class=\"pele-label\" font-size=\"13\" xml:space=\"preserve\"><tspan x=\"498.44\" y=\"97.84\">Cup of Tea</tspan></text></g><g class=\"pele-node pele-wardley-component\" data-id=\"Tea\"><circle cx=\"651.24\" cy=\"186.48\" r=\"6\" fill=\"var(--_bg)\" stroke=\"var(--_l)\"/><text class=\"pele-label\" font-size=\"13\" xml:space=\"preserve\"><tspan x=\"659.24\" y=\"178.48\">Tea</tspan></text></g><g class=\"pele-node pele-wardley-component\" data-id=\"Kettle\"><circle cx=\"281.4\" cy=\"287.28\" r=\"6\" fill=\"var(--_bg)\" stroke=\"var(--_l)\"/><text class=\"pele-label\" font-size=\"13\" xml:space=\"preserve\"><tspan x=\"240.16\" y=\"279.28\">Kettle</tspan></text></g><g class=\"pele-node pele-wardley-component\" data-id=\"Power\"><circle cx=\"562.8\" cy=\"453.6\" r=\"6\" fill=\"var(--_bg)\" stroke=\"var(--_l)\"/><text class=\"pele-label\" font-size=\"13\" xml:space=\"preserve\"><tspan x=\"570.8\" y=\"445.6\">Power</tspan></text></g><text class=\"pele-wardley-note\" font-size=\"13\" font-weight=\"var(--_hw)\" xml:space=\"preserve\"><tspan x=\"393.96\" y=\"352.8\">Standardising power</tspan></text></g></svg>",
  )
  assert_eq(
    sized(TEA, max_width=400),
    "400x484 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-wardley\" viewBox=\"0 0 400 484\" width=\"400\" height=\"484\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_tw:var(--pele-title-weight,bold);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"wardley\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"213\" y=\"25.6\">Tea Shop</tspan></text><g transform=\"translate(34,44)\"><g class=\"pele-wardley-frame\" fill=\"none\"><path class=\"pele-wardley-stage\" d=\"M89.5,0V378\" stroke=\"var(--_b)\" stroke-dasharray=\"4 4\"/><path class=\"pele-wardley-stage\" d=\"M179,0V378\" stroke=\"var(--_b)\" stroke-dasharray=\"4 4\"/><path class=\"pele-wardley-stage\" d=\"M268.5,0V378\" stroke=\"var(--_b)\" stroke-dasharray=\"4 4\"/><path class=\"pele-wardley-axis\" d=\"M0,0V378H358\" stroke=\"var(--_l)\"/></g><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" x=\"44.75\" y=\"400.55\" text-anchor=\"middle\">Genesis</text><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" x=\"134.25\" y=\"400.55\" text-anchor=\"middle\">Custom Built</text><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" x=\"223.75\" y=\"400.55\" text-anchor=\"middle\">Product</text><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" x=\"313.25\" y=\"400.55\" text-anchor=\"middle\">Commodity</text><text class=\"pele-wardley-axis-label\" font-size=\"13\" font-weight=\"var(--_hw)\" x=\"179\" y=\"426.55\" text-anchor=\"middle\">Evolution</text><text class=\"pele-wardley-axis-label\" font-size=\"13\" font-weight=\"var(--_hw)\" transform=\"rotate(-90 -16 189)\" x=\"-16\" y=\"193.55\" text-anchor=\"middle\">Visibility</text><g class=\"pele-edges\" fill=\"none\"><g class=\"pele-edge\" data-id=\"Business-Cup of Tea\"><path d=\"M224.31,29.29L219.09,73.42\" stroke=\"var(--_l)\"/></g><g class=\"pele-edge\" data-id=\"Cup of Tea-Tea\"><path d=\"M222.96,83.25L285.4,135.99\" stroke=\"var(--_l)\"/></g><g class=\"pele-edge\" data-id=\"Cup of Tea-Kettle\"><path d=\"M214.99,84.33L128.69,210.51\" stroke=\"var(--_l)\"/></g><g class=\"pele-edge\" data-id=\"Kettle-Power\"><path d=\"M129.55,219.69L246.35,335.97\" stroke=\"var(--_l)\"/></g></g><g class=\"pele-wardley-trends\" fill=\"none\"><g class=\"pele-wardley-trend\" data-id=\"Kettle\"><path d=\"M131.3,215.46L206.96,215.46\" stroke=\"var(--_c)\" stroke-dasharray=\"4 4\"/><path class=\"pele-marker\" d=\"M213.96,215.46L205.96,218.82L205.96,212.1Z\" fill=\"var(--_c)\" stroke=\"none\"/><circle cx=\"221.96\" cy=\"215.46\" r=\"6\" fill=\"var(--_bg)\" stroke=\"var(--_c)\"/></g><g class=\"pele-wardley-trend\" data-id=\"Power\"><path d=\"M256.6,340.2L303.62,340.2\" stroke=\"var(--_c)\" stroke-dasharray=\"4 4\"/><path class=\"pele-marker\" d=\"M310.62,340.2L302.62,343.56L302.62,336.84Z\" fill=\"var(--_c)\" stroke=\"none\"/><circle cx=\"318.62\" cy=\"340.2\" r=\"6\" fill=\"var(--_bg)\" stroke=\"var(--_c)\"/></g></g><g class=\"pele-node pele-wardley-anchor\" data-id=\"Business\"><text class=\"pele-label\" font-size=\"13\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"225.54\" y=\"20.45\">Business</tspan></text></g><g class=\"pele-node pele-wardley-component\" data-id=\"Cup of Tea\"><circle cx=\"218.38\" cy=\"79.38\" r=\"6\" fill=\"var(--_bg)\" stroke=\"var(--_l)\"/><text class=\"pele-label\" font-size=\"13\" xml:space=\"preserve\"><tspan x=\"226.38\" y=\"71.38\">Cup of Tea</tspan></text></g><g class=\"pele-node pele-wardley-component\" data-id=\"Tea\"><circle cx=\"289.98\" cy=\"139.86\" r=\"6\" fill=\"var(--_bg)\" stroke=\"var(--_l)\"/><text class=\"pele-label\" font-size=\"13\" xml:space=\"preserve\"><tspan x=\"297.98\" y=\"131.86\">Tea</tspan></text></g><g class=\"pele-node pele-wardley-component\" data-id=\"Kettle\"><circle cx=\"125.3\" cy=\"215.46\" r=\"6\" fill=\"var(--_bg)\" stroke=\"var(--_l)\"/><text class=\"pele-label\" font-size=\"13\" xml:space=\"preserve\"><tspan x=\"84.06\" y=\"207.46\">Kettle</tspan></text></g><g class=\"pele-node pele-wardley-component\" data-id=\"Power\"><circle cx=\"250.6\" cy=\"340.2\" r=\"6\" fill=\"var(--_bg)\" stroke=\"var(--_l)\"/><text class=\"pele-label\" font-size=\"13\" xml:space=\"preserve\"><tspan x=\"258.6\" y=\"332.2\">Power</tspan></text></g><text class=\"pele-wardley-note\" font-size=\"13\" font-weight=\"var(--_hw)\" xml:space=\"preserve\"><tspan x=\"175.42\" y=\"264.6\">Standardising power</tspan></text></g></svg>",
  )
}
