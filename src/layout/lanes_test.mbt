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
