///|
/// What a node of a layered graph stands for.
pub(all) enum Kind {
  Node
  Dummy
  Label
  StartPort
  EndPort
}

///|
/// A node of one flat graph, and where the layout puts it.
pub(all) struct LNode {
  mut w : Double
  mut h : Double
  mut kind : Kind
  mut pin : Int32
  /// Port's cross-flow destination; NaN if unknown. Fully hinted port ranks keep this order.
  mut hint : Double
  /// Initial cross-flow position; NaN if unknown. Used only when every node in a rank has one.
  mut key : Double
  /// How much of the side that edges meet may be shared out between them; 0 keeps them all at its middle.
  mut span : Double
  mut x : Double
  mut y : Double
  mut rank : Int32
}

///|
/// An edge of one flat graph, and how the layout routes it.
pub(all) struct LEdge {
  mut tail : Int32
  mut head : Int32
  mut minlen : Int32
  mut label_w : Double
  mut label_h : Double
  mut tail_dx : Double
  mut head_dx : Double
  /// An end that is held where its offset puts it, and takes no part in sharing out a node's side.
  mut tail_fixed : Bool
  mut head_fixed : Bool
  mut reversed : Bool
  mut points : Array[Double]
  mut label_x : Double
  mut label_y : Double
}

///|
/// Groups that keep their nodes contiguous within ranks.
/// `of` maps nodes to groups and `parent` maps groups to parents, with -1 for none.
pub(all) struct LayeredGroups {
  of : Array[Int32]
  parent : Array[Int32]
}

///|
/// How a layered graph is spaced and routed.
pub(all) struct LayeredOptions {
  node_sep : Double
  edge_sep : Double
  rank_sep : Double
  port_sep : Double
  /// Route edges at right angles, each on a track of its own across the gap between two ranks.
  tracks : Bool
  /// Draw every edge straight from point to point: none is given a level to turn onto.
  straight : Bool
  /// The caller sets the ends of the edges on one side of a node apart itself, so two edges between the same two nodes need no bend to keep them from being drawn as one.
  apart : Bool
  /// The room that the marker at the head of an edge takes.
  /// A rank of labels whose edges all head the same way sits half of this nearer their tails.
  head_room : Double
  groups : LayeredGroups?
  /// Compute cross-flow positions in `x` without full routing.
  order_only : Bool
}

///|
/// Options with the given spacing and every other choice off.
pub fn LayeredOptions::new(
  node_sep~ : Double,
  edge_sep~ : Double,
  rank_sep~ : Double,
  port_sep~ : Double,
  tracks~ : Bool = false,
  straight~ : Bool = false,
  apart~ : Bool = false,
  head_room~ : Double = 0,
  groups? : LayeredGroups,
  order_only~ : Bool = false,
) -> LayeredOptions {
  {
    node_sep,
    edge_sep,
    rank_sep,
    port_sep,
    tracks,
    straight,
    apart,
    head_room,
    groups,
    order_only,
  }
}

///|
/// The size of a laid out graph.
/// With `order_only`, also the final crossings and those before grouping or reordering.
pub(all) struct LayeredResult {
  width : Double
  height : Double
  crossings : Int32
  declared : Int32
}

///|
/// An edge gets a bend point in every rank it skips.
/// Past this many, the longest edges are drawn as one direct curve instead, which keeps huge graphs from exhausting time and memory.
let max_dummies = 20000

///|
/// Where edges are not given levels, a gap between ranks grows to keep the edges that cross it at least this steep, up to this many times its usual height.
/// Shallower than that, the edges of a wide rank are hard to tell apart.
let min_slope = 0.125

///|
let max_gap = 3.0

///|
/// A node of the given size.
pub fn lnode(w : Double, h : Double, kind~ : Kind = Node) -> LNode {
  {
    w,
    h,
    kind,
    pin: 0,
    hint: @double.not_a_number,
    key: @double.not_a_number,
    span: 0,
    x: 0,
    y: 0,
    rank: 0,
  }
}

///|
/// An edge from `tail` to `head`.
pub fn ledge(
  tail : Int32,
  head : Int32,
  minlen~ : Int32 = 1,
  label_w~ : Double = 0,
  label_h~ : Double = 0,
) -> LEdge {
  {
    tail,
    head,
    minlen,
    label_w,
    label_h,
    tail_dx: 0,
    head_dx: 0,
    tail_fixed: false,
    head_fixed: false,
    reversed: false,
    points: [],
    label_x: 0,
    label_y: 0,
  }
}

///|
/// Lays out one flat graph in ranks down the y axis, Sugiyama style, writing positions into `nodes` and routes into `edges`.
/// Callers rotate the result for other directions.
pub fn layered(
  nodes : Array[LNode],
  edges : Array[LEdge],
  opt : LayeredOptions,
) -> LayeredResult {
  let real = nodes.length()
  if real == 0 {
    return { width: 0, height: 0, crossings: 0, declared: 0, }
  }
  let m = edges.length()
  if real == 1 && m == 0 && nodes[0].kind is Node {
    let node = nodes[0]
    node.rank = 0
    node.x = node.w / 2
    node.y = node.h / 2
    return { width: node.w, height: node.h, crossings: 0, declared: 0, }
  }

  // Every edge gets a middle rank of its own when labels or parallel edges need the room.
  let mut step = 1
  if m > 0 {
    let seen : Set[Int64] = Set([])
    for e in edges {
      let a = if e.tail < e.head { e.tail } else { e.head }
      let b = if e.tail < e.head { e.head } else { e.tail }
      let key = a.to_int64() * real.to_int64() + b.to_int64()
      if e.label_w > 0 || seen.contains(key) {
        step = 2
        break
      }
      seen.add(key)
    }
  }
  orient(nodes, edges)
  rank(nodes, edges, step)
  let span = FixedArray::make(m, 0)
  let mut dummies = 0
  for ei in 0..<m {
    let e = edges[ei]
    span[ei] = (nodes[e.head].rank - nodes[e.tail].rank).abs()
    if span[ei] > 1 {
      dummies += span[ei] - 1
    }
  }
  let direct = FixedArray::make(m, false)
  if dummies > max_dummies {
    let longest : Array[Int32] = []
    for ei in 0..<m {
      if span[ei] > 1 {
        longest.push(ei)
      }
    }
    let list = FixedArray::makei(longest.length(), i => longest[i])
    sort_range(list, 0, list.length(), fn(a, b) {
      or_else((span[b] - span[a]).to_double(), (a - b).to_double())
    })
    for ei in list {
      if dummies <= max_dummies {
        break
      }
      direct[ei] = true
      dummies -= span[ei] - 1
    }
  }
  let n = real + dummies
  let w = FixedArray::make(n, 0.0)
  let h = FixedArray::make(n, 0.0)
  let kind = FixedArray::make(n, Kind::Node)
  let rank = FixedArray::make(n, 0)
  let mut max_rank = 0
  for i in 0..<real {
    let node = nodes[i]
    w[i] = node.w
    h[i] = node.h
    kind[i] = node.kind
    rank[i] = node.rank
    if node.rank > max_rank {
      max_rank = node.rank
    }
  }
  let mut segments = 0
  for ei in 0..<m {
    if !direct[ei] {
      segments += span[ei]
    }
  }
  let ef = FixedArray::make(segments, 0)
  let et = FixedArray::make(segments, 0)
  let efd = FixedArray::make(segments, 0.0)
  let etd = FixedArray::make(segments, 0.0)
  let first_dummy = FixedArray::make(m, -1)
  // Which way the edges with a label in each rank head: 1 down, 2 up, 3 both.
  let heads = FixedArray::make(max_rank + 1, 0)
  let label_node = FixedArray::make(m, -1)
  let mut spans = false
  for i in 0..<real {
    if nodes[i].span > 0 && nodes[i].kind is Node {
      spans = true
    }
  }
  // What each segment's end is to the node it meets, for the ends that may move along the node's side.
  let efk = FixedArray::make(if spans { segments } else { 0 }, end_held)
  let etk = FixedArray::make(if spans { segments } else { 0 }, end_held)
  let first_seg = FixedArray::make(m, -1)
  let last_seg = FixedArray::make(m, -1)
  let key = FixedArray::make(n, @double.not_a_number)
  for i in 0..<real {
    key[i] = nodes[i].key
  }
  let mut offsets = false
  let mut next = real
  let mut ce = 0
  for ei in 0..<m {
    if direct[ei] {
      continue
    }
    let e = edges[ei]
    let a = if e.reversed { e.head } else { e.tail }
    let b = if e.reversed { e.tail } else { e.head }
    let a_dx = if e.reversed { e.head_dx } else { e.tail_dx }
    let b_dx = if e.reversed { e.tail_dx } else { e.head_dx }
    if a_dx != 0.0 || b_dx != 0.0 {
      offsets = true
    }
    let ra = rank[a]
    let rb = rank[b]
    let mut label_rank = -1
    if e.label_w > 0 {
      // The label goes halfway along.
      // An edge that passes ranks of nodes on its way has its label in one of those, beside the nodes, where it takes no height of its own: the one halfway, or of the two either side of halfway, the one nearer the node the edge starts from, which is the lower when the edge runs against the flow.
      // An edge between two neighbouring ranks has its label in the rank between them.
      label_rank = ra + ((rb - ra) >> 1)
      if step == 2 && rb - ra >= 4 {
        if (label_rank & 1) == 1 {
          label_rank += if e.reversed { 1 } else { -1 }
        }
      } else if step == 2 && (label_rank & 1) == 0 {
        label_rank += if e.reversed { 1 } else { -1 }
      }
    }
    let mut prev = a
    if rb - ra > 1 {
      first_dummy[ei] = next
    }
    first_seg[ei] = ce
    if spans && !(if e.reversed { e.head_fixed } else { e.tail_fixed }) {
      efk[ce] = if e.reversed { end_arrives } else { end_leaves }
    }
    for r in (ra + 1)..<rb {
      let d = next
      next += 1
      rank[d] = r
      key[d] = key[a] +
        (key[b] - key[a]) * (r - ra).to_double() / (rb - ra).to_double()
      if r == label_rank {
        w[d] = e.label_w
        h[d] = e.label_h
        kind[d] = Label
        label_node[ei] = d
        heads[r] = heads[r] | (if e.reversed { 2 } else { 1 })
      } else {
        kind[d] = Dummy
      }
      ef[ce] = prev
      et[ce] = d
      efd[ce] = if prev == a { a_dx } else { 0 }
      ce += 1
      prev = d
    }
    ef[ce] = prev
    et[ce] = b
    efd[ce] = if prev == a { a_dx } else { 0 }
    etd[ce] = b_dx
    if spans && !(if e.reversed { e.tail_fixed } else { e.head_fixed }) {
      etk[ce] = if e.reversed { end_leaves } else { end_arrives }
    }
    last_seg[ei] = ce
    ce += 1
  }

  // Bends belong to the innermost group containing both edge endpoints.
  let grp = match opt.groups {
    None => None
    Some({ of: of_, parent, }) => {
      let grp = FixedArray::make(n, 0)
      for i in 0..<real {
        grp[i] = of_[i]
      }
      let depth = fn(gr : Int32) {
        let mut d = 0
        let mut gr = gr
        while gr >= 0 {
          d += 1
          gr = parent[gr]
        }
        d
      }
      let lca = fn(x : Int32, y : Int32) {
        let mut x = x
        let mut y = y
        let mut dx = depth(x)
        let mut dy = depth(y)
        while dx > dy {
          x = parent[x]
          dx -= 1
        }
        while dy > dx {
          y = parent[y]
          dy -= 1
        }
        while x != y {
          x = parent[x]
          y = parent[y]
        }
        x
      }
      for ei in 0..<m {
        if first_dummy[ei] < 0 {
          continue
        }
        let e = edges[ei]
        let gr = lca(of_[e.tail], of_[e.head])
        for d in first_dummy[ei]..<(first_dummy[ei] + span[ei] - 1) {
          grp[d] = gr
        }
      }
      Some(grp)
    }
  }
  let succ_start = FixedArray::make(n + 1, 0)
  let pred_start = FixedArray::make(n + 1, 0)
  for e in 0..<segments {
    succ_start[ef[e] + 1] += 1
    pred_start[et[e] + 1] += 1
  }
  for i in 0..<n {
    succ_start[i + 1] += succ_start[i]
    pred_start[i + 1] += pred_start[i]
  }
  let succ_e = FixedArray::make(segments, 0)
  let pred_e = FixedArray::make(segments, 0)
  let sf = FixedArray::makei(n, i => succ_start[i])
  let pf = FixedArray::makei(n, i => pred_start[i])
  for e in 0..<segments {
    succ_e[sf[ef[e]]] = e
    sf[ef[e]] += 1
    pred_e[pf[et[e]]] = e
    pf[et[e]] += 1
  }
  let layer_start = FixedArray::make(max_rank + 2, 0)
  for i in 0..<n {
    layer_start[rank[i] + 1] += 1
  }
  for r in 0..<=max_rank {
    layer_start[r + 1] += layer_start[r]
  }
  let order = FixedArray::make(n, 0)
  let pos = FixedArray::make(n, 0)

  // The first order is depth-first from the top, so that subtrees start out contiguous.
  let by_rank = FixedArray::make(n, 0)
  let fill = FixedArray::makei(max_rank + 1, r => layer_start[r])
  for i in 0..<n {
    by_rank[fill[rank[i]]] = i
    fill[rank[i]] += 1
  }
  for r in 0..<=max_rank {
    fill[r] = layer_start[r]
  }
  let visited = FixedArray::make(n, false)
  let stack : Array[Int32] = []
  for k in 0..<n {
    if visited[by_rank[k]] {
      continue
    }
    stack.push(by_rank[k])
    while stack.pop() is Some(v) {
      if visited[v] {
        continue
      }
      visited[v] = true
      order[fill[rank[v]]] = v
      fill[rank[v]] += 1
      for j = succ_start[v + 1] - 1; j >= succ_start[v]; j = j - 1 {
        let u = et[succ_e[j]]
        if !visited[u] {
          stack.push(u)
        }
      }
    }
  }
  let sort_rank = fn(r : Int32, key : (Int32) -> Double) {
    let s = layer_start[r]
    let e = layer_start[r + 1]
    if e - s < 2 {
      return false
    }
    for i in s..<e {
      if key(order[i]).is_nan() {
        return false
      }
    }
    let index = FixedArray::make(n, 0)
    for i in s..<e {
      index[order[i]] = i - s
    }
    sort_range(order, s, e, fn(a, b) {
      or_else(key(a) - key(b), (index[a] - index[b]).to_double())
    })
    true
  }
  for r in 0..<=max_rank {
    ignore(sort_rank(r, v => key[v]))
  }
  let mut pinned = false
  for i in 0..<real {
    if nodes[i].pin != 0 {
      pinned = true
    }
  }
  if pinned {
    let index = FixedArray::make(n, 0)
    let pin_of = fn(v : Int32) { if v < real { nodes[v].pin } else { 0 } }
    for r in 0..<=max_rank {
      let s = layer_start[r]
      let e = layer_start[r + 1]
      for i in s..<e {
        index[order[i]] = i - s
      }
      sort_range(order, s, e, fn(a, b) {
        or_else(
          (pin_of(a) - pin_of(b)).to_double(),
          (index[a] - index[b]).to_double(),
        )
      })
    }
  }
  // Port order is preserved to avoid crossings outside the group.
  let fixed = FixedArray::make(max_rank + 1, false)
  let hint = fn(v : Int32) {
    if v < real && nodes[v].kind is (StartPort | EndPort) {
      nodes[v].hint
    } else {
      @double.not_a_number
    }
  }
  for r in [0, max_rank] {
    if sort_rank(r, hint) {
      fixed[r] = true
    }
  }
  let set_positions = fn() {
    for r in 0..<=max_rank {
      let s = layer_start[r]
      for i in s..<layer_start[r + 1] {
        pos[order[i]] = i - s
      }
    }
  }
  set_positions()
  let g : Graph = {
    n,
    real,
    max_rank,
    w,
    kind,
    rank,
    ef,
    et,
    efd,
    etd,
    succ_start,
    succ_e,
    pred_start,
    pred_e,
    layer_start,
    order,
    pos,
    offsets,
    fixed,
    grp,
    group_parent: opt.groups.map(groups => groups.parent),
  }
  let mut crossings = 0
  let mut declared = 0
  if segments > 0 && max_rank > 0 {
    let (c, d) = reduce_crossings(g, nodes)
    crossings = c
    declared = d
    set_positions()
  }
  if opt.order_only {
    // Points are (rank, cross-flow position) pairs.
    let at = position(g, opt)
    for i in 0..<real {
      nodes[i].x = at[i]
    }
    for ei in 0..<m {
      let e = edges[ei]
      let a = if e.reversed { e.head } else { e.tail }
      let b = if e.reversed { e.tail } else { e.head }
      let pts = [rank[a].to_double(), at[a]]
      if !direct[ei] && first_dummy[ei] >= 0 {
        for d in first_dummy[ei]..<(first_dummy[ei] + span[ei] - 1) {
          pts.push(rank[d].to_double())
          pts.push(at[d])
        }
      }
      pts.push(rank[b].to_double())
      pts.push(at[b])
      e.points = pts
    }
    return { width: 0, height: 0, crossings, declared, }
  }
  ignore(efk)
  ignore(etk)
  ignore(first_seg)
  ignore(last_seg)
  let xs = position(g, opt)
  let empty = empty_ranks(g)

  // A rank that holds nothing but the bends of edges is only there because some other edge has a label or a twin.
  // Its bends move onto the straight line between the ends of their edges, and one that gets there is left out of the route, so that the edge is drawn as a single curve.
  let on_line = FixedArray::make(n, false)
  if empty is Some(empty) && !opt.tracks {
    straighten(
      g,
      xs,
      empty,
      first_dummy,
      span,
      if opt.apart {
        0
      } else {
        opt.edge_sep
      },
      on_line,
    )
  }
  if !opt.tracks {
    past_labels(g, xs, first_dummy, span, opt.edge_sep, on_line)
  }

  // Ranks that hold only border ports or their pass-through dummies need little room of their own.
  let port_only = fn(r : Int32, wanted : Kind) {
    let mut found = false
    for i in layer_start[r]..<layer_start[r + 1] {
      let k = kind[order[i]]
      if k.ordinal() == wanted.ordinal() {
        found = true
      } else if !(k is Dummy) {
        return false
      }
    }
    found
  }
  let start_ranks = if port_only(0, StartPort) { step } else { 0 }
  let end_ranks = if port_only(max_rank, EndPort) { step } else { 0 }
  // The longest way across that any edge travels in the gap below each rank.
  let run = FixedArray::make(max_rank + 1, 0.0)
  for e in 0..<segments {
    let across = (xs[ef[e]] + efd[e] - xs[et[e]] - etd[e]).abs()
    if across > run[rank[ef[e]]] {
      run[rank[ef[e]]] = across
    }
  }
  let band_top = FixedArray::make(max_rank + 1, 0.0)
  let band_bottom = FixedArray::make(max_rank + 1, 0.0)
  let usual = fn(r : Int32) {
    (if r < start_ranks || r >= max_rank - end_ranks {
      opt.port_sep
    } else {
      opt.rank_sep
    }) /
    step.to_double()
  }
  // The room under each rank.
  // Edges that are not cut into pieces need more where they run far across.
  let gap_under = FixedArray::make(max_rank + 1, 0.0)
  for r in 0..<max_rank {
    gap_under[r] = jmax(
      usual(r),
      jmin(max_gap * opt.rank_sep / step.to_double(), run[r] * min_slope),
    )
  }
  // A rank between two ranks of nodes, which holds labels and bends only.
  let between = FixedArray::make(max_rank + 1, true)
  for i in 0..<real {
    between[rank[i]] = false
  }
  for r in 1..<max_rank {
    if opt.tracks || !between[r] || (heads[r] != 1 && heads[r] != 2) {
      continue
    }
    let shift = jmin(
      opt.head_room / 2,
      gap_under[if heads[r] == 1 { r - 1 } else { r }] / 2,
    )
    gap_under[r - 1] += if heads[r] == 1 { -shift } else { shift }
    gap_under[r] += if heads[r] == 1 { shift } else { -shift }
  }
  // The part of its rank that an edge runs straight through at a bend or label.
  // A bare bend beside labels keeps to the middle half, which leaves the curves either side of it more room and still keeps them clear of the labels' corners.
  let inset = fn(d : Int32) {
    if kind[d] is Dummy && between[rank[d]] && !opt.tracks {
      (band_bottom[rank[d]] - band_top[rank[d]]) / 4
    } else {
      0.0
    }
  }
  let mut y = 0.0
  for r in 0..<=max_rank {
    let mut tallest = 0.0
    for i in layer_start[r]..<layer_start[r + 1] {
      if h[order[i]] > tallest {
        tallest = h[order[i]]
      }
    }
    band_top[r] = y
    band_bottom[r] = y + tallest
    y += tallest + gap_under[r]
  }
  let height = y
  let mut min_x = @double.infinity
  let mut max_x = @double.neg_infinity
  for i in 0..<n {
    let half = w[i] / 2
    if xs[i] - half < min_x {
      min_x = xs[i] - half
    }
    if xs[i] + half > max_x {
      max_x = xs[i] + half
    }
  }
  for i in 0..<real {
    let node = nodes[i]
    let r = node.rank
    node.x = xs[i] - min_x
    node.y = (band_top[r] + band_bottom[r]) / 2
  }
  for ei in 0..<m {
    let e = edges[ei]
    let first = nodes[if e.reversed { e.head } else { e.tail }]
    let last = nodes[if e.reversed { e.tail } else { e.head }]
    let pts = [
      first.x + (if e.reversed { e.head_dx } else { e.tail_dx }),
      first.y + first.h / 2,
    ]
    let d0 = first_dummy[ei]
    if d0 >= 0 {
      for d in d0..<(d0 + span[ei] - 1) {
        if on_line[d] {
          continue
        }
        let x = xs[d] - min_x
        let top = band_top[rank[d]]
        let bottom = band_bottom[rank[d]]
        pts.push(x)
        pts.push(top + inset(d))
        if bottom > top {
          pts.push(x)
          pts.push(bottom - inset(d))
        }
      }
    }
    pts.push(last.x + (if e.reversed { e.tail_dx } else { e.head_dx }))
    pts.push(last.y - last.h / 2)
    if e.reversed {
      let mut i = 0
      let mut j = pts.length() - 2
      while i < j {
        let tx = pts[i]
        let ty = pts[i + 1]
        pts[i] = pts[j]
        pts[i + 1] = pts[j + 1]
        pts[j] = tx
        pts[j + 1] = ty
        i += 2
        j -= 2
      }
    }
    e.points = pts
    let ln = label_node[ei]
    if ln >= 0 {
      e.label_x = xs[ln] - min_x
      e.label_y = (band_top[rank[ln]] + band_bottom[rank[ln]]) / 2
    } else if e.label_w > 0 {
      e.label_x = (pts[0] + pts[pts.length() - 2]) / 2
      e.label_y = (pts[1] + pts[pts.length() - 1]) / 2
    }
  }
  { width: max_x - min_x, height, crossings: 0, declared: 0, }
}
