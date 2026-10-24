///|
test "runs ranks along the requested direction" {
  for dir in dirs {
    let nodes = nodes_in_order([(60, 40), (60, 40), (60, 40)])
    ignore(
      @layout.compound_layout(nodes, [edge(0, 1), edge(1, 2)], dir, options()),
    )
    let along = fn(node : @layout.CNode) {
      match dir {
        TB | BT => node.y
        LR | RL => node.x
      }
    }
    let sign = match dir {
      TB | LR => 1.0
      BT | RL => -1.0
    }
    assert_true(sign * (along(nodes[1]) - along(nodes[0])) > 40)
    assert_true(sign * (along(nodes[2]) - along(nodes[1])) > 40)
  }
}

///|
test "keeps a long edge straight through the ranks it skips" {
  let nodes = nodes_in_order([(60, 40), (60, 40), (60, 40)])
  let edges = [edge(0, 1), edge(1, 2), edge(0, 2)]
  ignore(@layout.compound_layout(nodes, edges, TB, options()))
  let route = edges[2].route
  let xs : Set[Double] = Set([])
  let mut i = 3
  while i < route.length() - 3 {
    xs.add(route[i].round())
    i += 3
  }
  assert_eq(xs.length(), 1)
}

///|
test "keeps the edges on one side of a node at its middle unless the node has a span" {
  let nodes = nodes_in_order([(120, 40), (60, 40), (60, 40), (60, 40)])
  let edges = [edge(0, 1), edge(0, 2), edge(0, 3)]
  ignore(@layout.compound_layout(nodes, edges, TB, options()))
  for e in edges {
    assert_true((e.route[0] - nodes[0].x).abs() < 1.0e-5)
  }
}

///|
/// A node above a row of `children`, with an edge to each.
/// With a `span`, the edges spread along the nodes' sides.
fn fan(
  children : Int32,
  span~ : Double = 0,
) -> (Array[@layout.CNode], Array[@layout.CEdge], Double) {
  let nodes = [@layout.cnode(100, 40)]
  let edges = []
  for i in 1..<=children {
    nodes.push(@layout.cnode(100, 40))
    edges.push(edge(0, i))
  }
  for i, node in nodes {
    node.seq = i.to_double()
    node.span = span
  }
  ignore(@layout.compound_layout(nodes, edges, TB, options()))
  (nodes, edges, nodes[1].y - nodes[0].y - 40)
}

///|
test "gives the gap between two ranks more room when edges that meet at the middle of their nodes run far across it" {
  assert_true((fan(3).2 - 48).abs() < 1.0e-5)
  // Seven children reach 420 across from the middle, and the gap is an eighth of that.
  assert_true((fan(7).2 - 420.0 / 8).abs() < 1.0e-5)
  assert_true((fan(40).2 - 3 * 48).abs() < 1.0e-5)
}

///|
test "keeps twin edges apart where their ends cannot be" {
  let nodes = nodes_in_order([(60, 40), (60, 40)])
  let edges = [edge(0, 1), edge(0, 1)]
  ignore(@layout.compound_layout(nodes, edges, TB, options()))
  let a = edges[0].route
  let b = edges[1].route
  assert_eq(a.length(), 9)
  assert_eq(b.length(), 9)
  assert_true((a[0] - b[0]).abs() < 1.0e-5)
  assert_true(((a[3] - b[3]).abs() - 16).abs() < 1.0e-5)
}

///|
test "survives groups that contain each other" {
  let a = @layout.cnode(0, 0, parent=1)
  let b = @layout.cnode(0, 0, parent=0)
  a.is_group = true
  b.is_group = true
  let leaf = @layout.cnode(40, 40, parent=0)
  let nodes = [a, b, leaf, @layout.cnode(40, 40)]
  let edges = [edge(2, 3)]
  let size = @layout.compound_layout(nodes, edges, TB, options())
  assert_false(size.width.is_nan() || size.width.is_inf())
  assert_true(edges[0].route.length() >= 6)
}

///|
test "shifts nodes, routes and labels by an offset, leaving each point's axis" {
  let nodes = nodes_in_order([(60, 40), (60, 40)])
  let edges = [edge(0, 1, label_w=20, label_h=10)]
  edges[0].route = [30, 40, 0, 30, 88, 1]
  edges[0].label_x = 30
  edges[0].label_y = 64
  nodes[1].y = 108
  @layout.shift_layout(nodes, edges, 8, 12.5)
  let route = edges[0].route.map(x => "\{x}").join(",")
  inspect(
    "\{nodes[0].x},\{nodes[0].y} \{nodes[1].x},\{nodes[1].y} \{route} \{edges[0].label_x},\{edges[0].label_y}",
    content="8,12.5 8,120.5 38,52.5,0,38,100.5,1 38,76.5",
  )
}
