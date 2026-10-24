///|
/// How routes are drawn, which decides where they cross.
pub(all) enum Style {
  Curved
  Stepped
  Linear
}

///|
/// How the routes of a layout with these options are drawn.
pub fn style_of(opt : LayeredOptions) -> Style {
  if opt.tracks {
    Stepped
  } else if opt.straight {
    Linear
  } else {
    Curved
  }
}

///|
/// Crossings this near a node that both edges meet are where they fan out from it.
let fan_room = 24.0

///|
let in_line : Double = 0.5

///|
let curve_pieces = 3

///|
let corner_pieces = 2

///|
/// Room for a step, an S-curve, or a straight segment plus a rounded corner.
let step_pieces = 3

///|
/// Matches the renderer's corner handles.
let handle = 0.62

///|
let max_insert = 128

///|
/// How many times the drawn routes of `edges` cross, leaving out edges that fan out from a node they share.
pub fn route_crossings(
  nodes : Array[CNode],
  edges : Array[CEdge],
  style~ : Style = Curved,
) -> Int32 {
  let curved = style is Curved
  let mut size = 0
  for e in edges {
    if e.src != e.dst && e.route.length() > 3 {
      size += (e.route.length() / 3 - 1) * step_pieces
    }
  }
  let ax = FixedArray::make(size, 0.0)
  let ay = FixedArray::make(size, 0.0)
  let bx = FixedArray::make(size, 0.0)
  let by = FixedArray::make(size, 0.0)
  let low = FixedArray::make(size, 0.0)
  let high = FixedArray::make(size, 0.0)
  let owner = FixedArray::make(size, 0)
  // 1 marks an edge's first segment, 2 its last.
  let ends = FixedArray::make(size, 0)
  let mut count = 0
  let mut top = @double.infinity
  let mut bottom = @double.neg_infinity
  let mut from_x = @double.not_a_number
  let mut from_y = @double.not_a_number
  let mut to_x = @double.not_a_number
  let mut to_y = @double.not_a_number
  fn add(
    ei : Int32,
    part : Int32,
    x0 : Double,
    y0 : Double,
    x1 : Double,
    y1 : Double,
  ) {
    let p = count - 1
    let mut x0 = x0
    let mut y0 = y0
    let on = x0 == to_x &&
      y0 == to_y &&
      ((y1 == y0 && from_y == y0) || (x1 == x0 && from_x == x0))
    if on &&
      owner[p] == ei &&
      ends[p] == part &&
      (x0 - from_x) * (x1 - x0) + (y0 - from_y) * (y1 - y0) > 0.0 {
      count -= 1
      x0 = from_x
      y0 = from_y
    }
    from_x = x0
    from_y = y0
    to_x = x1
    to_y = y1
    ends[count] = part
    ax[count] = @util.js_min(x0, x1)
    bx[count] = @util.js_max(x0, x1)
    ay[count] = if x0 <= x1 { y0 } else { y1 }
    by[count] = if x0 <= x1 { y1 } else { y0 }
    low[count] = @util.js_min(y0, y1)
    high[count] = @util.js_max(y0, y1)
    if low[count] < top {
      top = low[count]
    }
    if high[count] > bottom {
      bottom = high[count]
    }
    owner[count] = ei
    count += 1
  }

  for ei in 0..<edges.length() {
    let e = edges[ei]
    if e.src == e.dst {
      continue
    }
    let r = e.route
    // An edge whose ends share a group has no route yet while the layout compares its attempts; pele reads past the end of it and draws nothing.
    if r.length() < 6 {
      continue
    }
    let aligned = fn(k : Int32) {
      (r[k] - r[k - 3]).abs() < 0.01 || (r[k + 1] - r[k - 2]).abs() < 0.01
    }
    let length = fn(k : Int32) {
      (r[k] - r[k - 3]).abs() + (r[k + 1] - r[k - 2]).abs()
    }
    let turns = fn(k : Int32) {
      curved &&
      k > 0 &&
      k < r.length() - 3 &&
      aligned(k) &&
      aligned(k + 3) &&
      length(k) >= 0.01 &&
      length(k + 3) >= 0.01 &&
      ((r[k] - r[k - 3]).abs() < 0.01) != ((r[k + 3] - r[k]).abs() < 0.01)
    }
    let mut at_x = r[0]
    let mut at_y = r[1]
    let mut k = 3
    while k < r.length() {
      let part = (if k == 3 { 1 } else { 0 }) |
        (if k == r.length() - 3 { 2 } else { 0 })
      let x0 = at_x
      let y0 = at_y
      let x1 = r[k]
      let y1 = r[k + 1]
      at_x = x1
      at_y = y1
      if aligned(k) || style is Linear {
        if !turns(k) {
          add(ei, part, x0, y0, x1, y1)
          k += 3
          continue
        }
        // Adjacent corners share a leg, so each gets half.
        let before = if turns(k - 3) { length(k) / 2 } else { length(k) }
        let after = if turns(k + 3) { length(k + 3) / 2 } else { length(k + 3) }
        let ux = (x1 - r[k - 3]) / length(k)
        let uy = (y1 - r[k - 2]) / length(k)
        let vx = (r[k + 3] - x1) / length(k + 3)
        let vy = (r[k + 4] - y1) / length(k + 3)
        let sx = x1 - ux * before
        let sy = y1 - uy * before
        add(ei, part, x0, y0, sx, sy)
        let c1x = x1 - ux * before * (1.0 - handle)
        let c1y = y1 - uy * before * (1.0 - handle)
        let c2x = x1 + vx * after * (1.0 - handle)
        let c2y = y1 + vy * after * (1.0 - handle)
        at_x = x1 + vx * after
        at_y = y1 + vy * after
        let turn = part | (if k + 3 == r.length() - 3 { 2 } else { 0 })
        let mut px = sx
        let mut py = sy
        for i in 1..<=corner_pieces {
          let t = i.to_double() / corner_pieces.to_double()
          let u = 1.0 - t
          let x = u * u * u * sx +
            3.0 * u * u * t * c1x +
            3.0 * u * t * t * c2x +
            t * t * t * at_x
          let y = u * u * u * sy +
            3.0 * u * u * t * c1y +
            3.0 * u * t * t * c2y +
            t * t * t * at_y
          add(ei, turn, px, py, x, y)
          px = x
          py = y
        }
        k += 3
        continue
      }
      if style is Stepped {
        let down = r[k + 2] == 0.0
        let mx = if down { x0 } else { (x0 + x1) / 2 }
        let my = if down { (y0 + y1) / 2 } else { y0 }
        let nx = if down { x1 } else { mx }
        let ny = if down { my } else { y1 }
        add(ei, part, x0, y0, mx, my)
        add(ei, part, mx, my, nx, ny)
        add(ei, part, nx, ny, x1, y1)
        k += 3
        continue
      }
      // Approximates the rendered S-curve with straight segments.
      let down = r[k + 2] == 0.0
      let c = if down { ease(x1 - x0, y1 - y0) } else { ease(y1 - y0, x1 - x0) }
      let mut px = x0
      let mut py = y0
      for i in 1..<=curve_pieces {
        let t = i.to_double() / curve_pieces.to_double()
        let u = 1.0 - t
        let across = t * t * (3.0 - 2.0 * t)
        let along = 3.0 * c * t * u * u +
          3.0 * (1.0 - c) * t * t * u +
          t * t * t
        let x = x0 + (x1 - x0) * (if down { across } else { along })
        let y = y0 + (y1 - y0) * (if down { along } else { across })
        add(ei, part, px, py, x, y)
        px = x
        py = y
      }
      k += 3
    }
  }
  // Each pair is counted only in the first band that both segments share.
  let bands = if bottom > top {
    count.to_double().sqrt().round().to_int()
  } else {
    1
  }
  let scale = if bottom > top {
    bands.to_double() / (bottom - top)
  } else {
    0.0
  }
  let band_of = fn(y : Double) {
    @util.js_min((bands - 1).to_double(), ((y - top) * scale).floor()).to_int()
  }
  let first = FixedArray::make(count, 0)
  let band_start = FixedArray::make(bands + 1, 0)
  for p in 0..<count {
    first[p] = band_of(low[p])
    for b in first[p]..<=band_of(high[p]) {
      band_start[b + 1] += 1
    }
  }
  for b in 0..<bands {
    band_start[b + 1] += band_start[b]
  }
  let fill = FixedArray::make(bands, 0)
  for b in 0..<bands {
    fill[b] = band_start[b]
  }
  let in_band = FixedArray::make(band_start[bands], 0)
  for p in 0..<count {
    for b in first[p]..<=band_of(high[p]) {
      in_band[fill[b]] = p
      fill[b] += 1
    }
  }
  // Edges that merge into a shared run at their end do not cross there.
  let runs = FixedArray::make(edges.length() * 8, 0.0)
  let in_line_at = fn(r : Array[Double], a : Int32, b : Int32, c : Int32) {
    ((r[a] - r[b]).abs() < in_line && (r[a] - r[c]).abs() < in_line) ||
    (
      (r[a + 1] - r[b + 1]).abs() < in_line &&
      (r[a + 1] - r[c + 1]).abs() < in_line
    )
  }
  for ei in 0..<edges.length() {
    let r = edges[ei].route
    if r.length() < 6 {
      continue
    }
    let mut k = 3
    while k + 3 < r.length() && in_line_at(r, 0, k, k + 3) {
      k += 3
    }
    let last = r.length() - 3
    let mut j = last - 3
    while j >= 3 && in_line_at(r, last, j, j - 3) {
      j -= 3
    }
    let o = ei * 8
    runs[o] = r[0]
    runs[o + 1] = r[1]
    runs[o + 2] = r[k]
    runs[o + 3] = r[k + 1]
    runs[o + 4] = r[j]
    runs[o + 5] = r[j + 1]
    runs[o + 6] = r[last]
    runs[o + 7] = r[last + 1]
  }
  let on_run = fn(ei : Int32, end : Int32, x : Double, y : Double) {
    let o = ei * 8 + (if end == 1 { 0 } else { 4 })
    let x0 = runs[o]
    let y0 = runs[o + 1]
    let dx = runs[o + 2] - x0
    let dy = runs[o + 3] - y0
    let length = dx * dx + dy * dy
    let t = if length > 0.0 {
      @util.js_max(
        0.0,
        @util.js_min(1.0, ((x - x0) * dx + (y - y0) * dy) / length),
      )
    } else {
      0.0
    }
    @util.js_hypot(x - x0 - t * dx, y - y0 - t * dy) < in_line
  }
  let mut total = 0
  for band in 0..<bands {
    let band_end = band_start[band + 1]
    if band_end - band_start[band] > max_insert {
      sort_range(in_band, band_start[band], band_end, fn(p, q) {
        or_else(ax[p] - ax[q], (p - q).to_double())
      })
    } else {
      for i in (band_start[band] + 1)..<band_end {
        let p = in_band[i]
        let mut j = i
        while j > band_start[band] && ax[in_band[j - 1]] > ax[p] {
          in_band[j] = in_band[j - 1]
          j -= 1
        }
        in_band[j] = p
      }
    }
    for s in band_start[band]..<band_end {
      let p = in_band[s]
      let dx = bx[p] - ax[p]
      let dy = by[p] - ay[p]
      let here = first[p] == band
      for t in (s + 1)..<band_end {
        let q = in_band[t]
        if ax[q] > bx[p] {
          break
        }
        if high[q] < low[p] ||
          low[q] > high[p] ||
          owner[p] == owner[q] ||
          (!here && first[q] != band) {
          continue
        }
        let d1 = dx * (ay[q] - ay[p]) - dy * (ax[q] - ax[p])
        let d2 = dx * (by[q] - ay[p]) - dy * (bx[q] - ax[p])
        // A point on the line counts as one side, so a crossing at a segment boundary counts once.
        if (d1 > 0.0) == (d2 > 0.0) {
          continue
        }
        let ex = bx[q] - ax[q]
        let ey = by[q] - ay[q]
        let d3 = ex * (ay[p] - ay[q]) - ey * (ax[p] - ax[q])
        let d4 = ex * (by[p] - ay[q]) - ey * (bx[p] - ax[q])
        if (d3 > 0.0) == (d4 > 0.0) {
          continue
        }
        let ep = edges[owner[p]]
        let eq = edges[owner[q]]
        let at = d3 / (d3 - d4)
        let x = ax[p] + at * dx
        let y = ay[p] + at * dy
        let fan = fn(v : Int32, pe : Int32, qe : Int32) {
          ((ends[p] & pe) != 0 && (ends[q] & qe) != 0) ||
          (
            (x - nodes[v].x).abs() < nodes[v].w / 2 + fan_room &&
            (y - nodes[v].y).abs() < nodes[v].h / 2 + fan_room
          ) ||
          (on_run(owner[p], pe, x, y) && on_run(owner[q], qe, x, y))
        }
        if ep.src == eq.src && fan(ep.src, 1, 1) {
          continue
        }
        if ep.src == eq.dst && fan(ep.src, 1, 2) {
          continue
        }
        if ep.dst == eq.src && fan(ep.dst, 2, 1) {
          continue
        }
        if ep.dst == eq.dst && fan(ep.dst, 2, 2) {
          continue
        }
        total += 1
      }
    }
  }
  total
}
