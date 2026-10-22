///|
let max_sweeps = 24

///|
/// Sorts the first `count` of `list` by barycenter, ties by position, without a comparator call per pair.
/// The insertion runs of eight and the merges are pele's own, so ties fall the same way.
fn sort_by_bary(
  list : FixedArray[Int32],
  count : Int32,
  bary : FixedArray[Double],
  pos : FixedArray[Int32],
  right : Bool,
  spare : FixedArray[Int32],
) -> Unit {
  let before = fn(a : Int32, b : Int32) {
    bary[a] < bary[b] ||
    (
      bary[a] == bary[b] &&
      (if right { pos[a] > pos[b] } else { pos[a] < pos[b] })
    )
  }
  let run = 8
  let mut s = 0
  while s < count {
    let end = if s + run < count { s + run } else { count }
    for i in (s + 1)..<end {
      let item = list[i]
      let mut j = i - 1
      while j >= s && before(item, list[j]) {
        list[j + 1] = list[j]
        j -= 1
      }
      list[j + 1] = item
    }
    s += run
  }
  let mut from = list
  let mut to = spare
  let mut width = run
  while width < count {
    let mut s = 0
    while s < count {
      let mid = if s + width < count { s + width } else { count }
      let end = if s + 2 * width < count { s + 2 * width } else { count }
      let mut i = s
      let mut j = mid
      let mut k = s
      while i < mid && j < end {
        if before(from[j], from[i]) {
          to[k] = from[j]
          j += 1
        } else {
          to[k] = from[i]
          i += 1
        }
        k += 1
      }
      while i < mid {
        to[k] = from[i]
        i += 1
        k += 1
      }
      while j < end {
        to[k] = from[j]
        j += 1
        k += 1
      }
      s += 2 * width
    }
    let t = from
    from = to
    to = t
    width *= 2
  }
  if !physical_equal(from, list) {
    for i in 0..<count {
      list[i] = from[i]
    }
  }
}

///|
/// Orders each rank to cross as few edges as it can, keeping groups contiguous.
/// Returns the final crossings and the crossings before grouping or reordering.
fn reduce_crossings(g : Graph, nodes : Array[LNode]) -> (Int32, Int32) {
  let n = g.n
  let real = g.real
  let max_rank = g.max_rank
  let w = g.w
  let ef = g.ef
  let et = g.et
  let efd = g.efd
  let etd = g.etd
  let succ_start = g.succ_start
  let succ_e = g.succ_e
  let pred_start = g.pred_start
  let pred_e = g.pred_e
  let layer_start = g.layer_start
  let order = g.order
  let pos = g.pos
  let offsets = g.offsets
  let fixed = g.fixed
  let segments = ef.length()
  let mut widest = 0
  for r in 0..<=max_rank {
    let size = layer_start[r + 1] - layer_start[r]
    if size > widest {
      widest = size
    }
  }
  if widest < 2 {
    return (0, 0)
  }
  // With offsets, edges that reach one node at different offsets take separate places along it.
  let place = if offsets { Some(FixedArray::make(segments, 0)) } else { None }
  // Local offset indices and counts do not depend on node order.
  let place_in = FixedArray::make(if offsets { segments } else { 0 }, 0)
  let places = FixedArray::make(if offsets { n } else { 0 }, 0)
  let leaving = if offsets {
    FixedArray::makei(segments, i => succ_e[i])
  } else {
    succ_e
  }
  let mixed = FixedArray::make(if offsets { n } else { 0 }, false)
  if offsets {
    let arriving = FixedArray::makei(segments, i => pred_e[i])
    let by_offset = fn(
      list : FixedArray[Int32],
      from : Int32,
      to : Int32,
      dx : FixedArray[Double],
    ) {
      for k in (from + 1)..<to {
        if dx[list[k]] == dx[list[from]] {
          continue
        }
        sort_range(list, from, to, fn(a, b) { dx[a] - dx[b] })
        return true
      }
      false
    }
    for v in 0..<n {
      places[v] = 1
      if by_offset(arriving, pred_start[v], pred_start[v + 1], etd) {
        for k in (pred_start[v] + 1)..<pred_start[v + 1] {
          if etd[arriving[k]] != etd[arriving[k - 1]] {
            places[v] += 1
          }
          place_in[arriving[k]] = places[v] - 1
        }
      }
      if by_offset(leaving, succ_start[v], succ_start[v + 1], efd) {
        mixed[v] = true
      }
    }
  }
  let mut size = 1
  let limit = if offsets { widest + segments } else { widest }
  while size < limit {
    size = size << 1
  }
  let tree = FixedArray::make(2 * size, 0)
  let targets = FixedArray::make(segments, 0)
  let count = fn() {
    let mut total = 0
    for r in 0..<max_rank {
      let mut south_len = layer_start[r + 2] - layer_start[r + 1]
      if place is Some(place) {
        let mut next = 0
        for i in layer_start[r + 1]..<layer_start[r + 2] {
          let v = order[i]
          for k in pred_start[v]..<pred_start[v + 1] {
            place[pred_e[k]] = next + place_in[pred_e[k]]
          }
          next += places[v]
        }
        south_len = next
      }
      if south_len < 2 {
        continue
      }
      let mut t = 0
      for i in layer_start[r]..<layer_start[r + 1] {
        let v = order[i]
        let from = succ_start[v]
        let to = succ_start[v + 1]
        let t0 = t
        for k in from..<to {
          targets[t] = match place {
            Some(place) => place[leaving[k]]
            None => pos[et[succ_e[k]]]
          }
          t += 1
        }
        let d = t - t0
        if d < 2 {
          continue
        }
        if offsets && mixed[v] {
          // Edges at one offset go in the order of their destinations, so that a shared endpoint does not count as a crossing.
          for a in (t0 + 1)..<t {
            let item = targets[a]
            let dx = efd[leaving[from + a - t0]]
            let mut b = a - 1
            while b >= t0 &&
                  efd[leaving[from + b - t0]] == dx &&
                  targets[b] > item {
              targets[b + 1] = targets[b]
              b -= 1
            }
            targets[b + 1] = item
          }
        } else {
          for a in (t0 + 1)..<t {
            let item = targets[a]
            let mut b = a - 1
            while b >= t0 && targets[b] > item {
              targets[b + 1] = targets[b]
              b -= 1
            }
            targets[b + 1] = item
          }
        }
      }
      if t < 2 {
        continue
      }
      let mut leaves = 1
      while leaves < south_len {
        leaves = leaves << 1
      }
      for i in 0..<(2 * leaves) {
        tree[i] = 0
      }
      for k in 0..<t {
        let mut i = targets[k] + leaves
        tree[i] += 1
        while i > 1 {
          if (i & 1) == 0 {
            total += tree[i + 1]
          }
          i = i >> 1
          tree[i] += 1
        }
      }
    }
    total
  }
  let declared = count()
  let bary = FixedArray::make(n, 0.0)
  let moving = FixedArray::make(widest, 0)
  let spare = FixedArray::make(widest, 0)

  // Groups stay contiguous, each ordered by its mean key.
  let group_parent = g.group_parent.unwrap_or([])
  let groups = group_parent.length()
  let depth = FixedArray::make(groups, 0)
  for gr in 0..<groups {
    let mut p = gr
    while p >= 0 {
      depth[gr] += 1
      p = group_parent[p]
    }
  }
  let group_sum = FixedArray::make(groups, 0.0)
  let group_count = FixedArray::make(groups, 0)
  let group_first = FixedArray::make(groups, 0)
  let arrange = fn(
    grp : FixedArray[Int32],
    r : Int32,
    key : FixedArray[Double],
  ) {
    let s = layer_start[r]
    let e = layer_start[r + 1]
    for i in s..<e {
      let mut gr = grp[order[i]]
      while gr >= 0 {
        group_sum[gr] = 0
        group_count[gr] = 0
        gr = group_parent[gr]
      }
    }
    for i in s..<e {
      let v = order[i]
      let mut gr = grp[v]
      while gr >= 0 {
        if group_count[gr] == 0 {
          group_first[gr] = i
        }
        group_sum[gr] += key[v]
        group_count[gr] += 1
        gr = group_parent[gr]
      }
    }
    // Siblings compare in their nearest common group, where a group stands as n + its id.
    let value = fn(item : Int32) {
      if item >= n {
        group_sum[item - n] / group_count[item - n].to_double()
      } else {
        key[item]
      }
    }
    let first = fn(item : Int32) {
      if item >= n {
        group_first[item - n]
      } else {
        s + pos[item]
      }
    }
    let compare = fn(a : Int32, b : Int32) {
      let mut ia = a
      let mut ib = b
      let mut ca = grp[a]
      let mut cb = grp[b]
      let mut da = if ca < 0 { 0 } else { depth[ca] }
      let mut db = if cb < 0 { 0 } else { depth[cb] }
      while da > db {
        ia = n + ca
        ca = group_parent[ca]
        da -= 1
      }
      while db > da {
        ib = n + cb
        cb = group_parent[cb]
        db -= 1
      }
      while ca != cb {
        ia = n + ca
        ca = group_parent[ca]
        ib = n + cb
        cb = group_parent[cb]
      }
      or_else(value(ia) - value(ib), (first(ia) - first(ib)).to_double())
    }
    sort_range(order, s, e, compare)
    for i in s..<e {
      pos[order[i]] = i - s
    }
  }
  if g.grp is Some(grp) {
    let at = FixedArray::make(n, 0.0)
    for r in 0..<=max_rank {
      for i in layer_start[r]..<layer_start[r + 1] {
        at[order[i]] = (i - layer_start[r]).to_double()
      }
      arrange(grp, r, at)
    }
  }
  let mut best = if g.grp is Some(_) { count() } else { declared }
  if best == 0 {
    return (0, declared)
  }
  let best_order = order.copy()
  // Improvements must beat both the grouped and the ungrouped starting orders.
  let start = if best < declared { best } else { declared }
  let sweep = fn(down : Bool, bias_right : Bool) {
    let start = if down { pred_start } else { succ_start }
    let list = if down { pred_e } else { succ_e }
    let other = if down { ef } else { et }
    let other_dx = if down { efd } else { etd }
    for step in 1..<=max_rank {
      let r = if down { step } else { max_rank - step }
      if fixed[r] {
        continue
      }
      let s = layer_start[r]
      let e = layer_start[r + 1]
      let mut movable = 0
      for i in s..<e {
        let v = order[i]
        let pin = if v < real { nodes[v].pin } else { 0 }
        if pin != 0 {
          bary[v] = pin.to_double() * 1.0e9
          moving[movable] = v
          movable += 1
          continue
        }
        let from = start[v]
        let to = start[v + 1]
        if from == to {
          if g.grp is Some(_) {
            // A node with no neighbours in the adjacent rank keeps its relative position.
            let across = if down {
              layer_start[r] - layer_start[r - 1]
            } else {
              layer_start[r + 2] - layer_start[r + 1]
            }
            bary[v] = ((i - s) * across).to_double() / (e - s).to_double()
            continue
          }
          bary[v] = -1
          continue
        }
        let mut sum = 0.0
        for k in from..<to {
          let u = other[list[k]]
          sum += pos[u].to_double()
          if offsets && w[u] > 0 {
            sum += other_dx[list[k]] / w[u]
          }
        }
        bary[v] = sum / (to - from).to_double()
        moving[movable] = v
        movable += 1
      }
      if g.grp is Some(grp) {
        arrange(grp, r, bary)
        continue
      }
      if movable < 2 {
        continue
      }
      sort_by_bary(moving, movable, bary, pos, bias_right, spare)
      let mut k = 0
      for i in s..<e {
        if bary[order[i]] != -1.0 {
          order[i] = moving[k]
          k += 1
        }
      }
      for i in s..<e {
        pos[order[i]] = i - s
      }
    }
  }

  // How many pairs of nodes in one rank are not in the order they were given.
  let out_of_order = fn() {
    let mut total = 0
    for r in 0..<=max_rank {
      for i in layer_start[r]..<layer_start[r + 1] {
        if order[i] >= real {
          continue
        }
        for j in (i + 1)..<layer_start[r + 1] {
          if order[j] < order[i] {
            total += 1
          }
        }
      }
    }
    total
  }
  let settle_positions = fn() {
    for r in 0..<=max_rank {
      for i in layer_start[r]..<layer_start[r + 1] {
        pos[order[i]] = i - layer_start[r]
      }
    }
  }

  // Adjacent swaps can remove crossings that the barycenter sweeps miss.
  let pin_of = fn(v : Int32) { if v < real { nodes[v].pin } else { 0 } }
  let at = fn(e : Int32, up : Bool) {
    let u = if up { ef[e] } else { et[e] }
    if offsets && w[u] > 0 {
      pos[u].to_double() + (if up { efd[e] } else { etd[e] }) / w[u]
    } else {
      pos[u].to_double()
    }
  }
  // Crossings between a and b, with a left of b.
  let between = fn(a : Int32, b : Int32) {
    let mut c = 0
    for k in pred_start[a]..<pred_start[a + 1] {
      let x = at(pred_e[k], true)
      for j in pred_start[b]..<pred_start[b + 1] {
        if x > at(pred_e[j], true) {
          c += 1
        }
      }
    }
    for k in succ_start[a]..<succ_start[a + 1] {
      let x = at(succ_e[k], false)
      for j in succ_start[b]..<succ_start[b + 1] {
        if x > at(succ_e[j], false) {
          c += 1
        }
      }
    }
    c
  }
  let transpose = fn() {
    for _pass in 0..<8 {
      let mut improved = false
      for r in 0..<=max_rank {
        if fixed[r] {
          continue
        }
        let s = layer_start[r]
        for i = s; i + 1 < layer_start[r + 1]; i = i + 1 {
          let a = order[i]
          let b = order[i + 1]
          if pin_of(a) != pin_of(b) {
            continue
          }
          if g.grp is Some(grp) && grp[a] != grp[b] {
            continue
          }
          if between(b, a) >= between(a, b) {
            continue
          }
          order[i] = b
          order[i + 1] = a
          pos[b] = i - s
          pos[a] = i + 1 - s
          improved = true
        }
      }
      if !improved {
        break
      }
    }
  }

  // The sweeps run twice from the same start, going down first and going up first.
  // They often end with as few crossings either way but a different order, and then the one that keeps more of the nodes in the order they were given is the less surprising.
  // Only graphs small enough to be read node by node get the second run, which costs as much as the first.
  let initial = order.copy()
  let small = n <= 600
  let mut chosen = best_order
  let mut chosen_out = 2147483647
  for attempt in 0..<(if small { 2 } else { 1 }) {
    if attempt > 0 {
      for i in 0..<n {
        order[i] = initial[i]
      }
      settle_positions()
    }
    let mut found = start
    let found_order = initial.copy()
    let mut i = 0
    let mut stale = 0
    while stale < 4 && i < max_sweeps {
      sweep((i + attempt) % 2 == 0, i % 4 >= 2)
      let c = count()
      if c < found {
        found = c
        for j in 0..<n {
          found_order[j] = order[j]
        }
        stale = 0
        if c == 0 {
          break
        }
      }
      i += 1
      stale += 1
    }
    for j in 0..<n {
      order[j] = found_order[j]
    }
    if small && found > 0 {
      settle_positions()
      transpose()
      let c = count()
      if c < found {
        found = c
        for j in 0..<n {
          found_order[j] = order[j]
        }
      }
    }
    let out = if small { out_of_order() } else { 0 }
    if attempt == 0 || found < best || (found == best && out < chosen_out) {
      best = found
      chosen = found_order
      chosen_out = out
    }
  }
  for i in 0..<n {
    order[i] = chosen[i]
  }
  settle_positions()
  for i in 0..<n {
    best_order[i] = chosen[i]
  }
  // The grouped order that was kept may exceed the ungrouped threshold, so it is counted again.
  if g.grp is Some(_) {
    best = count()
  }

  // A drawing and its mirror image cross as often too, and of those two the same choice is made.
  if !small {
    return (best, declared)
  }
  for i in 0..<real {
    if nodes[i].pin != 0 {
      return (best, declared)
    }
  }
  if chosen_out == 0 || fixed[0] || fixed[max_rank] {
    return (best, declared)
  }
  for r in 0..<=max_rank {
    let mut a = layer_start[r]
    let mut b = layer_start[r + 1] - 1
    while a < b {
      let t = order[a]
      order[a] = order[b]
      order[b] = t
      a += 1
      b -= 1
    }
  }
  settle_positions()
  if count() > best || out_of_order() >= chosen_out {
    for i in 0..<n {
      order[i] = best_order[i]
    }
  }
  (best, declared)
}
