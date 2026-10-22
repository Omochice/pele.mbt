///|
fn edge(
  src : Int32,
  dst : Int32,
  label_w~ : Double = 0,
  label_h~ : Double = 0,
) -> @layout.CEdge {
  { src, dst, minlen: 1, label_w, label_h, route: [], label_x: 0, label_y: 0, }
}

///|
test "counts where routes cross, but not where edges that meet at one node fan out from it" {
  let nodes = [
    @layout.cnode(40, 40),
    @layout.cnode(40, 40),
    @layout.cnode(40, 40),
    @layout.cnode(40, 40),
  ]
  for i, node in nodes {
    node.x = 100.0 * (i % 2).to_double()
    node.y = 200.0 * (i / 2).to_double()
  }
  let crossed = [edge(0, 3), edge(1, 2)]
  crossed[0].route = [0, 20, 0, 100, 180, 0]
  crossed[1].route = [100, 20, 0, 0, 180, 0]
  assert_eq(@layout.route_crossings(nodes, crossed), 1)
  let fan = [edge(0, 2), edge(0, 3)]
  fan[0].route = [10, 20, 0, 0, 180, 0]
  fan[1].route = [-10, 20, 0, 100, 180, 0]
  assert_eq(@layout.route_crossings(nodes, fan), 0)
}

///|
test "does not count edges that join one straight run into the node they meet at as crossing" {
  let nodes = [
    @layout.cnode(40, 40),
    @layout.cnode(40, 40),
    @layout.cnode(40, 40),
  ]
  nodes[1].x = 100
  nodes[2].x = 50
  nodes[2].y = 300
  let edges = [edge(0, 2), edge(1, 2)]
  edges[0].route = [0, 20, 0, 0, 200, 0, 50, 200, 0, 50, 280, 0]
  edges[1].route = [100, 20, 0, 100, 150, 0, 50, 150, 0, 50, 280, 0]
  assert_eq(@layout.route_crossings(nodes, edges), 0)
}

///|
test "counts crossings where the drawing has them, round its corners or at its steps" {
  let nodes = [
    @layout.cnode(40, 40),
    @layout.cnode(40, 40),
    @layout.cnode(40, 40),
    @layout.cnode(40, 40),
  ]
  nodes[0].y = -20
  nodes[1].x = 120
  nodes[1].y = 100
  nodes[2].x = 5
  nodes[2].y = 170
  nodes[3].x = 5
  nodes[3].y = 40
  // Rounding the corner clears the other edge.
  let corner = [edge(0, 1), edge(2, 3)]
  corner[0].route = [0, 0, 0, 0, 100, 0, 100, 100, 1]
  corner[1].route = [5, 150, 0, 5, 60, 0]
  assert_eq(@layout.route_crossings(nodes, corner, style=Curved), 0)
  assert_eq(@layout.route_crossings(nodes, corner, style=Stepped), 1)
  assert_eq(@layout.route_crossings(nodes, corner, style=Linear), 1)
}
