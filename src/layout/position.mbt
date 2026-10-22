///|
/// Half the room a node, bend or port takes across the flow, with its share of the gap beside it.
/// A port on a group's border is a point that an edge passes through, and needs no more than a bend.
fn half_room(g : Graph, opt : LayeredOptions, v : Int32) -> Double {
  g.w[v] / 2 + (if g.kind[v] is Node { opt.node_sep } else { opt.edge_sep }) / 2
}

///|
/// Sorts `list[from:to]` by `key`, ties by item, with pele's insertion sort.
fn sort_by_key(
  list : FixedArray[Int32],
  from : Int32,
  to : Int32,
  key : FixedArray[Int32],
) -> Unit {
  for i in (from + 1)..<to {
    let item = list[i]
    let k = key[item]
    let mut j = i - 1
    while j >= from &&
          (key[list[j]] > k || (key[list[j]] == k && list[j] > item)) {
      list[j + 1] = list[j]
      j -= 1
    }
    list[j + 1] = item
  }
}

///|
/// Brandes-Köpf coordinate assignment across the flow: four aligned layouts, balanced.
fn position(g : Graph, opt : LayeredOptions) -> FixedArray[Double] {
  let n = g.n
  let max_rank = g.max_rank
  let w = g.w
  let kind = g.kind
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
  let segments = ef.length()
  let gap = FixedArray::makei(n, i => half_room(g, opt, i))

  // Neighbours in left-to-right order, so the medians can be read off directly.
  let key = FixedArray::make(segments, 0)
  for e in 0..<segments {
    key[e] = pos[et[e]]
  }
  for v in 0..<n {
    if succ_start[v + 1] - succ_start[v] > 1 {
      sort_by_key(succ_e, succ_start[v], succ_start[v + 1], key)
    }
  }
  for e in 0..<segments {
    key[e] = pos[ef[e]]
  }
  for v in 0..<n {
    if pred_start[v + 1] - pred_start[v] > 1 {
      sort_by_key(pred_e, pred_start[v], pred_start[v + 1], key)
    }
  }

  // An edge between two real nodes may not cross a dummy-to-dummy segment; those that would are marked.
  let conflict = FixedArray::make(segments, false)
  for r in 1..<=max_rank {
    let prev_len = layer_start[r] - layer_start[r - 1]
    let s = layer_start[r]
    let end = layer_start[r + 1]
    let mut k0 = 0
    let mut scan = s
    for i in s..<end {
      let v = order[i]
      let mut inner = -1
      if is_dummy(kind[v]) {
        let u = ef[pred_e[pred_start[v]]]
        if is_dummy(kind[u]) {
          inner = u
        }
      }
      let k1 = if inner >= 0 { pos[inner] } else { prev_len }
      if inner >= 0 || i == end - 1 {
        for j in scan..<=i {
          let x = order[j]
          let x_dummy = is_dummy(kind[x])
          for k in pred_start[x]..<pred_start[x + 1] {
            let e = pred_e[k]
            let up = pos[ef[e]]
            if (up < k0 || k1 < up) && !(x_dummy && is_dummy(kind[ef[e]])) {
              conflict[e] = true
            }
          }
        }
        scan = i + 1
        k0 = k1
      }
    }
  }
  let results : Array[FixedArray[Double]] = []
  let root = FixedArray::make(n, 0)
  let align = FixedArray::make(n, 0)
  // Offset of each node from its block's root, so that aligned edges meet at their attachment points.
  let shift = FixedArray::make(n, 0.0)
  let e_from = FixedArray::make(n, 0)
  let e_to = FixedArray::make(n, 0)
  let e_w = FixedArray::make(n, 0.0)
  let indeg = FixedArray::make(n, 0)
  let out_start = FixedArray::make(n + 1, 0)
  let out_e = FixedArray::make(n, 0)
  let fill = FixedArray::make(n, 0)
  let topo = FixedArray::make(n, 0)
  let x = FixedArray::make(n, 0.0)
  for variant in 0..<4 {
    let up = variant < 2
    let right = (variant & 1) == 1
    let start = if up { pred_start } else { succ_start }
    let list = if up { pred_e } else { succ_e }
    let other = if up { ef } else { et }
    let own_dx = if up { etd } else { efd }
    let other_dx = if up { efd } else { etd }
    for i in 0..<n {
      root[i] = i
      align[i] = i
      shift[i] = 0
      indeg[i] = 0
      out_start[i + 1] = 0
      x[i] = 0
    }
    for step in 0..<=max_rank {
      let r = if up { step } else { max_rank - step }
      let s = layer_start[r]
      let end = layer_start[r + 1]
      let adjacent = if up { r - 1 } else { r + 1 }
      let adjacent_last = if adjacent >= 0 && adjacent <= max_rank {
        layer_start[adjacent + 1] - layer_start[adjacent] - 1
      } else {
        0
      }
      let mut prev_idx = -1
      let mut i = if right { end - 1 } else { s }
      while (if right { i >= s } else { i < end }) {
        let v = order[i]
        let from = start[v]
        let d = start[v + 1] - from
        if d != 0 {
          let lo = from + ((d - 1) >> 1)
          let hi = from + (d >> 1)
          for pass in 0..<2 {
            if pass == 1 && lo == hi {
              break
            }
            let e = list[if (pass == 0) != right { lo } else { hi }]
            let u = other[e]
            let idx = if right { adjacent_last - pos[u] } else { pos[u] }
            if align[v] == v && prev_idx < idx && !conflict[e] {
              align[u] = v
              root[v] = root[u]
              align[v] = root[u]
              shift[v] = shift[u] + other_dx[e] - own_dx[e]
              prev_idx = idx
            }
          }
        }
        i = if right { i - 1 } else { i + 1 }
      }
    }
    let mut block_edges = 0
    for r in 0..<=max_rank {
      let s = layer_start[r]
      let end = layer_start[r + 1]
      for i in (s + 1)..<end {
        let a = if right { order[i] } else { order[i - 1] }
        let b = if right { order[i - 1] } else { order[i] }
        let sep = gap[a] + gap[b]
        e_from[block_edges] = root[a]
        e_to[block_edges] = root[b]
        e_w[block_edges] = if right {
          sep - shift[a] + shift[b]
        } else {
          sep + shift[a] - shift[b]
        }
        indeg[root[b]] += 1
        out_start[root[a] + 1] += 1
        block_edges += 1
      }
    }
    for i in 0..<n {
      out_start[i + 1] += out_start[i]
    }
    for i in 0..<n {
      fill[i] = out_start[i]
    }
    for e in 0..<block_edges {
      out_e[fill[e_from[e]]] = e
      fill[e_from[e]] += 1
    }
    let mut count = 0
    for i in 0..<n {
      if root[i] == i && indeg[i] == 0 {
        topo[count] = i
        count += 1
      }
    }
    let mut q = 0
    while q < count {
      let v = topo[q]
      for k in out_start[v]..<out_start[v + 1] {
        let e = out_e[k]
        let u = e_to[e]
        if x[v] + e_w[e] > x[u] {
          x[u] = x[v] + e_w[e]
        }
        indeg[u] -= 1
        if indeg[u] == 0 {
          topo[count] = u
          count += 1
        }
      }
      q += 1
    }
    for q = count - 1; q >= 0; q = q - 1 {
      let v = topo[q]
      let mut min = @double.infinity
      for k in out_start[v]..<out_start[v + 1] {
        let e = out_e[k]
        let cand = x[e_to[e]] - e_w[e]
        if cand < min {
          min = cand
        }
      }
      if min != @double.infinity && min > x[v] {
        x[v] = min
      }
    }
    let xs = FixedArray::make(n, 0.0)
    for i in 0..<n {
      xs[i] = (if right { -x[root[i]] } else { x[root[i]] }) + shift[i]
    }
    results.push(xs)
  }
  let mut narrowest = 0
  let mut best_width = @double.infinity
  let mins : Array[Double] = []
  let maxs : Array[Double] = []
  for k in 0..<4 {
    let mut lo = @double.infinity
    let mut hi = @double.neg_infinity
    let xs = results[k]
    for i in 0..<n {
      let half = w[i] / 2
      if xs[i] - half < lo {
        lo = xs[i] - half
      }
      if xs[i] + half > hi {
        hi = xs[i] + half
      }
    }
    mins.push(lo)
    maxs.push(hi)
    if hi - lo < best_width {
      best_width = hi - lo
      narrowest = k
    }
  }
  for k in 0..<4 {
    let delta = if (k & 1) == 0 {
      mins[narrowest] - mins[k]
    } else {
      maxs[narrowest] - maxs[k]
    }
    if delta != 0.0 {
      let xs = results[k]
      for i in 0..<n {
        xs[i] += delta
      }
    }
  }
  let out = FixedArray::make(n, 0.0)
  for i in 0..<n {
    let mut a = results[0][i]
    let mut b = results[1][i]
    let mut c = results[2][i]
    let mut d = results[3][i]
    if a > b {
      let t = a
      a = b
      b = t
    }
    if c > d {
      let t = c
      c = d
      d = t
    }
    if a > c {
      let t = a
      a = c
      c = t
    }
    if b > d {
      let t = b
      b = d
      d = t
    }
    if b > c {
      let t = b
      b = c
      c = t
    }
    out[i] = (b + c) / 2
  }
  out
}
