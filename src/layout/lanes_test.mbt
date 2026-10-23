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
