///|
/// The way a diagram's ranks run.
pub(all) enum Dir {
  TB
  BT
  LR
  RL
}

///|
/// A node or group of a graph whose nodes may be nested in groups.
pub(all) struct CNode {
  mut w : Double
  mut h : Double
  mut parent : Int32
  mut is_group : Bool
  mut dir : Dir?
  mut pad_x : Double
  mut pad_top : Double
  mut pad_bottom : Double
  mut min_w : Double
  /// Declaration order; a group takes the smallest value among its members.
  mut seq : Double
  /// How much of a side its edges may spread along, measured across the flow; 0 keeps them at its middle.
  mut span : Double
  mut x : Double
  mut y : Double
}

///|
/// An edge of a compound graph, and where the layout routes it.
pub(all) struct CEdge {
  mut src : Int32
  mut dst : Int32
  minlen : Int32
  label_w : Double
  label_h : Double
  /// x, y, axis triples; axis is 0 where the edge runs vertically into the point, 1 horizontally.
  mut route : Array[Double]
  mut label_x : Double
  mut label_y : Double
}

///|
/// A node of the given size, in `parent` or at the top level for -1.
pub fn cnode(w : Double, h : Double, parent~ : Int32 = -1) -> CNode {
  {
    w,
    h,
    parent,
    is_group: false,
    dir: None,
    pad_x: 0,
    pad_top: 0,
    pad_bottom: 0,
    min_w: 0,
    seq: 0,
    span: 0,
    x: 0,
    y: 0,
  }
}

///|
/// The size of a laid out compound graph.
pub(all) struct CompoundResult {
  width : Double
  height : Double
}

///|
/// Moves a laid out graph by `ox` across and `oy` down.
pub fn shift_layout(
  nodes : Array[CNode],
  edges : Array[CEdge],
  ox : Double,
  oy : Double,
) -> Unit {
  for c in nodes {
    c.x += ox
    c.y += oy
  }
  for e in edges {
    let mut k = 0
    while k < e.route.length() {
      e.route[k] += ox
      e.route[k + 1] += oy
      k += 3
    }
    e.label_x += ox
    e.label_y += oy
  }
}

///|
/// The direction a diagram names, or top to bottom for anything else.
pub fn direction(dir : String?) -> Dir {
  match dir {
    Some("BT") => BT
    Some("LR") => LR
    Some("RL") => RL
    _ => TB
  }
}

///|
/// Lays out a graph whose nodes may be nested in groups, writing node centers and sizes into `nodes` and routes and label centers into `edges`.
/// Each group is laid out on its own, in its own direction, and then placed in its parent as a single box.
/// An edge that crosses a group's border passes through a port on the side facing its other end.
pub fn compound_layout(
  nodes : Array[CNode],
  edges : Array[CEdge],
  root_dir : Dir,
  opt : LayeredOptions,
) -> CompoundResult {
  let n = nodes.length()
  let level_of : Map[Int32, Level] = Map([])
  let order : Array[Level] = []
  let make_level = fn(id : Int32, dir : Dir) -> Level {
    let level : Level = {
      id,
      dir,
      items: [],
      edges: [],
      ports: [],
      port_of: Map([]),
      routes: Map([]),
      x: 0,
      y: 0,
    }
    level_of[id] = level
    level
  }
  let level_at = fn(id : Int32) -> Level { level_of.get(id).unwrap() }
  let root = make_level(-1, root_dir)
  let children : Array[Array[Int32]] = Array::makei(n, _ => [])
  let root_items = []
  for i in 0..<n {
    let p = nodes[i].parent
    if p >= 0 && p < n && p != i && nodes[p].is_group {
      children[p].push(i)
    } else {
      nodes[i].parent = -1
      root_items.push(i)
    }
  }
  root.items = root_items
  order.push(root)
  let depth = FixedArray::make(n, 0)
  let placed = FixedArray::make(n, false)
  let descend = fn(from : Int32) {
    let mut q = from
    while q < order.length() {
      let level = order[q]
      for item in level.items {
        placed[item] = true
        depth[item] = if level.id < 0 { 0 } else { depth[level.id] + 1 }
        if nodes[item].is_group {
          let child = make_level(item, nodes[item].dir.unwrap_or(level.dir))
          child.items = children[item]
          order.push(child)
        }
      }
      q += 1
    }
  }
  descend(0)
  // Groups that contain each other are unreachable from the root, so they are lifted out.
  for i in 0..<n {
    if placed[i] {
      continue
    }
    let former = nodes[i].parent
    children[former] = children[former].filter(c => c != i)
    nodes[i].parent = -1
    root.items.push(i)
    placed[i] = true
    depth[i] = 0
    if nodes[i].is_group {
      let from = order.length()
      let child = make_level(i, nodes[i].dir.unwrap_or(root_dir))
      child.items = children[i]
      order.push(child)
      descend(from)
    }
  }
  for q = order.length() - 1; q > 0; q = q - 1 {
    let level = order[q]
    let mut seq = @double.infinity
    for item in level.items {
      if nodes[item].seq < seq {
        seq = nodes[item].seq
      }
    }
    if seq != @double.infinity {
      nodes[level.id].seq = seq
    }
  }
  for level in order {
    sort_array(level.items, fn(a, b) {
      or_else(nodes[a].seq - nodes[b].seq, (a - b).to_double())
    })
  }

  // Every group border an edge crosses costs a port.
  // Past the budget, an edge is drawn between the groups that hold its ends, at the level they share.
  let mut ports = 0
  for e in edges {
    let mut a = e.src
    let mut b = e.dst
    let mut crossed = 0
    while depth[a] > depth[b] {
      a = nodes[a].parent
      crossed += 1
    }
    while depth[b] > depth[a] {
      b = nodes[b].parent
      crossed += 1
    }
    while a != b && nodes[a].parent != nodes[b].parent {
      a = nodes[a].parent
      b = nodes[b].parent
      crossed += 2
    }
    if a == b {
      continue
    }
    if ports + crossed > max_ports {
      e.src = a
      e.dst = b
    } else {
      ports += crossed
    }
  }
  let loops : Array[Int32] = []
  let stray : Array[Int32] = []
  for ei in 0..<edges.length() {
    let e = edges[ei]
    e.route = []
    if e.src == e.dst {
      loops.push(ei)
      continue
    }
    let mut a = e.src
    let mut b = e.dst
    let a_path : Array[Int32] = []
    let b_path : Array[Int32] = []
    while depth[a] > depth[b] {
      a_path.push(a)
      a = nodes[a].parent
    }
    while depth[b] > depth[a] {
      b_path.push(b)
      b = nodes[b].parent
    }
    if a == b {
      stray.push(ei)
      continue
    }
    while nodes[a].parent != nodes[b].parent {
      a_path.push(a)
      b_path.push(b)
      a = nodes[a].parent
      b = nodes[b].parent
    }
    level_at(nodes[a].parent).edges.push({ e: ei, a, b, })
    for path_out in [(a_path, true), (b_path, false)] {
      let (path, out) = path_out
      for inner in path {
        let level = level_at(nodes[inner].parent)
        let port : PortEdge = {
          e: ei,
          inner,
          out,
          side: side_top,
          hint: @double.not_a_number,
          px: 0,
          py: 0,
          route: [],
        }
        level.ports.push(port)
        level.port_of[ei * 2 + (if out { 0 } else { 1 })] = port
      }
    }
  }
  let item_index = FixedArray::make(n, 0)
  let endpoint_below = fn(item : Int32, e : CEdge, out : Bool) {
    (if out { e.src } else { e.dst }) != item
  }
  let port_below = fn(item : Int32, ei : Int32, out : Bool) {
    level_at(item).port_of.get(ei * 2 + (if out { 0 } else { 1 })).unwrap()
  }
  let key = FixedArray::make(n, @double.not_a_number)
  let mut keyed = false
  let mut far_hint : ((Level, PortEdge) -> Double)? = None
  let build = fn(level : Level, sized : Bool) {
    let vertical = is_vertical(level.dir)
    let start = start_side(level.dir)
    let lnodes : Array[LNode] = []
    let ledges : Array[LEdge] = []
    for i, item in level.items {
      item_index[item] = i
      let node = nodes[item]
      let ln = if sized {
        lnode(
          if vertical {
            node.w
          } else {
            node.h
          },
          if vertical {
            node.h
          } else {
            node.w
          },
        )
      } else {
        lnode(0, 0)
      }
      ln.span = if node.is_group {
        @util.js_min(node.span, ln.w - 2 * node.pad_x)
      } else {
        node.span
      }
      ln.key = if keyed { key[item] } else { @double.not_a_number }
      lnodes.push(ln)
    }
    let held = fn(item : Int32, ei : Int32, out : Bool) {
      nodes[item].is_group && endpoint_below(item, edges[ei], out)
    }
    let offset = fn(item : Int32, ei : Int32, out : Bool) {
      if !sized ||
        !nodes[item].is_group ||
        !endpoint_below(item, edges[ei], out) {
        return 0.0
      }
      let port = port_below(item, ei, out)
      if vertical {
        port.px - nodes[item].w / 2
      } else {
        port.py - nodes[item].h / 2
      }
    }
    for le in level.edges {
      let e = edges[le.e]
      let edge = ledge(item_index[le.a], item_index[le.b], minlen=e.minlen)
      if sized {
        edge.label_w = if vertical { e.label_w } else { e.label_h }
        edge.label_h = if vertical { e.label_h } else { e.label_w }
        edge.tail_dx = offset(le.a, le.e, true)
        edge.head_dx = offset(le.b, le.e, false)
        edge.tail_fixed = held(le.a, le.e, true)
        edge.head_fixed = held(le.b, le.e, false)
      }
      ledges.push(edge)
    }
    let dummies = FixedArray::make(level.ports.length(), -1)
    for i, port in level.ports {
      if port.side == start || port.side == opposite(start) {
        let d = lnodes.length()
        let ln = lnode(
          0,
          0,
          kind=if port.side == start { StartPort } else { EndPort },
        )
        ln.key = if keyed {
          key[if port.out { edges[port.e].dst } else { edges[port.e].src }]
        } else {
          @double.not_a_number
        }
        ln.hint = match far_hint {
          Some(far) if port.hint.is_nan() && keyed => far(level, port)
          _ => port.hint
        }
        lnodes.push(ln)
        dummies[i] = d
        let edge = if port.out {
          ledge(item_index[port.inner], d)
        } else {
          ledge(d, item_index[port.inner])
        }
        if port.out {
          edge.tail_dx = offset(port.inner, port.e, true)
          edge.tail_fixed = held(port.inner, port.e, true)
        } else {
          edge.head_dx = offset(port.inner, port.e, false)
          edge.head_fixed = held(port.inner, port.e, false)
        }
        ledges.push(edge)
      } else {
        lnodes[item_index[port.inner]].pin = if port.side == side_top ||
          port.side == side_left {
          -1
        } else {
          1
        }
      }
    }
    (lnodes, ledges, dummies)
  }
  let ordered = ports > 1 &&
    ports <= max_ordered_ports &&
    edges.length() <= max_ordered_edges

  // A flat layout coordinates node and port order across groups.
  let mut flat_crossings = 0
  let mut flat = order.length() > 1 && ordered
  for level in order {
    if !same_dir(level.dir, root_dir) {
      flat = false
    }
  }
  if flat {
    let vertical = is_vertical(root_dir)
    let leaf = FixedArray::make(n, -1)
    let group = FixedArray::make(n, -1)
    let lnodes : Array[LNode] = []
    let of_ : Array[Int32] = []
    let parent : Array[Int32] = []
    for i in 0..<n {
      if !nodes[i].is_group {
        continue
      }
      group[i] = parent.length()
      parent.push(-1)
    }
    for i in 0..<n {
      let p = nodes[i].parent
      if nodes[i].is_group {
        parent[group[i]] = if p >= 0 { group[p] } else { -1 }
      } else {
        leaf[i] = lnodes.length()
        lnodes.push(
          lnode(
            if vertical {
              nodes[i].w
            } else {
              nodes[i].h
            },
            if vertical {
              nodes[i].h
            } else {
              nodes[i].w
            },
          ),
        )
        of_.push(if p >= 0 { group[p] } else { -1 })
      }
    }
    let ledges : Array[LEdge] = []
    let ledge_of = FixedArray::make(edges.length(), -1)
    for ei, e in edges {
      if e.src == e.dst || leaf[e.src] < 0 || leaf[e.dst] < 0 {
        continue
      }
      ledge_of[ei] = ledges.length()
      ledges.push(
        ledge(
          leaf[e.src],
          leaf[e.dst],
          minlen=e.minlen,
          label_w=if vertical { e.label_w } else { e.label_h },
          label_h=if vertical { e.label_h } else { e.label_w },
        ),
      )
    }
    let flat_layout = layered(lnodes, ledges, {
      ..opt,
      groups: Some({ of: of_, parent, }),
      order_only: true,
    })
    flat_crossings = if flat_layout.crossings < flat_layout.declared {
      flat_layout.crossings
    } else {
      flat_layout.declared
    }
    let sum = FixedArray::make(n, 0.0)
    let count = FixedArray::make(n, 0)
    // The last rank each group occupies.
    let last = FixedArray::make(n, -1)
    for i in 0..<n {
      if leaf[i] < 0 {
        continue
      }
      key[i] = lnodes[leaf[i]].x
      let mut p = nodes[i].parent
      while p >= 0 {
        sum[p] += key[i]
        count[p] += 1
        if lnodes[leaf[i]].rank > last[p] {
          last[p] = lnodes[leaf[i]].rank
        }
        p = nodes[p].parent
      }
    }
    for i in 0..<n {
      if count[i] > 0 {
        key[i] = sum[i] / count[i].to_double()
      }
    }
    // Outgoing ports at the group's last rank are ordered by where their edges are there, ties broken by the next rank.
    far_hint = Some(fn(level : Level, port : PortEdge) {
      let le = ledge_of[port.e]
      if le < 0 ||
        level.id < 0 ||
        !port.out ||
        port.side != opposite(start_side(level.dir)) {
        return @double.not_a_number
      }
      let points = ledges[le].points
      let mut inside = key[edges[port.e].src]
      let mut outside = 0.0
      let mut k = 0
      while k < points.length() {
        if points[k] == last[level.id].to_double() {
          inside = points[k + 1]
        }
        if points[k] == (last[level.id] + 1).to_double() {
          outside = points[k + 1]
        }
        k += 2
      }
      inside + outside * 1.0e-6
    })
  }

  // Unchanged levels are reused across layout attempts.
  let laid : Map[Int32, Array[LaidOut]] = Map([])
  let lay_out = fn(
    level : Level,
    lnodes : Array[LNode],
    ledges : Array[LEdge],
  ) -> LaidOut {
    if !ordered {
      return { given: [], lnodes, ledges, size: layered(lnodes, ledges, opt), }
    }
    let given = describe(lnodes, ledges)
    let past = match laid.get(level.id) {
      Some(past) => past
      None => {
        let past = []
        laid[level.id] = past
        past
      }
    }
    for p in past {
      if same_values(p.given, given) {
        return p
      }
    }
    let done = { given, lnodes, ledges, size: layered(lnodes, ledges, opt), }
    past.push(done)
    done
  }
  let mut total : CompoundResult = { width: 0, height: 0, }
  let place = fn() {
    // Parents are ranked first to determine which group sides edges cross.
    for level in order {
      for port in level.ports {
        if nodes[port.inner].is_group &&
          endpoint_below(port.inner, edges[port.e], port.out) {
          port_below(port.inner, port.e, port.out).side = port.side
        }
      }
      if level.edges.length() == 0 {
        continue
      }
      let mut needed = false
      for le in level.edges {
        let e = edges[le.e]
        if (nodes[le.a].is_group && e.src != le.a) ||
          (nodes[le.b].is_group && e.dst != le.b) {
          needed = true
        }
      }
      if !needed {
        continue
      }
      let (lnodes, ledges, _) = build(level, false)
      orient(lnodes, ledges)
      rank(lnodes, ledges, 1)
      let start = start_side(level.dir)
      for i, le in level.edges {
        let e = edges[le.e]
        let a_above = !ledges[i].reversed
        if nodes[le.a].is_group && e.src != le.a {
          port_below(le.a, le.e, true).side = if a_above {
            opposite(start)
          } else {
            start
          }
        }
        if nodes[le.b].is_group && e.dst != le.b {
          port_below(le.b, le.e, false).side = if a_above {
            start
          } else {
            opposite(start)
          }
        }
      }
    }

    // Children are laid out first so that their sizes are known.
    for q = order.length() - 1; q >= 0; q = q - 1 {
      let level = order[q]
      let group = if level.id >= 0 { Some(nodes[level.id]) } else { None }
      let vertical = is_vertical(level.dir)
      let flip = level.dir is (BT | RL)
      let (built_nodes, built_edges, dummies) = build(level, true)
      let { lnodes, ledges, size, .. } = lay_out(
        level, built_nodes, built_edges,
      )
      let content_w = if vertical { size.width } else { size.height }
      let content_h = if vertical { size.height } else { size.width }
      let pad_x = match group {
        Some(group) => group.pad_x
        None => 0
      }
      let pad_top = match group {
        Some(group) => group.pad_top
        None => 0
      }
      let box_w = @util.js_max(
        content_w + 2 * pad_x,
        match group {
          Some(group) => group.min_w
          None => 0
        },
      )
      let box_h = content_h +
        pad_top +
        (match group {
          Some(group) => group.pad_bottom
          None => 0
        })
      let off_x = (box_w - content_w) / 2
      let off_y = pad_top
      let tx = fn(lx : Double, ly : Double) {
        off_x +
        (if vertical { lx } else if flip { size.height - ly } else { ly })
      }
      let ty = fn(lx : Double, ly : Double) {
        off_y +
        (if vertical { if flip { size.height - ly } else { ly } } else { lx })
      }
      let axis = if vertical { 0.0 } else { 1.0 }
      let convert = fn(points : Array[Double]) {
        let out = []
        let mut i = 0
        while i < points.length() {
          out.push(tx(points[i], points[i + 1]))
          out.push(ty(points[i], points[i + 1]))
          out.push(axis)
          i += 2
        }
        out
      }
      for i, item in level.items {
        nodes[item].x = tx(lnodes[i].x, lnodes[i].y)
        nodes[item].y = ty(lnodes[i].x, lnodes[i].y)
      }
      for i, le in level.edges {
        let edge = ledges[i]
        level.routes[le.e] = convert(edge.points)
        let e = edges[le.e]
        if e.label_w > 0 {
          e.label_x = tx(edge.label_x, edge.label_y)
          e.label_y = ty(edge.label_x, edge.label_y)
        }
      }
      let mut k = level.edges.length()
      for i, port in level.ports {
        let item = nodes[port.inner]
        if dummies[i] >= 0 {
          let route = convert(ledges[k].points)
          k += 1
          let at = if port.out { route.length() - 3 } else { 0 }
          let mut bx = route[at]
          let mut by = route[at + 1]
          if port.side == side_top {
            by = 0
          } else if port.side == side_bottom {
            by = box_h
          } else if port.side == side_left {
            bx = 0
          } else {
            bx = box_w
          }
          if port.out {
            route.push(bx)
            route.push(by)
            route.push(axis)
          } else {
            route.insert(0, axis)
            route.insert(0, by)
            route.insert(0, bx)
          }
          port.px = bx
          port.py = by
          port.route = route
          continue
        }
        let mut ix = item.x
        let mut iy = item.y
        if item.is_group && endpoint_below(port.inner, edges[port.e], port.out) {
          let inner = port_below(port.inner, port.e, port.out)
          ix += inner.px - item.w / 2
          iy += inner.py - item.h / 2
        } else if port.side == side_top {
          iy -= item.h / 2
        } else if port.side == side_bottom {
          iy += item.h / 2
        } else if port.side == side_left {
          ix -= item.w / 2
        } else {
          ix += item.w / 2
        }
        let mut bx = ix
        let mut by = iy
        if port.side == side_top {
          by = 0
        } else if port.side == side_bottom {
          by = box_h
        } else if port.side == side_left {
          bx = 0
        } else {
          bx = box_w
        }
        let a = if port.side == side_top || port.side == side_bottom {
          0.0
        } else {
          1.0
        }
        port.px = bx
        port.py = by
        port.route = if port.out {
          [ix, iy, a, bx, by, a]
        } else {
          [bx, by, a, ix, iy, a]
        }
      }
      match group {
        Some(group) => {
          group.w = box_w
          group.h = box_h
        }
        None => total = { width: box_w, height: box_h, }
      }
    }
    for level in order {
      let ox = level.x
      let oy = level.y
      for item in level.items {
        let node = nodes[item]
        node.x += ox
        node.y += oy
        if node.is_group {
          let child = level_at(item)
          child.x = node.x - node.w / 2
          child.y = node.y - node.h / 2
        }
      }
    }
    let append = fn(
      route : Array[Double],
      part : Array[Double],
      ox : Double,
      oy : Double,
    ) {
      let mut i = 0
      while i < part.length() {
        let x = part[i] + ox
        let y = part[i + 1] + oy
        let len = route.length()
        if !(len >= 3 &&
          (route[len - 3] - x).abs() < 0.01 &&
          (route[len - 2] - y).abs() < 0.01) {
          route.push(x)
          route.push(y)
          route.push(part[i + 2])
        }
        i += 3
      }
    }
    for level in order {
      for le in level.edges {
        let e = edges[le.e]
        let route = []
        let outward : Array[Level] = []
        let mut item = e.src
        while nodes[item].parent != level.id {
          outward.push(level_at(nodes[item].parent))
          item = nodes[item].parent
        }
        for lv in outward {
          append(route, lv.port_of.get(le.e * 2).unwrap().route, lv.x, lv.y)
        }
        append(route, level.routes.get(le.e).unwrap(), level.x, level.y)
        let inward : Array[Level] = []
        let mut item = e.dst
        while nodes[item].parent != level.id {
          inward.push(level_at(nodes[item].parent))
          item = nodes[item].parent
        }
        for i = inward.length() - 1; i >= 0; i = i - 1 {
          append(
            route,
            inward[i].port_of.get(le.e * 2 + 1).unwrap().route,
            inward[i].x,
            inward[i].y,
          )
        }
        e.route = route
        if e.label_w > 0 {
          e.label_x += level.x
          e.label_y += level.y
        }
      }
    }
  }
  // The flat layout ignores group boxes, so ordering each group on its own may cross less.
  let style = style_of(opt)
  keyed = flat
  place()
  let mut crossings = -1
  if flat {
    crossings = route_crossings(nodes, edges, style~)
    if crossings.to_double() >
      flat_crossings.to_double() * flat_slack + flat_spare {
      let first = Snapshot::take(nodes, edges, order, total)
      keyed = false
      place()
      let own = route_crossings(nodes, edges, style~)
      if own >= crossings {
        keyed = true
        total = first.restore(nodes, edges, order)
      } else {
        crossings = own
      }
    }
  }

  // Port order is refined from the routes outside each group.
  // This is skipped if ordering each group on its own won, since it rarely helps enough to justify another layout.
  if keyed == flat && ordered {
    let mut again = false
    for level in order {
      if level.id < 0 {
        continue
      }
      let box = nodes[level.id]
      let vertical = is_vertical(level.dir)
      let end = opposite(start_side(level.dir))
      let seen : Array[(Double, Double)] = []
      for port in level.ports {
        if port.side != end {
          continue
        }
        // The straight run out of the port is skipped to find where the edge turns.
        let route = edges[port.e].route
        let bx = level.x + port.px
        let by = level.y + port.py
        let mut at = -1
        let mut k = 0
        while k < route.length() && (at < 0 || port.out) {
          if (route[k] - bx).abs() < 0.01 && (route[k + 1] - by).abs() < 0.01 {
            at = k
          }
          k += 3
        }
        if at < 0 {
          continue
        }
        let a = if vertical { 0 } else { 1 }
        let step = if port.out { 3 } else { -3 }
        let mut next = at + step
        while next >= 0 &&
              next < route.length() &&
              (route[next + a] - route[at + a]).abs() < in_line {
          next += step
        }
        if next < 0 || next >= route.length() {
          continue
        }
        port.hint = route[next + a] -
          (if vertical { box.x - box.w / 2 } else { box.y - box.h / 2 })
        seen.push((if vertical { port.px } else { port.py }, port.hint))
      }
      sort_array(seen, fn(p, q) { p.0 - q.0 })
      for i in 1..<seen.length() {
        if seen[i - 1].1 > seen[i].1 {
          again = true
        }
      }
    }
    if again {
      let before = if crossings >= 0 {
        crossings
      } else {
        route_crossings(nodes, edges, style~)
      }
      if before > 0 {
        let first = Snapshot::take(nodes, edges, order, total)
        place()
        if route_crossings(nodes, edges, style~) >= before {
          total = first.restore(nodes, edges, order)
        }
      }
    }
  }
  for ei in stray {
    let e = edges[ei]
    let a = nodes[e.src]
    let b = nodes[e.dst]
    e.route = [a.x, a.y, 0, b.x, b.y, 0]
    e.label_x = (a.x + b.x) / 2
    e.label_y = (a.y + b.y) / 2
  }
  for ei in loops {
    let e = edges[ei]
    let node = nodes[e.src]
    e.label_x = node.x + node.w / 2 + 28 + e.label_w / 2
    e.label_y = node.y
  }
  total
}

///|
let max_ports = 40000

///|
/// Repeated layouts are limited to small graphs.
let max_ordered_ports = 400

///|
let max_ordered_edges = 500

///|
/// How many more crossings than the flat drawing had the grouped one may have before each group is ordered on its own instead.
let flat_slack = 1.5

///|
let flat_spare = 4.0

///|
/// A level's layout, kept with what it was given so that the same level laid out again with the same input can reuse it.
priv struct LaidOut {
  given : Array[Double]
  lnodes : Array[LNode]
  ledges : Array[LEdge]
  size : LayeredResult
}

///|
fn describe(lnodes : Array[LNode], ledges : Array[LEdge]) -> Array[Double] {
  let given = []
  for ln in lnodes {
    given.push(ln.w)
    given.push(ln.h)
    given.push(ln.kind.ordinal().to_double())
    given.push(ln.pin.to_double())
    given.push(ln.hint)
    given.push(ln.key)
    given.push(ln.span)
  }
  let flag = fn(b : Bool) { if b { 1.0 } else { 0.0 } }
  for le in ledges {
    given.push(le.tail.to_double())
    given.push(le.head.to_double())
    given.push(le.minlen.to_double())
    given.push(le.label_w)
    given.push(le.label_h)
    given.push(le.tail_dx)
    given.push(le.head_dx)
    given.push(flag(le.tail_fixed))
    given.push(flag(le.head_fixed))
  }
  given
}

///|
/// Whether two lists hold the same values as `Object.is` tells them apart: NaN is NaN, and 0 is not -0.
fn same_values(a : Array[Double], b : Array[Double]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i in 0..<a.length() {
    let x = a[i]
    let y = b[i]
    let same = if x.is_nan() {
      y.is_nan()
    } else {
      x == y && (x != 0.0 || 1.0 / x == 1.0 / y)
    }
    if !same {
      return false
    }
  }
  true
}
