///|
let lane_head = 34.0

///|
let default_lane_pad = 24.0

///|
let lane_sweeps = 8

///|
let lane_max_dummies = 20000

///|
let lane_max_hops = 10000

///|
/// What every layout of the same lanes shares: the lanes, the items that are ranked and placed, and the relations between them.
priv struct Lanes {
  nodes : Array[CNode]
  edges : Array[CEdge]
  opt : LayeredOptions
  sideways : Bool
  flipped : Bool
  lanes : Array[Int32]
  lane_count : Int32
  lane_slot : FixedArray[Int32]
  item_of : FixedArray[Int32]
  real : Array[Int32]
  lane_pads : FixedArray[Double]
  end_pad : Double
  item_lane : FixedArray[Int32]
  lnodes : Array[LNode]
  ledges : Array[LEdge]
  edge_of : Array[Int32]
  step : Int32
}

///|
/// Lays out swimlanes: every top-level group is a lane, a band that runs the length of the diagram along the flow.
/// Ranks are shared by all lanes, so a step sits level with the steps that happen at the same time in other lanes, and each node stays inside its own lane.
/// Node centers and sizes are written into `nodes`, and routes and label centers into `edges`.
pub fn lane_layout(
  nodes : Array[CNode],
  edges : Array[CEdge],
  dir : Dir,
  opt : LayeredOptions,
  lane_pad~ : Double = default_lane_pad,
) -> CompoundResult {
  if nodes.length() == 0 {
    return { width: 0, height: 0, }
  }
  Lanes::new(nodes, edges, dir, opt, lane_pad).place()
}

///|
fn Lanes::new(
  nodes : Array[CNode],
  edges : Array[CEdge],
  dir : Dir,
  opt : LayeredOptions,
  lane_pad : Double,
) -> Lanes {
  let n = nodes.length()
  let sideways = dir is (LR | RL)
  let flipped = dir is (BT | RL)
  // Lanes in the order they were written. The graph lists groups last-declared first.
  let lanes : Array[Int32] = []
  for i = n - 1; i >= 0; i = i - 1 {
    if nodes[i].parent < 0 && nodes[i].is_group {
      lanes.push(i)
    }
  }
  let lane_count = if lanes.length() > 1 { lanes.length() } else { 1 }
  let lane_slot = FixedArray::make(n, -1)
  for k, id in lanes {
    lane_slot[id] = k
  }
  let has_child = FixedArray::make(n, false)
  for i in 0..<n {
    if nodes[i].parent >= 0 {
      has_child[nodes[i].parent] = true
    }
  }
  // Room a lane keeps around its items, so that the groups drawn around them stay inside it.
  let lane_pads = FixedArray::make(lane_count, lane_pad)
  let mut end_pad = lane_pad
  let lane_of = (i : Int32) => {
    let mut t = i
    let mut room = lane_pad
    let mut hops = 0
    while nodes[t].parent >= 0 && hops < lane_max_hops {
      t = nodes[t].parent
      if lane_slot[t] < 0 {
        room += @util.js_max(
          @util.js_max(nodes[t].pad_x, nodes[t].pad_top),
          nodes[t].pad_bottom,
        )
      }
      hops += 1
    }
    let lane = if lane_slot[t] > 0 { lane_slot[t] } else { 0 }
    if room > lane_pads[lane] {
      lane_pads[lane] = room
    }
    if room > end_pad {
      end_pad = room
    }
    lane
  }
  // What gets ranked and placed: nodes, and groups that are empty and so act as nodes.
  let item_of = FixedArray::make(n, -1)
  let real : Array[Int32] = []
  for i in 0..<n {
    if lane_slot[i] >= 0 {
      continue
    }
    if !nodes[i].is_group || !has_child[i] {
      item_of[i] = real.length()
      real.push(i)
    }
  }
  let along = (c : CNode) => if sideways { c.w } else { c.h }
  let cross = (c : CNode) => if sideways { c.h } else { c.w }
  let lnodes = real.map(i => lnode(cross(nodes[i]), along(nodes[i])))
  let ledges : Array[LEdge] = []
  let edge_of : Array[Int32] = []
  let mut step = 1
  let seen : Set[Int64] = Set([])
  for ei, e in edges {
    let a = item_of[e.src]
    let b = item_of[e.dst]
    if a < 0 || b < 0 || a == b {
      continue
    }
    let key = (if a < b { a } else { b }).to_int64() * real.length().to_int64() +
      (if a < b { b } else { a }).to_int64()
    if e.label_w > 0 || seen.contains(key) {
      step = 2
    }
    seen.add(key)
    ledges.push(
      ledge(
        a,
        b,
        minlen=e.minlen,
        label_w=if sideways { e.label_h } else { e.label_w },
        label_h=if sideways { e.label_w } else { e.label_h },
      ),
    )
    edge_of.push(ei)
  }
  orient(lnodes, ledges)
  rank(lnodes, ledges, step)
  let item_lane = FixedArray::makei(real.length(), k => lane_of(real[k]))
  {
    nodes,
    edges,
    opt,
    sideways,
    flipped,
    lanes,
    lane_count,
    lane_slot,
    item_of,
    real,
    lane_pads,
    end_pad,
    item_lane,
    lnodes,
    ledges,
    edge_of,
    step,
  }
}

///|
/// Where one layout of the lanes put its items: every item's rank, and the bands and lanes they sit in.
/// Positions are kept across and along the flow, and `px` and `py` turn them into the diagram's.
priv struct Placement {
  sideways : Bool
  flipped : Bool
  rank_of : FixedArray[Int32]
  band_start : FixedArray[Double]
  band_end : FixedArray[Double]
  head : Double
  length : Double
  breadth : Double
}

///|
fn Placement::flip(self : Placement, a : Double) -> Double {
  if self.flipped {
    self.head + self.length - a
  } else {
    a
  }
}

///|
fn Placement::px(self : Placement, c : Double, a : Double) -> Double {
  if self.sideways {
    self.flip(a)
  } else {
    c
  }
}

///|
fn Placement::py(self : Placement, c : Double, a : Double) -> Double {
  if self.sideways {
    c
  } else {
    self.flip(a)
  }
}

///|
fn Placement::axis(self : Placement) -> Double {
  if self.sideways {
    1
  } else {
    0
  }
}

///|
/// The middle of an item's band along the flow.
fn Placement::amid(self : Placement, i : Int32) -> Double {
  (self.band_start[self.rank_of[i]] + self.band_end[self.rank_of[i]]) / 2
}

///|
/// Lays the ranked items out and routes the relations through the ranks they pass.
fn Lanes::place(self : Lanes) -> CompoundResult {
  let { nodes, edges, opt, lanes, lane_count, real, lnodes, ledges, step, .. } = self
  let m = ledges.length()
  let pad = self.lane_pads
  // Items: the real ones, then a dummy for every rank an edge passes through.
  let mut dummies = 0
  let span = FixedArray::make(m, 0)
  for k in 0..<m {
    let d = lnodes[ledges[k].head].rank - lnodes[ledges[k].tail].rank
    span[k] = if d < 0 { -d } else { d }
    dummies += span[k] - 1
  }
  let direct = dummies > lane_max_dummies
  let total = real.length() + (if direct { 0 } else { dummies })
  let rank_of = FixedArray::make(total, 0)
  let lane_at = FixedArray::make(total, 0)
  let size = FixedArray::make(total, 0.0)
  let depth = FixedArray::make(total, 0.0)
  let dummy = FixedArray::make(total, false)
  let mut max_rank = 0
  for k in 0..<real.length() {
    rank_of[k] = lnodes[k].rank
    lane_at[k] = self.item_lane[k]
    size[k] = lnodes[k].w
    depth[k] = lnodes[k].h
    if rank_of[k] > max_rank {
      max_rank = rank_of[k]
    }
  }
  let first_dummy = FixedArray::make(m, -1)
  let label_item = FixedArray::make(m, -1)
  let links : Array[Int32] = []
  let mut next = real.length()
  for k in 0..<m {
    let e = ledges[k]
    let a = if e.reversed { e.head } else { e.tail }
    let b = if e.reversed { e.tail } else { e.head }
    if direct || span[k] < 2 {
      links.push(a)
      links.push(b)
      continue
    }
    let ra = rank_of[a]
    let rb = rank_of[b]
    let mut label_rank = -1
    if e.label_w > 0 {
      label_rank = ra + ((rb - ra) >> 1)
      if step == 2 && (label_rank & 1) == 0 {
        label_rank -= 1
      }
    }
    first_dummy[k] = next
    let mut prev = a
    for r in (ra + 1)..<rb {
      let d = next
      next += 1
      rank_of[d] = r
      // The edge crosses from its first lane to its last one evenly along the way.
      lane_at[d] = lane_at[a] +
        (((lane_at[b] - lane_at[a]) * (r - ra)).to_double() /
        (rb - ra).to_double())
        .round()
        .to_int()
      dummy[d] = true
      if r == label_rank {
        size[d] = e.label_w
        depth[d] = e.label_h
        label_item[k] = d
      }
      links.push(prev)
      links.push(d)
      prev = d
    }
    links.push(prev)
    links.push(b)
  }
  let up_start = FixedArray::make(total + 1, 0)
  let down_start = FixedArray::make(total + 1, 0)
  for k = 0; k < links.length(); k = k + 2 {
    down_start[links[k] + 1] += 1
    up_start[links[k + 1] + 1] += 1
  }
  for i in 0..<total {
    up_start[i + 1] += up_start[i]
    down_start[i + 1] += down_start[i]
  }
  let up = FixedArray::make(links.length() / 2, 0)
  let down = FixedArray::make(links.length() / 2, 0)
  {
    let uf = FixedArray::makei(total, i => up_start[i])
    let df = FixedArray::makei(total, i => down_start[i])
    for k = 0; k < links.length(); k = k + 2 {
      down[df[links[k]]] = links[k + 1]
      df[links[k]] += 1
      up[uf[links[k + 1]]] = links[k]
      uf[links[k + 1]] += 1
    }
  }

  // Order within each rank: by lane first, then by where the item's neighbours sit.
  let rows : Array[Array[Int32]] = Array::makei(max_rank + 1, _ => [])
  for i in 0..<total {
    rows[rank_of[i]].push(i)
  }
  let pos = FixedArray::make(total, 0.0)
  let key = FixedArray::make(total, 0.0)
  let settle_row = (row : Array[Int32]) => {
    sort_array(row, (a, b) => {
      or_else(
        (lane_at[a] - lane_at[b]).to_double(),
        or_else(key[a] - key[b], (a - b).to_double()),
      )
    })
    for k, i in row {
      pos[i] = k.to_double()
    }
  }
  for row in rows {
    for k, i in row {
      key[i] = k.to_double()
    }
    settle_row(row)
  }
  for sweep = 0; sweep < lane_sweeps && max_rank > 0; sweep = sweep + 1 {
    let downward = (sweep & 1) == 0
    for s in 1..<=max_rank {
      let row = rows[if downward { s } else { max_rank - s }]
      let start = if downward { up_start } else { down_start }
      let list = if downward { up } else { down }
      for i in row {
        let mut sum = 0.0
        let count = start[i + 1] - start[i]
        for k in start[i]..<start[i + 1] {
          sum += pos[list[k]]
        }
        key[i] = if count > 0 { sum / count.to_double() } else { pos[i] }
      }
      settle_row(row)
    }
  }

  // The items of one rank that share a lane sit side by side as a run.
  let gap = (a : Int32, b : Int32) => {
    if dummy[a] || dummy[b] {
      opt.edge_sep
    } else {
      opt.node_sep
    }
  }
  let each_run = (row : Array[Int32], visit : (Int32, Int32) -> Unit) => {
    let mut from = 0
    while from < row.length() {
      let mut to = from
      while to + 1 < row.length() && lane_at[row[to + 1]] == lane_at[row[from]] {
        to += 1
      }
      visit(from, to)
      from = to + 1
    }
  }
  let run_size = (row : Array[Int32], from : Int32, to : Int32) => {
    let mut total = size[row[from]]
    for k in from..<to {
      total += gap(row[k], row[k + 1]) + size[row[k + 1]]
    }
    total
  }

  // Lane breadth: enough for its fullest rank, and for its title.
  let breadth = FixedArray::make(lane_count, 0.0)
  let mut head = if lanes.length() > 0 { lane_head } else { 0 }
  for k, id in lanes {
    let lane = nodes[id]
    breadth[k] = @util.js_max(0, lane.min_w - 2 * pad[k])
    if lane.pad_top > head {
      head = lane.pad_top
    }
  }
  for row in rows {
    each_run(row, (from, to) => {
      let run = run_size(row, from, to)
      if run > breadth[lane_at[row[from]]] {
        breadth[lane_at[row[from]]] = run
      }
    })
  }
  let lane_start = FixedArray::make(lane_count + 1, 0.0)
  for k in 0..<lane_count {
    lane_start[k + 1] = lane_start[k] + breadth[k] + 2 * pad[k]
  }

  // Across the flow: each lane's items start centered, then line up with their neighbours in the same lane as far as the lane and the items beside them allow.
  let across = FixedArray::make(total, 0.0)
  let want = FixedArray::make(total, 0.0)
  for row in rows {
    each_run(row, (from, to) => {
      let lane = lane_at[row[from]]
      let mut at = (
          lane_start[lane] +
          pad[lane] +
          (lane_start[lane + 1] - pad[lane]) -
          run_size(row, from, to)
        ) /
        2
      for k in from..<=to {
        across[row[k]] = at + size[row[k]] / 2
        if k < to {
          at += size[row[k]] + gap(row[k], row[k + 1])
        }
      }
    })
  }
  for pass = 0; pass < 4 && max_rank > 0; pass = pass + 1 {
    let downward = (pass & 1) == 0
    for s in 1..<=max_rank {
      let row = rows[if downward { s } else { max_rank - s }]
      let start = if downward { up_start } else { down_start }
      let list = if downward { up } else { down }
      for i in row {
        let mut sum = 0.0
        let mut count = 0
        for k in start[i]..<start[i + 1] {
          if lane_at[list[k]] != lane_at[i] {
            continue
          }
          sum += across[list[k]]
          count += 1
        }
        want[i] = if count > 0 { sum / count.to_double() } else { across[i] }
      }
      each_run(row, (from, to) => {
        let lane = lane_at[row[from]]
        let mut floor = lane_start[lane] + pad[lane]
        for k in from..<=to {
          let i = row[k]
          across[i] = @util.js_max(want[i], floor + size[i] / 2)
          if k < to {
            floor = across[i] + size[i] / 2 + gap(i, row[k + 1])
          }
        }
        let mut ceil = lane_start[lane + 1] - pad[lane]
        for k = to; k >= from; k = k - 1 {
          let i = row[k]
          across[i] = @util.js_min(across[i], ceil - size[i] / 2)
          if k > from {
            ceil = across[i] - size[i] / 2 - gap(row[k - 1], i)
          }
        }
      })
    }
  }

  // Along the flow: one band per rank, after the lane titles.
  let band_start = FixedArray::make(max_rank + 1, 0.0)
  let band_end = FixedArray::make(max_rank + 1, 0.0)
  let sep = opt.rank_sep / step.to_double()
  let mut at = head + self.end_pad
  for r in 0..<=max_rank {
    let mut deepest = 0.0
    for i in rows[r] {
      if depth[i] > deepest {
        deepest = depth[i]
      }
    }
    band_start[r] = at
    band_end[r] = at + deepest
    at += deepest + (if r == max_rank { 0 } else { sep })
  }
  let placement : Placement = {
    sideways: self.sideways,
    flipped: self.flipped,
    rank_of,
    band_start,
    band_end,
    head,
    length: at + self.end_pad,
    breadth: lane_start[lane_count],
  }
  let { length, sideways, .. } = placement
  for k, id in real {
    let node = nodes[id]
    let a = placement.amid(k)
    node.x = placement.px(across[k], a)
    node.y = placement.py(across[k], a)
  }
  for k, id in lanes {
    let lane = nodes[id]
    let c = (lane_start[k] + lane_start[k + 1]) / 2
    let breadth = lane_start[k + 1] - lane_start[k]
    lane.x = if sideways { length / 2 } else { c }
    lane.y = if sideways { c } else { length / 2 }
    lane.w = if sideways { length } else { breadth }
    lane.h = if sideways { breadth } else { length }
    lane.pad_top = head
  }
  self.wrap_groups()
  for e in edges {
    e.route = []
  }
  for k in 0..<m {
    let e = ledges[k]
    let out = edges[self.edge_of[k]]
    let a = if e.reversed { e.head } else { e.tail }
    let b = if e.reversed { e.tail } else { e.head }
    let pts = [
      across[a],
      band_end[rank_of[a]] -
      (band_end[rank_of[a]] - band_start[rank_of[a]] - depth[a]) / 2,
    ]
    let d0 = first_dummy[k]
    if d0 >= 0 {
      for d in d0..<(d0 + span[k] - 1) {
        pts.push(across[d])
        pts.push(band_start[rank_of[d]])
        if band_end[rank_of[d]] > band_start[rank_of[d]] {
          pts.push(across[d])
          pts.push(band_end[rank_of[d]])
        }
      }
    }
    pts.push(across[b])
    pts.push(
      band_start[rank_of[b]] +
      (band_end[rank_of[b]] - band_start[rank_of[b]] - depth[b]) / 2,
    )
    let route : Array[Double] = []
    for p = 0; p < pts.length(); p = p + 2 {
      route.push(placement.px(pts[p], pts[p + 1]))
      route.push(placement.py(pts[p], pts[p + 1]))
      route.push(placement.axis())
    }
    if e.reversed {
      let mut i = 0
      let mut j = route.length() - 3
      while i < j {
        for t in 0..<2 {
          let keep = route[i + t]
          route[i + t] = route[j + t]
          route[j + t] = keep
        }
        i += 3
        j -= 3
      }
    }
    out.route = route
    let label = label_item[k]
    if label >= 0 {
      let mid = placement.amid(label)
      out.label_x = placement.px(across[label], mid)
      out.label_y = placement.py(across[label], mid)
    } else {
      out.label_x = (route[0] + route[route.length() - 3]) / 2
      out.label_y = (route[1] + route[route.length() - 2]) / 2
    }
  }

  // An edge that starts or ends at a lane or a group runs straight to its border.
  for e in edges {
    if e.route.length() > 0 || e.src == e.dst {
      continue
    }
    let (ax, ay) = border(nodes[e.src], nodes[e.dst])
    let (bx, by) = border(nodes[e.dst], nodes[e.src])
    let flat = if (bx - ax).abs() > (by - ay).abs() { 1.0 } else { 0.0 }
    e.route = [ax, ay, flat, bx, by, flat]
    e.label_x = (ax + bx) / 2
    e.label_y = (ay + by) / 2
  }
  {
    width: if sideways {
      length
    } else {
      placement.breadth
    },
    height: if sideways {
      placement.breadth
    } else {
      length
    },
  }
}

///|
/// Draws the groups inside a lane around their members, deepest first.
fn Lanes::wrap_groups(self : Lanes) -> Unit {
  let { nodes, lane_slot, item_of, real, .. } = self
  let n = nodes.length()
  let depth_of = FixedArray::make(n, 0)
  let inner : Array[Int32] = []
  for i in 0..<n {
    if !nodes[i].is_group || lane_slot[i] >= 0 || item_of[i] >= 0 {
      continue
    }
    let mut d = 0
    let mut p = nodes[i].parent
    while p >= 0 && d < lane_max_hops {
      d += 1
      p = nodes[p].parent
    }
    depth_of[i] = d
    inner.push(i)
  }
  sort_array(inner, (a, b) => {
    or_else((depth_of[b] - depth_of[a]).to_double(), (a - b).to_double())
  })
  let box = FixedArray::make(n * 4, 0.0)
  for i in 0..<n {
    box[i * 4] = @double.infinity
    box[i * 4 + 1] = @double.infinity
    box[i * 4 + 2] = @double.neg_infinity
    box[i * 4 + 3] = @double.neg_infinity
  }
  let grow = (g : Int32, c : CNode) => {
    if c.x - c.w / 2 < box[g * 4] {
      box[g * 4] = c.x - c.w / 2
    }
    if c.y - c.h / 2 < box[g * 4 + 1] {
      box[g * 4 + 1] = c.y - c.h / 2
    }
    if c.x + c.w / 2 > box[g * 4 + 2] {
      box[g * 4 + 2] = c.x + c.w / 2
    }
    if c.y + c.h / 2 > box[g * 4 + 3] {
      box[g * 4 + 3] = c.y + c.h / 2
    }
  }
  for i in real {
    if nodes[i].parent >= 0 && lane_slot[nodes[i].parent] < 0 {
      grow(nodes[i].parent, nodes[i])
    }
  }
  for g in inner {
    let c = nodes[g]
    if box[g * 4] == @double.infinity {
      continue
    }
    let w = @util.js_max(box[g * 4 + 2] - box[g * 4] + 2 * c.pad_x, c.min_w)
    c.x = (box[g * 4] + box[g * 4 + 2]) / 2
    c.w = w
    c.y = (box[g * 4 + 1] - c.pad_top + box[g * 4 + 3] + c.pad_bottom) / 2
    c.h = box[g * 4 + 3] - box[g * 4 + 1] + c.pad_top + c.pad_bottom
    if c.parent >= 0 && lane_slot[c.parent] < 0 {
      grow(c.parent, c)
    }
  }
}

///|
/// The point where the line from one box's center to another's leaves the first box.
/// When the other center is inside the box, the point is on the nearest side instead.
fn border(from : CNode, to : CNode) -> (Double, Double) {
  let dx = to.x - from.x
  let dy = to.y - from.y
  let hw = @util.js_max(from.w / 2, 0.5)
  let hh = @util.js_max(from.h / 2, 0.5)
  if dx.abs() < hw && dy.abs() < hh {
    let to_side = hw - dx.abs()
    let to_end = hh - dy.abs()
    return if to_side < to_end {
      (from.x + (if dx < 0 { -hw } else { hw }), to.y)
    } else {
      (to.x, from.y + (if dy < 0 { -hh } else { hh }))
    }
  }
  let scale = @util.js_min(
    if dx != 0 {
      hw / dx.abs()
    } else {
      @double.infinity
    },
    if dy != 0 {
      hh / dy.abs()
    } else {
      @double.infinity
    },
  )
  (from.x + dx * scale, from.y + dy * scale)
}
