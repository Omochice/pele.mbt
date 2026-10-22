///|
/// The room between two edges that meet one side of a node.
let port_pitch = 16.0

///|
/// The least room that keeps the arrowheads of two edges on one side apart.
let min_pitch = 8.0

///|
/// A node, with whatever it is already in line with, moves this far at most to bring one more of its edges into line.
let snap_reach = 12.0

///|
/// An end that cannot be brought into line leans towards where its edge goes, but keeps this far from the ends of the part of its side that edges spread along.
/// On a narrow node that leaves it in the middle.
let lean_clear = 40.0

///|
/// The ends of edges that may move along one side of a node (0 the side its edges arrive at, 1 the other), ordered by their opposite nodes to avoid crossings.
/// `ids` receives the ends and `room` their minimum gaps, and both must start empty.
/// Returns the sum of the gaps.
/// When there is too little room for a full pitch between each pair, the edges that leave side by side move closer together, since they have no arrowheads to keep apart.
/// With less room still, neighbours that run the same way share a place, which keeps an arrowhead apart from an edge that leaves beside it.
fn side_ends(
  g : Graph,
  v : Int32,
  side : Int32,
  span : Double,
  kinds : FixedArray[Int32],
  ids : Array[Int32],
  room : Array[Double],
) -> Double {
  let start = if side == 0 { g.pred_start } else { g.succ_start }
  let list = if side == 0 { g.pred_e } else { g.succ_e }
  let other = if side == 0 { g.ef } else { g.et }
  let pos = g.pos
  for k in start[v]..<start[v + 1] {
    if kinds[list[k]] != end_held {
      ids.push(list[k])
    }
  }
  if ids.length() < 2 {
    return 0
  }
  sort_array(ids, fn(a, b) {
    or_else((pos[other[a]] - pos[other[b]]).to_double(), (a - b).to_double())
  })
  let fill = fn(share : (Bool, Bool) -> Double) {
    let mut total = 0.0
    room.clear()
    room.push(0)
    for k in 1..<ids.length() {
      let same = kinds[ids[k]] == kinds[ids[k - 1]]
      room.push(share(same && kinds[ids[k]] == end_leaves, same))
      total += room[k]
    }
    total
  }
  let mut total = fill(fn(_leaves, _same) { 1 })
  if span / total < min_pitch {
    total = fill(fn(leaves, _same) { if leaves { 0.5 } else { 1 } })
  }
  if span / total < min_pitch {
    total = fill(fn(_leaves, same) { if same { 0 } else { 1 } })
  }
  if total == 0.0 {
    return 0
  }
  let pitch = jmin(port_pitch, span / total)
  for k in 1..<ids.length() {
    room[k] *= pitch
  }
  total * pitch
}

///|
/// Gives the edges that meet one side of a node places of their own along it, around its middle.
fn spread(
  g : Graph,
  nodes : Array[LNode],
  efk : FixedArray[Int32],
  etk : FixedArray[Int32],
) -> Unit {
  for v in 0..<g.real {
    let span = jmin(nodes[v].span, g.w[v])
    if span <= 0 || !(nodes[v].kind is Node) {
      continue
    }
    for side in 0..<2 {
      let ids = []
      let room = []
      let total = side_ends(
        g,
        v,
        side,
        span,
        if side == 0 {
          etk
        } else {
          efk
        },
        ids,
        room,
      )
      if total == 0.0 {
        continue
      }
      let dx = if side == 0 { g.etd } else { g.efd }
      let mut at = -total / 2
      for k in 0..<ids.length() {
        at += room[k]
        dx[ids[k]] = at
      }
    }
  }
}

///|
/// The segment of an edge that reaches the next point held in place, on the way up from segment `e` (side 0) or down: past the bends in ranks that hold nothing else.
fn follow(
  g : Graph,
  empty : FixedArray[Bool]?,
  e : Int32,
  side : Int32,
) -> Int32 {
  guard empty is Some(empty) else { return e }
  let mut e = e
  for _hops in 0..<100000 {
    let u = if side == 0 { g.ef[e] } else { g.et[e] }
    if !(g.kind[u] is Dummy) || !empty[g.rank[u]] {
      break
    }
    e = if side == 0 {
      g.pred_e[g.pred_start[u]]
    } else {
      g.succ_e[g.succ_start[u]]
    }
  }
  e
}

///|
/// How many ends that may move along it each node has on the side its edges arrive at, and on the other.
/// An end that has a side to itself keeps to the middle; ends that share one cannot all be there, so those may move.
fn free_ends(
  g : Graph,
  efk : FixedArray[Int32],
  etk : FixedArray[Int32],
) -> (FixedArray[Int32], FixedArray[Int32]) {
  let arriving = FixedArray::make(g.n, 0)
  let leaving = FixedArray::make(g.n, 0)
  for e in 0..<g.ef.length() {
    if etk[e] != end_held {
      arriving[g.et[e]] += 1
    }
    if efk[e] != end_held {
      leaving[g.ef[e]] += 1
    }
  }
  (arriving, leaving)
}

///|
/// Brings the labels and bends of each edge into line with an end of the edge, so that it runs straight from that end and turns once, at the other.
/// The end chosen is the one with fewer edges beside it on its node, which is the one nearer the middle of its side, or else the other, as near to that as what is beside them in their ranks leaves room.
/// The other end may then move along its node to meet the line.
/// Bends in ranks that hold nothing else are left to `straighten`.
/// An edge with no one line that all of its labels and bends have room on has each brought into line with the nearest point above or below that is held in place.
fn align_labels(
  g : Graph,
  nodes : Array[LNode],
  xs : FixedArray[Double],
  free : (FixedArray[Int32], FixedArray[Int32]),
  opt : LayeredOptions,
  empty : FixedArray[Bool]?,
) -> Unit {
  let sep = opt.edge_sep
  let real = g.real
  let kind = g.kind
  let rank = g.rank
  let w = g.w
  let ef = g.ef
  let et = g.et
  let succ_start = g.succ_start
  let succ_e = g.succ_e
  let pred_start = g.pred_start
  let pred_e = g.pred_e
  let layer_start = g.layer_start
  let order = g.order
  let pos = g.pos
  let free_on = fn(side : Int32, u : Int32) {
    if side == 0 {
      free.0[u]
    } else {
      free.1[u]
    }
  }
  let placed = fn(v : Int32) {
    match kind[v] {
      Label => true
      Dummy =>
        !(match empty {
          Some(empty) => empty[rank[v]]
          None => false
        })
      _ => false
    }
  }
  // Where segment `e` ends on the way up (side 0) or down, and how many ends share that side of the node there: none for a point that is not on a node.
  let end = fn(e : Int32, side : Int32) {
    let u = if side == 0 { ef[e] } else { et[e] }
    let x = if side == 0 { xs[u] + g.efd[e] } else { xs[u] + g.etd[e] }
    (
      x,
      if u < real && nodes[u].kind is Node {
        free_on(1 - side, u)
      } else {
        0
      },
    )
  }
  // The room the neighbours in its rank leave a label or bend: a full gap from a node or between two labels, half of one between a label and a line that passes it.
  let room = fn(v : Int32) {
    let s = layer_start[rank[v]]
    let i = s + pos[v]
    let clear = fn(other : Int32) {
      w[other] / 2 +
      w[v] / 2 +
      (match kind[other] {
        Node => opt.node_sep / 2 + sep / 2
        k => if k.ordinal() == kind[v].ordinal() { sep } else { sep / 2 }
      })
    }
    let least = if i > s {
      xs[order[i - 1]] + clear(order[i - 1])
    } else {
      @double.neg_infinity
    }
    let most = if i + 1 < layer_start[rank[v] + 1] {
      xs[order[i + 1]] - clear(order[i + 1])
    } else {
      @double.infinity
    }
    (least, most)
  }
  // The place between `lo` and `hi` that is in line with one of two ends, or else nearest the first choice.
  let choose = fn(
    x : Double,
    up : (Double, Int32),
    down : (Double, Int32),
    lo : Double,
    hi : Double,
  ) {
    let up_first = if up.1 != down.1 {
      up.1 < down.1
    } else {
      (up.0 - x).abs() <= (down.0 - x).abs()
    }
    let choices = if up_first { [up.0, down.0] } else { [down.0, up.0] }
    for choice in choices {
      if choice >= lo && choice <= hi {
        return choice
      }
    }
    jmax(lo, jmin(hi, choices[0]))
  }
  let done = FixedArray::make(g.n, false)
  let chain : Array[Int32] = []
  for r in 1..<g.max_rank {
    for i in layer_start[r]..<layer_start[r + 1] {
      if !placed(order[i]) || done[order[i]] {
        continue
      }
      // The edge's labels and bends from its first node to its last, and the room they share.
      let mut top = order[i]
      while is_dummy(kind[ef[pred_e[pred_start[top]]]]) {
        top = ef[pred_e[pred_start[top]]]
      }
      let mut bottom = top
      let mut lo = @double.neg_infinity
      let mut hi = @double.infinity
      chain.clear()
      let mut d = top
      while is_dummy(kind[d]) {
        bottom = d
        if placed(d) {
          done[d] = true
          chain.push(d)
          let (least, most) = room(d)
          if least > lo {
            lo = least
          }
          if most < hi {
            hi = most
          }
        }
        d = et[succ_e[succ_start[d]]]
      }
      if lo <= hi {
        let x = choose(
          xs[chain[0]],
          end(pred_e[pred_start[top]], 0),
          end(succ_e[succ_start[bottom]], 1),
          lo,
          hi,
        )
        for d in chain {
          xs[d] = x
        }
        continue
      }
      for d in chain {
        let (least, most) = room(d)
        if least > most {
          continue
        }
        xs[d] = choose(
          xs[d],
          end(follow(g, empty, pred_e[pred_start[d]], 0), 0),
          end(follow(g, empty, succ_e[succ_start[d]], 1), 1),
          least,
          most,
        )
      }
    }
  }
}

///|
/// The ends of one side of a node that `settle` moves, in the order they keep.
priv struct SideEnds {
  v : Int32
  side : Int32
  span : Double
  ids : Array[Int32]
  room : Array[Double]
  all : Array[Int32]
}

///|
/// Once the nodes have their places, moves an end along its side when that lets its edge run straight: when the point the edge runs to, or some part of the side it runs to, is in line with the end's own side.
/// Any other end leans towards the point its edge runs to, where its side is long enough, and an end with a side to itself stays in the middle.
/// On a group, the ends keep clear of the points where other edges pass through its border.
fn settle(
  g : Graph,
  nodes : Array[LNode],
  xs : FixedArray[Double],
  efk : FixedArray[Int32],
  etk : FixedArray[Int32],
  free : (FixedArray[Int32], FixedArray[Int32]),
  empty : FixedArray[Bool]?,
) -> Unit {
  let real = g.real
  let w = g.w
  let ef = g.ef
  let et = g.et
  let efd = g.efd
  let etd = g.etd
  let pos = g.pos
  let free_on = fn(side : Int32, u : Int32) {
    if side == 0 {
      free.0[u]
    } else {
      free.1[u]
    }
  }
  // Where the end of segment `e` on node `v` should be, from the middle of its side.
  // The edge is followed up from the segment (side 0) or down, past the bends in ranks that hold nothing else, to where it next comes to a point that is held in place or to another node's side.
  let wanted = fn(
    e : Int32,
    side : Int32,
    v : Int32,
    span : Double,
    again : Bool,
  ) {
    if free_on(side, v) < 2 {
      return 0.0
    }
    let e = follow(g, empty, e, side)
    let u = if side == 0 { ef[e] } else { et[e] }
    let point = if side == 0 { xs[u] + efd[e] } else { xs[u] + etd[e] }
    // Once the other end has its place, this one comes into line with it if it can.
    if again && (point - xs[v]).abs() <= span / 2 + in_line {
      return jmax(-span / 2, jmin(span / 2, point - xs[v]))
    }
    // The part of the other side that its end may move along, if it may move.
    let mut middle = point
    let mut width = 0.0
    if u < real &&
      nodes[u].kind is Node &&
      (if side == 0 { efk } else { etk })[e] != end_held &&
      free_on(1 - side, u) >= 2 {
      width = jmax(0, jmin(nodes[u].span, w[u]))
      if width > 0 {
        middle = xs[u]
      }
    }
    let lo = jmax(xs[v] - span / 2, middle - width / 2)
    let hi = jmin(xs[v] + span / 2, middle + width / 2)
    // Two sides with no part in line: the end leans towards the other, if its side is long enough.
    if lo > hi + in_line {
      let lean = jmax(0, span / 2 - lean_clear)
      return jmax(-lean, jmin(lean, point - xs[v]))
    }
    // Both ends settle on one place in the part the two sides share: nearer the middle of the narrower.
    let place = (xs[v] * width + middle * span) / (width + span)
    jmax(lo, jmin(hi, place)) - xs[v]
  }
  // End order and spacing stay fixed across passes; held ends divide free ends into runs.
  let sides : Array[SideEnds] = []
  for v in 0..<real {
    let span = jmin(nodes[v].span, w[v])
    if span <= 0 || !(nodes[v].kind is Node) {
      continue
    }
    for side in 0..<2 {
      let other = if side == 0 { ef } else { et }
      let start = if side == 0 { g.pred_start } else { g.succ_start }
      let list = if side == 0 { g.pred_e } else { g.succ_e }
      let ids = []
      let room = []
      ignore(
        side_ends(
          g,
          v,
          side,
          span,
          if side == 0 {
            etk
          } else {
            efk
          },
          ids,
          room,
        ),
      )
      if ids.length() == 0 {
        continue
      }
      if ids.length() == 1 {
        room.clear()
        room.push(0)
      }
      let all = []
      for k in start[v]..<start[v + 1] {
        all.push(list[k])
      }
      sort_array(all, fn(a, b) {
        or_else(
          (pos[other[a]] - pos[other[b]]).to_double(),
          (a - b).to_double(),
        )
      })
      sides.push({ v, side, span, ids, room, all, })
    }
  }
  // The ends of an edge follow each other, so the nodes are gone over until none moves: a few times at most, in practice.
  let mut moved = true
  let mut pass = 0
  while moved && pass < 6 {
    moved = false
    for entry in sides {
      let { v, side, span, ids, room, all, } = entry
      let kinds = if side == 0 { etk } else { efk }
      let dx = if side == 0 { etd } else { efd }
      let mut k = 0
      let mut lo = -span / 2
      for i in 0..<=all.length() {
        let held = i < all.length() && kinds[all[i]] == end_held
        if i < all.length() && !held {
          continue
        }
        // The free ends since the last held end occupy ids[k:k + size].
        let mut size = 0
        let mut j = i - 1
        while j >= 0 && kinds[all[j]] != end_held {
          size += 1
          j -= 1
        }
        let hi = if held { dx[all[i]] - port_pitch } else { span / 2 }
        if size > 0 {
          // Isotonic fitting keeps order and spacing by pooling neighbours that are too close.
          let sum : Array[Double] = []
          let count : Array[Int32] = []
          let mut before = 0.0
          for j in 0..<size {
            if j > 0 {
              before += room[k + j]
            }
            sum.push(wanted(ids[k + j], side, v, span, pass > 0) - before)
            count.push(1)
            // Ends that spacing forced to share a place stay together.
            let mut together = j > 0 && room[k + j] == 0.0
            while sum.length() > 1 &&
                  (
                    together ||
                    sum[sum.length() - 2] /
                    count[count.length() - 2].to_double() >
                    sum[sum.length() - 1] /
                    count[count.length() - 1].to_double()
                  ) {
              together = false
              let top = sum.pop().unwrap()
              let pooled = count.pop().unwrap()
              sum[sum.length() - 1] += top
              count[count.length() - 1] += pooled
            }
          }
          let total = before
          let mut j = 0
          before = 0
          for b in 0..<sum.length() {
            // A run that cannot fit between held ends is centered.
            let level = if hi - total < lo {
              (lo + hi - total) / 2
            } else {
              jmax(lo, jmin(hi - total, sum[b] / count[b].to_double()))
            }
            for _c in 0..<count[b] {
              if j > 0 {
                before += room[k + j]
              }
              if (dx[ids[k + j]] - level - before).abs() > 0.01 {
                moved = true
              }
              dx[ids[k + j]] = level + before
              j += 1
            }
          }
          k += size
        }
        if held {
          lo = dx[all[i]] + port_pitch
        }
      }
    }
    pass += 1
  }
}

///|
/// Brings edges that are nearly straight into line, by moving a node a little across the flow along with everything it is in line with already, where the nodes beside them leave room.
/// What is in line stays in line, so each move leaves one more edge straight.
fn snap(
  g : Graph,
  xs : FixedArray[Double],
  empty : FixedArray[Bool]?,
  opt : LayeredOptions,
) -> Unit {
  let n = g.n
  let layer_start = g.layer_start
  let order = g.order
  let pos = g.pos
  let passed = fn(u : Int32) {
    match empty {
      Some(empty) => g.kind[u] is Dummy && empty[g.rank[u]]
      None => false
    }
  }
  // Each edge from one point that is held in place to the next, past the bends in ranks that hold nothing else.
  let a : Array[Int32] = []
  let b : Array[Int32] = []
  let da : Array[Double] = []
  let db : Array[Double] = []
  for e in 0..<g.ef.length() {
    if passed(g.ef[e]) {
      continue
    }
    let f = follow(g, empty, e, 1)
    a.push(g.ef[e])
    b.push(g.et[f])
    da.push(g.efd[e])
    db.push(g.etd[f])
  }
  let off = fn(k : Int32) { xs[b[k]] + db[k] - xs[a[k]] - da[k] }
  // The nodes in line with each other move as one.
  let block = FixedArray::makei(n, i => i)
  let members : Array[Array[Int32]] = Array::makei(n, i => [i])
  let join = fn(x : Int32, y : Int32) {
    let mut keep = block[x]
    let mut drop = block[y]
    if keep == drop {
      return
    }
    if members[keep].length() < members[drop].length() {
      let t = keep
      keep = drop
      drop = t
    }
    for v in members[drop] {
      block[v] = keep
      members[keep].push(v)
    }
    members[drop] = []
  }
  let near : Array[Int32] = []
  for k in 0..<a.length() {
    let d = off(k).abs()
    if d < 0.01 {
      join(a[k], b[k])
    } else if d <= snap_reach {
      near.push(k)
    }
  }
  if near.length() == 0 {
    return
  }
  sort_array(near, fn(x, y) {
    or_else(off(x).abs() - off(y).abs(), (x - y).to_double())
  })
  let gap = fn(v : Int32) { half_room(g, opt, v) }
  // Whether every node of a block can move by `shift` and keep its room from those beside it.
  let free = fn(id : Int32, shift : Double) {
    for v in members[id] {
      let s = layer_start[g.rank[v]]
      let end = layer_start[g.rank[v] + 1]
      let i = s + pos[v]
      if i > s &&
        block[order[i - 1]] != id &&
        xs[v] + shift - xs[order[i - 1]] < gap(v) + gap(order[i - 1]) - 0.01 {
        return false
      }
      if i + 1 < end &&
        block[order[i + 1]] != id &&
        xs[order[i + 1]] - xs[v] - shift < gap(v) + gap(order[i + 1]) - 0.01 {
        return false
      }
    }
    true
  }
  for k in near {
    let d = off(k)
    if d.abs() < 0.01 {
      join(a[k], b[k])
      continue
    }
    if d.abs() > snap_reach || block[a[k]] == block[b[k]] {
      continue
    }
    // The smaller of the two blocks moves, if it can; else the other.
    let upper = block[a[k]]
    let lower = block[b[k]]
    let first = if members[upper].length() <= members[lower].length() {
      upper
    } else {
      lower
    }
    for id in [first, if first == upper { lower } else { upper }] {
      let shift = if id == upper { d } else { -d }
      if !free(id, shift) {
        continue
      }
      for v in members[id] {
        xs[v] += shift
      }
      join(a[k], b[k])
      break
    }
  }
}
