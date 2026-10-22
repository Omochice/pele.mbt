///|
/// One set drawn as a circle, in layout units.
pub(all) struct Circle {
  id : String
  mut x : Double
  mut y : Double
  r : Double
}

///|
/// Where the content of a region goes: the point inside all of `inside` and outside every other
/// circle that is farthest from their outlines, and how far that is. A margin of 0 or less means
/// the circles as placed leave the region empty.
pub(all) struct Spot {
  x : Double
  y : Double
  margin : Double
}

///|
let tau : Double = @math.PI * 2

///|
fn is_finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
/// For every overlap of three or more sets, adds the pairwise overlaps it implies and the diagram
/// does not state, a quarter of the smaller set each, so that the circles are drawn overlapping.
/// Returns the list it was given when there is nothing to add.
pub fn ensure_pairwise_subsets(
  subsets : Array[VennSubset],
) -> Array[VennSubset] {
  let present : Set[String] = Set([])
  let sizes : Map[String, Double] = Map([])
  for subset in subsets {
    present.add(sorted_key(subset.sets))
    if subset.sets.length() == 1 {
      sizes[subset.sets[0]] = subset.size
    }
  }
  let added = []
  for subset in subsets {
    if subset.sets.length() < 3 {
      continue
    }
    let members = subset.sets.copy()
    members.sort()
    for i in 0..<(members.length() - 1) {
      for j in (i + 1)..<members.length() {
        let pair = [members[i], members[j]]
        let key = sorted_key(pair)
        if present.contains(key) {
          continue
        }
        present.add(key)
        let size = match (sizes.get(pair[0]), sizes.get(pair[1])) {
          (Some(a), Some(b)) => @cmp.minimum(a, b) / 4
          _ => 2.5
        }
        added.push({ sets: pair, size, label: Some(""), })
      }
    }
  }
  if added.is_empty() {
    subsets
  } else {
    subsets + added
  }
}

///|
/// The area two circles share when their centers are d apart.
pub fn lens_area(r1 : Double, r2 : Double, d : Double) -> Double {
  if d >= r1 + r2 {
    return 0
  }
  let small = @cmp.minimum(r1, r2)
  if d <= (r1 - r2).abs() {
    return @math.PI * small * small
  }
  let a1 = r1 * r1 * @math.acos((d * d + r1 * r1 - r2 * r2) / (2 * d * r1))
  let a2 = r2 * r2 * @math.acos((d * d + r2 * r2 - r1 * r1) / (2 * d * r2))
  let product = (-d + r1 + r2) * (d + r1 - r2) * (d - r1 + r2) * (d + r1 + r2)
  let a3 = 0.5 * (if product > 0 { product } else { 0.0 }).sqrt()
  a1 + a2 - a3
}

///|
/// How far apart two circles sit for their overlap to have the given area. The area falls as the
/// distance grows, so bisection finds it.
pub fn distance_for_overlap(r1 : Double, r2 : Double, area : Double) -> Double {
  let mut low = (r1 - r2).abs()
  let mut high = r1 + r2
  if !(area > 0) {
    return high
  }
  let small = @cmp.minimum(r1, r2)
  if area >= @math.PI * (small * small) {
    return low
  }
  for _ in 0..<48 {
    let middle = (low + high) / 2
    if lens_area(r1, r2, middle) > area {
      low = middle
    } else {
      high = middle
    }
  }
  (low + high) / 2
}

///|
/// How far a point is from the nearest outline it must stay within or without. Gives up, with
/// some value below `floor`, as soon as the point cannot reach `floor`.
fn margin(
  circles : Array[Circle],
  inside : Array[Int32],
  outside : Array[Int32],
  x : Double,
  y : Double,
  floor : Double,
) -> Double {
  let mut best = @double.infinity
  for i in inside {
    let c = circles[i]
    let dx = x - c.x
    let dy = y - c.y
    let room = c.r - (dx * dx + dy * dy).sqrt()
    if room < best {
      if room < floor {
        return room
      }
      best = room
    }
  }
  for i in outside {
    let c = circles[i]
    let dx = x - c.x
    let dy = y - c.y
    let room = (dx * dx + dy * dy).sqrt() - c.r
    if room < best {
      if room < floor {
        return room
      }
      best = room
    }
  }
  best
}

///|
priv struct Search {
  mut x : Double
  mut y : Double
  mut best : Double
  mut off : Double
}

///|
fn Search::consider(
  self : Search,
  circles : Array[Circle],
  inside : Array[Int32],
  outside : Array[Int32],
  center : (Double, Double),
  r : Double,
  px : Double,
  py : Double,
) -> Bool {
  let m = margin(circles, inside, outside, px, py, self.best - r * 1.0e-9)
  if !(m > self.best - r * 1.0e-9) {
    return false
  }
  let distance = hypot(px - center.0, py - center.1)
  if m > self.best + r * 1.0e-9 || distance < self.off - r * 1.0e-9 {
    self.best = m
    self.off = distance
    self.x = px
    self.y = py
    return true
  }
  false
}

///|
/// Finds the roomiest point of a region by sampling the smallest of its circles on a grid and then
/// walking uphill from the best sample. Ties go to the point nearest the middle of the region, so
/// a symmetric arrangement gets symmetric labels.
pub fn find_spot(
  circles : Array[Circle],
  inside : Array[Int32],
  outside : Array[Int32],
) -> Spot {
  let mut cx = 0.0
  let mut cy = 0.0
  let mut smallest = circles[inside[0]]
  let count = inside.length().to_double()
  for i in inside {
    let c = circles[i]
    cx += c.x / count
    cy += c.y / count
    if c.r < smallest.r {
      smallest = c
    }
  }
  let r = smallest.r
  let search = {
    x: cx,
    y: cy,
    best: margin(circles, inside, outside, cx, cy, @double.neg_infinity),
    off: 0.0,
  }
  let consider = (px : Double, py : Double) => {
    search.consider(circles, inside, outside, (cx, cy), r, px, py)
  }
  let grid = 10
  for gy in -grid..<=grid {
    for gx in -grid..<=grid {
      if gx * gx + gy * gy <= grid * grid {
        consider(
          smallest.x + gx.to_double() * r / grid.to_double(),
          smallest.y + gy.to_double() * r / grid.to_double(),
        )
        |> ignore
      }
    }
  }
  let mut step = r / grid.to_double()
  let mut round = 0
  while round < 40 && step > r * 1.0e-6 {
    let mut moved = false
    for k in 0..<8 {
      let angle = k.to_double() * tau / 8
      if consider(
          search.x + @math.cos(angle) * step,
          search.y + @math.sin(angle) * step,
        ) {
        moved = true
      }
    }
    if !moved {
      step /= 2
    }
    round += 1
  }
  { x: search.x, y: search.y, margin: search.best, }
}

///|
/// Places one circle per set, with areas in proportion to the sizes of the sets and each pair as
/// far apart as its overlap asks: one, two and three sets exactly, more by relaxing a ring of
/// circles toward those distances. Lengths are in units of the square root of a size.
pub fn layout_circles(subsets : Array[VennSubset]) -> Array[Circle] {
  let sizes : Map[String, Double] = Map([])
  for subset in subsets {
    for id in subset.sets {
      if !sizes.contains(id) {
        sizes[id] = 10
      }
    }
  }
  for subset in subsets {
    if subset.sets.length() == 1 {
      sizes[subset.sets[0]] = subset.size
    }
  }
  let index : Map[String, Int32] = Map([])
  let circles : Array[Circle] = []
  let mut largest = 0.0
  for size in sizes.values() {
    if is_finite(size) && size > largest {
      largest = size
    }
  }
  if largest == 0 {
    largest = 10
  }
  let widest = (largest / @math.PI).sqrt()
  for id, size in sizes {
    index[id] = circles.length()
    // A set too small to hold its name, or with no size at all, still gets a circle that shows.
    let r = if is_finite(size) && size > 0 {
      (size / @math.PI).sqrt()
    } else {
      0.0
    }
    circles.push({ id, x: 0, y: 0, r: @cmp.maximum(r, widest * 0.3), })
  }
  let n = circles.length()
  if n < 2 {
    return circles
  }
  let overlaps : Map[Int32, Double] = Map([])
  for subset in ensure_pairwise_subsets(subsets) {
    if subset.sets.length() != 2 {
      continue
    }
    let a = index[subset.sets[0]]
    let b = index[subset.sets[1]]
    if a != b {
      overlaps[@cmp.minimum(a, b) * n + @cmp.maximum(a, b)] = subset.size
    }
  }
  let wanted : Map[Int32, Double] = Map([])
  for key, area in overlaps {
    wanted[key] = distance_for_overlap(
      circles[key / n].r,
      circles[key % n].r,
      area,
    )
  }
  let gap = widest * 0.15
  let distance = (a : Int32, b : Int32) => {
    match wanted.get(a * n + b) {
      Some(d) => d
      None => circles[a].r + circles[b].r + gap
    }
  }
  if n == 2 {
    circles[1].x = distance(0, 1)
    return circles
  }
  if n == 3 {
    // Two sets side by side and the third below, the corners of a triangle whose sides are the
    // three distances. An overlap of all three has to exist, so the triangle shrinks until it does.
    let mut ab = distance(0, 1)
    let mut ac = distance(0, 2)
    let mut bc = distance(1, 2)
    let triple = subsets.any(subset => {
      let distinct : Set[String] = Set([])
      for id in subset.sets {
        distinct.add(id)
      }
      distinct.length() == 3
    })
    for _ in 0..<40 {
      let x = if ab > 0 {
        (ab * ab + ac * ac - bc * bc) / (2 * ab)
      } else {
        0.0
      }
      circles[1].x = ab
      circles[2].x = @cmp.maximum(-ac, @cmp.minimum(ac, x))
      let rest = ac * ac - x * x
      circles[2].y = (if rest > 0 { rest } else { 0.0 }).sqrt()
      if !triple || find_spot(circles, [0, 1, 2], []).margin > widest * 0.12 {
        break
      }
      ab *= 0.94
      ac *= 0.94
      bc *= 0.94
    }
    return circles
  }
  let mut total = 0.0
  for c in circles {
    total += 2 * c.r + gap
  }
  let rounds = @cmp.minimum(300, (3.0e6 / (n * n).to_double()).floor().to_int())
  if n <= 64 {
    let ring = total / tau
    for i, c in circles {
      let angle = i.to_double() * tau / n.to_double() - @math.PI / 2
      c.x = @math.cos(angle) * ring
      c.y = @math.sin(angle) * ring
    }
  } else {
    let columns = n.to_double().sqrt().ceil().to_int()
    let pitch : Double = widest * 2 + gap
    for i, c in circles {
      c.x = (i % columns).to_double() * pitch
      c.y = (i / columns).to_double() * pitch
    }
  }
  let dx = Array::make(n, 0.0)
  let dy = Array::make(n, 0.0)
  let pulls = Array::make(n, 0)
  for _ in 0..<rounds {
    for i in 0..<n {
      dx[i] = 0
      dy[i] = 0
      pulls[i] = 0
    }
    for a in 0..<n {
      for b in (a + 1)..<n {
        let overlap = wanted.get(a * n + b)
        let apart = circles[a].r + circles[b].r + gap
        let mut ux = circles[b].x - circles[a].x
        let mut uy = circles[b].y - circles[a].y
        let mut length = hypot(ux, uy)
        if overlap is None && length >= apart {
          continue
        }
        if length < 1.0e-9 {
          ux = @math.cos((a + b).to_double())
          uy = @math.sin((a + b).to_double())
          length = 1
        }
        let shift = (length - overlap.unwrap_or(apart)) / 2 / length
        dx[a] += ux * shift
        dy[a] += uy * shift
        dx[b] -= ux * shift
        dy[b] -= uy * shift
        pulls[a] += 1
        pulls[b] += 1
      }
    }
    for i in 0..<n {
      if pulls[i] == 0 {
        continue
      }
      circles[i].x += dx[i] / pulls[i].to_double()
      circles[i].y += dy[i] / pulls[i].to_double()
    }
  }
  circles
}

///|
priv struct Corner {
  x : Double
  y : Double
  a : Int32
  b : Int32
}

///|
fn whole(c : Circle, format : (Double) -> String) -> String {
  "M\{format(c.x - c.r)},\{format(c.y)}A\{format(c.r)},\{format(c.r)} 0 1 1 \{format(c.x + c.r)},\{format(c.y)}A\{format(c.r)},\{format(c.r)} 0 1 1 \{format(c.x - c.r)},\{format(c.y)}Z"
}

///|
/// The outline of the region all the given circles share, as an SVG path, or '' if they share none.
pub fn region_path(
  circles : Array[Circle],
  format : (Double) -> String,
) -> String {
  if circles.length() == 1 {
    return whole(circles[0], format)
  }
  let within = (x : Double, y : Double, skip : Int32, other : Int32) => {
    for i, c in circles {
      if i != skip && i != other && hypot(x - c.x, y - c.y) > c.r * (1 + 1.0e-9) {
        return false
      }
    }
    true
  }
  // The corners of the region: where two outlines cross inside all the other circles.
  let corners : Array[Corner] = []
  for i in 0..<circles.length() {
    for j in (i + 1)..<circles.length() {
      let a = circles[i]
      let b = circles[j]
      let d = hypot(b.x - a.x, b.y - a.y)
      if d >= a.r + b.r || d <= (a.r - b.r).abs() || d == 0 {
        continue
      }
      let along = (a.r * a.r - b.r * b.r + d * d) / (2 * d)
      let rest = a.r * a.r - along * along
      let up = (if rest > 0 { rest } else { 0.0 }).sqrt()
      let mx = a.x + (b.x - a.x) * along / d
      let my = a.y + (b.y - a.y) * along / d
      for sign in [1.0, -1.0] {
        let x = mx + sign * up * (b.y - a.y) / d
        let y = my - sign * up * (b.x - a.x) / d
        if within(x, y, i, j) {
          corners.push({ x, y, a: i, b: j, })
        }
      }
    }
  }
  if corners.length() < 2 {
    // No corners: either one circle lies inside all the others, or there is nothing shared.
    let mut smallest = 0
    for i, c in circles {
      if c.r < circles[smallest].r {
        smallest = i
      }
    }
    let inner = circles[smallest]
    for i, c in circles {
      if i != smallest &&
        hypot(c.x - inner.x, c.y - inner.y) + inner.r > c.r * (1 + 1.0e-9) {
        return ""
      }
    }
    return whole(inner, format)
  }
  let mut cx = 0.0
  let mut cy = 0.0
  let count = corners.length().to_double()
  for p in corners {
    cx += p.x / count
    cy += p.y / count
  }
  // The sort is stable in JavaScript; the original position settles ties here.
  let ordered = corners.mapi((i, p) => (@math.atan2(p.y - cy, p.x - cx), i, p))
  ordered.sort_by((p, q) => {
    if p.0 < q.0 {
      -1
    } else if p.0 > q.0 {
      1
    } else {
      p.1 - q.1
    }
  })
  let sorted = ordered.map(entry => entry.2)
  let d = StringBuilder::new()
  for i in 0..<sorted.length() {
    let from = sorted[i]
    let to = sorted[(i + 1) % sorted.length()]
    if i == 0 {
      d.write_string("M\{format(from.x)},\{format(from.y)}")
    }
    // The side between two corners is an arc of a circle that passes through both; of those, the
    // one whose arc stays inside the others.
    let mut arc = -1
    let mut large = 0
    let mut narrowest = @double.infinity
    for index in [from.a, from.b] {
      if index != to.a && index != to.b {
        continue
      }
      let c = circles[index]
      let start = @math.atan2(from.y - c.y, from.x - c.x)
      let mut sweep = @math.atan2(to.y - c.y, to.x - c.x) - start
      if sweep <= 0 {
        sweep += tau
      }
      let mx = c.x + c.r * @math.cos(start + sweep / 2)
      let my = c.y + c.r * @math.sin(start + sweep / 2)
      let width = hypot(mx - (from.x + to.x) / 2, my - (from.y + to.y) / 2)
      if width < narrowest {
        narrowest = width
        arc = index
        large = if sweep > @math.PI { 1 } else { 0 }
      }
    }
    if arc == -1 {
      d.write_string("L\{format(to.x)},\{format(to.y)}")
    } else {
      let r = format(circles[arc].r)
      d.write_string("A\{r},\{r} 0 \{large} 1 \{format(to.x)},\{format(to.y)}")
    }
  }
  d.write_string("Z")
  d.to_string()
}
