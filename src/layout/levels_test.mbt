///|
test "turns edges that run far across side by side at levels of their own, in a gap that grows to hold them" {
  // With three children nothing runs far, and each edge is one curve across the usual gap.
  let (_, few_edges, few_gap) = fan(3, span=76)
  assert_true(near(few_gap, 48))
  for e in few_edges {
    assert_eq(e.route.length(), 6)
  }
  // With seven, the three on each side run down, across and down again.
  let (nodes, edges, gap) = fan(7, span=76)
  let level = fn(e : @layout.CEdge) raise {
    assert_eq(e.route.length(), 12)
    assert_true(near(e.route[3], e.route[0]))
    assert_true(near(e.route[7], e.route[4]))
    assert_true(near(e.route[9], e.route[6]))
    e.route[4]
  }
  // The edge that runs furthest turns first, and each of the others 12 further down.
  assert_true(near(level(edges[1]) - level(edges[0]), 12))
  assert_true(near(level(edges[2]) - level(edges[1]), 12))
  for i in 0..<3 {
    assert_true(near(level(edges[6 - i]), level(edges[i])))
  }
  // The one in the middle runs straight down.
  assert_eq(edges[3].route.length(), 6)
  assert_true(near(edges[3].route[3], edges[3].route[0]))
  // The levels keep 28 from the ranks above and below.
  assert_true(near(level(edges[0]) - nodes[0].y - 20, 28))
  assert_true(near(gap, 2 * 28 + 2 * 12))
}

///|
test "draws the edges of a gap as plain curves, in a taller gap, where they cross each other more than they run alongside" {
  // Four nodes above four, each with an edge to every one below.
  let nodes = nodes_in_order(Array::make(8, (80.0, 40.0)))
  for node in nodes {
    node.span = 56
  }
  let edges = []
  for i in 0..<4 {
    for j in 4..<8 {
      edges.push(edge(i, j))
    }
  }
  ignore(@layout.compound_layout(nodes, edges, TB, options()))
  // No edge turns onto a level: each runs from one point to the other.
  for e in edges {
    assert_eq(e.route.length(), 6)
  }
  // The gap is half as tall as the widest edge runs across, and no more than three times the usual.
  let mut widest = 0.0
  for e in edges {
    let across = (e.route[0] - e.route[3]).abs()
    if across > widest {
      widest = across
    }
  }
  assert_true(widest > 6 * 48)
  assert_true(near(nodes[4].y - nodes[0].y - 40, 3 * 48))
}

///|
test "sets a rank of labels half an arrowhead nearer the tails of its edges, and holds a bend beside them for half their height" {
  let lay = fn(head_room : Double) {
    let nodes = nodes_in_order([(60, 40), (60, 40)])
    for node in nodes {
      node.span = 36
    }
    let edges = [
      edge(0, 1, label_w=40, label_h=20),
      edge(0, 1, label_w=50, label_h=20),
      edge(0, 1),
    ]
    ignore(@layout.compound_layout(nodes, edges, TB, options(head_room~)))
    edges
  }
  // Without arrowheads the labels are midway between the two nodes.
  let plain = lay(0)
  assert_true(near(plain[0].label_y, (40.0 + 108) / 2))
  // With them, the labels are midway between the node above and the backs of the arrowheads.
  let edges = lay(8)
  let first = edges[0]
  let second = edges[1]
  let bare = edges[2]
  assert_true(near(first.label_y, (40.0 + 108 - 8) / 2))
  assert_true(near(second.label_y, first.label_y))
  // A labelled edge runs straight for the height of its label, and the bare one for half of that.
  assert_true(near(first.route[7] - first.route[4], 20))
  assert_true(near(bare.route[7] - bare.route[4], 10))
  assert_true(near((bare.route[4] + bare.route[7]) / 2, first.label_y))
}

///|
test "turns an edge that runs far across at a level of its own where a shorter one would run close beside it" {
  // A node above a row of three, and an edge back up to it from below the row.
  let nodes = nodes_in_order(Array::make(5, (80.0, 40.0)))
  for node in nodes {
    node.span = 56
  }
  let edges = [
    edge(0, 1),
    edge(0, 2),
    edge(0, 3),
    edge(1, 4),
    edge(2, 4),
    edge(3, 4),
    edge(4, 0),
  ]
  ignore(@layout.compound_layout(nodes, edges, TB, options()))
  // The edge back up passes the row on one side, then runs across to the top node and up into it.
  let back = edges[6].route
  let n = back.length()
  let level = back[n - 5]
  assert_true(near(back[n - 8], level))
  assert_true(near(back[n - 6], back[n - 3]))
  assert_true((back[n - 9] - back[n - 6]).abs() > 2 * 48)
  // The edge down to the node on that side leaves next to where it arrives.
  // It runs straight down as far as that level and curves below it.
  let down = edges[2].route
  assert_true((down[0] - back[n - 3]).abs() < 20)
  assert_eq(down.length(), 9)
  assert_true(near(down[3], down[0]))
  assert_true(down[4] > level - 0.01)
}

///|
test "draws an edge as one curve across a rank that only a twin of another edge put there" {
  let lay = fn(twin : Bool) {
    let nodes = nodes_in_order(Array::make(4, (60.0, 40.0)))
    for node in nodes {
      node.span = 36
    }
    let edges = [edge(0, 1), edge(0, 2), edge(0, 3)]
    if twin {
      edges.push(edge(0, 3))
    }
    ignore(@layout.compound_layout(nodes, edges, TB, options()))
    edges
  }
  let plain = lay(false)
  let twinned = lay(true)
  // The twins make every edge take a rank in the middle, but none of them needs a bend there.
  for e in twinned[:2] {
    assert_eq(e.route.length(), 6)
  }
  assert_true(near(twinned[0].route[1], plain[0].route[1]))
  // The gap is tall enough for the twins to turn at two levels, 12 apart and 28 from the ranks.
  assert_true(near(twinned[0].route[4], plain[0].route[4] + 2 * 28 + 12 - 48))
  // The twins leave and arrive at places of their own.
  let one = twinned[2].route
  let other = twinned[3].route
  assert_true((one[0] - other[0]).abs() >= 8)
  assert_true((one[one.length() - 3] - other[other.length() - 3]).abs() >= 8)
  // They would run close beside each other, so one turns straight away and the other further down.
  let turns_at = fn(route : Array[Double]) {
    if (route[3] - route[0]).abs() < 0.01 {
      route[4]
    } else {
      route[1]
    }
  }
  assert_true((turns_at(one) - turns_at(other)).abs() >= 10)
}
