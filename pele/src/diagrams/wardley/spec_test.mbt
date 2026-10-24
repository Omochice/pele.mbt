// Mermaid's wardleyParser.spec.ts, as pele ports it through its adapter.

///|
fn build(src : String) -> @wardley.WardleyModel raise {
  @wardley.build_wardley(@wardley.parse_wardley(src), None)
}

///|
fn node_labelled(
  m : @wardley.WardleyModel,
  label : String,
) -> @wardley.WardleyNode {
  m.nodes.search_by(n => n.label == label).map(i => m.nodes[i]).unwrap()
}

///|
test "parses components and links" {
  let m = build(
    "wardley-beta\ntitle Example\ncomponent Alpha [0.2, 0.1]\ncomponent Beta [0.4, 0.3]\nAlpha -> Beta",
  )
  assert_eq(m.nodes.length(), 2)
  assert_eq(m.links.length(), 1)
  assert_eq(m.title, Some("Example"))
}

///|
test "parses custom evolution stages" {
  let m = build(
    "wardley-beta\ntitle Test\nevolution Genesis -> Custom -> Product -> Commodity\ncomponent A [0.5, 0.5]",
  )
  assert_eq(m.stages, Some(["Genesis", "Custom", "Product", "Commodity"]))
}

///|
test "parses dual-label evolution stages with slashes" {
  let m = build(
    "wardley-beta\ntitle Test\nevolution Genesis / Concept -> Custom / Emerging -> Product / Converging -> Commodity / Accepted\ncomponent A [0.5, 0.5]",
  )
  assert_eq(
    m.stages,
    Some([
      "Genesis / Concept", "Custom / Emerging", "Product / Converging", "Commodity / Accepted",
    ]),
  )
}

///|
test "parses pipeline blocks with single-coordinate components" {
  let m = build(
    "wardley-beta\ntitle Test Pipeline\ncomponent Kettle [0.45, 0.57]\npipeline Kettle {\n  component Campfire Kettle [0.35] label [-60, 35]\n  component Electric Kettle [0.53]\n}",
  )
  let kettle = node_labelled(m, "Kettle")
  let campfire = node_labelled(m, "Campfire Kettle")
  let electric = node_labelled(m, "Electric Kettle")
  assert_eq(campfire.y, kettle.y)
  assert_eq(electric.y, kettle.y)
  assert_eq(campfire.x, 35)
  assert_eq(electric.x, 53)
}

///|
test "parses custom stage widths with boundary notation" {
  let m = build(
    "wardley-beta\ntitle Test Custom Widths\nevolution Genesis@0.3 -> Custom@0.6 -> Product@0.85 -> Commodity@1.0\ncomponent A [0.5, 0.5]",
  )
  assert_eq(m.stages, Some(["Genesis", "Custom", "Product", "Commodity"]))
  assert_eq(m.stage_boundaries, Some([0.3, 0.6, 0.85, 1.0]))
}

///|
test "parses notes and annotations with quoted text" {
  let m = build(
    "wardley-beta\ntitle Test Notes\ncomponent API [0.6, 0.7]\nnote \"Critical decision point\" [0.65, 0.55]\nannotations [0.1, 0.9]\nannotation 1,[0.6, 0.65] \"Critical component\"\nannotation 2,[0.5, 0.5] \"Performance layer\"",
  )
  assert_eq(m.notes.map(n => n.text), ["Critical decision point"])
  assert_eq(m.annotations.map(a => a.text), [
    "Critical component", "Performance layer",
  ])
}

///|
test "parses anchors" {
  let m = build(
    "wardley-beta\ntitle Test Anchors\nanchor Business [0.95, 0.63]\nanchor Public [0.95, 0.78]\ncomponent Tea [0.63, 0.81]",
  )
  let anchors = m.nodes.filter(n => n.class_name == "anchor")
  assert_eq(anchors.map(n => n.label), ["Business", "Public"])
}

///|
test "parses evolve statements" {
  let m = build(
    "wardley-beta\ntitle Test Evolve\ncomponent Kettle [0.35, 0.43]\nevolve Kettle 0.62",
  )
  assert_eq(m.trends.map(t => t.target_x), [62])
}

///|
test "parses component decorators" {
  let m = build(
    "wardley-beta\ntitle Test Decorators\ncomponent API [0.6, 0.7] (build)\ncomponent Database [0.4, 0.5] (buy)\ncomponent Cache [0.5, 0.6] (outsource)",
  )
  assert_eq(node_labelled(m, "API").source_strategy, Some("build"))
  assert_eq(node_labelled(m, "Database").source_strategy, Some("buy"))
  assert_eq(node_labelled(m, "Cache").source_strategy, Some("outsource"))
}

///|
test "parses size directive" {
  let m = build(
    "wardley-beta\ntitle Test Size\nsize [1200, 900]\ncomponent A [0.5, 0.5]",
  )
  assert_eq(m.size, Some((1200, 900)))
}

///|
test "handles quoted identifiers, inline labels, and converts coordinates to percentages" {
  let m = build(
    "wardley-beta\ntitle Coordinate Handling\ncomponent \"Mobile App\" [0.2, 0.4] (build) (inertia)\ncomponent API [0.3, 0.5]\n\"Mobile App\" +<> API; constraint\nnote \"Check dependencies\" [0.25, 0.45]\nannotations [0.10, 0.90]\nannotation 1,[0.60, 0.65] \"Critical component\"\naccelerator \"Cloud Native\" [0.20, 0.85]\ndeaccelerator \"Legacy Data\" [0.40, 0.35]",
  )
  let mobile = node_labelled(m, "Mobile App")
  assert_eq((mobile.x, mobile.y), (40, 20))
  assert_eq(mobile.source_strategy, Some("build"))
  assert_true(mobile.inertia)
  assert_eq(m.links.length(), 1)
  assert_true(m.links[0].flow is Some(Bidirectional))
  assert_eq(m.links[0].label, Some("constraint"))
  assert_eq((m.notes[0].x, m.notes[0].y), (45, 25))
  assert_eq(m.annotations_box, Some((90, 10)))
  assert_eq(m.annotations[0].text, "Critical component")
  assert_eq((m.annotations[0].x, m.annotations[0].y), (65, 60))
  let fast = m.accelerators[0]
  assert_eq((fast.name, fast.x, fast.y), ("Cloud Native", 85, 20))
  let slow = m.deaccelerators[0]
  assert_eq((slow.name, slow.x, slow.y), ("Legacy Data", 35, 40))
}

///|
test "accepts hyphens in names, link endpoints, and pipeline components" {
  let m = build(
    "wardley-beta\ncomponent real-time processing [0.5, 0.5]\ncomponent end-user [0.8, 0.9]\nanchor on-call engineer [0.9, 0.95]\nreal-time processing -> end-user",
  )
  let realtime = node_labelled(m, "real-time processing")
  assert_eq((realtime.x, realtime.y), (50, 50))
  let enduser = node_labelled(m, "end-user")
  assert_eq((enduser.x, enduser.y), (90, 80))
  let anchor = node_labelled(m, "on-call engineer")
  assert_eq((anchor.class_name, anchor.x, anchor.y), ("anchor", 95, 90))
  assert_eq(m.links.map(l => (l.source, l.target)), [
    ("real-time processing", "end-user"),
  ])
  let piped = build(
    "wardley-beta\ncomponent Data Store [0.5, 0.5]\npipeline Data Store {\n  component real-time queue [0.3] label [-40, 20]\n  component batch-loader [0.7]\n}",
  )
  let queue = node_labelled(piped, "real-time queue")
  assert_eq(queue.class_name, "pipeline-component")
  assert_eq((queue.label_offset_x, queue.label_offset_y), (Some(-40), Some(20)))
  assert_eq(queue.x, 30)
  let loader = node_labelled(piped, "batch-loader")
  assert_eq((loader.class_name, loader.x), ("pipeline-component", 70))
}

///|
test "still tokenises A->B and foo-bar->baz as arrows" {
  let m = build(
    "wardley-beta\ncomponent A [0.1, 0.1]\ncomponent B [0.2, 0.2]\ncomponent foo-bar [0.3, 0.3]\ncomponent baz [0.6, 0.6]\nA->B\nfoo-bar->baz",
  )
  assert_eq(m.links.map(l => (l.source, l.target)), [
    ("A", "B"),
    ("foo-bar", "baz"),
  ])
}

///|
test "accepts consecutive and trailing hyphens inside a name" {
  let m = build(
    "wardley-beta\ncomponent foo--bar [0.3, 0.4]\ncomponent foo- [0.2, 0.3]",
  )
  let double = node_labelled(m, "foo--bar")
  assert_eq((double.x, double.y), (40, 30))
  let trailing = node_labelled(m, "foo-")
  assert_eq((trailing.x, trailing.y), (30, 20))
}
