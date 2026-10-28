///|
/// The third of Mermaid's documentation examples in pele's corpus: a long flow across three lanes with labelled handoffs.
let support_flow : String =
  #|swimlane-beta LR
  #|  subgraph Customer
  #|    request[Request service]
  #|    receive[Receive update]
  #|  end
  #|
  #|  subgraph Support
  #|    triage[Triage request]
  #|    answer[Send answer]
  #|  end
  #|
  #|  subgraph Engineering
  #|    investigate[Investigate issue]
  #|    fix[Prepare fix]
  #|  end
  #|
  #|  request --> triage
  #|  triage -->|Known issue| answer
  #|  triage -->|Needs code change| investigate
  #|  investigate --> fix --> answer
  #|  answer --> receive
  #|

///|
/// The tenth of Mermaid's documentation examples in pele's corpus: an approval decision with a branch back to the applicant.
let approval_flow : String =
  #|swimlane-beta LR
  #|  subgraph Applicant
  #|    apply[Submit application]
  #|    sign[Sign agreement]
  #|  end
  #|
  #|  subgraph Reviewer
  #|    screen[Screen application]
  #|    decide{Approved?}
  #|  end
  #|
  #|  subgraph System
  #|    create[Create account]
  #|    notify[Send welcome email]
  #|  end
  #|
  #|  apply -->|Application received| screen
  #|  screen --> decide
  #|  decide -->|Approved| create --> notify --> sign
  #|  decide -->|Needs changes| apply
  #|

///|
fn options(
  max_width? : Double,
  auto_direction? : Bool,
  direction_breakpoint? : Double,
  responsive? : Bool,
) -> @types.RenderOptions {
  {
    ..@types.RenderOptions::default(),
    max_width,
    auto_direction,
    direction_breakpoint,
    responsive,
  }
}

///|
fn drawn(
  source : String,
  options~ : @types.RenderOptions = @types.RenderOptions::default(),
) -> @types.RenderResult raise {
  @core.render([@swimlane.swimlane], source, options)
}

///|
fn svg_of(
  source : String,
  options~ : @types.RenderOptions = @types.RenderOptions::default(),
) -> String raise {
  drawn(source, options~).svg
}

///|
fn count(text : String, needle : String) -> Int32 {
  let mut n = 0
  let mut at = @util.index_of(text, needle)
  while at >= 0 {
    n += 1
    at = @util.index_of(text, needle, from=at + needle.length())
  }
  n
}

///|
/// The text of the attribute `name` that comes first after `from`, and where it ends.
fn attribute(svg : String, name : String, from : Int32) -> (String, Int32) {
  let start = @util.index_of(svg, " \{name}=\"", from~) + name.length() + 3
  let end = @util.index_of(svg, "\"", from=start)
  (@util.slice(svg, start, end~), end)
}

///|
priv struct Box {
  x : Double
  y : Double
  w : Double
  h : Double
}

///|
/// The outline of each lane, read back from the SVG in the order drawn.
fn lanes(svg : String) -> Array[(String, Box)] {
  let out = []
  let mut at = @util.index_of(svg, "<g class=\"pele-cluster pele-lane")
  while at >= 0 {
    let (id, after) = attribute(svg, "data-id", at)
    let (x, after) = attribute(svg, "x", after)
    let (y, after) = attribute(svg, "y", after)
    let (w, after) = attribute(svg, "width", after)
    let (h, _) = attribute(svg, "height", after)
    out.push(
      (
        id,
        {
          x: @util.parse_float(x),
          y: @util.parse_float(y),
          w: @util.parse_float(w),
          h: @util.parse_float(h),
        },
      ),
    )
    at = @util.index_of(svg, "<g class=\"pele-cluster pele-lane", from=at + 1)
  }
  out
}

///|
fn lane(svg : String, id : String) -> Box {
  for entry in lanes(svg) {
    if entry.0 == id {
      return entry.1
    }
  }
  abort("no lane \{id}")
}

///|
/// The center of each node, read back from the SVG in the order drawn.
fn centers(svg : String) -> Array[(String, Double, Double)] {
  let out = []
  let mut at = @util.index_of(svg, "<g class=\"pele-node")
  while at >= 0 {
    let (id, after) = attribute(svg, "data-id", at)
    let (transform, _) = attribute(svg, "transform", after)
    let comma = @util.index_of(transform, ",")
    let x = @util.slice(transform, 10, end=comma)
    let y = @util.slice(transform, comma + 1, end=transform.length() - 1)
    out.push((id, @util.parse_float(x), @util.parse_float(y)))
    at = @util.index_of(svg, "<g class=\"pele-node", from=at + 1)
  }
  out
}

///|
fn center(svg : String, id : String) -> (Double, Double) {
  for entry in centers(svg) {
    if entry.0 == id {
      return (entry.1, entry.2)
    }
  }
  abort("no node \{id}")
}

///|
fn inside(p : (Double, Double), b : Box) -> Bool {
  p.0 > b.x && p.0 < b.x + b.w && p.1 > b.y && p.1 < b.y + b.h
}

///|
/// The first point of the path drawn for an edge.
fn start_of(svg : String, id : String) -> (Double, Double) {
  let head = "data-id=\"\{id}\"><path d=\"M"
  let from = @util.index_of(svg, head) + head.length()
  let comma = @util.index_of(svg, ",", from~)
  let mut end = comma + 1
  while end < svg.length() {
    let c = @util.code_at(svg, end)
    if !(c == 45 || c == 46 || (c >= 48 && c <= 57)) {
      break
    }
    end += 1
  }
  (
    @util.parse_float(@util.slice(svg, from, end=comma)),
    @util.parse_float(@util.slice(svg, comma + 1, end~)),
  )
}

///|
/// The text of every text element, without markup or white space.
fn texts(svg : String) -> Array[String] {
  let out = []
  let mut at = @util.index_of(svg, "<text")
  while at >= 0 {
    let open = @util.index_of(svg, ">", from=at)
    let close = @util.index_of(svg, "</text>", from=open)
    let inner = @util.slice(svg, open + 1, end=close)
    let plain = StringBuilder()
    let mut in_tag = false
    for c in inner {
      if c == '<' {
        in_tag = true
      } else if c == '>' {
        in_tag = false
      } else if !in_tag && c != ' ' && c != '\n' && c != '\t' {
        plain.write_char(c)
      }
    }
    out.push(plain.to_string())
    at = @util.index_of(svg, "<text", from=close)
  }
  out
}

///|
test "draws one lane per top-level subgraph and keeps each node in its lane" {
  let svg = svg_of(order)
  assert_true(svg.contains("class=\"pele pele-swimlane\""))
  assert_true(svg.contains("aria-roledescription=\"swimlane\""))
  assert_eq(lanes(svg).map(entry => entry.0), ["Warehouse", "Customer"])
  assert_true(inside(center(svg, "browse"), lane(svg, "Customer")))
  assert_true(inside(center(svg, "pay"), lane(svg, "Customer")))
  assert_true(inside(center(svg, "pick"), lane(svg, "Warehouse")))
  assert_true(inside(center(svg, "ship"), lane(svg, "Warehouse")))
  assert_true(svg.contains(">paid<"))
}

///|
/// The opening tag of the first text drawn after `data-id="id"`.
fn text_tag_after(svg : String, id : String) -> String {
  let from = @util.index_of(
    svg,
    "<text",
    from=@util.index_of(svg, "data-id=\"\{id}\""),
  )
  @util.slice(svg, from, end=@util.index_of(svg, ">", from~) + 1)
}

///|
test "picks a contrasting lane title color on a fill a style sets" {
  let svg = svg_of(
    "swimlane-beta LR\n  subgraph L[Light]\n    a\n  end\n  subgraph D[Dark]\n    b\n  end\n  subgraph P[Plain]\n    c\n  end\n  style L fill:#BBDEFB\n  style D fill:#1f3a5f",
  )
  inspect(
    ["L", "D", "P", "a"].map(id => text_tag_after(svg, id)).join("\n"),
    content=(
      #|<text class="pele-cluster-label" fill="var(--pele-fg-on-light,#1f1f1f)" x="28" y="61.6" text-anchor="middle">
      #|<text class="pele-cluster-label" fill="var(--pele-fg-on-dark,#fff)" x="28" y="157.6" text-anchor="middle">
      #|<text class="pele-cluster-label" fill="var(--_m)" x="28" y="253.6" text-anchor="middle">
      #|<text class="pele-label" x="0" y="5.6" text-anchor="middle">
    ),
  )
}

///|
test "inks or cases edges on a lane band a style fills" {
  let source = "swimlane-beta TB\nsubgraph S[\"one<br/>two<br/>three<br/>four<br/>five<br/>six<br/>seven<br/>eight\"]\n  A\nend\nS --> S\nstyle S fill:black"
  let svg = svg_of(source)
  let at = @util.index_of(
    svg,
    "<g class=\"pele-edge",
    from=@util.index_of(svg, "<g class=\"pele-edges\"") + 1,
  )
  inspect(
    @util.slice(svg, at, end=@util.index_of(svg, ">", from=at) + 1),
    content=(
      #|<g class="pele-edge" data-id="L_S_S_0" stroke="var(--pele-fg-on-dark,#fff)">
    ),
  )
  let plain = svg_of(source.replace(old="\nstyle S fill:black", new=""))
  assert_false(plain.contains("pele-casings"))
  assert_false(plain.contains("--pele-fg-on"))
}

///|
test "stacks lanes down the page when the flow runs sideways, and across it otherwise" {
  let sideways = svg_of(order)
  assert_true(lane(sideways, "Customer").y < lane(sideways, "Warehouse").y)
  assert_eq(lane(sideways, "Customer").x, lane(sideways, "Warehouse").x)
  assert_true(sideways.contains("transform=\"rotate(-90 "))
  let down = svg_of(order.replace(old="LR", new="TD"))
  assert_true(lane(down, "Customer").x < lane(down, "Warehouse").x)
  assert_eq(lane(down, "Customer").y, lane(down, "Warehouse").y)
  assert_false(down.contains("rotate("))
}

///|
test "lines up steps of the same rank across lanes" {
  let svg = svg_of(
    "swimlane-beta TD\n  subgraph A\n    a1 --> a2\n  end\n  subgraph B\n    b1 --> b2\n  end\n  a1 --> b2",
  )
  assert_eq(center(svg, "a1").1, center(svg, "b1").1)
  assert_eq(center(svg, "a2").1, center(svg, "b2").1)
  assert_eq(center(svg, "a1").0, center(svg, "a2").0)
}

///|
test "turns long horizontal flows downward while retaining every lane, step and relation" {
  for source in [support_flow, approval_flow] {
    let wide = drawn(source)
    let narrow = drawn(source, options=options(max_width=480))
    assert_true(narrow.width <= 480)
    assert_true(narrow.height > wide.height)
    assert_false(narrow.svg.contains("rotate("))
    assert_true(narrow.svg.contains("font:16px"))
    let names = (svg : String) => lanes(svg).map(entry => entry.0)
    assert_eq(names(narrow.svg), names(wide.svg))
    let ids = (svg : String) => centers(svg).map(entry => entry.0)
    assert_eq(ids(narrow.svg), ids(wide.svg))
    let db = read(source)
    for group in db.subgraphs {
      for id in group.nodes {
        assert_true(inside(center(narrow.svg, id), lane(narrow.svg, group.id)))
      }
    }
    assert_eq(
      count(narrow.svg, "class=\"pele-edge\""),
      count(wide.svg, "class=\"pele-edge\""),
    )
    assert_eq(
      count(narrow.svg, "class=\"pele-marker\""),
      count(wide.svg, "class=\"pele-marker\""),
    )
    assert_eq(texts(narrow.svg), texts(wide.svg))
    assert_eq(svg_of(source, options=options(max_width=wide.width)), wide.svg)
  }
}

///|
test "honors autoDirection, the breakpoint and an already vertical direction" {
  let horizontal = svg_of(
    support_flow,
    options=options(max_width=480, auto_direction=false),
  )
  assert_true(horizontal.contains("rotate(-90 "))
  assert_eq(
    svg_of(
      support_flow,
      options=options(max_width=480, direction_breakpoint=480),
    ),
    horizontal,
  )
  assert_true(
    svg_of(support_flow, options=options(max_width=700)).contains("rotate(-90 "),
  )
  assert_false(
    svg_of(
      support_flow,
      options=options(max_width=700, direction_breakpoint=800),
    ).contains("rotate("),
  )
  assert_eq(
    svg_of(support_flow, options=options(max_width=480)),
    svg_of(
      support_flow.replace(old="LR", new="TB"),
      options=options(max_width=480),
    ),
  )
  assert_eq(
    svg_of(
      support_flow.replace(old="LR", new="RL"),
      options=options(max_width=480),
    ),
    svg_of(support_flow, options=options(max_width=480)),
  )
  let up = svg_of(
    order.replace(old="LR", new="BT"),
    options=options(max_width=160),
  )
  assert_true(center(up, "browse").1 > center(up, "pay").1)
}

///|
test "keeps a horizontal layout when turning would make it wider" {
  let source = StringBuilder()
  source.write_string("swimlane-beta LR\n")
  for i in 0..<5 {
    if i > 0 {
      source.write_string("\n")
    }
    source.write_string("subgraph L\{i}\n a\{i} --> b\{i}\nend")
  }
  let source = source.to_string()
  let turned = svg_of(source, options=options(max_width=160))
  assert_eq(
    turned,
    svg_of(source, options=options(max_width=160, auto_direction=false)),
  )
  assert_true(turned.contains("rotate(-90 "))
}

///|
test "draws the changes branch from a separate side of the approval decision" {
  let wide = svg_of(approval_flow)
  let (cx, cy) = center(wide, "decide")
  let accepted = start_of(wide, "L_decide_create_0")
  let returned = start_of(wide, "L_decide_apply_0")
  assert_eq(accepted.0, cx)
  assert_eq(returned.0, cx)
  assert_true(accepted.1 > cy)
  assert_true(returned.1 < cy)
  let narrow = svg_of(approval_flow, options=options(max_width=320))
  let (cx, cy) = center(narrow, "decide")
  let accepted = start_of(narrow, "L_decide_create_0")
  let returned = start_of(narrow, "L_decide_apply_0")
  assert_eq(accepted.1, cy)
  assert_eq(returned.1, cy)
  assert_true(accepted.0 > cx)
  assert_true(returned.0 < cx)
}

///|
test "retains nested groups, unnamed and empty lanes, styled nodes, links and self-loops after turning" {
  let source = "---\ntitle: Delivery\n---\nswimlane-beta LR\naccTitle: Accessible delivery\naccDescr: Delivery process\nstart --> a\nsubgraph Team\n subgraph Inner\n a{Ready?} --> b[(Store)]\n b --> b\n end\n c --> d --> e\nend\nsubgraph Empty\nend\nb --> c\nclick a \"https://example.com\"\nstyle a fill:#f00\nclassDef hot stroke:#0f0\nclass b hot"
  let wide = drawn(source)
  let narrow = drawn(source, options=options(max_width=320))
  assert_false(narrow.svg.contains("rotate("))
  assert_eq(lanes(narrow.svg).length(), 3)
  let head = "class=\"pele-cluster\" data-id=\"Inner\">"
  let at = @util.index_of(narrow.svg, head)
  assert_true(at >= 0)
  let (x, after) = attribute(narrow.svg, "x", at)
  let (y, after) = attribute(narrow.svg, "y", after)
  let (w, after) = attribute(narrow.svg, "width", after)
  let (h, _) = attribute(narrow.svg, "height", after)
  let inner = {
    x: @util.parse_float(x),
    y: @util.parse_float(y),
    w: @util.parse_float(w),
    h: @util.parse_float(h),
  }
  assert_true(inside(center(narrow.svg, "a"), inner))
  assert_true(inside(center(narrow.svg, "b"), inner))
  let links = (r : @types.RenderResult) => {
    r.links.map(l => "\{l.id}|\{l.href}|\{l.internal}")
  }
  assert_eq(links(narrow), links(wide))
  for
    value in [
      ">Delivery<", "<title id=\"pele-title\">Accessible delivery</title>", "Delivery process",
      "fill:#f00", "stroke:#0f0", "pele-shape-diam", "pele-shape-cyl",
    ] {
    assert_true(narrow.svg.contains(value), msg=value)
  }
  assert_eq(
    count(narrow.svg, "class=\"pele-edge\""),
    count(wide.svg, "class=\"pele-edge\""),
  )
}

///|
test "follows every direction" {
  let at = (dir : String, id : String) => {
    center(svg_of("swimlane-beta \{dir}\n  subgraph L\n    a --> b\n  end"), id)
  }
  assert_true(at("TB", "a").1 < at("TB", "b").1)
  assert_true(at("BT", "a").1 > at("BT", "b").1)
  assert_true(at("LR", "a").0 < at("LR", "b").0)
  assert_true(at("RL", "a").0 > at("RL", "b").0)
}

///|
test "gives nodes outside every lane a lane of their own" {
  let svg = svg_of(
    "swimlane-beta TD\n  start --> a\n  subgraph Team\n    a --> b\n  end",
  )
  let boxes = lanes(svg)
  assert_eq(boxes.length(), 2)
  let loose = boxes.filter(entry => entry.0 != "Team")[0].1
  assert_true(inside(center(svg, "start"), loose))
  assert_true(loose.x < lane(svg, "Team").x)
  assert_eq(lanes(svg_of("swimlane-beta TD\n  a --> b")).length(), 1)
}

///|
test "draws an empty lane and a group inside a lane" {
  let svg = svg_of(
    "swimlane-beta TD\n  subgraph One\n    subgraph Inner\n      a --> b\n    end\n    c\n  end\n  subgraph Two\n  end\n  b --> c",
  )
  assert_eq(lanes(svg).length(), 2)
  assert_eq(count(svg, "class=\"pele-cluster\""), 1)
  assert_true(svg.contains(">Inner<"))
}

///|
test "ignores a direction inside a lane" {
  let plain = svg_of("swimlane-beta TD\n  subgraph L\n    a --> b\n  end")
  let turned = svg_of(
    "swimlane-beta TD\n  subgraph L\n    direction LR\n    a --> b\n  end",
  )
  assert_eq(turned, plain)
}

///|
test "keeps flowchart features: shapes, styles, links, titles and accessible names" {
  let svg = svg_of(
    "---\ntitle: Orders\n---\nswimlane-beta LR\n  accTitle: Order flow\n  accDescr: Who does what\n  subgraph L[Lane **one**]\n    a{Choice} --> b[(Store)]\n    b --> b\n  end\n  click a \"https://example.com\" \"tip\"\n  style a fill:#f00\n  classDef hot stroke:#0f0\n  class b hot\n  style L fill:#00f",
  )
  for
    value in [
      "pele-shape-", ">Orders<", "<title id=\"pele-title\">Order flow</title>", "href=\"https://example.com/\"",
      "fill:#f00", "fill:#00f",
    ] {
    assert_true(svg.contains(value), msg=value)
  }
  let links = drawn("swimlane-beta LR\n  a\n  click a \"https://example.com\"").links.map(l => {
      "\{l.id}|\{l.href}|\{l.internal}"
    },
  )
  assert_eq(links, ["a|https://example.com/|false"])
}

///|
test "reads spacing from the swimlane config, then the flowchart config" {
  let source = "swimlane-beta TD\n  subgraph L\n    a --> b\n  end"
  let plain = drawn(source).height
  assert_true(
    drawn("---\nconfig:\n  swimlane:\n    rankSpacing: 200\n---\n\{source}").height >
    plain + 100,
  )
  assert_true(
    drawn("---\nconfig:\n  flowchart:\n    rankSpacing: 200\n---\n\{source}").height >
    plain + 100,
  )
}

///|
test "shrinks to its container unless told not to" {
  assert_true(svg_of(order).contains("max-width:100%;height:auto;"))
  assert_false(
    svg_of(order, options=options(responsive=false)).contains("max-width"),
  )
}

///|
test "is the same every time" {
  assert_eq(svg_of(order), svg_of(order))
}

///|
test "draws two lanes, their steps and a labelled handoff as pele does" {
  let result = drawn(order)
  assert_eq(result.width, 534)
  assert_eq(result.height, 224)
  inspect(
    result.svg,
    content="<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-swimlane\" viewBox=\"0 0 534 224\" width=\"534\" height=\"224\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"swimlane\"><g class=\"pele-clusters\"><g class=\"pele-cluster pele-lane\" data-id=\"Warehouse\"><rect x=\"8\" y=\"105.34\" width=\"517.83\" height=\"109.81\" fill=\"none\" stroke=\"var(--_b)\"/><rect x=\"8\" y=\"105.34\" width=\"40\" height=\"109.81\" fill=\"var(--_a)\" stroke=\"var(--_b)\"/><g transform=\"rotate(-90 28 160.25)\"><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"28\" y=\"165.85\" text-anchor=\"middle\">Warehouse</text></g></g><g class=\"pele-cluster pele-lane\" data-id=\"Customer\"><rect x=\"8\" y=\"8\" width=\"517.83\" height=\"97.34\" fill=\"none\" stroke=\"var(--_b)\"/><rect x=\"8\" y=\"8\" width=\"40\" height=\"97.34\" fill=\"var(--_a)\" stroke=\"var(--_b)\"/><g transform=\"rotate(-90 28 56.67)\"><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"28\" y=\"62.27\" text-anchor=\"middle\">Customer</text></g></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_browse_pay_0\"><path d=\"M161.34,56.67L202.34,56.67\"/><path class=\"pele-marker\" d=\"M209.34,56.67L201.34,60.03L201.34,53.31Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_pick_ship_0\"><path d=\"M385.81,160.25L426.81,160.25\"/><path class=\"pele-marker\" d=\"M433.81,160.25L425.81,163.61L425.81,156.89Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_pay_pick_0\"><path d=\"M241.13,80.67L241.13,140.25C241.13,152.65 248.73,160.25 261.13,160.25L312.59,160.25\"/><path class=\"pele-marker\" d=\"M319.59,160.25L311.59,163.61L311.59,156.89Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"L_pay_pick_0\"><rect x=\"223.9\" y=\"109.96\" width=\"34.46\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"241.13\" y=\"125.36\" text-anchor=\"middle\">paid</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"browse\" transform=\"translate(116.67,56.67)\"><rect x=\"-44.67\" y=\"-24\" width=\"89.34\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Browse</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"pay\" transform=\"translate(241.13,56.67)\"><rect x=\"-31.78\" y=\"-24\" width=\"63.57\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Pay</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"pick\" transform=\"translate(352.7,160.25)\"><rect x=\"-33.11\" y=\"-24\" width=\"66.22\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Pick</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"ship\" transform=\"translate(467.82,160.25)\"><rect x=\"-34.01\" y=\"-24\" width=\"68.02\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Ship</text></g></g></svg>",
  )
}
