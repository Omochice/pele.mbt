///|
const GAP : Double = 12

///|
const WRAP : Double = 200

///|
const CORNER : Double = 8

///|
/// JavaScript's `Math.SQRT1_2`.
const SQRT1_2 : Double = 0.7071067811865476

///|
const SHAPE_ATTRS : String = " fill=\"var(--_s)\" stroke=\"var(--_b)\""

///|
const LINE_ATTRS : String = " stroke=\"var(--_b)\""

///|
/// Checking every edge against every block is quadratic, so large diagrams route without it.
const OBSTACLE_BUDGET : Double = 2000000

///|
const LABEL_GAP : Double = 4

///|
/// The outline each shape of Mermaid's is drawn with.
fn shape_name(kind : String) -> String {
  match kind {
    "square" => "rect"
    "round" => "rounded"
    "circle" => "circle"
    "doublecircle" => "dbl-circ"
    "diamond" => "diam"
    "hexagon" => "hex"
    "stadium" => "stadium"
    "subroutine" => "fr-rect"
    "cylinder" => "cyl"
    "rect_left_inv_arrow" => "odd"
    "lean_right" => "lean-r"
    "lean_left" => "lean-l"
    "trapezoid" => "trap-b"
    "inv_trapezoid" => "trap-t"
    _ => "rect"
  }
}

///|
/// Shapes that keep their own size in a larger cell, where the others stretch to fill it.
fn is_fixed(shape : String) -> Bool {
  shape is ("circle" | "dbl-circ" | "diam")
}

///|
/// Shapes that only widen, because their slants and curves are set by their height.
fn is_wide(shape : String) -> Bool {
  shape
  is ("stadium" | "hex" | "odd" | "lean-r" | "lean-l" | "trap-b" | "trap-t")
}

///|
priv enum Kind {
  Leaf
  Arrow
  Composite
  Space
}

///|
/// A block as drawn: its grid cell, and what it shows.
priv struct View {
  cell : Cell
  children : Array[View]
  block : Block
  kind : Kind
  index : Int32
  shape : String
  label : @text.Label
  style : @svg.RawStyle
  mask : Int32
  dx : Double
  mut dy : Double
  /// Size as drawn, which for a fixed shape is smaller than its cell.
  mut bw : Double
  mut bh : Double
}

///|
fn View::x(self : View) -> Double {
  self.cell.x
}

///|
fn View::y(self : View) -> Double {
  self.cell.y
}

///|
fn View::is_leaf(self : View) -> Bool {
  self.kind is Leaf
}

///|
fn View::is_round(self : View) -> Bool {
  self.is_leaf() && (self.shape == "circle" || self.shape == "dbl-circ")
}

///|
fn View::is_diamond(self : View) -> Bool {
  self.is_leaf() && self.shape == "diam"
}

///|
/// A composite title as a box that stacked labels keep clear of.
priv struct Box {
  x : Double
  y : Double
  bw : Double
  bh : Double
}

///|
/// An edge with its route: two points for a straight line, three for a bend, none for a self-loop.
priv struct Route {
  edge : Block
  points : Array[Double]
  loop_count : Int32
  label : @text.Label
  mut lx : Double
  mut ly : Double
}

///|
/// Where a vertical line at x meets the outline, below the center (sign 1) or above it (sign -1).
fn edge_y(v : View, x : Double, sign : Double) -> Double {
  let hw = v.bw / 2
  let hh = v.bh / 2
  let dx = (x - v.x()).abs()
  let reach = if v.is_round() {
    @util.js_max(hw * hw - dx * dx, 0).sqrt()
  } else if v.is_diamond() {
    hh * @util.js_max(1 - dx / hw, 0)
  } else if v.is_leaf() {
    hh - @svg.shape_inset(v.shape, v.bw, v.bh, if sign > 0 { 2 } else { 0 })
  } else if v.kind is Arrow && arrow_axis(v.mask) == "x" {
    hh - OVERHANG
  } else {
    hh
  }
  v.y() + sign * reach
}

///|
/// Where a horizontal line at y meets the outline, right of the center (sign 1) or left of it (sign -1).
fn edge_x(v : View, y : Double, sign : Double) -> Double {
  let hw = v.bw / 2
  let hh = v.bh / 2
  let dy = (y - v.y()).abs()
  let reach = if v.is_round() {
    @util.js_max(hh * hh - dy * dy, 0).sqrt()
  } else if v.is_diamond() {
    hw * @util.js_max(1 - dy / hh, 0)
  } else if v.is_leaf() {
    hw - @svg.shape_inset(v.shape, v.bw, v.bh, if sign > 0 { 1 } else { 3 })
  } else if v.kind is Arrow && arrow_axis(v.mask) == "y" {
    hw - OVERHANG
  } else {
    hw
  }
  v.x() + sign * reach
}

///|
/// JavaScript's `a || 1` for a number: 1 in place of 0 or NaN.
fn or_one(value : Double) -> Double {
  if value == 0 || value.is_nan() {
    1
  } else {
    value
  }
}

///|
/// Where the line from the center toward (tx, ty) leaves the outline.
fn border(v : View, tx : Double, ty : Double, out : Array[Double]) -> Unit {
  let dx = tx - v.x()
  let dy = ty - v.y()
  let hw = v.bw / 2
  let hh = v.bh / 2
  let inf = @double.infinity
  let mut k = if v.is_round() {
    hw / or_one(@util.js_hypot(dx, dy))
  } else if v.is_diamond() {
    1 / or_one(dx.abs() / hw + dy.abs() / hh)
  } else {
    @util.js_min(
      if dx == 0 {
        inf
      } else {
        hw / dx.abs()
      },
      if dy == 0 {
        inf
      } else {
        hh / dy.abs()
      },
    )
  }
  if k == inf {
    k = 0
  }
  out.push(v.x() + dx * k)
  out.push(v.y() + dy * k)
}

///|
/// JavaScript's `Math.sign`, which keeps 0, -0 and NaN as they are.
fn js_sign(value : Double) -> Double {
  if value > 0 {
    1
  } else if value < 0 {
    -1
  } else {
    value
  }
}

///|
fn crosses_box(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  v : View,
) -> Bool {
  let l = v.x() - v.bw / 2 + 1
  let r = v.x() + v.bw / 2 - 1
  let t = v.y() - v.bh / 2 + 1
  let b = v.y() + v.bh / 2 - 1
  if (x1 < l && x2 < l) ||
    (x1 > r && x2 > r) ||
    (y1 < t && y2 < t) ||
    (y1 > b && y2 > b) {
    return false
  }
  if x1 == x2 || y1 == y2 {
    return true
  }
  // The segment is diagonal and its bounding box overlaps: the box is hit unless all four corners are on one side.
  let dx = x2 - x1
  let dy = y2 - y1
  let side = (x : Double, y : Double) => js_sign(dx * (y - y1) - dy * (x - x1))
  let first = side(l, t)
  first == 0 ||
  side(r, t) != first ||
  side(r, b) != first ||
  side(l, b) != first
}

///|
fn hits(
  points : Array[Double],
  s : View,
  t : View,
  obstacles : Array[View],
) -> Int32 {
  let mut count = 0
  for v in obstacles {
    if physical_equal(v, s) || physical_equal(v, t) {
      continue
    }
    let mut i = 0
    while i + 3 < points.length() {
      if crosses_box(points[i], points[i + 1], points[i + 2], points[i + 3], v) {
        count += 1
        break
      }
      i += 2
    }
  }
  count
}

///|
/// A straight line where the two blocks share a row or a column, otherwise one bend between facing sides.
fn route_edge(
  s : View,
  t : View,
  shift : Double,
  obstacles : Array[View]?,
) -> Array[Double] {
  let sl = s.x() - s.bw / 2
  let sr = s.x() + s.bw / 2
  let st = s.y() - s.bh / 2
  let sb = s.y() + s.bh / 2
  let tl = t.x() - t.bw / 2
  let tr = t.x() + t.bw / 2
  let tt = t.y() - t.bh / 2
  let tb = t.y() + t.bh / 2
  let x1 = @util.js_max(sl, tl)
  let x2 = @util.js_min(sr, tr)
  let y1 = @util.js_max(st, tt)
  let y2 = @util.js_min(sb, tb)
  let over_x = x2 - x1 > 6
  let over_y = y2 - y1 > 6
  if over_x && over_y {
    // One block is inside the other: join the inner one to the nearest side of the outer one.
    let inner = if s.bw * s.bh <= t.bw * t.bh { s } else { t }
    let outer = if physical_equal(inner, s) { t } else { s }
    let up = inner.y() - inner.bh / 2 - (outer.y() - outer.bh / 2)
    let down = outer.y() + outer.bh / 2 - (inner.y() + inner.bh / 2)
    let left = inner.x() - inner.bw / 2 - (outer.x() - outer.bw / 2)
    let right = outer.x() + outer.bw / 2 - (inner.x() + inner.bw / 2)
    let least = @util.js_min(@util.js_min(@util.js_min(up, down), left), right)
    let points = if least == down {
      [
        inner.x(),
        edge_y(inner, inner.x(), 1),
        inner.x(),
        outer.y() + outer.bh / 2,
      ]
    } else if least == up {
      [
        inner.x(),
        edge_y(inner, inner.x(), -1),
        inner.x(),
        outer.y() - outer.bh / 2,
      ]
    } else if least == right {
      [
        edge_x(inner, inner.y(), 1),
        inner.y(),
        outer.x() + outer.bw / 2,
        inner.y(),
      ]
    } else {
      [
        edge_x(inner, inner.y(), -1),
        inner.y(),
        outer.x() - outer.bw / 2,
        inner.y(),
      ]
    }
    return if physical_equal(inner, s) {
      points
    } else {
      [points[2], points[3], points[0], points[1]]
    }
  }
  if over_x {
    let margin = @util.js_min(6, (x2 - x1) / 2)
    let x = @util.js_min(
      @util.js_max((x1 + x2) / 2 + shift, x1 + margin),
      x2 - margin,
    )
    let down : Double = if t.y() > s.y() { 1 } else { -1 }
    return [x, edge_y(s, x, down), x, edge_y(t, x, -down)]
  }
  if over_y {
    let margin = @util.js_min(6, (y2 - y1) / 2)
    let y = @util.js_min(
      @util.js_max((y1 + y2) / 2 + shift, y1 + margin),
      y2 - margin,
    )
    let right : Double = if t.x() > s.x() { 1 } else { -1 }
    return [edge_x(s, y, right), y, edge_x(t, y, -right), y]
  }
  let right : Double = if t.x() > s.x() { 1 } else { -1 }
  let down : Double = if t.y() > s.y() { 1 } else { -1 }
  let across = [
    edge_x(s, s.y(), right),
    s.y(),
    t.x(),
    s.y(),
    t.x(),
    edge_y(t, t.x(), -down),
  ]
  let along = [
    s.x(),
    edge_y(s, s.x(), down),
    s.x(),
    t.y(),
    edge_x(t, t.y(), -right),
    t.y(),
  ]
  let wide = (t.x() - s.x()).abs() >= (t.y() - s.y()).abs()
  let mut best = if wide { across } else { along }
  guard obstacles is Some(obstacles) else { return best }
  let mut least = hits(best, s, t, obstacles)
  if least == 0 {
    return best
  }
  let other = if wide { along } else { across }
  let count = hits(other, s, t, obstacles)
  if count < least {
    best = other
    least = count
  }
  if least == 0 {
    return best
  }
  let direct = []
  border(s, t.x(), t.y(), direct)
  border(t, s.x(), s.y(), direct)
  if hits(direct, s, t, obstacles) < least {
    direct
  } else {
    best
  }
}

///|
/// Builds the path through two or three points, rounding the bend and leaving room for markers.
fn trace(
  p : Array[Double],
  start_trim : Double,
  end_trim : Double,
) -> @svg.EdgePath {
  let n = p.length()
  let sx = p[0]
  let sy = p[1]
  let ex = p[n - 2]
  let ey = p[n - 1]
  let mut ax = p[2] - sx
  let mut ay = p[3] - sy
  let first = @util.js_hypot(ax, ay)
  ax = ax / or_one(first)
  ay = ay / or_one(first)
  let mut bx = ex - p[n - 4]
  let mut by = ey - p[n - 3]
  let last = @util.js_hypot(bx, by)
  bx = bx / or_one(last)
  by = by / or_one(last)
  let mut start_trim = start_trim
  let mut end_trim = end_trim
  if n == 4 && start_trim + end_trim > first {
    let scale = first / (start_trim + end_trim)
    start_trim = start_trim * scale
    end_trim = end_trim * scale
  }
  start_trim = @util.js_min(start_trim, first)
  end_trim = @util.js_min(end_trim, last)
  let d = StringBuilder()
  d.write_string(
    "M\{@svg.num(sx + ax * start_trim)},\{@svg.num(sy + ay * start_trim)}",
  )
  if n == 6 {
    let r = @util.js_max(
      0,
      @util.js_min(@util.js_min(CORNER, first - start_trim), last - end_trim),
    )
    d.write_string(
      "L\{@svg.num(p[2] - ax * r)},\{@svg.num(p[3] - ay * r)}Q\{@svg.num(p[2])},\{@svg.num(p[3])} \{@svg.num(p[2] + bx * r)},\{@svg.num(p[3] + by * r)}",
    )
  }
  d.write_string(
    "L\{@svg.num(ex - bx * end_trim)},\{@svg.num(ey - by * end_trim)}",
  )
  { d: d.to_string(), sx, sy, sdx: -ax, sdy: -ay, ex, ey, edx: bx, edy: by, }
}

///|
/// A self-loop is an arc around the top right corner of the block, or around the matching point on a round or diamond outline.
/// Gives the arc's center and radius and the angles where it leaves and returns.
fn loop_arc(v : View, k : Int32) -> (Double, Double, Double, Double, Double) {
  let hw = v.bw / 2
  let hh = v.bh / 2
  let r = @util.js_max(
    1,
    @util.js_min(@util.js_min(10 + 5 * (k - 1).to_double(), hw), hh),
  )
  if v.is_round() {
    let px = v.x() + hw * SQRT1_2
    let py = v.y() - hw * SQRT1_2
    let half = 2.0 * @math.asin(@util.js_min(1, r / (2 * hw)))
    let angle = (at : Double) => {
      @math.atan2(
        v.y() - hw * @math.sin(at) - py,
        v.x() + hw * @math.cos(at) - px,
      )
    }
    return (px, py, r, angle(@math.PI / 4 + half), angle(@math.PI / 4 - half))
  }
  if v.is_diamond() {
    let slope = @math.atan2(hh, hw)
    return (v.x() + hw / 2, v.y() - hh / 2, r, slope + @math.PI, slope)
  }
  (v.x() + hw, v.y() - hh, r, @math.PI, @math.PI / 2)
}

///|
fn loop_path(
  v : View,
  k : Int32,
  start_trim : Double,
  end_trim : Double,
) -> @svg.EdgePath {
  let (px, py, r, a1, a2) = loop_arc(v, k)
  let from = a1 + start_trim / r
  let to = a2 - end_trim / r
  let mut sweep = (to - from) % (2 * @math.PI)
  if sweep <= 0 {
    sweep += 2 * @math.PI
  }
  let x1 = px + r * @math.cos(from)
  let y1 = py + r * @math.sin(from)
  let x2 = px + r * @math.cos(to)
  let y2 = py + r * @math.sin(to)
  let sx = px + r * @math.cos(a1)
  let sy = py + r * @math.sin(a1)
  let ex = px + r * @math.cos(a2)
  let ey = py + r * @math.sin(a2)
  // Each marker lies along the chord it covers, so it follows the curve instead of the tangent at its tip.
  let sl = @util.js_hypot(sx - x1, sy - y1)
  let el = @util.js_hypot(ex - x2, ey - y2)
  let large = if sweep > @math.PI { 1 } else { 0 }
  {
    d: "M\{@svg.num(x1)},\{@svg.num(y1)}A\{@svg.num(r)},\{@svg.num(r)} 0 \{large} 1 \{@svg.num(x2)},\{@svg.num(y2)}",
    sx,
    sy,
    sdx: if sl > 0 {
      (sx - x1) / sl
    } else {
      @math.sin(a1)
    },
    sdy: if sl > 0 {
      (sy - y1) / sl
    } else {
      -@math.cos(a1)
    },
    ex,
    ey,
    edx: if el > 0 {
      (ex - x2) / el
    } else {
      -@math.sin(a2)
    },
    edy: if el > 0 {
      (ey - y2) / el
    } else {
      @math.cos(a2)
    },
  }
}

///|
let spots : Array[Double] = [0.5, 0.3, 0.7, 0.15, 0.85]

///|
/// Whether a box of the given size centered at (x, y) covers a block other than `s` and `t`, or one of `titles`.
/// Nothing is covered without obstacles, since a diagram too large to check its blocks does not check its titles either.
fn covers(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  s : View,
  t : View,
  obstacles : Array[View]?,
  titles : Array[Box],
) -> Bool {
  guard obstacles is Some(obstacles) else { return false }
  for v in obstacles {
    if !physical_equal(v, s) &&
      !physical_equal(v, t) &&
      (x - v.x()).abs() < (w + v.bw) / 2 &&
      (y - v.y()).abs() < (h + v.bh) / 2 {
      return true
    }
  }
  for v in titles {
    if (x - v.x).abs() < (w + v.bw) / 2 && (y - v.y).abs() < (h + v.bh) / 2 {
      return true
    }
  }
  false
}

///|
/// Picks the point on a leg where a label of the given size covers no block other than the two it joins.
fn label_spot(
  p : Array[Double],
  at : Int32,
  w : Double,
  h : Double,
  s : View,
  t : View,
  obstacles : Array[View]?,
) -> Double {
  guard obstacles is Some(_) else { return 0.5 }
  for spot in spots {
    let x = p[at] + (p[at + 2] - p[at]) * spot
    let y = p[at + 1] + (p[at + 3] - p[at + 1]) * spot
    if !covers(x, y, w, h, s, t, obstacles, []) {
      return spot
    }
  }
  0.5
}

///|
/// Stacks overlapping labels along their shared line, if they fit between its markers and cover no other block or title.
/// Gives the extra length the line needs to fit the labels, or 0 when it needs none or more length would not help.
fn stack_labels(
  stack : Array[Int32],
  routes : Array[Route],
  legs : Array[Array[Double]],
  s : View,
  t : View,
  obstacles : Array[View]?,
  titles : Array[Box],
) -> Double {
  let vertical = legs[stack[0]][0] == legs[stack[0]][2]
  let mut lo = -@double.infinity
  let mut hi = @double.infinity
  let mut need = -LABEL_GAP
  let mut crowded = false
  for a in 0..<stack.length() {
    let leg = legs[stack[a]]
    if (if vertical { leg[0] != leg[2] } else { leg[1] != leg[3] }) {
      return 0
    }
    lo = @util.js_max(
      lo,
      if vertical {
        @util.js_min(leg[1], leg[3])
      } else {
        @util.js_min(leg[0], leg[2])
      },
    )
    hi = @util.js_min(
      hi,
      if vertical {
        @util.js_max(leg[1], leg[3])
      } else {
        @util.js_max(leg[0], leg[2])
      },
    )
    let p = routes[stack[a]]
    need += (if vertical { p.label.height } else { p.label.width + 8 }) +
      LABEL_GAP
    for b in 0..<a {
      let q = routes[stack[b]]
      if (p.lx - q.lx).abs() < (p.label.width + q.label.width) / 2 + 8 &&
        (p.ly - q.ly).abs() < (p.label.height + q.label.height) / 2 {
        crowded = true
      }
    }
  }
  if !crowded {
    return 0
  }
  if need > hi - lo - 2 * @svg.ARROW {
    return need - (hi - lo - 2 * @svg.ARROW)
  }
  let along = []
  let mut next = (lo + hi - need) / 2
  for i in stack {
    let route = routes[i]
    let label = route.label
    let size = if vertical { label.height } else { label.width + 8 }
    let at = next + size / 2
    if covers(
        if vertical {
          route.lx
        } else {
          at
        },
        if vertical {
          at
        } else {
          route.ly
        },
        label.width + 8,
        label.height,
        s,
        t,
        obstacles,
        titles,
      ) {
      return 0
    }
    along.push(at)
    next += size + LABEL_GAP
  }
  for k, i in stack {
    if vertical {
      routes[i].ly = along[k]
    } else {
      routes[i].lx = along[k]
    }
  }
  0
}

///|
/// Widens the gap between `s` and `t` in their nearest shared container, by `short` beyond the gap it had when the labels were measured.
/// `base` keeps those gaps, by container and direction, so several stacks across one gap widen it once by the most any of them needs.
/// Gives false when one block holds the other or they are not apart in that direction.
fn widen(
  parents : Array[View?],
  s : View,
  t : View,
  vertical : Bool,
  short : Double,
  base : Map[(Int32, Bool), Array[Double]],
) -> Bool {
  let chain : Set[Int32] = Set([])
  let mut up : View? = Some(s)
  while up is Some(v) {
    chain.add(v.index)
    up = parents[v.index]
  }
  let mut tb : View? = None
  let mut found : View? = Some(t)
  while found is Some(v) && !chain.contains(v.index) {
    tb = Some(v)
    found = parents[v.index]
  }
  guard found is Some(box) && tb is Some(tb) && !physical_equal(box, s) else {
    return false
  }
  let mut sb = s
  while parents[sb.index] is Some(parent) && !physical_equal(parent, box) {
    sb = parent
  }
  let at = if vertical {
    if sb.cell.row == tb.cell.row {
      return false
    }
    (if sb.cell.row > tb.cell.row { sb.cell.row } else { tb.cell.row }) - 1
  } else {
    let (l, r) = if sb.cell.col < tb.cell.col { (sb, tb) } else { (tb, sb) }
    if r.cell.col < l.cell.col + l.cell.span {
      return false
    }
    (r.cell.col - 1).to_int()
  }
  let gaps = if vertical { box.cell.row_gaps } else { box.cell.col_gaps }
  let key = (box.index, vertical)
  let measured = match base.get(key) {
    Some(measured) => measured
    None => {
      let measured = gaps.copy()
      base.set(key, measured)
      measured
    }
  }
  while gaps.length() <= at {
    gaps.push(0)
  }
  gaps[at] = @util.js_max(gaps[at], gap_at(measured, at.to_double()) + short)
  true
}

///|
/// The gap between blocks, from `block.padding` when it is a usable number.
fn configured_gap(config : @types.Config) -> Double {
  match config.get("block") {
    Some(Object(section)) =>
      match section.get("padding") {
        Some(Number(value, ..)) if value >= 0 => @util.js_min(value, 200)
        _ => GAP
      }
    _ => GAP
  }
}

///|
/// Draws a block diagram.
/// Raises a semantic error for a composite with blocks whose column count is zero or not an integer.
pub fn render_block(
  db : BlockDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  @common.tighten(options, tight => draw(db, config, options, tight))
}

///|
/// The style of a block: its classes, or the default class when it has none, and then its own styles.
/// A style list is split on commas only, so one entry can still hold several declarations.
fn style_of(db : BlockDb, block : Block) -> @svg.RawStyle {
  let declarations = []
  let add = (styles : Array[String]) => {
    for style in styles {
      for part in style.split(";") {
        declarations.push(part.to_owned())
      }
    }
  }
  let names = if block.classes.length() > 0 {
    block.classes
  } else {
    ["default"]
  }
  for name in names {
    if db.classes.get(name) is Some(def) {
      add(def.styles)
    }
  }
  add(block.styles)
  @svg.resolve_raw_style(declarations)
}

///|
/// Whether a label shows nothing but blanks.
fn is_blank(label : @text.Label) -> Bool {
  for line in label.lines {
    for part in line {
      if part.icon is Some(_) || @util.trim(part.text) != "" {
        return false
      }
    }
  }
  true
}

///|
fn draw(
  db : BlockDb,
  config : @types.Config,
  options : @types.RenderOptions,
  tight : Bool,
) -> @types.Rendered raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let edge_size = (size * 0.875).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let gap = @util.js_min(
    configured_gap(config),
    if tight {
      6
    } else {
      @double.infinity
    },
  )
  let wrap = if tight { 80.0 } else { WRAP }
  let view = (block : Block, index : Int32) => {
    let kind_name = block.kind
    let style = if kind_name == "space" {
      @svg.resolve_raw_style([])
    } else {
      style_of(db, block)
    }
    let text_style = (if style.bold { @text.STYLE_BOLD } else { 0 }) |
      (if style.italic { @text.STYLE_ITALIC } else { 0 })
    let font_size = style.font_size.unwrap_or(size)
    let mut kind = Leaf
    let mut shape = ""
    let mut nw = 0.0
    let mut nh = 0.0
    let mut head = 0.0
    let mut mask = 0
    let mut dx = 0.0
    let mut dy = 0.0
    let label = if kind_name == "space" {
      kind = Space
      @text.layout_label(None, false, measurer, font_size, wrap)
    } else if kind_name == "composite" {
      kind = Composite
      let label = @text.layout_label(
        Some(block.label),
        false,
        measurer,
        font_size,
        if tight {
          @common.title_room(options)
        } else {
          4000
        },
        base=text_style,
      )
      head = if label.height > 0 { label.height + 4 } else { 0 }
      nw = label.width + 2 * gap
      nh = head + 2 * gap
      label
    } else if kind_name == "block_arrow" {
      kind = Arrow
      let label = @text.layout_label(
        Some(block.label),
        false,
        measurer,
        font_size,
        wrap,
        base=text_style,
      )
      mask = arrow_mask(block.directions)
      let s = if is_blank(label) {
        arrow_size(mask, 0, 0)
      } else {
        arrow_size(mask, label.width, label.height)
      }
      nw = s.w
      nh = s.h
      dx = s.dx
      dy = s.dy
      label
    } else {
      shape = shape_name(kind_name)
      let label = @text.layout_label(
        Some(block.label),
        false,
        measurer,
        font_size,
        wrap,
        base=text_style,
      )
      let s = @svg.shape_size(shape, label.width, label.height)
      nw = s.w
      // A cylinder's caps deepen as it widens, so it is sized for the deepest ones.
      nh = if shape == "cyl" {
        @util.js_max(s.h, label.height + 40)
      } else {
        s.h
      }
      dy = s.dy
      label
    }
    let made = cell(
      nw,
      nh,
      span=match kind {
        Space => 1
        _ => block.width_in_columns.unwrap_or(1)
      },
    )
    made.columns = if kind is Composite { block.columns } else { -1 }
    made.space = kind is Space
    made.head = head
    {
      cell: made,
      children: [],
      block,
      kind,
      index,
      shape,
      label,
      style,
      mask,
      dx,
      dy,
      bw: 0,
      bh: 0,
    }
  }
  let root = view(db.root, 0)
  root.cell.nw = 0
  root.cell.nh = 0
  let order = [root]
  let parents : Array[View?] = [None]
  let by_id : Map[String, View] = Map([])
  let mut i = 0
  while i < order.length() {
    let parent = order[i]
    i += 1
    if !(parent.kind is Composite) {
      continue
    }
    for child in parent.block.children {
      let v = view(child, order.length())
      parent.children.push(v)
      parent.cell.children.push(v.cell)
      parents.push(Some(parent))
      order.push(v)
      if !(v.kind is Space) {
        by_id.set(child.id, v)
      }
    }
  }
  let obstacles = []
  let titles : Array[Box] = []
  // Layout keeps the widest a container has been, so each run starts from the widths it needs.
  let widths = order.map(v => v.cell.nw)
  fn place() -> (Double, Double) raise @errors.PeleError {
    for v in order {
      v.cell.nw = widths[v.index]
    }
    let content = layout(root.cell, gap)
    obstacles.clear()
    titles.clear()
    for v in order {
      if v.is_leaf() && is_fixed(v.shape) {
        v.bw = v.cell.nw
        v.bh = v.cell.nh
      } else if v.kind is Arrow {
        v.bw = if v.cell.span > 1 { v.cell.w } else { v.cell.nw }
        v.bh = v.cell.nh
      } else {
        v.bw = v.cell.w
        v.bh = if v.is_leaf() && is_wide(v.shape) {
          v.cell.nh
        } else {
          v.cell.h
        }
      }
      if v.is_leaf() && v.shape == "cyl" {
        v.dy = @util.js_min(12, @util.js_max(6, v.bw / 14)) / 2
      }
      if v.kind is (Leaf | Arrow) {
        obstacles.push(v)
      } else if v.cell.head > 0 {
        titles.push({
          x: v.x(),
          y: v.y() - v.cell.h / 2 + (v.cell.head + gap) / 2 + 2,
          bw: v.label.width,
          bh: v.label.height,
        })
      }
    }
    content
  }
  let mut content = place()

  // Edges between the same two blocks are spread apart instead of drawn on top of each other.
  let count = order.length().to_int64()
  let pair_key = (s : View, t : View) => {
    let low = if s.index < t.index { s.index } else { t.index }
    let high = if s.index < t.index { t.index } else { s.index }
    low.to_int64() * count + high.to_int64()
  }
  let pairs : Map[Int64, Int32] = Map([])
  let labelled : Set[Int64] = Set([])
  let ends : Array[(View, View)] = []
  let drawn : Array[Block] = []
  for edge in db.edges {
    guard by_id.get(edge.start) is Some(s) && by_id.get(edge.end) is Some(t) else {
      continue
    }
    let key = pair_key(s, t)
    pairs.set(key, pairs.get(key).unwrap_or(0) + 1)
    if edge.label != "" {
      labelled.add(key)
    }
    ends.push((s, t))
    drawn.push(edge)
  }
  let check = if drawn.length().to_double() * obstacles.length().to_double() <=
    OBSTACLE_BUDGET {
    Some(obstacles)
  } else {
    None
  }
  let routes : Array[Route] = []
  let stacks : Map[Int64, Array[Int32]] = Map([])
  let legs : Array[Array[Double]] = Array::make(drawn.length(), [])
  fn route() -> Unit {
    let seen : Map[Int64, Int32] = Map([])
    routes.clear()
    stacks.clear()
    for j, edge in drawn {
      let (s, t) = ends[j]
      let key = pair_key(s, t)
      let total = pairs.get(key).unwrap_or(1)
      let k = seen.get(key).unwrap_or(0)
      seen.set(key, k + 1)
      let label = @text.layout_label(
        Some(edge.label),
        false,
        measurer,
        edge_size,
        WRAP,
      )
      let mut points = []
      let mut lx = 0.0
      let mut ly = 0.0
      if physical_equal(s, t) {
        let (px, py, r, _, _) = loop_arc(s, k + 1)
        lx = px + r + 6 + label.width / 2
        ly = py - r / 2
      } else {
        let step = if labelled.contains(key) {
          (edge_size * 1.5).round() + 2
        } else {
          14
        }
        points = route_edge(
          s,
          t,
          (k.to_double() - (total - 1).to_double() / 2) * step,
          check,
        )
        let n = points.length()
        // The label goes on the longer leg.
        let first_leg = (points[2] - points[0]).abs() +
          (points[3] - points[1]).abs()
        let last_leg = (points[n - 2] - points[n - 4]).abs() +
          (points[n - 1] - points[n - 3]).abs()
        let at = if n == 6 && last_leg > first_leg { 2 } else { 0 }
        let spot = if label.width > 0 {
          label_spot(points, at, label.width + 8, label.height, s, t, check)
        } else {
          0.5
        }
        lx = points[at] + (points[at + 2] - points[at]) * spot
        ly = points[at + 1] + (points[at + 3] - points[at + 1]) * spot
        if label.width > 0 && total > 1 {
          legs[j] = [points[at], points[at + 1], points[at + 2], points[at + 3]]
          match stacks.get(key) {
            Some(stack) => stack.push(j)
            None => stacks.set(key, [j])
          }
        }
      }
      routes.push({
        edge,
        points,
        loop_count: if physical_equal(s, t) {
          k + 1
        } else {
          0
        },
        label,
        lx,
        ly,
      })
    }
  }
  fn settle(allow : Bool) -> Bool {
    route()
    let base : Map[(Int32, Bool), Array[Double]] = Map([])
    let mut grown = false
    for _, stack in stacks {
      if stack.length() < 2 {
        continue
      }
      let (s, t) = ends[stack[0]]
      let short = stack_labels(stack, routes, legs, s, t, check, titles)
      let vertical = legs[stack[0]][0] == legs[stack[0]][2]
      // Keep columns narrow to fit the host in tight layouts.
      if allow &&
        short > 0 &&
        (vertical || !tight) &&
        widen(parents, s, t, vertical, short.ceil(), base) {
        grown = true
      }
    }
    grown
  }
  fn overlap() -> Double {
    let mut area = 0.0
    for i in 0..<routes.length() {
      let p = routes[i]
      for j in (i + 1)..<routes.length() {
        let q = routes[j]
        let pw = (p.label.width + 8) / 2
        let qw = (q.label.width + 8) / 2
        let w = @util.js_min(p.lx + pw, q.lx + qw) -
          @util.js_max(p.lx - pw, q.lx - qw)
        let h = @util.js_min(
            p.ly + p.label.height / 2,
            q.ly + q.label.height / 2,
          ) -
          @util.js_max(p.ly - p.label.height / 2, q.ly - q.label.height / 2)
        if p.label.width > 0 && q.label.width > 0 && w > 0 && h > 0 {
          area += w * h
        }
      }
    }
    area
  }
  let mut min_x = 0.0
  let mut min_y = 0.0
  let mut max_x = 0.0
  let mut max_y = 0.0
  let grow = (x : Double, y : Double, w : Double, h : Double) => {
    if x - w / 2 < min_x {
      min_x = x - w / 2
    }
    if x + w / 2 > max_x {
      max_x = x + w / 2
    }
    if y - h / 2 < min_y {
      min_y = y - h / 2
    }
    if y + h / 2 > max_y {
      max_y = y + h / 2
    }
  }
  // Finds the drawing's extent and gives its width.
  fn bound() -> Double {
    min_x = 0
    min_y = 0
    max_x = content.0
    max_y = content.1
    for j, route in routes {
      if route.loop_count > 0 {
        let (px, py, r, _, _) = loop_arc(ends[j].0, route.loop_count)
        grow(px, py, 2 * r + 2, 2 * r + 2)
      }
      if route.label.width > 0 {
        grow(route.lx, route.ly, route.label.width + 8, route.label.height)
      }
    }
    max_x - min_x
  }
  if settle(
      drawn.length().to_double() * drawn.length().to_double() <= OBSTACLE_BUDGET,
    ) {
    let before = overlap()
    let narrow = bound()
    // A container stretched by its row gives some of a new gap back, so the gap may take a few rounds.
    let mut grown = true
    let mut round = 0
    while round < 3 && grown {
      content = place()
      grown = settle(round < 2)
      round += 1
    }
    // The drawing only grows if that leaves less of the labels covering each other, and within maxWidth.
    let wide = bound()
    let room = match options.max_width {
      Some(max_width) if max_width > 0 => max_width
      _ => @double.infinity
    }
    if overlap() > before - 1 ||
      (wide > narrow && (wide + 2 * pad).ceil() > room) {
      for v in order {
        v.cell.row_gaps = []
        v.cell.col_gaps = []
      }
      content = place()
      settle(false) |> ignore
    }
  }
  bound() |> ignore
  let title = @svg.title_label(
    db.title,
    measurer,
    size,
    if tight {
      @common.title_room(options)
    } else {
      4000
    },
  )
  let title_height = if title.height > 0 { title.height + 12 } else { 0 }
  let inner = @util.js_max(max_x - min_x, title.width)
  let ox = pad - min_x + (inner - (max_x - min_x)) / 2
  let oy = pad + title_height - min_y
  for v in order {
    v.cell.x += ox
    v.cell.y += oy
  }
  let width = (inner + 2 * pad).ceil()
  let height = (max_y - min_y + title_height + 2 * pad).ceil()
  let clusters = @svg.Markup::new()
  let nodes = @svg.Markup::new()
  let fills : Array[@svg.Fill] = []
  for j in 1..<order.length() {
    let v = order[j]
    if v.kind is Space {
      continue
    }
    let classes = @svg.class_names(v.block.classes.join(" "))
    if v.kind is Composite {
      let c = v.cell
      let top = c.y - c.h / 2
      if @svg.raw_paints(v.style.shape) {
        fills.push(
          @svg.Fill::raw(
            [c.x - c.w / 2, top, c.x + c.w / 2, top + c.h],
            v.style.shape,
          ),
        )
      }
      clusters.write("<g class=\"pele-cluster\{classes}\" data-id=\"")
      clusters.write_esc_text(v.block.id)
      let wash = if @svg.sets_raw_fill(v.style.shape) {
        ""
      } else {
        " fill-opacity=\"0.5\""
      }
      clusters.write(
        "\"><rect x=\"\{@svg.num(c.x - c.w / 2)}\" y=\"\{@svg.num(top)}\" width=\"\{@svg.num(c.w)}\" height=\"\{@svg.num(c.h)}\" fill=\"var(--_a)\"\{wash} stroke=\"var(--_b)\"",
      )
      @svg.write_rounded_style(clusters, v.style.shape)
      clusters.write("/>")
      @svg.write_label_styled(
        clusters,
        v.label,
        c.x,
        top + (c.head + gap) / 2 + 2,
        " class=\"pele-cluster-label\"\{@svg.raw_ink_fill(v.style, fallback="var(--_m)")}",
        v.style.text,
        icons?=options.icons,
      )
      clusters.write("</g>")
      continue
    }
    let arrow = v.kind is Arrow
    let shape_class = if arrow { "block-arrow" } else { v.shape }
    nodes.write(
      "<g class=\"pele-node pele-shape-\{shape_class}\{classes}\" data-id=\"",
    )
    nodes.write_esc_text(v.block.id)
    nodes.write(
      "\" transform=\"translate(\{@svg.num(v.x())},\{@svg.num(v.y())})\">",
    )
    if arrow {
      // The attributes close the arrow's one polygon, so its style goes just before the `/>`.
      let drawn = draw_arrow(v.mask, v.bw, v.bh, SHAPE_ATTRS)
      nodes.write(@util.slice(drawn, 0, end=-2))
      @svg.write_style(nodes, v.style.shape)
      nodes.write("/>")
    } else {
      let slots = v.style.slots()
      @svg.write_styled(
        nodes,
        @svg.draw_shape(
          v.shape,
          v.bw,
          v.bh,
          SHAPE_ATTRS + slots.shape,
          LINE_ATTRS + slots.line,
        ),
        v.style,
      )
    }
    let ink = if arrow || @svg.shape_filled(v.shape) {
      @svg.raw_ink_fill(v.style)
    } else {
      ""
    }
    @svg.write_label_styled(
      nodes,
      v.label,
      v.dx,
      v.dy,
      " class=\"pele-label\"\{ink}",
      v.style.text,
      icons?=options.icons,
    )
    nodes.write("</g>")
  }
  let casings = @svg.Markup::new()
  let edges = @svg.Markup::new()
  let labels = @svg.Markup::new()
  for j, route in routes {
    let edge = route.edge
    let start_type = edge.arrow_type_start
    let end_type = edge.arrow_type_end
    let path = if route.loop_count > 0 {
      loop_path(
        ends[j].0,
        route.loop_count,
        @svg.marker_trim(start_type),
        @svg.marker_trim(end_type),
      )
    } else {
      let points = route.points
      let mut k = 0
      while k < points.length() {
        points[k] += ox
        points[k + 1] += oy
        k += 2
      }
      trace(points, @svg.marker_trim(start_type), @svg.marker_trim(end_type))
    }
    let over = @svg.over_fills(
      path.d,
      [path.sx, path.sy, path.ex, path.ey],
      fills,
    )
    if over is Some("") {
      casings.write(
        @svg.edge_casing(
          path,
          start_type,
          end_type,
          thick=edge.thickness == "thick",
        ),
      )
    }
    let (ink, color) = match over {
      Some(ink) if ink != "" => (" stroke=\"\{ink}\"", ink)
      _ => ("", "var(--_l)")
    }
    let thick = if edge.thickness == "thick" {
      " stroke-width=\"2.5\""
    } else {
      ""
    }
    let dotted = if edge.pattern == "dotted" {
      " stroke-dasharray=\"3 4\""
    } else {
      ""
    }
    edges.write("<g class=\"pele-edge\" data-id=\"")
    edges.write_esc_text(edge.id)
    edges.write("\"\{ink}><path d=\"\{path.d}\"\{thick}\{dotted}/>")
    edges.write(
      @svg.marker(start_type, path.sx, path.sy, path.sdx, path.sdy, color),
    )
    edges.write(
      @svg.marker(end_type, path.ex, path.ey, path.edx, path.edy, color),
    )
    edges.write("</g>")
    if route.label.width > 0 {
      @svg.write_edge_label_with_id(
        labels,
        edge.id,
        route.label,
        route.lx + ox,
        route.ly + oy,
        "",
        icons?=options.icons,
      )
    }
  }
  let body = @svg.Markup::new()
  @svg.write_label(
    body,
    title,
    width / 2,
    pad + title.height / 2,
    " class=\"pele-title\" font-weight=\"var(--_tw)\"",
  )
  if !clusters.is_empty() {
    body.write_group("<g class=\"pele-clusters\">", clusters, "</g>")
  }
  @svg.write_casings(body, casings)
  if !edges.is_empty() {
    body.write_group(
      "<g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\">",
      edges, "</g>",
    )
  }
  body.write_group("<g class=\"pele-nodes\">", nodes, "</g>")
  if !labels.is_empty() {
    body.write_group(
      "<g class=\"pele-edge-labels\" font-size=\"\{edge_size}\">",
      labels,
      "</g>",
    )
  }
  let svg = @svg.markup_document(
    "block",
    width,
    height,
    size,
    options,
    None,
    None,
    body,
  )
  { svg, width, height, links: [], }
}
