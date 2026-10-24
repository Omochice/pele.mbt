///|
/// How many times a route changes its place across the flow.
fn turns(route : Array[Double]) -> Int32 {
  let mut count = 0
  let mut i = 3
  while i < route.length() {
    if (route[i] - route[i - 3]).abs() > 0.01 {
      count += 1
    }
    i += 3
  }
  count
}

///|
test "runs an edge that skips ranks in line with one of its ends, so that it turns once, at the other" {
  // A chain of eight, with edges that skip ranks down it and back up.
  let nodes = nodes_in_order(Array::make(8, (80.0, 40.0)))
  for node in nodes {
    node.span = 56
  }
  let edges = [
    edge(0, 1),
    edge(1, 2),
    edge(2, 3),
    edge(3, 4),
    edge(4, 5),
    edge(5, 6),
    edge(6, 7),
    edge(0, 3),
    edge(0, 7),
    edge(1, 5),
    edge(2, 6),
    edge(6, 1),
    edge(7, 0),
  ]
  ignore(@layout.compound_layout(nodes, edges, TB, options()))
  for e in edges[7:] {
    assert_eq(turns(e.route), 1)
  }
  // The edge from the second node down and the one back up to it both meet it in line.
  let down = edges[9].route
  let up = edges[11].route
  assert_true(near(down[3], down[0]))
  assert_true(near(up[up.length() - 6], up[up.length() - 3]))
}

///|
test "spreads the edges on one side of a node in the order of the nodes they lead to" {
  for dir in dirs {
    let nodes = nodes_in_order([(120, 120), (60, 60), (60, 60), (60, 60)])
    nodes[0].span = 96
    let edges = [edge(0, 1), edge(0, 2), edge(0, 3)]
    ignore(@layout.compound_layout(nodes, edges, dir, options()))
    let across = fn(node : @layout.CNode) {
      match dir {
        TB | BT => node.x
        LR | RL => node.y
      }
    }
    let starts = edges.map(e => {
      match dir {
        TB | BT => e.route[0] - nodes[0].x
        LR | RL => e.route[1] - nodes[0].y
      }
    })
    let targets = edges.map(e => across(nodes[e.dst]))
    let by_start = [0, 1, 2]
    by_start.sort_by((a, b) => starts[a].compare(starts[b]))
    let by_target = [0, 1, 2]
    by_target.sort_by((a, b) => targets[a].compare(targets[b]))
    assert_eq(by_start, by_target)
    // None of the three can run straight, so they stay around the middle, a pitch apart.
    assert_true(near(starts[by_start[0]], -16))
    assert_true(near(starts[by_start[1]], 0))
    assert_true(near(starts[by_start[2]], 16))
    for e in edges {
      assert_true(on_border(nodes[0], e.route[0], e.route[1]))
    }
  }
}

///|
test "keeps an edge that arrives apart from one that leaves on the same side" {
  let nodes = nodes_in_order([(60, 40), (60, 40)])
  for node in nodes {
    node.span = 36
  }
  let edges = [edge(0, 1), edge(1, 0)]
  ignore(@layout.compound_layout(nodes, edges, TB, options()))
  let down = edges[0].route
  let up = edges[1].route
  assert_true(near((down[down.length() - 3] - up[0]).abs(), 16))
  assert_true(near((down[0] - up[up.length() - 3]).abs(), 16))
}

///|
test "shares a place among edges that run the same way when there is no room for one each" {
  let nodes = nodes_in_order(Array::make(13, (60.0, 40.0)))
  for node in nodes {
    node.span = 36
  }
  let edges = []
  for i in 0..<12 {
    edges.push(edge(i, 12))
  }
  // One edge the other way on the same side, which keeps a place of its own.
  edges.push(edge(12, 0))
  ignore(@layout.compound_layout(nodes, edges, TB, options()))
  let into = edges[:12].iter().map(e => e.route[e.route.length() - 3]).collect()
  let places : Set[Double] = Set([])
  for x in into {
    places.add((x * 100).round())
  }
  assert_true(places.length() <= 2)
  let back = edges[12].route
  assert_true(near(back[1], nodes[12].y - 20))
  for x in into {
    assert_true((x - back[0]).abs() >= 8)
  }
}

///|
test "stands a rank that only sends edges on one line, and hangs a rank that only receives them from one" {
  let lay = fn(span : Double) {
    let nodes = nodes_in_order([(60, 40), (60, 120), (60, 30), (60, 90)])
    for node in nodes {
      node.span = span
    }
    ignore(
      @layout.compound_layout(
        nodes,
        [edge(0, 2), edge(1, 2), edge(0, 3), edge(1, 3)],
        TB,
        options(),
      ),
    )
    nodes
  }
  let spread = lay(36)
  assert_true(near(spread[0].y + 20, spread[1].y + 60))
  assert_true(near(spread[2].y - 15, spread[3].y - 45))
  // Without spreading, as in the diagram types that do not use it yet, each rank is centered.
  let plain = lay(0)
  assert_true(near(plain[0].y, plain[1].y))
  assert_true(near(plain[2].y, plain[3].y))
}

///|
test "moves an end along its side to let its edge run straight, and no closer to its neighbour than a pitch" {
  // A wide node above four narrow ones.
  let nodes = nodes_in_order([(400, 40), (40, 40), (40, 40), (40, 40), (40, 40)])
  for node in nodes {
    node.span = node.w - 24
  }
  let edges = [edge(0, 1), edge(0, 2), edge(0, 3), edge(0, 4)]
  ignore(@layout.compound_layout(nodes, edges, TB, options()))
  // Each child is under the wide node, so each edge runs straight down to it.
  for e in edges {
    assert_true(near(e.route[0], e.route[e.route.length() - 3]))
  }
  let two_way = nodes_in_order([(200, 40), (40, 40)])
  for node in two_way {
    node.span = node.w - 24
  }
  let pair = [edge(0, 1), edge(1, 0)]
  ignore(@layout.compound_layout(two_way, pair, TB, options()))
  let back = pair[1].route
  assert_true(near((pair[0].route[0] - back[back.length() - 3]).abs(), 16))
}

///|
test "moves the edges that leave side by side closer together before it lets them share a place" {
  let nodes = nodes_in_order(Array::make(8, (60.0, 40.0)))
  let edges = []
  for i in 1..<=7 {
    edges.push(edge(0, i))
  }
  nodes[0].span = 36
  ignore(@layout.compound_layout(nodes, edges, TB, options()))
  let starts = edges.map(e => e.route[0])
  starts.sort_by((a, b) => a.compare(b))
  // Six gaps of half a pitch each across the 36 there is.
  for i in 1..<starts.length() {
    assert_true(near(starts[i] - starts[i - 1], 6))
  }
}
