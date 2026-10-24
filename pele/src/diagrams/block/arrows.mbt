///|
const RIGHT : Int32 = 1

///|
const LEFT : Int32 = 2

///|
const UP : Int32 = 4

///|
const DOWN : Int32 = 8

///|
/// How far a head reaches past each side of its shaft.
const OVERHANG : Double = 7

///|
const MAX_DEPTH : Double = 20

///|
const NUB : Double = 12

///|
/// The size a block arrow needs, and the shift of its label from the center, away from the heads.
pub(all) struct ArrowSize {
  w : Double
  h : Double
  dx : Double
  dy : Double
}

///|
/// The directions an arrow points in, as a set of bits.
/// Mermaid compares directions exactly, so `( up )` draws no arrow there; here spaces are ignored.
pub fn arrow_mask(directions : Array[String]) -> Int32 {
  let mut mask = 0
  for direction in directions {
    mask = mask |
      (match @util.trim(direction) {
        "right" => RIGHT
        "left" => LEFT
        "up" => UP
        "down" => DOWN
        "x" => RIGHT | LEFT
        "y" => UP | DOWN
        _ => 0
      })
  }
  mask
}

///|
fn bit(mask : Int32, flag : Int32) -> Double {
  if (mask & flag) != 0 {
    1
  } else {
    0
  }
}

///|
/// The axis an arrow runs along: `x`, `y`, or none for one that points along both or neither.
/// An arrow along one axis has a shaft and heads wider than it; one that points along both axes is a box with a small point on each side it names.
pub fn arrow_axis(mask : Int32) -> String {
  if mask != 0 && (mask & (UP | DOWN)) == 0 {
    return "x"
  }
  if mask != 0 && (mask & (RIGHT | LEFT)) == 0 {
    return "y"
  }
  ""
}

///|
/// The size of an arrow around a label of that size.
pub fn arrow_size(mask : Int32, tw : Double, th : Double) -> ArrowSize {
  let axis = arrow_axis(mask)
  let across = bit(mask, LEFT) - bit(mask, RIGHT)
  let along = bit(mask, UP) - bit(mask, DOWN)
  if axis == "x" {
    let h = @util.js_max(th + 8, 14) + 2 * OVERHANG
    let depth = @util.js_min(h / 2, MAX_DEPTH)
    let heads : Double = if mask == (RIGHT | LEFT) { 2 } else { 1 }
    return {
      w: @util.js_max(tw + 12, 16) + depth * heads,
      h,
      dx: across * depth / 2,
      dy: 0,
    }
  }
  if axis == "y" {
    let w = @util.js_max(tw + 16, 14) + 2 * OVERHANG
    let depth = @util.js_min(w / 2, MAX_DEPTH)
    let heads : Double = if mask == (UP | DOWN) { 2 } else { 1 }
    return {
      w,
      h: @util.js_max(th + 8, 16) + depth * heads,
      dx: 0,
      dy: along * depth / 2,
    }
  }
  {
    w: @util.js_max(tw + 16, 24) + NUB * (bit(mask, LEFT) + bit(mask, RIGHT)),
    h: @util.js_max(th + 8, 24) + NUB * (bit(mask, UP) + bit(mask, DOWN)),
    dx: across * NUB / 2,
    dy: along * NUB / 2,
  }
}

///|
/// The outline of an arrow of that size, centered on the origin.
pub fn draw_arrow(
  mask : Int32,
  w : Double,
  h : Double,
  attrs : String,
) -> String {
  let axis = arrow_axis(mask)
  let x = w / 2
  let y = h / 2
  let p : Array[Double] = []
  let has = (flag : Int32) => (mask & flag) != 0
  if axis == "x" {
    let depth = @util.js_min(y, MAX_DEPTH)
    let s = y - OVERHANG
    let x0 = if has(LEFT) { -x + depth } else { -x }
    let x1 = if has(RIGHT) { x - depth } else { x }
    p.append([x0, -s, x1, -s])
    if has(RIGHT) {
      p.append([x1, -y, x, 0, x1, y])
    }
    p.append([x1, s, x0, s])
    if has(LEFT) {
      p.append([x0, y, -x, 0, x0, -y])
    }
  } else if axis == "y" {
    let depth = @util.js_min(x, MAX_DEPTH)
    let s = x - OVERHANG
    let y0 = if has(UP) { -y + depth } else { -y }
    let y1 = if has(DOWN) { y - depth } else { y }
    p.append([s, y0, s, y1])
    if has(DOWN) {
      p.append([x, y1, 0, y, -x, y1])
    }
    p.append([-s, y1, -s, y0])
    if has(UP) {
      p.append([-x, y0, 0, -y, x, y0])
    }
  } else {
    let x0 = if has(LEFT) { -x + NUB } else { -x }
    let x1 = if has(RIGHT) { x - NUB } else { x }
    let y0 = if has(UP) { -y + NUB } else { -y }
    let y1 = if has(DOWN) { y - NUB } else { y }
    let cx = (x0 + x1) / 2
    let cy = (y0 + y1) / 2
    let kx = @util.js_min(10, (x1 - x0) / 2)
    let ky = @util.js_min(10, (y1 - y0) / 2)
    p.append([x0, y0])
    if has(UP) {
      p.append([cx - kx, y0, cx, -y, cx + kx, y0])
    }
    p.append([x1, y0])
    if has(RIGHT) {
      p.append([x1, cy - ky, x, cy, x1, cy + ky])
    }
    p.append([x1, y1])
    if has(DOWN) {
      p.append([cx + kx, y1, cx, y, cx - kx, y1])
    }
    p.append([x0, y1])
    if has(LEFT) {
      p.append([x0, cy + ky, -x, cy, x0, cy - ky])
    }
  }
  let points = StringBuilder()
  for i = 0; i < p.length(); i = i + 2 {
    if i > 0 {
      points.write_char(' ')
    }
    points.write_string(@svg.num(p[i]))
    points.write_char(',')
    points.write_string(@svg.num(p[i + 1]))
  }
  "<polygon points=\"\{points.to_string()}\" stroke-linejoin=\"round\"\{attrs}/>"
}
