///|
test "routes edges at right angles on tracks, where no two can be taken for each other" {
  for seed in 1..<=120 {
    let rnd = random(seed * 7919)
    let int = fn(n : Double) { (rnd() * n).floor().to_int() }
    let nodes = []
    let count = 3 + int(14)
    for i in 0..<count {
      let node = @layout.cnode(
        (40 + int(120)).to_double(),
        (30 + int(60)).to_double(),
      )
      node.seq = i.to_double()
      node.span = node.w - 24
      nodes.push(node)
    }
    let edges = []
    let wanted = int(count.to_double() * 2.5)
    for _ in 0..<wanted {
      let src = int(count.to_double())
      let dst = int(count.to_double())
      if src != dst {
        let label_w = if rnd() < 0.2 { (30 + int(40)).to_double() } else { 0 }
        edges.push(edge(src, dst, label_w~, label_h=20))
      }
    }
    ignore(@layout.compound_layout(nodes, edges, TB, options(tracks=true)))
    // Every run across, with the x where the edge comes down to it and where it goes down from it.
    let runs : Array[(Double, Double, Double, Double, Double)] = []
    for e in edges {
      let r = e.route
      assert_true(on_border(nodes[e.src], r[0], r[1]))
      assert_true(on_border(nodes[e.dst], r[r.length() - 3], r[r.length() - 2]))
      let mut k = 3
      while k < r.length() {
        // Two ends less than half a unit out of line are joined directly.
        let across = (r[k + 1] - r[k - 2]).abs() < 0.01
        let down = (r[k] - r[k - 3]).abs() < 0.5
        assert_true(across || down)
        if across && !down {
          // The route runs upwards when the edge does, so the higher end is the one it comes down to.
          let before = if k >= 6 { r[k - 5] } else { r[k - 2] }
          let from_first = before < r[k - 2] - 0.01 ||
            (k + 4 < r.length() && r[k + 4] > r[k + 1] + 0.01)
          runs.push(
            (
              r[k + 1],
              if r[k] < r[k - 3] {
                r[k]
              } else {
                r[k - 3]
              },
              if r[k] > r[k - 3] {
                r[k]
              } else {
                r[k - 3]
              },
              if from_first {
                r[k - 3]
              } else {
                r[k]
              },
              if from_first {
                r[k]
              } else {
                r[k - 3]
              },
            ),
          )
        }
        k += 3
      }
    }
    for a in 0..<runs.length() {
      for b in (a + 1)..<runs.length() {
        let (ya, loa, hia, froma, toa) = runs[a]
        let (yb, lob, hib, fromb, tob) = runs[b]
        if (ya - yb).abs() > 0.01 {
          continue
        }
        let overlap = loa < hib - 0.5 && lob < hia - 0.5
        let mates = (froma - fromb).abs() < 0.5 || (toa - tob).abs() < 0.5
        assert_false(overlap && !mates)
      }
    }
    // No run across passes through a node.
    for run in runs {
      let (y, lo, hi, _, _) = run
      for node in nodes {
        let inside = (y - node.y).abs() < node.h / 2 - 0.5 &&
          lo < node.x + node.w / 2 - 0.5 &&
          hi > node.x - node.w / 2 + 0.5
        assert_false(inside)
      }
    }
  }
}

///|
test "nests the tracks of a fan so that its edges do not cross" {
  let nodes = nodes_in_order([(120, 40), (60, 40), (60, 40), (60, 40), (60, 40)])
  nodes[0].span = 96
  let edges = [edge(0, 1), edge(0, 2), edge(0, 3), edge(0, 4)]
  ignore(@layout.compound_layout(nodes, edges, TB, options(tracks=true)))
  let across_y = fn(e : @layout.CEdge) { e.route[4] }
  let left = edges.filter(e => nodes[e.dst].x < nodes[0].x)
  left.sort_by((a, b) => nodes[a.dst].x.compare(nodes[b.dst].x))
  let right = edges.filter(e => nodes[e.dst].x > nodes[0].x)
  right.sort_by((a, b) => nodes[b.dst].x.compare(nodes[a.dst].x))
  // The edge that reaches furthest turns first, so the nearer ones pass under it.
  for side in [left, right] {
    for i in 1..<side.length() {
      assert_true(across_y(side[i - 1]) < across_y(side[i]))
    }
  }
}
