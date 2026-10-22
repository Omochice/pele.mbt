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
/// Between two points that are not in line, a route is one S that leaves and arrives along the flow.
pub fn route_path(
  route : Array[Double],
  curve : String?,
  start_trim : Double,
  end_trim : Double,
) -> EdgePath {
  let linear = curve == Some("linear")
  let xs : Array[Double] = []
  let ys : Array[Double] = []
  let axes : Array[Double] = []
  let near = fn(ax : Double, ay : Double, bx : Double, by : Double) {
    (ax - bx).abs() < 0.01 && (ay - by).abs() < 0.01
  }
  for i = 0; i < route.length(); i = i + 3 {
    xs.push(route[i])
    ys.push(route[i + 1])
    axes.push(route[i + 2])
  }
  let last = xs.length() - 1
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
    line_to(x, y)
  }
  { d: d.to_string(), sx, sy, sdx: -sdx, sdy: -sdy, ex, ey, edx, edy, }
}
