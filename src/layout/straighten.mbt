///|
/// Marks the ranks that hold nothing but the bends of edges, if there are any.
fn empty_ranks(g : Graph) -> FixedArray[Bool]? {
  let empty = FixedArray::make(g.max_rank + 1, false)
  let mut any = false
  for r in 1..<g.max_rank {
    let mut only = g.layer_start[r + 1] > g.layer_start[r]
    for i = g.layer_start[r]; only && i < g.layer_start[r + 1]; i = i + 1 {
      if !(g.kind[g.order[i]] is Dummy) {
        only = false
      }
    }
    if only {
      empty[r] = true
      any = true
    }
  }
  if any {
    Some(empty)
  } else {
    None
  }
}

///|
/// Moves the bends in ranks that hold only bends onto the straight line between the nearest points of their edges that are held in place, and marks the ones that can be left out of the route.
/// `first_dummy` and `span` give each edge's run of bends, one in every rank.
/// `sep` is the room kept between the bends of twin edges, or 0 to leave those out as well.
fn straighten(
  g : Graph,
  xs : FixedArray[Double],
  empty : FixedArray[Bool],
  first_dummy : FixedArray[Int32],
  span : FixedArray[Int32],
  sep : Double,
  on_line : FixedArray[Bool],
) -> Unit {
  let want = FixedArray::make(xs.length(), 0.0)
  // The points that each bend's edge runs between, across the ranks that hold only bends.
  let from = FixedArray::make(xs.length(), 0.0)
  let to = FixedArray::make(xs.length(), 0.0)
  for ei in 0..<first_dummy.length() {
    let d0 = first_dummy[ei]
    if d0 < 0 {
      continue
    }
    let end = d0 + span[ei] - 1
    // A bend's rank is its place in the run, counted from the rank after the edge's first node.
    let base = g.rank[d0]
    let mut d = d0
    while d < end {
      if !empty[base + d - d0] {
        d += 1
        continue
      }
      let mut last = d
      while last + 1 < end && empty[base + last + 1 - d0] {
        last += 1
      }
      let above = g.pred_e[g.pred_start[d]]
      let below = g.succ_e[g.succ_start[last]]
      let x0 = xs[g.ef[above]] + g.efd[above]
      let x1 = xs[g.et[below]] + g.etd[below]
      let steps = last - d + 2
      for k in d..<=last {
        want[k] = x0 + (x1 - x0) * (k - d + 1).to_double() / steps.to_double()
        from[k] = x0
        to[k] = x1
      }
      d = last + 1
    }
  }

  // Nothing in such a rank is in a bend's way, so each one goes onto its line and out of the route.
  // Only twins stay: bends of edges that run between the same two points, which would otherwise be drawn as one.
  // They take places a little apart, around the line.
  for r in 1..<g.max_rank {
    if !empty[r] {
      continue
    }
    let s = g.layer_start[r]
    let end = g.layer_start[r + 1]
    let row = FixedArray::makei(end - s, i => g.order[s + i])
    sort_range(row, 0, row.length(), fn(a, b) {
      or_else(from[a] - from[b], or_else(to[a] - to[b], (a - b).to_double()))
    })
    let mut i = 0
    while i < row.length() {
      let twins : Array[Int32] = []
      let mut j = i
      while j < row.length() &&
            (from[row[j]] - from[row[i]]).abs() < 1 &&
            (to[row[j]] - to[row[i]]).abs() < 1 {
        twins.push(row[j])
        j += 1
      }
      // The twins keep the order the rank gave them, so that two edges do not swap sides on the way.
      let list = FixedArray::makei(twins.length(), k => twins[k])
      sort_range(list, 0, list.length(), fn(a, b) {
        (g.pos[a] - g.pos[b]).to_double()
      })
      for k in 0..<list.length() {
        let d = list[k]
        xs[d] = want[d] +
          (k.to_double() - (list.length() - 1).to_double() / 2) * sep
        if list.length() == 1 || sep == 0.0 {
          on_line[d] = true
        }
      }
      i = j
    }
  }
}

///|
/// In a rank that holds labels and bends but no nodes, a bend is there to take its edge straight through between the labels.
/// Where the edge would pass clear of every label anyway, the bend is left out, and the edge turns in the whole height between the ranks on either side.
fn past_labels(
  g : Graph,
  xs : FixedArray[Double],
  first_dummy : FixedArray[Int32],
  span : FixedArray[Int32],
  clear : Double,
  on_line : FixedArray[Bool],
) -> Unit {
  let labelled = FixedArray::make(g.max_rank + 1, false)
  let mut any = false
  for r in 1..<g.max_rank {
    let mut labels = false
    let mut others = false
    for i in g.layer_start[r]..<g.layer_start[r + 1] {
      match g.kind[g.order[i]] {
        Label => labels = true
        Dummy => ()
        _ => others = true
      }
    }
    if labels && !others {
      labelled[r] = true
      any = true
    }
  }
  if !any {
    return
  }
  for ei in 0..<first_dummy.length() {
    let d0 = first_dummy[ei]
    if d0 < 0 {
      continue
    }
    let end = d0 + span[ei] - 1
    for d in d0..<end {
      if !(g.kind[d] is Dummy) || !labelled[g.rank[d]] {
        continue
      }
      // The points on either side that the edge is held at, past any bends already left out.
      let mut first = d
      let mut last = d
      while first > d0 && on_line[first - 1] {
        first -= 1
      }
      while last + 1 < end && on_line[last + 1] {
        last += 1
      }
      let above = g.pred_e[g.pred_start[first]]
      let below = g.succ_e[g.succ_start[last]]
      let from = xs[g.ef[above]] + g.efd[above]
      let to = xs[g.et[below]] + g.etd[below]
      let lo = jmin(from, to) - clear
      let hi = jmax(from, to) + clear
      let mut free = true
      let r = g.rank[d]
      for i = g.layer_start[r]; free && i < g.layer_start[r + 1]; i = i + 1 {
        let label = g.order[i]
        if g.kind[label] is Label &&
          xs[label] + g.w[label] / 2 > lo &&
          xs[label] - g.w[label] / 2 < hi {
          free = false
        }
      }
      if !free {
        continue
      }
      on_line[d] = true
      // The bends left out between the two points lie on the line between them.
      let steps = last - first + 2
      for k in first..<=last {
        xs[k] = from +
          (to - from) * (k - first + 1).to_double() / steps.to_double()
      }
    }
  }
}
