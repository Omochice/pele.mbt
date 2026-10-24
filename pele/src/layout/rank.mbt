///|
/// Reverses the edges that close a cycle, found by depth-first search in declaration order.
pub fn orient(nodes : Array[LNode], edges : Array[LEdge]) -> Unit {
  let n = nodes.length()
  let m = edges.length()
  let start = FixedArray::make(n + 1, 0)
  for i in 0..<m {
    let e = edges[i]
    e.reversed = nodes[e.head].kind is StartPort ||
      nodes[e.tail].kind is EndPort
    if !e.reversed {
      start[e.tail + 1] += 1
    }
  }
  for i in 0..<n {
    start[i + 1] += start[i]
  }
  let out = FixedArray::make(start[n], 0)
  let fill = FixedArray::makei(n, i => start[i])
  for i in 0..<m {
    if !edges[i].reversed {
      out[fill[edges[i].tail]] = i
      fill[edges[i].tail] += 1
    }
  }
  let state = FixedArray::make(n, 0)
  let cursor = FixedArray::makei(n, i => start[i])
  let stack : Array[Int32] = []
  for root in 0..<n {
    if state[root] != 0 {
      continue
    }
    stack.push(root)
    state[root] = 1
    while stack.length() > 0 {
      let v = stack[stack.length() - 1]
      if cursor[v] < start[v + 1] {
        let e = edges[out[cursor[v]]]
        cursor[v] += 1
        let w = e.head
        if state[w] == 1 {
          e.reversed = true
        } else if state[w] == 0 {
          state[w] = 1
          stack.push(w)
        }
      } else {
        state[v] = 2
        ignore(stack.pop())
      }
    }
  }
}

///|
/// Gives every node a rank, each edge spanning at least `step` times its `minlen`, with border ports in the first and last ranks.
pub fn rank(nodes : Array[LNode], edges : Array[LEdge], step : Int32) -> Unit {
  let n = nodes.length()
  let m = edges.length()
  let from = FixedArray::make(m, 0)
  let to = FixedArray::make(m, 0)
  let len = FixedArray::make(m, 0)
  let out_start = FixedArray::make(n + 1, 0)
  let in_start = FixedArray::make(n + 1, 0)
  for i in 0..<m {
    let e = edges[i]
    let a = if e.reversed { e.head } else { e.tail }
    let b = if e.reversed { e.tail } else { e.head }
    from[i] = a
    to[i] = b
    len[i] = (if e.minlen > 1 { e.minlen } else { 1 }) * step
    out_start[a + 1] += 1
    in_start[b + 1] += 1
  }
  for i in 0..<n {
    out_start[i + 1] += out_start[i]
    in_start[i + 1] += in_start[i]
  }
  let out_e = FixedArray::make(m, 0)
  let in_e = FixedArray::make(m, 0)
  let of_ = FixedArray::makei(n, i => out_start[i])
  let inf = FixedArray::makei(n, i => in_start[i])
  for i in 0..<m {
    out_e[of_[from[i]]] = i
    of_[from[i]] += 1
    in_e[inf[to[i]]] = i
    inf[to[i]] += 1
  }
  let r = FixedArray::make(n, 0)
  let indeg = FixedArray::makei(n, i => in_start[i + 1] - in_start[i])
  let topo = FixedArray::make(n, 0)
  let mut count = 0
  for i in 0..<n {
    if indeg[i] == 0 {
      topo[count] = i
      count += 1
    }
  }
  let mut q = 0
  while q < count {
    let v = topo[q]
    for k in out_start[v]..<out_start[v + 1] {
      let ei = out_e[k]
      let w = to[ei]
      if r[v] + len[ei] > r[w] {
        r[w] = r[v] + len[ei]
      }
      indeg[w] -= 1
      if indeg[w] == 0 {
        topo[count] = w
        count += 1
      }
    }
    q += 1
  }

  // Longest-path ranking leaves loosely attached nodes far from their neighbours.
  // Each moves toward the side that has more edges.
  for _pass in 0..<8 {
    let mut changed = false
    for q = count - 1; q >= 0; q = q - 1 {
      let v = topo[q]
      let ins = in_start[v + 1] - in_start[v]
      let outs = out_start[v + 1] - out_start[v]
      if ins == 0 && outs == 0 {
        continue
      }
      let mut lo : Int32? = None
      let mut hi : Int32? = None
      for k in in_start[v]..<in_start[v + 1] {
        let ei = in_e[k]
        let at = r[from[ei]] + len[ei]
        lo = match lo {
          Some(l) if l >= at => Some(l)
          _ => Some(at)
        }
      }
      for k in out_start[v]..<out_start[v + 1] {
        let ei = out_e[k]
        let at = r[to[ei]] - len[ei]
        hi = match hi {
          Some(h) if h <= at => Some(h)
          _ => Some(at)
        }
      }
      let mut next = r[v]
      if outs > ins && hi is Some(h) {
        next = h
      } else if ins > outs && lo is Some(l) {
        next = l
      }
      if next != r[v] {
        r[v] = next
        changed = true
      }
    }
    if !changed {
      break
    }
  }
  let mut min : Int32? = None
  let mut max = 0
  let mut start_ports = false
  for i in 0..<n {
    let kind = nodes[i].kind
    if kind is StartPort {
      start_ports = true
    }
    if kind is (StartPort | EndPort) {
      continue
    }
    match min {
      None => {
        min = Some(r[i])
        max = r[i]
      }
      Some(low) => {
        if r[i] < low {
          min = Some(r[i])
        }
        if r[i] > max {
          max = r[i]
        }
      }
    }
  }
  let mut min = min.unwrap_or(0)
  for i in 0..<n {
    if nodes[i].kind is StartPort {
      r[i] = min - step
    } else if nodes[i].kind is EndPort {
      r[i] = max + step
    }
  }
  if start_ports {
    min -= step
  }
  for i in 0..<n {
    nodes[i].rank = r[i] - min
  }
}
