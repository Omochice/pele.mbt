///|
fn build(rows : Array[(String, String, Double)]) -> @sankey.SankeyDb {
  let db = @sankey.SankeyDb::new()
  for row in rows {
    let (source, target, value) = row
    db.add_link(
      db.find_or_create_node(source),
      db.find_or_create_node(target),
      value,
    )
  }
  db
}

///|
fn options(
  alignment~ : @sankey.Alignment = Justify,
  node_padding~ : Double = 12,
  label_height~ : Double = 0,
) -> @sankey.LayoutOptions {
  {
    width: 600,
    height: 400,
    node_width: 10,
    node_padding,
    label_height,
    alignment,
  }
}

///|
fn close(actual : Double, expected : Double) -> Bool {
  (actual - expected).abs() < 1.0e-6
}

///|
fn layers(db : @sankey.SankeyDb, alignment : @sankey.Alignment) -> String {
  let layout = @sankey.layout_sankey(db, options(alignment~)) catch {
    @errors.PeleError(failure) => return failure.message
  }
  let parts = []
  for i, node in db.nodes {
    parts.push("\{node.id}=\{layout.nodes[i].layer}")
  }
  parts.join(" ")
}

///|
let shape : Array[(String, String, Double)] = [
  ("a", "b", 4),
  ("b", "c", 3),
  ("c", "d", 3),
  ("x", "d", 2),
  ("a", "y", 1),
]

///|
test "a node takes the column of its longest distance from a source" {
  inspect(layers(build(shape), Left), content="a=0 b=1 c=2 d=3 x=0 y=1")
  inspect(
    layers(build([("a", "b", 1), ("b", "c", 1), ("a", "c", 1)]), Left),
    content="a=0 b=1 c=2",
  )
}

///|
test "the four alignments place sources and sinks differently" {
  inspect(layers(build(shape), Justify), content="a=0 b=1 c=2 d=3 x=0 y=3")
  inspect(layers(build(shape), Right), content="a=0 b=1 c=2 d=3 x=2 y=3")
  inspect(layers(build(shape), Center), content="a=0 b=1 c=2 d=3 x=2 y=1")
}

///|
test "columns are spread over the width" {
  let layout = @sankey.layout_sankey(build(shape), options(alignment=Left))
  assert_true(layout.nodes[0].x == 0)
  assert_true(layout.nodes[3].x == 590)
  assert_true(close(layout.nodes[1].x, 590.0 / 3.0))
}

///|
test "nodes and bands are sized in proportion to their flow" {
  let db = build([("a", "b", 30), ("a", "c", 10), ("b", "d", 30)])
  let layout = @sankey.layout_sankey(db, options())
  let nodes = layout.nodes
  let links = layout.links
  assert_true(nodes[0].value == 40)
  // The second column holds two nodes and one gap, and sets the scale.
  assert_true(close(nodes[0].height, 388))
  assert_true(close(nodes[1].height / nodes[2].height, 3))
  assert_true(close(links[0].thickness / links[1].thickness, 3))
  assert_true(close(links[0].thickness + links[1].thickness, nodes[0].height))
}

///|
test "a node is as large as the greater of what flows in and out" {
  let layout = @sankey.layout_sankey(
    build([("a", "b", 5), ("b", "c", 2)]),
    options(),
  )
  assert_true(layout.nodes[1].value == 5)
  assert_true(layout.nodes[1].height > layout.nodes[2].height)
}

///|
test "nodes of a column keep apart and stay inside the height" {
  let rows = []
  for i in 0..<12 {
    rows.push(("s\{i % 4}", "t\{i}", (1 + i % 5).to_double()))
  }
  let db = build(rows)
  let layout = @sankey.layout_sankey(db, options())
  let columns : Map[Int32, Array[@sankey.PlacedNode]] = Map([])
  for node in layout.nodes {
    if columns.get(node.layer) is None {
      columns[node.layer] = []
    }
    columns[node.layer].push(node)
  }
  for _, column in columns {
    column.sort_by(fn(p, q) { p.y.compare(q.y) })
    assert_true(column[0].y >= -1.0e-6)
    for i in 1..<column.length() {
      let gap = column[i].y - (column[i - 1].y + column[i - 1].height)
      assert_true(gap >= 12 - 1.0e-6)
    }
    let last = column[column.length() - 1]
    assert_true(last.y + last.height <= 400 + 1.0e-6)
  }
}

///|
test "bands are stacked in the order of their other ends, inside the node" {
  let db = build([("a", "x", 1), ("a", "y", 2), ("a", "z", 3), ("b", "z", 1)])
  let layout = @sankey.layout_sankey(db, options())
  let out = layout.links.filter(link => link.source == 0)
  out.sort_by(fn(p, q) { p.source_y.compare(q.source_y) })
  let targets = out.map(link => layout.nodes[link.target].y)
  for i in 1..<targets.length() {
    assert_true(targets[i - 1] <= targets[i])
  }
  for link in layout.links {
    let source = layout.nodes[link.source]
    let target = layout.nodes[link.target]
    assert_true(link.source_y - link.thickness / 2 >= source.y - 1.0e-6)
    assert_true(
      link.source_y + link.thickness / 2 <= source.y + source.height + 1.0e-6,
    )
    assert_true(link.target_y - link.thickness / 2 >= target.y - 1.0e-6)
    assert_true(
      link.target_y + link.thickness / 2 <= target.y + target.height + 1.0e-6,
    )
  }
}

///|
test "a column is reordered so that bands do not cross when they need not" {
  // Declared in an order that crosses: a feeds the lower target, b the upper one.
  let db = build([
    ("a", "low", 1),
    ("b", "high", 1),
    ("root", "high", 0.1),
    ("root", "low", 0.1),
  ])
  let layout = @sankey.layout_sankey(db, options())
  let first = layout.links[0]
  let second = layout.links[1]
  let by_source = layout.nodes[first.source].y.compare(
    layout.nodes[second.source].y,
  )
  let by_target = layout.nodes[first.target].y.compare(
    layout.nodes[second.target].y,
  )
  assert_true(by_source == by_target)
}

///|
test "thin nodes get room for their labels when the column can afford it" {
  let rows = [("big", "t", 1000.0)]
  for i in 0..<8 {
    rows.push(("thin\{i}", "t", 1.0))
  }
  let roomy = @sankey.layout_sankey(
      build(rows),
      options(node_padding=2, label_height=16),
    ).nodes
  let ys = [roomy[0], ..roomy[2:]].map(node => node.y + node.height / 2)
  ys.sort_by(fn(p, q) { p.compare(q) })
  for i in 1..<ys.length() {
    assert_true(ys[i] - ys[i - 1] >= 16 - 1.0e-6)
  }
  // With more thin nodes than the height can hold labels for, the plain gaps are used.
  let many = Array::makei(100, i => ("n\{i}", "t", 1.0))
  let crowded = @sankey.layout_sankey(build(many), options(label_height=16)).nodes
  assert_true(crowded.iter().all(node => node.y >= -1.0e-6 && node.y <= 400))
}

///|
test "circular links are rejected, naming a node on the cycle" {
  let reject = (rows : Array[(String, String, Double)]) => {
    try @sankey.layout_sankey(build(rows), options()) catch {
      @errors.PeleError(failure) =>
        "\{failure.code.to_string()} \{failure.kind.unwrap_or("-")}: \{failure.message}"
    } noraise {
      _ => "accepted"
    }
  }
  inspect(
    reject([("a", "a", 1)]),
    content="semantic sankey: Sankey diagrams cannot have circular links, and \"a\" is part of one.",
  )
  inspect(
    reject([("a", "b", 1), ("b", "a", 1)]),
    content="semantic sankey: Sankey diagrams cannot have circular links, and \"a\" is part of one.",
  )
  inspect(
    reject([
      ("s", "a", 1),
      ("a", "b", 1),
      ("b", "c", 1),
      ("c", "a", 1),
      ("c", "tail", 1),
    ]),
    content="semantic sankey: Sankey diagrams cannot have circular links, and \"a\" is part of one.",
  )
}

///|
test "values that are not positive numbers are no flow, and everything stays finite" {
  let db = build([
    ("a", "b", @double.not_a_number),
    ("a", "c", -5),
    ("a", "d", @double.infinity),
    ("b", "e", 0),
    ("x", "y", 1.0e308),
    ("x", "z", 1.0e308),
  ])
  let layout = @sankey.layout_sankey(db, options())
  for node in layout.nodes {
    for v in [node.x, node.y, node.height] {
      assert_true(v.is_nan() == false && v.is_inf() == false)
    }
  }
  for link in layout.links {
    for v in [link.thickness, link.source_y, link.target_y] {
      assert_true(v.is_nan() == false && v.is_inf() == false)
    }
  }
  assert_true(layout.nodes[0].value == 0)
  assert_true(layout.nodes[0].height == 0)
  inspect(
    @sankey.layout_sankey(@sankey.SankeyDb::new(), options()).nodes.length(),
    content="0",
  )
}
