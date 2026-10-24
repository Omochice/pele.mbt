///|
/// A lane or a group inside one, padded as pele's lane layout tests pad them.
fn lane_group(parent~ : Int32 = -1) -> @layout.CNode {
  let node = @layout.cnode(0, 0, parent~)
  node.is_group = true
  node.pad_x = 20
  node.pad_top = 36
  node.pad_bottom = 20
  node.min_w = 60
  node
}

///|
fn nodes_of(sizes : Array[(Double, Double)]) -> Array[@layout.CNode] {
  sizes.map(size => @layout.cnode(size.0, size.1))
}

///|
fn box(c : @layout.CNode) -> (Double, Double, Double, Double) {
  (c.x - c.w / 2, c.y - c.h / 2, c.x + c.w / 2, c.y + c.h / 2)
}

///|
fn distinct(values : Array[Int32]) -> Int32 {
  let seen : Array[Int32] = []
  for v in values {
    if !seen.contains(v) {
      seen.push(v)
    }
  }
  seen.length()
}

///|
/// Every stretch of a route runs straight across or straight along.
fn square(route : Array[Double]) -> Bool {
  for p = 3; p < route.length(); p = p + 3 {
    if route[p] != route[p - 3] && route[p + 1] != route[p - 2] {
      return false
    }
  }
  true
}

///|
fn sideways(dir : @layout.Dir) -> Bool {
  dir is (LR | RL)
}

///|
test "lays out nothing" {
  let size = @layout.lane_layout([], [], TB, options())
  assert_eq(size.width, 0)
  assert_eq(size.height, 0)
}

///|
test "puts lanes side by side across the flow, in the order written" {
  for dir in dirs {
    let nodes = nodes_of([(60, 30), (60, 30)])
    nodes.push(lane_group())
    nodes.push(lane_group())
    nodes[0].parent = 3
    nodes[1].parent = 2
    let result = @layout.lane_layout(nodes, [edge(0, 1)], dir, options())
    let first = nodes[3]
    let second = nodes[2]
    if sideways(dir) {
      assert_true(first.y < second.y)
      assert_eq(first.w, result.width)
      assert_true(near(first.h + second.h, result.height))
    } else {
      assert_true(first.x < second.x)
      assert_eq(first.h, result.height)
      assert_true(near(first.w + second.w, result.width))
    }
  }
}

///|
test "runs the flow in the direction asked for" {
  let at = (dir : @layout.Dir) => {
    let nodes = nodes_of([(60, 30), (60, 30)])
    nodes.push(lane_group())
    nodes[0].parent = 2
    nodes[1].parent = 2
    ignore(@layout.lane_layout(nodes, [edge(0, 1)], dir, options()))
    nodes
  }
  assert_true(at(TB)[0].y < at(TB)[1].y)
  assert_true(at(BT)[0].y > at(BT)[1].y)
  assert_true(at(LR)[0].x < at(LR)[1].x)
  assert_true(at(RL)[0].x > at(RL)[1].x)
}

///|
test "keeps a chain in one lane on a straight line" {
  let nodes = nodes_of([(50, 30), (120, 30), (70, 30)])
  nodes.push(lane_group())
  for i in 0..<3 {
    nodes[i].parent = 3
  }
  ignore(@layout.lane_layout(nodes, [edge(0, 1), edge(1, 2)], TB, options()))
  assert_true(near(nodes[0].x, nodes[1].x))
  assert_true(near(nodes[1].x, nodes[2].x))
}

///|
test "separates an approval decision's incoming, accepted and returned paths" {
  for dir in dirs {
    let nodes = nodes_of([
      (60, 40),
      (80, 40),
      (70, 70),
      (80, 40),
      (80, 40),
      (60, 40),
    ])
    nodes.push(lane_group())
    nodes.push(lane_group())
    nodes.push(lane_group())
    nodes[0].parent = 8
    nodes[5].parent = 8
    nodes[1].parent = 7
    nodes[2].parent = 7
    nodes[3].parent = 6
    nodes[4].parent = 6
    let edges = [
      edge(0, 1, label_w=70, label_h=20),
      edge(1, 2),
      edge(2, 3, label_w=50, label_h=20),
      edge(3, 4),
      edge(4, 5),
      edge(2, 0, label_w=70, label_h=20),
    ]
    ignore(@layout.lane_layout(nodes, edges, dir, options()))
    let incoming = @svg.end_side(
      edges[1].route,
      edges[1].route.length() - 3,
      nodes[2],
    )
    let accepted = @svg.end_side(edges[2].route, 0, nodes[2])
    let returned = @svg.end_side(edges[5].route, 0, nodes[2])
    let sides = [incoming, accepted, returned]
    assert_eq(distinct(sides), 3)
    assert_false(sides.contains(-1))
    let back = edges[5]
    let mut corners = 0
    for p = 6; p < back.route.length(); p = p + 3 {
      if (back.route[p] == back.route[p - 3]) !=
        (back.route[p - 3] == back.route[p - 6]) {
        corners += 1
      }
    }
    assert_eq(corners, 1)
    assert_true(square(back.route))
    for node in nodes[0:6] {
      let (l, t, r, b) = box(node)
      let clear = back.label_x + back.label_w / 2 <= l ||
        back.label_x - back.label_w / 2 >= r ||
        back.label_y + back.label_h / 2 <= t ||
        back.label_y - back.label_h / 2 >= b
      assert_true(clear)
    }
  }
}

///|
test "keeps a handoff into a step apart from the handoff out of it" {
  for dir in dirs {
    let nodes = nodes_of([(110, 38), (110, 38), (100, 38), (110, 38)])
    nodes.push(lane_group())
    nodes.push(lane_group())
    nodes[0].parent = 5
    nodes[1].parent = 5
    nodes[2].parent = 4
    nodes[3].parent = 4
    let edges = [edge(2, 3), edge(0, 3), edge(3, 1)]
    ignore(@layout.lane_layout(nodes, edges, dir, options()))
    let into = edges[1].route
    let out = edges[2].route
    assert_not_eq(
      @svg.end_side(into, into.length() - 3, nodes[3]),
      @svg.end_side(out, 0, nodes[3]),
    )
    for p = 3; p < into.length(); p = p + 3 {
      for q = 3; q < out.length(); q = q + 3 {
        let upright = into[p] == into[p - 3] &&
          out[q] == out[q - 3] &&
          into[p] == out[q]
        let level = into[p + 1] == into[p - 2] &&
          out[q + 1] == out[q - 2] &&
          into[p + 1] == out[q + 1]
        let k = if upright { 1 } else { 0 }
        let shared = @util.js_min(
            @util.js_max(into[p + k], into[p - 3 + k]),
            @util.js_max(out[q + k], out[q - 3 + k]),
          ) -
          @util.js_max(
            @util.js_min(into[p + k], into[p - 3 + k]),
            @util.js_min(out[q + k], out[q - 3 + k]),
          )
        if upright || level {
          assert_true(shared <= 0)
        }
      }
    }
  }
}

///|
test "takes a return past the steps between around the margin of its lane" {
  for dir in dirs {
    let nodes = nodes_of([
      (140, 44),
      (140, 44),
      (140, 44),
      (120, 76),
      (140, 44),
      (140, 44),
    ])
    nodes.push(lane_group())
    nodes.push(lane_group())
    nodes.push(lane_group())
    nodes[0].parent = 8
    nodes[1].parent = 8
    nodes[2].parent = 7
    nodes[3].parent = 7
    nodes[4].parent = 6
    nodes[5].parent = 6
    let edges = [
      edge(0, 1),
      edge(1, 2),
      edge(2, 3),
      edge(3, 4, label_w=30, label_h=20),
      edge(4, 5),
      edge(3, 0, label_w=30, label_h=20),
    ]
    ignore(@layout.lane_layout(nodes, edges, dir, options()))
    let across = (c : @layout.CNode) => if sideways(dir) { c.y } else { c.x }
    let along = (c : @layout.CNode) => if sideways(dir) { c.x } else { c.y }
    let depth = (c : @layout.CNode) => if sideways(dir) { c.w } else { c.h }
    assert_true(near(across(nodes[0]), across(nodes[1])))
    assert_true(near(across(nodes[4]), across(nodes[5])))
    let back = edges[5].route
    let sides = [
      @svg.end_side(edges[2].route, edges[2].route.length() - 3, nodes[3]),
      @svg.end_side(edges[3].route, 0, nodes[3]),
      @svg.end_side(back, 0, nodes[3]),
    ]
    assert_eq(distinct(sides), 3)
    assert_not_eq(
      @svg.end_side(back, back.length() - 3, nodes[0]),
      @svg.end_side(edges[0].route, 0, nodes[0]),
    )
    assert_true(square(back))
    for p = 3; p < back.length(); p = p + 3 {
      for i in [1, 2, 4, 5] {
        let (l, t, r, b) = box(nodes[i])
        assert_true(
          @util.js_max(back[p], back[p - 3]) <= l ||
          @util.js_min(back[p], back[p - 3]) >= r ||
          @util.js_max(back[p + 1], back[p - 2]) <= t ||
          @util.js_min(back[p + 1], back[p - 2]) >= b,
        )
      }
    }
    let gap = (a : Int32, b : Int32) => {
      (along(nodes[b]) - along(nodes[a])).abs() -
      (depth(nodes[a]) + depth(nodes[b])) / 2
    }
    assert_true(gap(1, 2) < gap(0, 1))
    assert_true(near(gap(0, 1), 48))
  }
}

///|
test "draws a link asked to be longer at its length beside a handoff" {
  for dir in dirs {
    let nodes = nodes_of([(80, 40), (80, 40), (80, 40), (80, 40)])
    nodes.push(lane_group())
    nodes.push(lane_group())
    nodes[0].parent = 5
    nodes[1].parent = 5
    nodes[2].parent = 5
    nodes[3].parent = 4
    let edges = [{ ..edge(0, 1), minlen: 2, }, edge(1, 2), edge(2, 3)]
    ignore(@layout.lane_layout(nodes, edges, dir, options()))
    let gap = (a : Int32, b : Int32) => {
      if sideways(dir) {
        (nodes[b].x - nodes[a].x).abs() - 80
      } else {
        (nodes[b].y - nodes[a].y).abs() - 40
      }
    }
    assert_true(near(gap(0, 1), 2 * 48))
    assert_true(near(gap(1, 2), 48))
  }
}

///|
test "routes a handoff by where the label of a relation to a lane is" {
  let nodes = nodes_of(Array::make(6, (110, 38)))
  nodes.push(lane_group())
  nodes.push(lane_group())
  nodes[0].parent = 7
  for i in 1..<6 {
    nodes[i].parent = 6
  }
  let edges = [
    edge(0, 1),
    edge(1, 2),
    edge(2, 3),
    edge(3, 4),
    edge(4, 5),
    edge(6, 5, label_w=400, label_h=200),
  ]
  ignore(@layout.lane_layout(nodes, edges, TB, options()))
  let handoff = edges[0].route
  assert_true(handoff.length() > 6)
  assert_true(square(handoff))
  for p = 1; p < handoff.length(); p = p + 3 {
    assert_true((handoff[p] - edges[5].label_y).abs() > 100)
  }
}

///|
/// A graph from pele's lane layout tests: leaves first and lanes after them, as the flowchart graph lists them, with groups inside some lanes.
priv struct LaneSample {
  nodes : Array[@layout.CNode]
  edges : Array[@layout.CEdge]
  lanes : Array[Int32]
  leaves : Array[Int32]
  lane_of : Map[Int32, Int32]
  inner : Array[Int32]
  inner_lane : Array[Int32]
  dir : @layout.Dir
}

///|
fn random_lanes(seed : Int32) -> LaneSample {
  let rnd = random(seed)
  let int = (n : Int32) => (rnd() * n.to_double()).floor().to_int()
  let nodes : Array[@layout.CNode] = []
  let leaves : Array[Int32] = []
  let lane_of : Map[Int32, Int32] = Map([])
  let lanes : Array[Int32] = []
  let leaf_count = 1 + int(30)
  let lane_count = 1 + int(5)
  let inner : Array[Int32] = []
  let inner_lane : Array[Int32] = []
  for i in 0..<leaf_count {
    let w = 30 + int(120)
    let h = 24 + int(60)
    nodes.push(@layout.cnode(w.to_double(), h.to_double()))
    leaves.push(i)
  }
  for _ in 0..<lane_count {
    lanes.push(nodes.length())
    nodes.push(lane_group())
  }
  // The bound is drawn again on every pass, as pele draws it, so that the same random numbers go to the same choices.
  for k = 0; k < int(4); k = k + 1 {
    let lane = lanes[int(lane_count)]
    inner.push(nodes.length())
    inner_lane.push(lane)
    nodes.push(lane_group(parent=lane))
  }
  for i in leaves {
    if inner.length() > 0 && rnd() < 0.25 {
      let g = int(inner.length())
      nodes[i].parent = inner[g]
      lane_of[i] = inner_lane[g]
    } else {
      lane_of[i] = lanes[int(lane_count)]
      nodes[i].parent = lane_of[i]
    }
  }
  let edges : Array[@layout.CEdge] = []
  let count = int(leaf_count * 2)
  for _ in 0..<count {
    let labelled = rnd() < 0.3
    let src = int(leaf_count)
    let dst = int(leaf_count)
    let label_w = if labelled { (20 + int(80)).to_double() } else { 0 }
    edges.push(edge(src, dst, label_w~, label_h=if labelled { 18 } else { 0 }))
  }
  if rnd() < 0.3 {
    edges.push(edge(lanes[0], leaves[0]))
  }
  let dir = dirs[int(4)]
  { nodes, edges, lanes, leaves, lane_of, inner, inner_lane, dir, }
}

///|
fn within(
  inner : (Double, Double, Double, Double),
  outer : (Double, Double, Double, Double),
) -> Bool {
  inner.0 >= outer.0 - 0.01 &&
  inner.2 <= outer.2 + 0.01 &&
  inner.1 >= outer.1 - 0.01 &&
  inner.3 <= outer.3 + 0.01
}

///|
fn apart(
  a : (Double, Double, Double, Double),
  b : (Double, Double, Double, Double),
) -> Bool {
  a.2 <= b.0 + 0.01 ||
  b.2 <= a.0 + 0.01 ||
  a.3 <= b.1 + 0.01 ||
  b.3 <= a.1 + 0.01
}

///|
fn check_random_lanes(lane_pad : Double) -> Unit raise {
  for seed in 1..<=300 {
    let { nodes, edges, lanes, leaves, lane_of, inner, inner_lane, dir, } = random_lanes(
      seed,
    )
    let result = @layout.lane_layout(nodes, edges, dir, options(), lane_pad~)
    let finite = (v : Double) => !v.is_nan() && !v.is_inf()
    let place = "seed \{seed}"
    assert_true(finite(result.width) && finite(result.height), msg=place)
    for c in nodes {
      assert_true(
        finite(c.x) && finite(c.y) && finite(c.w) && finite(c.h),
        msg=place,
      )
    }
    for i in leaves {
      assert_true(
        within(box(nodes[i]), box(nodes[lane_of[i]])),
        msg="\{place}: node \{i} in its lane",
      )
    }
    for k, g in inner {
      if !leaves.iter().any(i => nodes[i].parent == g) {
        continue
      }
      assert_true(
        within(box(nodes[g]), box(nodes[inner_lane[k]])),
        msg="\{place}: group \{g} in its lane",
      )
      for i in leaves {
        if nodes[i].parent == g {
          assert_true(
            within(box(nodes[i]), box(nodes[g])),
            msg="\{place}: node \{i} in its group",
          )
        }
      }
    }
    for a in 0..<leaves.length() {
      for b in (a + 1)..<leaves.length() {
        assert_true(
          apart(box(nodes[leaves[a]]), box(nodes[leaves[b]])),
          msg="\{place}: nodes \{a} and \{b} overlap",
        )
      }
    }
    let whole = (0.0, 0.0, result.width, result.height)
    for a in 0..<lanes.length() {
      assert_true(
        within(box(nodes[lanes[a]]), whole),
        msg="\{place}: lane inside",
      )
      for k in (a + 1)..<lanes.length() {
        assert_true(
          apart(box(nodes[lanes[a]]), box(nodes[lanes[k]])),
          msg="\{place}: lanes overlap",
        )
      }
    }
    for e in edges {
      if e.src == e.dst {
        continue
      }
      assert_true(
        e.route.length() >= 6 && e.route.length() % 3 == 0,
        msg="\{place}: route",
      )
      for v in e.route {
        assert_true(finite(v), msg="\{place}: route value")
      }
      for p = 0; p < e.route.length(); p = p + 3 {
        assert_true(
          e.route[p] >= -0.01 &&
          e.route[p] <= result.width + 0.01 &&
          e.route[p + 1] >= -0.01 &&
          e.route[p + 1] <= result.height + 0.01,
          msg="\{place}: route inside the lanes",
        )
      }
      assert_true(finite(e.label_x) && finite(e.label_y), msg="\{place}: label")
    }
  }
}

///|
test "keeps random graphs well formed with 24 pixels of lane padding" {
  check_random_lanes(24)
}

///|
test "keeps random graphs well formed with 12 pixels of lane padding" {
  check_random_lanes(12)
}

///|
test "gives the same result every time" {
  let a = random_lanes(42)
  let b = random_lanes(42)
  ignore(@layout.lane_layout(a.nodes, a.edges, a.dir, options()))
  ignore(@layout.lane_layout(b.nodes, b.edges, b.dir, options()))
  let boxes = (s : LaneSample) => s.nodes.map(c => [c.x, c.y, c.w, c.h])
  assert_eq(boxes(a), boxes(b))
  assert_eq(a.edges.map(e => e.route), b.edges.map(e => e.route))
}
