// Grid placement.
// Mermaid hands the edge sides to a force-directed solver as relative placement constraints.
// Pele applies them directly: every service and junction takes a cell, an edge `a:R -- L:b` puts b in the cell to the right of a, and a group is a solid rectangle of cells, so a group never encloses a node that is not in it.
// Each container (the diagram, then every group) is laid out on its own, innermost first, and a finished group is placed in its parent as one block.

///|
/// Cells of the nodes and groups, in the order they were passed in.
/// A parent is a group's index, or -1 for the diagram itself.
pub(all) struct Grid {
  col : Array[Int32]
  row : Array[Int32]
  group_col : Array[Int32]
  group_row : Array[Int32]
  /// The size of each group in cells.
  /// A group with nothing in it takes one cell.
  group_cols : Array[Int32]
  group_rows : Array[Int32]
  group_parent : Array[Int32]
  group_empty : Array[Bool]
  node_parent : Array[Int32]
}

///|
let dir_x : Array[Int32] = [-1, 1, 0, 0]

///|
let dir_y : Array[Int32] = [0, 0, -1, 1]

///|
/// The index of a side into the direction tables: left, right, top, bottom.
pub fn Side::index(self : Side) -> Int32 {
  match self {
    L => 0
    R => 1
    T => 2
    B => 3
  }
}

///|
/// Blocks up to this many cells are found through the cell map; larger ones are compared one by one.
const SMALL : Int32 = 64

///|
const OFFSET : Int64 = 33554432L

///|
const SPAN : Int64 = 67108864L

///|
fn cell_key(cx : Int32, cy : Int32) -> Int64 {
  (cx.to_int64() + OFFSET) * SPAN + cy.to_int64() + OFFSET
}

///|
/// A link asks for one node to sit beside another.
/// It belongs to the innermost container that holds both ends, and there it relates the two children of that container the ends are in.
priv struct Links {
  node_a : Array[Int32]
  node_b : Array[Int32]
  side_a : Array[Int32]
  side_b : Array[Int32]
  item_a : Array[Int32]
  item_b : Array[Int32]
}

///|
/// Places every node and group on a grid of cells, following the sides that edges and
/// alignments name.
pub fn place_on_grid(
  nodes : Array[ArchNode],
  groups : Array[ArchGroup],
  edges : Array[ArchEdge],
  hints : Array[ArchLayoutHint],
) -> Grid {
  let n = nodes.length()
  let g_count = groups.length()
  let root = g_count
  let node_index : Map[String, Int32] = Map([])
  let group_index : Map[String, Int32] = Map([])
  // Items are nodes (0..n-1) then groups (n..n+g_count-1).
  // Containers are groups (0..g_count-1) then the root.
  let parent = Array::make(n + g_count, root)
  let depth = Array::make(g_count + 1, 0)
  let kids : Array[Array[Int32]] = Array::makei(g_count + 1, _ => [])
  for g, group in groups {
    group_index.set(group.id, g)
    let p = match group.parent {
      Some(id) => group_index.get(id)
      None => None
    }
    match p {
      Some(p) if p != g => {
        parent[n + g] = p
        depth[g] = depth[p] + 1
      }
      _ => depth[g] = 1
    }
  }
  for i, node in nodes {
    node_index.set(node.id, i)
    if node.parent is Some(id) && group_index.get(id) is Some(p) {
      parent[i] = p
    }
    kids[parent[i]].push(i)
  }
  for g in 0..<g_count {
    kids[parent[n + g]].push(n + g)
  }
  let links : Links = {
    node_a: [],
    node_b: [],
    side_a: [],
    side_b: [],
    item_a: [],
    item_b: [],
  }
  let hint_links : Array[Array[Int32]?] = Array::make(n + g_count, None)
  let edge_links : Array[Array[Int32]?] = Array::make(n + g_count, None)
  fn add_to(lists : Array[Array[Int32]?], item : Int32, k : Int32) {
    match lists[item] {
      Some(list) => list.push(k)
      None => lists[item] = Some([k])
    }
  }

  fn add_link(
    a : Int32,
    b : Int32,
    sa : Int32,
    sb : Int32,
    lists : Array[Array[Int32]?],
  ) {
    if a == b {
      return
    }
    let mut ia = a
    let mut ib = b
    let mut ca = parent[a]
    let mut cb = parent[b]
    while ca != cb {
      if depth[ca] >= depth[cb] {
        ia = n + ca
        ca = parent[ia]
      } else {
        ib = n + cb
        cb = parent[ib]
      }
    }
    let k = links.node_a.length()
    links.node_a.push(a)
    links.node_b.push(b)
    links.side_a.push(sa)
    links.side_b.push(sb)
    links.item_a.push(ia)
    links.item_b.push(ib)
    add_to(lists, ia, k)
    add_to(lists, ib, k)
  }

  for hint in hints {
    let row = hint.direction == "row"
    for i in 1..<hint.members.length() {
      if node_index.get(hint.members[i - 1]) is Some(a) &&
        node_index.get(hint.members[i]) is Some(b) {
        add_link(
          a,
          b,
          if row {
            1
          } else {
            3
          },
          if row {
            0
          } else {
            2
          },
          hint_links,
        )
      }
    }
  }
  // An edge between two like sides says least about where its ends go, so those come last.
  for like_sides in [false, true] {
    for edge in edges {
      if (edge.lhs_dir.index() == edge.rhs_dir.index()) != like_sides {
        continue
      }
      if node_index.get(edge.lhs_id) is Some(a) &&
        node_index.get(edge.rhs_id) is Some(b) {
        add_link(a, b, edge.lhs_dir.index(), edge.rhs_dir.index(), edge_links)
      }
    }
  }

  // Position of each item in its container, and its size in cells.
  let x = Array::make(n + g_count, 0)
  let y = Array::make(n + g_count, 0)
  let w = Array::make(n + g_count, 1)
  let h = Array::make(n + g_count, 1)
  let placed = Array::make(n + g_count, false)
  let order : Array[Int32] = []
  let cells : Map[Int64, Int32] = Map([])
  let large : Array[Int32] = []
  let reach : Map[((Int32, Int32), (Int32, Int32), (Int32, Int32)), Int32] = Map([],
  )
  let mut first = 0
  let mut ax = 0
  let mut ay = 0
  fn anchor(node : Int32, item : Int32) {
    ax = 0
    ay = 0
    let mut cur = node
    while cur != item {
      ax += x[cur]
      ay += y[cur]
      cur = n + parent[cur]
    }
  }

  fn put(item : Int32, px : Int32, py : Int32) {
    x[item] = px
    y[item] = py
    placed[item] = true
    order.push(item)
    if w[item] * h[item] > SMALL {
      large.push(item)
      return
    }
    for cy in py..<(py + h[item]) {
      for cx in px..<(px + w[item]) {
        cells.set(cell_key(cx, cy), item)
      }
    }
  }

  fn overlaps(item : Int32, rx : Int32, ry : Int32, rw : Int32, rh : Int32) {
    x[item] < rx + rw &&
    rx < x[item] + w[item] &&
    y[item] < ry + rh &&
    ry < y[item] + h[item]
  }

  fn collide(rx : Int32, ry : Int32, rw : Int32, rh : Int32) -> Int32 {
    if rw * rh > SMALL {
      for i in first..<order.length() {
        if overlaps(order[i], rx, ry, rw, rh) {
          return order[i]
        }
      }
      return -1
    }
    for cy in ry..<(ry + rh) {
      for cx in rx..<(rx + rw) {
        if cells.get(cell_key(cx, cy)) is Some(hit) {
          return hit
        }
      }
    }
    for item in large {
      if overlaps(item, rx, ry, rw, rh) {
        return item
      }
    }
    -1
  }

  // How far a block must slide along (sx, sy) to be clear.
  // Each step jumps past what it hit, and the result is kept, because a later block starting from the same place cannot stop sooner.
  fn slide(
    rx : Int32,
    ry : Int32,
    rw : Int32,
    rh : Int32,
    sx : Int32,
    sy : Int32,
  ) -> Int32 {
    let key = ((rx, ry), (rw, rh), (sx, sy))
    let mut k = reach.get(key).unwrap_or(0)
    while true {
      let hit = collide(rx + k * sx, ry + k * sy, rw, rh)
      if hit < 0 {
        break
      }
      k = if sx > 0 {
        x[hit] + w[hit] - rx
      } else if sx < 0 {
        rx + rw - x[hit]
      } else if sy > 0 {
        y[hit] + h[hit] - ry
      } else {
        ry + rh - y[hit]
      }
    }
    reach.set(key, k)
    k
  }

  fn follow(from : Int32, k : Int32) {
    let forward = links.item_a[k] == from
    let to = if forward { links.item_b[k] } else { links.item_a[k] }
    if placed[to] {
      return
    }
    let sp = if forward { links.side_a[k] } else { links.side_b[k] }
    let sq = if forward { links.side_b[k] } else { links.side_a[k] }
    anchor(if forward { links.node_a[k] } else { links.node_b[k] }, from)
    let pax = ax
    let pay = ay
    anchor(if forward { links.node_b[k] } else { links.node_a[k] }, to)
    let mut dx = dir_x[sp]
    let mut dy = dir_y[sp]
    let mut shift_x = 0
    let mut shift_y = 0
    let facing = dir_x[sp] + dir_x[sq] == 0 && dir_y[sp] + dir_y[sq] == 0
    if sp == sq {
      // Like sides: the edge loops around, so the nodes stack across the direction it leaves in.
      dx = if dir_x[sp] == 0 { 1 } else { 0 }
      dy = 1 - dx
    } else if !facing {
      // A bend: one step along the side the edge leaves, one step back from the side it enters.
      shift_x = -dir_x[sq]
      shift_y = -dir_y[sq]
    }
    let mut bx = 0
    let mut by = 0
    if dx != 0 {
      bx = if dx > 0 { x[from] + w[from] } else { x[from] - w[to] }
      by = y[from] + pay + shift_y - ay
    } else {
      by = if dy > 0 { y[from] + h[from] } else { y[from] - h[to] }
      bx = x[from] + pax + shift_x - ax
    }
    if facing {
      // When several placed nodes reach this one through the same pair of sides, line it up
      // with the middle one, not with whichever happened to be visited first.
      if edge_links[to] is Some(list) && list.length() > 1 {
        let wanted : Array[Int32] = []
        for j in list {
          let to_is_b = links.item_b[j] == to
          let other = if to_is_b { links.item_a[j] } else { links.item_b[j] }
          let other_side = if to_is_b {
            links.side_a[j]
          } else {
            links.side_b[j]
          }
          let own_side = if to_is_b { links.side_b[j] } else { links.side_a[j] }
          if !placed[other] || other_side != sp || own_side != sq {
            continue
          }
          anchor(if to_is_b { links.node_a[j] } else { links.node_b[j] }, other)
          let at = if dx != 0 { y[other] + ay } else { x[other] + ax }
          anchor(if to_is_b { links.node_b[j] } else { links.node_a[j] }, to)
          wanted.push(at - (if dx != 0 { ay } else { ax }))
        }
        if wanted.length() > 1 {
          wanted.sort()
          let middle = wanted[(wanted.length() - 1) >> 1]
          if dx != 0 {
            by = middle
          } else {
            bx = middle
          }
        }
      }
      // Taken: move sideways, to whichever side is nearer, so the edge can still leave straight.
      let px = if dx == 0 { 1 } else { 0 }
      let py = 1 - px
      let forth = slide(bx, by, w[to], h[to], px, py)
      let back = if forth == 0 {
        0
      } else {
        slide(bx, by, w[to], h[to], -px, -py)
      }
      let near = if forth <= back { forth } else { -back }
      bx += px * near
      by += py * near
    } else {
      let far = slide(bx, by, w[to], h[to], dx, dy)
      bx += dx * far
      by += dy * far
    }
    put(to, bx, by)
  }

  fn layout(c : Int32) {
    let items = kids[c]
    if items.is_empty() {
      return
    }
    order.clear()
    let starts : Array[Int32] = []
    for start in items {
      if placed[start] {
        continue
      }
      first = order.length()
      starts.push(first)
      cells.clear()
      large.clear()
      reach.clear()
      put(start, 0, 0)
      // Declared alignments are followed as soon as a node is placed, ahead of any edge.
      let mut hint_at = first
      let mut edge_at = first
      let mut link_at = 0
      while true {
        if hint_at < order.length() {
          let from = order[hint_at]
          hint_at += 1
          if hint_links[from] is Some(list) {
            for k in list {
              follow(from, k)
            }
          }
          continue
        }
        if edge_at >= order.length() {
          break
        }
        match edge_links[order[edge_at]] {
          Some(list) if link_at < list.length() => {
            let k = list[link_at]
            link_at += 1
            follow(order[edge_at], k)
          }
          _ => {
            edge_at += 1
            link_at = 0
          }
        }
      }
    }
    starts.push(order.length())

    // Unconnected parts go side by side, wrapping into rows that keep the whole roughly square.
    let count = starts.length() - 1
    let min_x = Array::make(count, 0)
    let min_y = Array::make(count, 0)
    let part_w = Array::make(count, 0)
    let part_h = Array::make(count, 0)
    let mut area = 0
    let mut widest = 0
    for p in 0..<count {
      let mut x0 = @int.MAX_VALUE
      let mut y0 = @int.MAX_VALUE
      let mut x1 = @int.MIN_VALUE
      let mut y1 = @int.MIN_VALUE
      for i in starts[p]..<starts[p + 1] {
        let item = order[i]
        x0 = @cmp.minimum(x0, x[item])
        y0 = @cmp.minimum(y0, y[item])
        x1 = @cmp.maximum(x1, x[item] + w[item])
        y1 = @cmp.maximum(y1, y[item] + h[item])
      }
      min_x[p] = x0
      min_y[p] = y0
      part_w[p] = x1 - x0
      part_h[p] = y1 - y0
      area += part_w[p] * part_h[p]
      widest = @cmp.maximum(widest, part_w[p])
    }
    let limit = @cmp.maximum(
      widest,
      (area * 2).to_double().sqrt().ceil().to_int(),
    )
    let mut cx = 0
    let mut cy = 0
    let mut shelf = 0
    let mut width = 0
    for p in 0..<count {
      if cx > 0 && cx + part_w[p] > limit {
        cy += shelf
        cx = 0
        shelf = 0
      }
      for i in starts[p]..<starts[p + 1] {
        x[order[i]] += cx - min_x[p]
        y[order[i]] += cy - min_y[p]
      }
      cx += part_w[p]
      shelf = @cmp.maximum(shelf, part_h[p])
      width = @cmp.maximum(width, cx)
    }
    if c < g_count {
      w[n + c] = width
      h[n + c] = cy + shelf
    }
  }

  for c = g_count - 1; c >= 0; c = c - 1 {
    layout(c)
  }
  layout(root)
  let group_col = Array::make(g_count, 0)
  let group_row = Array::make(g_count, 0)
  let group_parent = Array::make(g_count, 0)
  let group_empty = Array::make(g_count, false)
  for g in 0..<g_count {
    let p = parent[n + g]
    group_parent[g] = if p == root { -1 } else { p }
    group_col[g] = x[n + g] + (if p == root { 0 } else { group_col[p] })
    group_row[g] = y[n + g] + (if p == root { 0 } else { group_row[p] })
    group_empty[g] = kids[g].is_empty()
  }
  let col = Array::make(n, 0)
  let row = Array::make(n, 0)
  let node_parent = Array::make(n, 0)
  for i in 0..<n {
    let p = parent[i]
    node_parent[i] = if p == root { -1 } else { p }
    col[i] = x[i] + (if p == root { 0 } else { group_col[p] })
    row[i] = y[i] + (if p == root { 0 } else { group_row[p] })
  }
  {
    col,
    row,
    group_col,
    group_row,
    group_cols: w[n:].to_owned(),
    group_rows: h[n:].to_owned(),
    group_parent,
    group_empty,
    node_parent,
  }
}
