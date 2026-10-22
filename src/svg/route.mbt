///|
/// The most a corner is rounded by in a stepped route.
const CORNER : Double = 12

///|
/// How far the handles of a wide turn reach along its two legs.
/// A little more than a circle's, which makes the turn fuller.
const HANDLE : Double = 0.62

///|
/// JavaScript's `Math.sign`, which keeps -0 and NaN.
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
/// JavaScript's `Math.sign(value) || 1`: the way a difference runs, forward where it is none.
fn way(value : Double) -> Double {
  if value < 0 {
    -1
  } else {
    1
  }
}

///|
/// Builds the path for a route of x, y, axis triples, where the axis is 0 for a point the edge runs into vertically and 1 horizontally.
/// Between two points that are not in line, a route is one S that leaves and arrives along the flow, or a step in a stepped route.
/// Where the route itself turns a corner, a stepped route rounds it a little, and any other but a linear one turns as widely as it can: the turn takes the whole of a leg that ends at a node and half of a leg it shares with the next turn.
/// `start_trim` and `end_trim` leave room for the markers at its ends.
/// `start_reach` and `end_reach` say how far from its nodes the edge starts to turn, where the other edges on the same side of a node need it to; by default, far enough to clear its own marker.
pub fn route_path(
  route : Array[Double],
  curve : String?,
  start_trim : Double,
  end_trim : Double,
  start_reach? : Double,
  end_reach? : Double,
) -> EdgePath {
  let start_reach = start_reach.unwrap_or(
    if start_trim > 0 {
      start_trim + LEAD
    } else {
      0
    },
  )
  let end_reach = end_reach.unwrap_or(
    if end_trim > 0 {
      end_trim + LEAD
    } else {
      0
    },
  )
  let linear = curve == Some("linear")
  let stepped = match curve {
    Some("step" | "stepBefore" | "stepAfter") => true
    _ => false
  }
  let xs : Array[Double] = []
  let ys : Array[Double] = []
  let axes : Array[Double] = []
  let near = fn(ax : Double, ay : Double, bx : Double, by : Double) {
    (ax - bx).abs() < 0.01 && (ay - by).abs() < 0.01
  }
  for i = 0; i < route.length(); i = i + 3 {
    let x = route[i]
    let y = route[i + 1]
    let axis = route[i + 2]
    let last = xs.length() - 1
    // A stepped route turns at right angles where a smooth one would curve.
    if stepped &&
      last >= 0 &&
      (x - xs[last]).abs() >= 0.01 &&
      (y - ys[last]).abs() >= 0.01 {
      let px = xs[last]
      let py = ys[last]
      let (mx, my) = match curve {
        Some("stepBefore") => (px, py)
        Some("stepAfter") => (x, y)
        _ => ((px + x) / 2, (py + y) / 2)
      }
      let turns = if axis == 0 { [px, my, x, my] } else { [mx, py, mx, y] }
      for k in [0, 2] {
        if near(turns[k], turns[k + 1], px, py) ||
          near(turns[k], turns[k + 1], x, y) {
          continue
        }
        xs.push(turns[k])
        ys.push(turns[k + 1])
        axes.push(axis)
      }
    }
    xs.push(x)
    ys.push(y)
    axes.push(axis)
  }
  let mut last = xs.length() - 1
  let aligned = fn(i : Int32) {
    (xs[i] - xs[i - 1]).abs() < 0.01 || (ys[i] - ys[i - 1]).abs() < 0.01
  }
  let straight = fn(i : Int32) { linear || aligned(i) }
  // The way the route heads from point i to point j: along the flow where an S joins them.
  let unit = fn(i : Int32, j : Int32, axis : Double) -> (Double, Double) {
    if !straight(if i > j { i } else { j }) {
      return if axis == 0 {
        (0, way(ys[j] - ys[i]))
      } else {
        (way(xs[j] - xs[i]), 0)
      }
    }
    let dx = xs[j] - xs[i]
    let dy = ys[j] - ys[i]
    let len = or_one(@layout.hypot(dx, dy))
    (dx / len, dy / len)
  }
  let (sdx, sdy) = unit(0, 1, axes[1])
  let (edx, edy) = unit(last - 1, last, axes[last])
  let sx = xs[0]
  let sy = ys[0]
  let ex = xs[last]
  let ey = ys[last]
  xs[0] += sdx * start_trim
  ys[0] += sdy * start_trim
  xs[last] -= edx * end_trim
  ys[last] -= edy * end_trim
  let length = fn(i : Int32) {
    (xs[i] - xs[i - 1]).abs() + (ys[i] - ys[i - 1]).abs()
  }
  // Whether the route turns a corner at point i, from running one way to running the other.
  let turns = fn(i : Int32) {
    !linear &&
    i > 0 &&
    i < last &&
    aligned(i) &&
    aligned(i + 1) &&
    length(i) >= 0.01 &&
    length(i + 1) >= 0.01 &&
    ((xs[i] - xs[i - 1]).abs() < 0.01) != ((xs[i + 1] - xs[i]).abs() < 0.01)
  }
  // An edge that curves into a marker runs straight for a little way first, where it has the room, so that the marker does not sit on the bend.
  let run_along = fn(i : Int32, ux : Double, uy : Double) {
    (xs[i] - xs[i - 1]).abs() * ux.abs() + (ys[i] - ys[i - 1]).abs() * uy.abs()
  }
  // Of the way from the end of a run to where it turns, the part that makes up for a larger marker beside this one is kept where it can be, and the rest is at most a quarter of what is left, so that ends on one side of a node turn equally far from it.
  let lead = fn(reach : Double, trim : Double, run : Double) {
    let room = @util.js_min(@util.js_max(0, reach - LEAD - trim), run / 4)
    room + @util.js_min(reach - trim - room, (run - room) / 4)
  }
  let arrives = if end_reach > end_trim && (!straight(last) || turns(last - 1)) {
    lead(end_reach, end_trim, run_along(last, edx, edy))
  } else {
    0
  }
  let leaves = if start_reach > start_trim && (!straight(1) || turns(1)) {
    lead(start_reach, start_trim, run_along(1, sdx, sdy))
  } else {
    0
  }
  if arrives >= 1 {
    xs.insert(last, xs[last] - edx * arrives)
    ys.insert(last, ys[last] - edy * arrives)
    axes.insert(last, axes[last])
    last += 1
  }
  if leaves >= 1 {
    xs.insert(1, xs[0] + sdx * leaves)
    ys.insert(1, ys[0] + sdy * leaves)
    axes.insert(1, axes[1])
    last += 1
  }
  let d = StringBuilder()
  d.write_string("M\{num(xs[0])},\{num(ys[0])}")
  let mut at_x = xs[0]
  let mut at_y = ys[0]
  let line_to = fn(x : Double, y : Double) {
    if near(x, y, at_x, at_y) {
      return
    }
    d.write_string("L\{num(x)},\{num(y)}")
    at_x = x
    at_y = y
  }
  for i in 1..<=last {
    let x = xs[i]
    let y = ys[i]
    if !straight(i) {
      let down = axes[i] == 0
      let along = if down { y - at_y } else { x - at_x }
      let k = along.abs() *
        @layout.ease(if down { x - at_x } else { y - at_y }, along)
      let ux = if down { 0.0 } else { js_sign(along) * k }
      let uy = if down { js_sign(along) * k } else { 0.0 }
      d.write_string(
        "C\{num(at_x + ux)},\{num(at_y + uy)} \{num(x - ux)},\{num(y - uy)} \{num(x)},\{num(y)}",
      )
      at_x = x
      at_y = y
      continue
    }
    if !turns(i) {
      // A point part of the way along one straight run adds nothing to the path.
      if i < last &&
        aligned(i) &&
        aligned(i + 1) &&
        (x - xs[i - 1]) * (xs[i + 1] - x) + (y - ys[i - 1]) * (ys[i + 1] - y) >
        0 {
        continue
      }
      line_to(x, y)
      continue
    }
    // How much of the leg before the turn and of the leg after it the turn takes: all of one that ends at a node, short of the straight run into a marker, and half of one it shares.
    let mut before = if turns(i - 1) { length(i) / 2 } else { length(i) }
    let mut after = if turns(i + 1) { length(i + 1) / 2 } else { length(i + 1) }
    if stepped {
      before = @util.js_min(@util.js_min(CORNER, before), after)
      after = before
    }
    let (ux, uy) = unit(i - 1, i, axes[i])
    let (vx, vy) = unit(i, i + 1, axes[i + 1])
    line_to(x - ux * before, y - uy * before)
    at_x = x + vx * after
    at_y = y + vy * after
    if stepped {
      d.write_string("Q\{num(x)},\{num(y)} \{num(at_x)},\{num(at_y)}")
    } else {
      d.write_string(
        "C\{num(x - ux * before * (1 - HANDLE))},\{num(y - uy * before * (1 - HANDLE))} \{num(x + vx * after * (1 - HANDLE))},\{num(y + vy * after * (1 - HANDLE))} \{num(at_x)},\{num(at_y)}",
      )
    }
  }
  { d: d.to_string(), sx, sy, sdx: -sdx, sdy: -sdy, ex, ey, edx, edy, }
}
