///|
/// A laid out shape or boundary: top-left corner, size, and the shared shape it is drawn as.
/// `id` tells boxes apart, as pele does by object identity.
pub(all) struct Box {
  id : Int32
  mut x : Double
  mut y : Double
  mut w : Double
  mut h : Double
  form : String
}

///|
/// How a relation is drawn: its path, its markers, and where its label goes.
pub(all) struct Route {
  d : String
  /// Where the markers go: the tip, and the way it points.
  sx : Double
  sy : Double
  sdx : Double
  sdy : Double
  ex : Double
  ey : Double
  edx : Double
  edy : Double
  /// The stretch the label may sit on.
  x0 : Double
  y0 : Double
  x1 : Double
  y1 : Double
  /// The side of that stretch the label is pushed to, as a unit vector; zero centers it on the stretch.
  nx : Double
  ny : Double
  /// When set, the label stays over the line and moves that way by at most this much.
  lean : Double
  /// The widest the label should be.
  room : Double
  /// The corners of the line, as x, y pairs.
  points : Array[Double]
}

///|
const LOOP : Double = 28

///|
/// How far out from the shapes it passes a detour runs.
pub const LANE : Double = 20

///|
const LANE_STEP : Double = 7

///|
const CORNER : Double = 8

///|
/// A wide label on an upright lane leans this far out from it, to the middle of the gap between columns.
const LEAN : Double = 30

///|
/// Label widths that fit the gap between two columns, and where there is room to spare.
const NARROW : Double = 88

///|
const WIDE : Double = 160

///|
/// The shared person shape: a head of radius 13 centered 14 below the top, over a body that starts 26 below it.
pub const HEAD : Double = 26

///|
/// Parallel stretches closer than this read as one line.
const NEAR : Double = 6

///|
/// A line this close to a boundary's frame reads as part of it.
const FRAME_NEAR : Double = 3

///|
const PORT_STEP : Double = 12

///|
let infinity : Double = @double.infinity

///|
/// The cap radius drawShape uses for a cylinder.
pub fn cyl_ry(w : Double) -> Double {
  @util.js_min(12, @util.js_max(6, w / 14))
}

///|
/// The cap radius drawShape uses for a queue.
pub fn queue_rx(h : Double) -> Double {
  @util.js_min(12, h / 4)
}

///|
/// Math.sign, which keeps NaN.
fn sign(v : Double) -> Double {
  if v > 0 {
    1
  } else if v < 0 {
    -1
  } else {
    v
  }
}

///|
/// How far along the segment from (px, py) by (dx, dy) it first meets the rectangle; infinity when it misses.
fn hit_rect(
  x0 : Double,
  y0 : Double,
  x1 : Double,
  y1 : Double,
  px : Double,
  py : Double,
  dx : Double,
  dy : Double,
) -> Double {
  let mut enter = 0.0
  let mut leave = 1.0
  if dx == 0 {
    if px < x0 || px > x1 {
      return infinity
    }
  } else {
    let a = (x0 - px) / dx
    let b = (x1 - px) / dx
    enter = @util.js_max(enter, @util.js_min(a, b))
    leave = @util.js_min(leave, @util.js_max(a, b))
  }
  if dy == 0 {
    if py < y0 || py > y1 {
      return infinity
    }
  } else {
    let a = (y0 - py) / dy
    let b = (y1 - py) / dy
    enter = @util.js_max(enter, @util.js_min(a, b))
    leave = @util.js_min(leave, @util.js_max(a, b))
  }
  if enter <= leave {
    enter
  } else {
    infinity
  }
}

///|
fn hit_ellipse(
  cx : Double,
  cy : Double,
  rx : Double,
  ry : Double,
  px : Double,
  py : Double,
  dx : Double,
  dy : Double,
) -> Double {
  let ux = dx / rx
  let uy = dy / ry
  let vx = (px - cx) / rx
  let vy = (py - cy) / ry
  let a = ux * ux + uy * uy
  let b = 2.0 * (ux * vx + uy * vy)
  let c = vx * vx + vy * vy - 1
  let disc = b * b - 4.0 * a * c
  if a == 0 || disc < 0 {
    return infinity
  }
  let t = (-b - disc.sqrt()) / (2.0 * a)
  if t >= 0 && t <= 1 {
    t
  } else if c <= 0 {
    0
  } else {
    infinity
  }
}

///|
/// Where a segment from outside first meets the outline of a shape, as a fraction of the segment.
fn hit(box : Box, px : Double, py : Double, qx : Double, qy : Double) -> Double {
  let { x, y, w, h, .. } = box
  let dx = qx - px
  let dy = qy - py
  match box.form {
    "person" =>
      @util.js_min(
        hit_rect(x, y + HEAD, x + w, y + h, px, py, dx, dy),
        hit_ellipse(x + w / 2, y + 14, 13, 13, px, py, dx, dy),
      )
    "cyl" => {
      let ry = cyl_ry(w)
      @util.js_min(
        @util.js_min(
          hit_rect(x, y + ry, x + w, y + h - ry, px, py, dx, dy),
          hit_ellipse(x + w / 2, y + ry, w / 2, ry, px, py, dx, dy),
        ),
        hit_ellipse(x + w / 2, y + h - ry, w / 2, ry, px, py, dx, dy),
      )
    }
    "h-cyl" => {
      let rx = queue_rx(h)
      @util.js_min(
        @util.js_min(
          hit_rect(x + rx, y, x + w - rx, y + h, px, py, dx, dy),
          hit_ellipse(x + rx, y + h / 2, rx, h / 2, px, py, dx, dy),
        ),
        hit_ellipse(x + w - rx, y + h / 2, rx, h / 2, px, py, dx, dy),
      )
    }
    _ => hit_rect(x, y, x + w, y + h, px, py, dx, dy)
  }
}

///|
/// Whether the line through `points` meets the rectangle.
pub fn crosses(
  points : Array[Double],
  x0 : Double,
  y0 : Double,
  x1 : Double,
  y1 : Double,
) -> Bool {
  for i = 2; i < points.length(); i = i + 2 {
    let px = points[i - 2]
    let py = points[i - 1]
    if hit_rect(x0, y0, x1, y1, px, py, points[i] - px, points[i + 1] - py) <= 1 {
      return true
    }
  }
  false
}

///|
fn contains(outer : Box, inner : Box) -> Bool {
  outer.x <= inner.x &&
  outer.y <= inner.y &&
  outer.x + outer.w >= inner.x + inner.w &&
  outer.y + outer.h >= inner.y + inner.h
}

///|
/// Math.hypot(dx, dy) || 1.
fn length_or_one(dx : Double, dy : Double) -> Double {
  let len = @util.js_hypot(dx, dy)
  if len == 0 || len.is_nan() {
    1
  } else {
    len
  }
}

///|
/// The straight line from a to b: x, y of its start, then of its end.
fn connect(
  a : Box,
  b : Box,
  shift : Double,
) -> (Double, Double, Double, Double) {
  let ax = a.x + a.w / 2
  let ay = a.y + a.h / 2
  let bx = b.x + b.w / 2
  let by = b.y + b.h / 2
  let down = contains(a, b)
  if down || contains(b, a) {
    // One holds the other: a short line from the nearest side of the outer box.
    let outer = if down { a } else { b }
    let inner = if down { b } else { a }
    let ix = inner.x + inner.w / 2
    let iy = inner.y + inner.h / 2
    let left = inner.x - outer.x
    let right = outer.x + outer.w - inner.x - inner.w
    let top = inner.y - outer.y
    let bottom = outer.y + outer.h - inner.y - inner.h
    let least = @util.js_min(
      @util.js_min(left, right),
      @util.js_min(top, bottom),
    )
    let ox = if least == left {
      outer.x
    } else if least == right {
      outer.x + outer.w
    } else {
      ix
    }
    let oy = if least == left || least == right {
      iy
    } else if least == bottom {
      outer.y + outer.h
    } else {
      outer.y
    }
    let t = @util.js_min(hit(inner, ox, oy, ix, iy), 1)
    let mx = ox + (ix - ox) * t
    let my = oy + (iy - oy) * t
    return if down { (ox, oy, mx, my) } else { (mx, my, ox, oy) }
  }
  let mut px = ax
  let mut py = ay
  let mut qx = bx
  let mut qy = by
  // Shapes that share a column or a row are joined by an upright or level line through the shared span.
  let x0 = @util.js_max(a.x, b.x)
  let x1 = @util.js_min(a.x + a.w, b.x + b.w)
  let y0 = @util.js_max(a.y, b.y)
  let y1 = @util.js_min(a.y + a.h, b.y + b.h)
  if x0 < x1 {
    px = (x0 + x1) / 2
    qx = px
  } else if y0 < y1 {
    py = (y0 + y1) / 2
    qy = py
  }
  let len = length_or_one(qx - px, qy - py)
  let nx = -(qy - py) / len * shift
  let ny = (qx - px) / len * shift
  let mut ta = hit(a, qx + nx, qy + ny, px + nx, py + ny)
  let mut tb = hit(b, px + nx, py + ny, qx + nx, qy + ny)
  if ta <= 1 && tb <= 1 {
    px += nx
    py += ny
    qx += nx
    qy += ny
  } else {
    px = ax
    py = ay
    qx = bx
    qy = by
    ta = @util.js_min(hit(a, qx, qy, px, py), 1)
    tb = @util.js_min(hit(b, px, py, qx, qy), 1)
  }
  (
    qx + (px - qx) * ta,
    qy + (py - qy) * ta,
    px + (qx - px) * tb,
    py + (qy - py) * tb,
  )
}

///|
/// What the routes drawn so far take up, so that the next keeps apart from them: upright stretches as x, top, bottom;
/// level ones as y, left, right; and where lines leave or reach each side of a shape.
pub struct Lanes {
  upright : Array[Double]
  level : Array[Double]
  upright_frames : Array[Double]
  level_frames : Array[Double]
  taken : Map[Int32, Array[Double]]
  /// Routes that found no lane of their own: a line left straight behind a shape, or a lane that runs along another.
  mut squeezed : Int32
}

///|
/// Lanes with nothing taken.
pub fn Lanes::new() -> Lanes {
  {
    upright: [],
    level: [],
    upright_frames: [],
    level_frames: [],
    taken: {},
    squeezed: 0,
  }
}

///|
fn near_any(
  list : Array[Double],
  gap : Double,
  at : Double,
  lo : Double,
  hi : Double,
) -> Bool {
  for i = 0; i < list.length(); i = i + 3 {
    if (list[i] - at).abs() < gap && list[i + 1] < hi && list[i + 2] > lo {
      return true
    }
  }
  false
}

///|
fn Lanes::free(
  self : Lanes,
  upright : Bool,
  at : Double,
  a0 : Double,
  a1 : Double,
) -> Bool {
  let lo = @util.js_min(a0, a1)
  let hi = @util.js_max(a0, a1)
  !near_any(if upright { self.upright } else { self.level }, NEAR, at, lo, hi) &&
  !near_any(
    if upright {
      self.upright_frames
    } else {
      self.level_frames
    },
    FRAME_NEAR,
    at,
    lo,
    hi,
  )
}

///|
fn Lanes::crossings(self : Lanes, points : Array[Double]) -> Int32 {
  let mut count = 0
  for i = 2; i < points.length(); i = i + 2 {
    let upright = points[i] == points[i - 2]
    let at = if upright { points[i] } else { points[i + 1] }
    let s0 = if upright { points[i - 1] } else { points[i - 2] }
    let s1 = if upright { points[i + 1] } else { points[i] }
    let lo = @util.js_min(s0, s1)
    let hi = @util.js_max(s0, s1)
    let list = if upright { self.level } else { self.upright }
    for j = 0; j < list.length(); j = j + 3 {
      if list[j] > lo && list[j] < hi && list[j + 1] < at && list[j + 2] > at {
        count += 1
      }
    }
  }
  count
}

///|
/// Marks the frame of a boundary, which lines keep a little apart from.
pub fn Lanes::frame(self : Lanes, box : Box) -> Unit {
  self.upright_frames.push_iter(
    [box.x, box.y, box.y + box.h, box.x + box.w, box.y, box.y + box.h].iter(),
  )
  self.level_frames.push_iter(
    [box.y, box.x, box.x + box.w, box.y + box.h, box.x, box.x + box.w].iter(),
  )
}

///|
fn Lanes::take(self : Lanes, points : Array[Double]) -> Unit {
  for i = 2; i < points.length(); i = i + 2 {
    if points[i] == points[i - 2] {
      self.upright.push(points[i])
      self.upright.push(@util.js_min(points[i - 1], points[i + 1]))
      self.upright.push(@util.js_max(points[i - 1], points[i + 1]))
    } else if points[i + 1] == points[i - 1] {
      self.level.push(points[i + 1])
      self.level.push(@util.js_min(points[i - 2], points[i]))
      self.level.push(@util.js_max(points[i - 2], points[i]))
    }
  }
}

///|
/// Where on one side of a shape (0 left, 1 right, 2 top, 3 bottom) a line can leave or arrive, between lo and hi:
/// the places clear of the lines already there, nearest `want` first.
fn Lanes::ports(
  self : Lanes,
  box : Box,
  side : Int32,
  want : Double,
  lo : Double,
  hi : Double,
) -> Array[Double] {
  let used = self.taken.get(box.id).unwrap_or([])
  let out = []
  for k = 0; k < 9 && out.length() < 4; k = k + 1 {
    let dir = if (k & 1) == 1 { 1.0 } else { -1.0 }
    let at = want + dir * ((k + 1) / 2).to_double() * PORT_STEP
    if at < lo || at > hi {
      continue
    }
    let mut clear = true
    for i = 0; i < used.length(); i = i + 2 {
      if used[i] == side.to_double() && (used[i + 1] - at).abs() < PORT_STEP {
        clear = false
      }
    }
    if clear {
      out.push(at)
    }
  }
  if out.length() > 0 {
    out
  } else {
    [want]
  }
}

///|
fn Lanes::claim(self : Lanes, box : Box, side : Int32, at : Double) -> Unit {
  match self.taken.get(box.id) {
    Some(used) => {
      used.push(side.to_double())
      used.push(at)
    }
    None => self.taken[box.id] = [side.to_double(), at]
  }
}

///|
fn path(
  points : Array[Double],
  start_trim : Double,
  end_trim : Double,
) -> String {
  let n = points.length()
  let ux = sign(points[2] - points[0])
  let uy = sign(points[3] - points[1])
  let d = StringBuilder()
  d.write_string(
    "M\{@svg.num(points[0] + ux * start_trim)},\{@svg.num(points[1] + uy * start_trim)}",
  )
  for i = 2; i < n - 2; i = i + 2 {
    let x = points[i]
    let y = points[i + 1]
    let ix = sign(x - points[i - 2])
    let iy = sign(y - points[i - 1])
    let ox = sign(points[i + 2] - x)
    let oy = sign(points[i + 3] - y)
    let r = @util.js_min(
      @util.js_min(CORNER, (x - points[i - 2] + y - points[i - 1]).abs() / 2),
      (points[i + 2] - x + points[i + 3] - y).abs() / 2,
    )
    if ix != 0 && !ix.is_nan() {
      d.write_string("H\{@svg.num(x - ix * r)}")
    } else {
      d.write_string("V\{@svg.num(y - iy * r)}")
    }
    d.write_string(
      "Q\{@svg.num(x)},\{@svg.num(y)} \{@svg.num(x + ox * r)},\{@svg.num(y + oy * r)}",
    )
  }
  let lx = sign(points[n - 2] - points[n - 4])
  let ly = sign(points[n - 1] - points[n - 3])
  if lx != 0 && !lx.is_nan() {
    d.write_string("H\{@svg.num(points[n - 2] - lx * end_trim)}")
  } else {
    d.write_string("V\{@svg.num(points[n - 1] - ly * end_trim)}")
  }
  d.to_string()
}

///|
fn clear_of(
  points : Array[Double],
  others : Array[Box],
  a : Box,
  b : Box,
) -> Bool {
  for other in others {
    if other.id != a.id &&
      other.id != b.id &&
      crosses(points, other.x, other.y, other.x + other.w, other.y + other.h) {
      return false
    }
  }
  true
}

///|
/// The route for a line with corners through `points`, from a's outline to b's.
/// `along` is the stretch its label sits on.
fn bent(
  points : Array[Double],
  along : Int32,
  start_trim : Double,
  end_trim : Double,
  nx~ : Double = 0,
  lean~ : Double = 0,
  room~ : Double = WIDE,
) -> Route {
  let n = points.length()
  {
    d: path(points, start_trim, end_trim),
    sx: points[0],
    sy: points[1],
    sdx: -sign(points[2] - points[0]),
    sdy: -sign(points[3] - points[1]),
    ex: points[n - 2],
    ey: points[n - 1],
    edx: sign(points[n - 2] - points[n - 4]),
    edy: sign(points[n - 1] - points[n - 3]),
    x0: points[along],
    y0: points[along + 1],
    x1: points[along + 2],
    y1: points[along + 3],
    nx,
    ny: 0,
    lean,
    room,
    points,
  }
}

///|
fn across(lo : Double, hi : Double) -> Array[Double] {
  let out = []
  let mid = (lo + hi) / 2
  let step = @util.js_max(LANE_STEP, (hi - lo) / 4)
  for k = 0; k < 9; k = k + 1 {
    let dir = if (k & 1) == 1 { 1.0 } else { -1.0 }
    let at = mid + dir * ((k + 1) / 2).to_double() * step
    if at >= lo + NEAR && at <= hi - NEAR {
      out.push(at)
    }
  }
  out
}

///|
priv struct Candidate {
  points : Array[Double]
  cost : Double
  upright : Bool
  sides : (Int32, Int32)
}

///|
fn elbow(
  a : Box,
  b : Box,
  others : Array[Box],
  lanes : Lanes,
  start_trim : Double,
  end_trim : Double,
) -> Route? {
  let ax = a.x + a.w / 2
  let ay = a.y + a.h / 2
  let bx = b.x + b.w / 2
  let by = b.y + b.h / 2
  let mut best : Candidate? = None
  // Whether the candidate became the best so far.
  let consider = (
    points : Array[Double],
    upright : Bool,
    sides : (Int32, Int32),
  ) => {
    if !clear_of(points, others, a, b) {
      return false
    }
    for i = 2; i < points.length(); i = i + 2 {
      let up = points[i] == points[i - 2]
      let free = lanes.free(
        up,
        if up {
          points[i]
        } else {
          points[i + 1]
        },
        if up {
          points[i - 1]
        } else {
          points[i - 2]
        },
        if up {
          points[i + 1]
        } else {
          points[i]
        },
      )
      if !free {
        return false
      }
    }
    let mut cost = lanes.crossings(points).to_double() * 1.0e6
    for i = 2; i < points.length(); i = i + 2 {
      cost += (points[i] - points[i - 2]).abs() +
        (points[i + 1] - points[i - 1]).abs()
    }
    match best {
      Some(current) if !(cost < current.cost) => false
      _ => {
        best = Some({ points, cost, upright, sides, })
        true
      }
    }
  }
  if a.x + a.w <= b.x || b.x + b.w <= a.x {
    let right = bx > ax
    let down = sign(by - ay)
    let sides = if right { (1, 0) } else { (0, 1) }
    let lanes_across = across(
      if right {
        a.x + a.w
      } else {
        b.x + b.w
      },
      if right {
        b.x
      } else {
        a.x
      },
    )
    let starts = lanes.ports(
      a,
      sides.0,
      ay + down * a.h / 4,
      a.y + 8,
      a.y + a.h - 8,
    )
    let ends = lanes.ports(
      b,
      sides.1,
      by - down * b.h / 4,
      b.y + 8,
      b.y + b.h - 8,
    )
    let search = () => {
      for y0 in starts {
        for y1 in ends {
          for lane in lanes_across {
            let x0 = lane +
              (ax - lane) * @util.js_min(hit(a, lane, y0, ax, y0), 1)
            let x1 = lane +
              (bx - lane) * @util.js_min(hit(b, lane, y1, bx, y1), 1)
            if consider([x0, y0, lane, y0, lane, y1, x1, y1], true, sides) {
              return
            }
          }
        }
      }
    }
    search()
  }
  if a.y + a.h <= b.y || b.y + b.h <= a.y {
    let below = by > ay
    let sideways = sign(bx - ax)
    let sides = if below { (3, 2) } else { (2, 3) }
    let lanes_across = across(
      if below {
        a.y + a.h
      } else {
        b.y + b.h
      },
      if below {
        b.y
      } else {
        a.y
      },
    )
    let starts = lanes.ports(
      a,
      sides.0,
      ax + sideways * a.w / 4,
      a.x + 8,
      a.x + a.w - 8,
    )
    let ends = lanes.ports(
      b,
      sides.1,
      bx - sideways * b.w / 4,
      b.x + 8,
      b.x + b.w - 8,
    )
    let search = () => {
      for x0 in starts {
        for x1 in ends {
          for lane in lanes_across {
            let y0 = lane +
              (ay - lane) * @util.js_min(hit(a, x0, lane, x0, ay), 1)
            let y1 = lane +
              (by - lane) * @util.js_min(hit(b, x1, lane, x1, by), 1)
            if consider([x0, y0, x0, lane, x1, lane, x1, y1], false, sides) {
              return
            }
          }
        }
      }
    }
    search()
  }
  guard best is Some({ points, upright, sides, .. }) else { return None }
  lanes.take(points)
  lanes.claim(a, sides.0, if upright { points[1] } else { points[0] })
  lanes.claim(b, sides.1, if upright { points[7] } else { points[6] })
  // The label sits on the middle stretch, across the gap.
  Some(
    bent(
      points,
      2,
      start_trim,
      end_trim,
      room=if upright { NARROW } else { WIDE },
    ),
  )
}

///|
priv struct Way {
  points : Array[Double]
  side : Int32
  p0 : Double
  p1 : Double
  step : Int32
}

///|
fn blocks(
  other : Box,
  sx : Double,
  sy : Double,
  ex : Double,
  ey : Double,
) -> Bool {
  hit_rect(
    other.x,
    other.y,
    other.x + other.w,
    other.y + other.h,
    sx,
    sy,
    ex - sx,
    ey - sy,
  ) <=
  1
}

///|
/// Routes a relation from a to b.
/// `shift` moves the line sideways when another runs the opposite way.
/// `others` are the shapes to steer clear of; None skips that check.
/// `lanes` holds what the routes before it take up, so that this one keeps apart from them.
pub fn route(
  a : Box,
  b : Box,
  shift : Double,
  others : Array[Box]?,
  lanes : Lanes,
  start_trim : Double,
  end_trim : Double,
) -> Route {
  if a.id == b.id {
    let spread = @util.js_min(a.h / 2 - 4, 10)
    let len = @util.js_hypot(LOOP, spread)
    let x = a.x + a.w
    let cy = a.y + a.h / 2
    let ux = LOOP / len
    let uy = spread / len
    return {
      d: "M\{@svg.num(x + ux * start_trim)},\{@svg.num(cy - spread - uy * start_trim)}C\{@svg.num(x + LOOP)},\{@svg.num(cy - spread * 2)} " +
      "\{@svg.num(x + LOOP)},\{@svg.num(cy + spread * 2)} \{@svg.num(x + ux * end_trim)},\{@svg.num(cy + spread + uy * end_trim)}",
      sx: x,
      sy: cy - spread,
      sdx: -ux,
      sdy: uy,
      ex: x,
      ey: cy + spread,
      edx: -ux,
      edy: -uy,
      x0: x + LOOP + 4,
      y0: cy,
      x1: x + LOOP + 4,
      y1: cy,
      nx: 1,
      ny: 0,
      lean: 0,
      room: 64,
      points: [],
    }
  }
  let (sx, sy, ex, ey) = connect(a, b, shift)
  let upright = sx == ex
  let mut blocked = false
  if others is Some(list) && !contains(a, b) && !contains(b, a) {
    for other in list {
      if other.id != a.id && other.id != b.id && blocks(other, sx, sy, ex, ey) {
        blocked = true
      }
    }
  }
  if others is Some(list) && blocked && !upright && sy != ey {
    if elbow(a, b, list, lanes, start_trim, end_trim) is Some(around) {
      return around
    }
    lanes.squeezed += 1
  }
  if others is Some(others) && blocked && (upright || sy == ey) {
    return detour(
      a, b, others, lanes, sx, sy, ex, ey, upright, start_trim, end_trim,
    )
  }
  let len = length_or_one(ex - sx, ey - sy)
  let dx = (ex - sx) / len
  let dy = (ey - sy) / len
  if upright || sy == ey {
    lanes.take([sx, sy, ex, ey])
  }
  {
    d: "M\{@svg.num(sx + dx * start_trim)},\{@svg.num(sy + dy * start_trim)}L\{@svg.num(ex - dx * end_trim)},\{@svg.num(ey - dy * end_trim)}",
    sx,
    sy,
    sdx: -dx,
    sdy: -dy,
    ex,
    ey,
    edx: dx,
    edy: dy,
    x0: sx,
    y0: sy,
    x1: ex,
    y1: ey,
    nx: if shift != 0 && !shift.is_nan() {
      -dy
    } else {
      0
    },
    ny: if shift != 0 && !shift.is_nan() {
      dx
    } else {
      0
    },
    lean: 0,
    room: if dx.abs() > dy.abs() {
      NARROW
    } else {
      WIDE
    },
    points: [sx, sy, ex, ey],
  }
}

///|
/// The route around the shapes between two in the same column or row.
fn detour(
  a : Box,
  b : Box,
  others : Array[Box],
  lanes : Lanes,
  sx : Double,
  sy : Double,
  ex : Double,
  ey : Double,
  upright : Bool,
  start_trim : Double,
  end_trim : Double,
) -> Route {
  let lane_on = (forward : Bool) => {
    let mut lane = if forward { -infinity } else { infinity }
    let widen = (box : Box) => {
      let edge = if upright { box.x } else { box.y }
      lane = if forward {
        @util.js_max(lane, edge + (if upright { box.w } else { box.h }))
      } else {
        @util.js_min(lane, edge)
      }
    }
    widen(a)
    widen(b)
    for other in others {
      if other.id != a.id && other.id != b.id && blocks(other, sx, sy, ex, ey) {
        widen(other)
      }
    }
    lane
  }
  let lo = if upright { @util.js_min(a.y, b.y) } else { @util.js_min(a.x, b.x) }
  let hi = if upright {
    @util.js_max(a.y + a.h, b.y + b.h)
  } else {
    @util.js_max(a.x + a.w, b.x + b.w)
  }
  let outside = (forward : Bool, lane : Double) => {
    for other in others {
      if other.id == a.id || other.id == b.id {
        continue
      }
      let near = if upright {
        other.y < hi && other.y + other.h > lo
      } else {
        other.x < hi && other.x + other.w > lo
      }
      let start = if upright { other.x } else { other.y }
      let end = start + (if upright { other.w } else { other.h })
      if near && (if forward { end > lane } else { start < lane }) {
        return false
      }
    }
    true
  }
  let ax = a.x + a.w / 2
  let ay = a.y + a.h / 2
  let bx = b.x + b.w / 2
  let by = b.y + b.h / 2
  let towards = if upright { sign(by - ay) } else { sign(bx - ax) }
  // The route on one side: each end leaves its shape a quarter of the way from the middle towards the other,
  // clear of the straight lines that meet the middle of that side and of other routes there.
  // The lane runs a little further out for each route already along that gap, and never behind a shape.
  // `step` is how many lanes out it went; 5 when none was free.
  let along = (forward : Bool) => {
    let lane = lane_on(forward)
    let dir = if forward { 1.0 } else { -1.0 }
    let side = if upright {
      if forward {
        1
      } else {
        0
      }
    } else if forward {
      3
    } else {
      2
    }
    let p0 = if upright {
      lanes.ports(a, side, ay + towards * a.h / 4, a.y + 8, a.y + a.h - 8)[0]
    } else {
      lanes.ports(a, side, ax + towards * a.w / 4, a.x + 8, a.x + a.w - 8)[0]
    }
    let p1 = if upright {
      lanes.ports(b, side, by - towards * b.h / 4, b.y + 8, b.y + b.h - 8)[0]
    } else {
      lanes.ports(b, side, bx - towards * b.w / 4, b.x + 8, b.x + b.w - 8)[0]
    }
    let points_at = (at : Double) => {
      if upright {
        let x0 = at + (ax - at) * @util.js_min(hit(a, at, p0, ax, p0), 1)
        let x1 = at + (bx - at) * @util.js_min(hit(b, at, p1, bx, p1), 1)
        [x0, p0, at, p0, at, p1, x1, p1]
      } else {
        let y0 = at + (ay - at) * @util.js_min(hit(a, p0, at, p0, ay), 1)
        let y1 = at + (by - at) * @util.js_min(hit(b, p1, at, p1, by), 1)
        [p0, y0, p0, at, p1, at, p1, y1]
      }
    }
    let mut points = points_at(lane + dir * LANE)
    for k = 0; k <= 4; k = k + 1 {
      let at = lane + dir * (LANE + k.to_double() * LANE_STEP)
      let tried = points_at(at)
      if !clear_of(tried, others, a, b) {
        continue
      }
      points = tried
      if lanes.free(upright, at, p0, p1) {
        return { points, side, p0, p1, step: k, }
      }
    }
    { points, side, p0, p1, step: 5, }
  }
  // A detour takes the outside of the drawing when only one side is outside, leaving the gaps between columns
  // and rows to the relations that cross them.
  // Otherwise it takes the side where it crosses fewer lines, then the one where it runs nearer its shapes,
  // so that detours spread over both sides.
  let natural = if upright { ey > sy } else { ex < sx }
  let out = outside(natural, lane_on(natural))
  let back = outside(!natural, lane_on(!natural))
  let first = along(natural)
  let other = if out == back { Some(along(!natural)) } else { None }
  let cost = (way : Way) => lanes.crossings(way.points) * 8 + way.step
  let forward = if back && !out {
    !natural
  } else if other is Some(o) && cost(o) < cost(first) {
    !natural
  } else {
    natural
  }
  let way = if forward == natural {
    first
  } else {
    match other {
      Some(o) => o
      None => along(!natural)
    }
  }
  let dir = if forward { 1.0 } else { -1.0 }
  if way.step > 4 {
    lanes.squeezed += 1
  }
  lanes.take(way.points)
  lanes.claim(a, way.side, way.p0)
  lanes.claim(b, way.side, way.p1)
  if upright {
    bent(way.points, 2, start_trim, end_trim, nx=dir, lean=LEAN, room=NARROW)
  } else {
    bent(way.points, 2, start_trim, end_trim, room=WIDE)
  }
}
