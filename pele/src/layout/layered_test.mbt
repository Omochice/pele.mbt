///|
test "orders a flat graph with groups side by side, and counts the crossings of that order" {
  let nodes = Array::makei(6, _ => @layout.lnode(40, 40))
  let of_ = [0, 1, 0, -1, 0, -1]
  let edges = [
    @layout.ledge(0, 4),
    @layout.ledge(1, 4),
    @layout.ledge(2, 5),
    @layout.ledge(3, 4),
    @layout.ledge(3, 5),
  ]
  let result = @layout.layered(
    nodes,
    edges,
    @layout.LayeredOptions::new(
      node_sep=40,
      edge_sep=16,
      rank_sep=48,
      port_sep=20,
      groups={ of: of_, parent: [-1, -1], },
      order_only=true,
    ),
  )
  // Points are (rank, cross-flow position) pairs.
  let pieces : Array[(Double, Double, Double)] = []
  for e in edges {
    let mut k = 2
    while k < e.points.length() {
      pieces.push((e.points[k - 2], e.points[k - 1], e.points[k + 1]))
      k += 2
    }
  }
  let mut crossed = 0
  for i in 0..<pieces.length() {
    for j in (i + 1)..<pieces.length() {
      let (r, a0, a1) = pieces[i]
      let (s, b0, b1) = pieces[j]
      if r == s && (a0 - b0) * (a1 - b1) < 0 {
        crossed += 1
      }
    }
  }
  assert_eq(result.crossings, crossed)
  for i in 0..<nodes.length() {
    for j in 0..<nodes.length() {
      if of_[i] < 0 ||
        of_[j] != of_[i] ||
        nodes[i].rank != nodes[j].rank ||
        nodes[i].x >= nodes[j].x {
        continue
      }
      for k in 0..<nodes.length() {
        let between = nodes[k].rank == nodes[i].rank &&
          nodes[k].x > nodes[i].x &&
          nodes[k].x < nodes[j].x
        assert_false(between && of_[k] != of_[i])
      }
    }
  }
  // The order and counts pele v1.8.0 gives this graph.
  let placed = nodes.map(n => "\{n.rank}:\{n.x}")
  inspect(
    "\{placed.join(" ")} crossings=\{result.crossings} declared=\{result.declared}",
    content="0:0 0:160 0:80 0:240 1:160 1:240 crossings=2 declared=1",
  )
}
