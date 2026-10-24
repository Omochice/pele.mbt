///|
fn group(seq : Double) -> @layout.CNode {
  let node = @layout.cnode(0, 0)
  node.is_group = true
  node.pad_x = 20
  node.pad_top = 40
  node.pad_bottom = 20
  node.span = @double.infinity
  node.seq = seq
  node
}

///|
/// Issue #3 of pele: two chains in separate groups feed a store in a third group.
fn fan_in() -> (Array[@layout.CNode], Array[@layout.CEdge]) {
  let nodes = [
    group(100),
    group(101),
    group(102),
    @layout.cnode(80, 60, parent=2),
  ]
  let edges = []
  for g in [0, 1] {
    for i in 0..<5 {
      let v = nodes.length()
      nodes.push(@layout.cnode(40, 40, parent=g))
      nodes[v].seq = v.to_double()
      if i > 0 {
        edges.push(edge(v - 1, v))
      }
      edges.push(edge(v, 3))
    }
  }
  (nodes, edges)
}

///|
test "does not count the edges of a fan into a store in another group as crossing on tracks" {
  let (nodes, edges) = fan_in()
  ignore(@layout.compound_layout(nodes, edges, TB, options(tracks=true)))
  assert_eq(@layout.route_crossings(nodes, edges), 0)
}

///|
test "crosses the edges of a fan into a store in another group a few times at most with curves" {
  let (nodes, edges) = fan_in()
  ignore(@layout.compound_layout(nodes, edges, TB, options()))
  assert_true(@layout.route_crossings(nodes, edges, style=Curved) <= 4)
}

///|
test "orders the ports on the far side of a group by where their edges go, so that a fan into one node does not cross between groups" {
  for dir in [@layout.Dir::TB, LR] {
    let nodes = [
      group(100),
      group(101),
      group(102),
      @layout.cnode(80, 40, parent=2),
    ]
    let edges = []
    for g in [0, 1] {
      for i in 0..<5 {
        let v = nodes.length()
        nodes.push(@layout.cnode(100, 40, parent=g))
        if i > 0 {
          edges.push(edge(v - 1, v))
        }
        edges.push(edge(v, 3))
      }
    }
    for i, node in nodes {
      if node.is_group {
        continue
      }
      node.seq = i.to_double()
      node.span = 72
    }
    ignore(@layout.compound_layout(nodes, edges, dir, options()))
    let at = fn(e : @layout.CEdge, g : Int32) {
      let mut k = 0
      while k < e.route.length() {
        if on_border(nodes[g], e.route[k], e.route[k + 1]) {
          return e.route[k + (if dir is TB { 0 } else { 1 })]
        }
        k += 3
      }
      @double.not_a_number
    }
    let fan = edges.filter(e => e.dst == 3)
    let leave = fan.map(e => at(e, nodes[e.src].parent))
    let enter = fan.map(e => at(e, 2))
    let sign = fn(x : Double) { if x > 0 { 1 } else if x < 0 { -1 } else { 0 } }
    for i in 0..<fan.length() {
      assert_false(leave[i].is_nan() || enter[i].is_nan())
      for j in (i + 1)..<fan.length() {
        assert_eq(sign(leave[i] - leave[j]), sign(enter[i] - enter[j]))
      }
    }
  }
}

///|
test "orders the nodes of a row of groups as one drawing, so that the edges between them do not cross" {
  let nodes = [group(100), group(101), group(102)]
  let stage = fn(g : Int32) {
    Array::makei(5, _ => {
      nodes.push(@layout.cnode(80, 40, parent=g))
      nodes[nodes.length() - 1].seq = nodes.length().to_double()
      nodes.length() - 1
    })
  }
  let a = stage(0)
  let b = stage(1)
  let c = stage(2)
  let edges = []
  for i, j in [4, 2, 0, 3, 1] {
    edges.push(edge(a[i], b[j]))
  }
  for i, j in [1, 3, 0, 4, 2] {
    edges.push(edge(b[i], c[j]))
  }
  ignore(@layout.compound_layout(nodes, edges, LR, options()))
  assert_eq(@layout.route_crossings(nodes, edges), 0)
}

///|
/// Pele's random compound graph: groups nested at random, leaves of random sizes in them, and random edges, some labelled.
/// Every other graph lets edges spread along the sides of its nodes.
fn random_graph(
  seed : Int32,
) -> (Array[@layout.CNode], Array[@layout.CEdge], @layout.Dir) {
  let rnd = random(seed)
  let int = fn(n : Int32) { (rnd() * n.to_double()).floor().to_int() }
  let nodes = []
  let groups = []
  let group_count = int(5)
  for g in 0..<group_count {
    let parent = if groups.length() > 0 && rnd() < 0.4 {
      groups[int(groups.length())]
    } else {
      -1
    }
    let node = @layout.cnode(0, 0, parent~)
    node.is_group = true
    node.pad_x = 20
    node.pad_top = 40
    node.pad_bottom = 20
    node.min_w = 60
    node.dir = if rnd() < 0.3 { Some(dirs[int(4)]) } else { None }
    node.seq = (1000 + g).to_double()
    if seed % 2 == 0 {
      node.span = @double.infinity
    }
    groups.push(nodes.length())
    nodes.push(node)
  }
  let leaves = 3 + int(30)
  for i in 0..<leaves {
    let parent = if groups.length() > 0 && rnd() < 0.5 {
      groups[int(groups.length())]
    } else {
      -1
    }
    let w = (30 + int(120)).to_double()
    let h = (30 + int(50)).to_double()
    let node = @layout.cnode(w, h, parent~)
    node.seq = i.to_double()
    if seed % 2 == 0 {
      node.span = (if node.w < node.h { node.w } else { node.h }) - 24
    }
    nodes.push(node)
  }
  let edges = []
  let count = int(leaves * 2)
  for _ in 0..<count {
    let labelled = rnd() < 0.3
    let src = int(nodes.length())
    let dst = int(nodes.length())
    let label_w = if labelled { (20 + int(60)).to_double() } else { 0 }
    edges.push(edge(src, dst, label_w~, label_h=if labelled { 24 } else { 0 }))
  }
  (nodes, edges, dirs[int(4)])
}

///|
fn is_ancestor(nodes : Array[@layout.CNode], a : Int32, b : Int32) -> Bool {
  let mut p = nodes[b].parent
  while p >= 0 {
    if p == a {
      return true
    }
    p = nodes[p].parent
  }
  false
}

///|
fn finite(x : Double) -> Bool {
  !x.is_nan() && !x.is_inf()
}

///|
test "keeps random graphs well formed" {
  for seed in 1..<=300 {
    let (nodes, edges, dir) = random_graph(seed)
    let size = @layout.compound_layout(nodes, edges, dir, options())
    assert_true(finite(size.width) && finite(size.height))
    for node in nodes {
      assert_true(finite(node.x) && finite(node.y))
      assert_true(node.x - node.w / 2 >= -0.5)
      assert_true(node.y - node.h / 2 >= -0.5)
      assert_true(node.x + node.w / 2 <= size.width + 0.5)
      assert_true(node.y + node.h / 2 <= size.height + 0.5)
      if node.parent >= 0 {
        let parent = nodes[node.parent]
        assert_true(
          (node.x - parent.x).abs() + node.w / 2 <= parent.w / 2 + 0.5,
        )
        assert_true(
          (node.y - parent.y).abs() + node.h / 2 <= parent.h / 2 + 0.5,
        )
      }
    }
    for a in 0..<nodes.length() {
      for b in (a + 1)..<nodes.length() {
        if nodes[a].parent != nodes[b].parent {
          continue
        }
        let overlap_x = (nodes[a].w + nodes[b].w) / 2 -
          (nodes[a].x - nodes[b].x).abs()
        let overlap_y = (nodes[a].h + nodes[b].h) / 2 -
          (nodes[a].y - nodes[b].y).abs()
        assert_false(overlap_x > 0.5 && overlap_y > 0.5)
      }
    }
    for e in edges {
      if e.src == e.dst {
        continue
      }
      assert_eq(e.route.length() % 3, 0)
      assert_true(e.route.length() >= 6)
      for value in e.route {
        assert_true(finite(value))
      }
      if is_ancestor(nodes, e.src, e.dst) || is_ancestor(nodes, e.dst, e.src) {
        continue
      }
      let last = e.route.length() - 3
      assert_true(on_border(nodes[e.src], e.route[0], e.route[1]))
      assert_true(on_border(nodes[e.dst], e.route[last], e.route[last + 1]))
    }
  }
}

///|
test "is deterministic" {
  for seed in 1..<=40 {
    let (first_nodes, first_edges, first_dir) = random_graph(seed)
    let (second_nodes, second_edges, second_dir) = random_graph(seed)
    ignore(
      @layout.compound_layout(first_nodes, first_edges, first_dir, options()),
    )
    ignore(
      @layout.compound_layout(second_nodes, second_edges, second_dir, options()),
    )
    let places = fn(nodes : Array[@layout.CNode]) {
      nodes.map(n => [n.x, n.y, n.w, n.h])
    }
    assert_eq(places(second_nodes), places(first_nodes))
    assert_eq(second_edges.map(e => e.route), first_edges.map(e => e.route))
  }
}
