///|
/// The powers of ten that a double holds exactly, from 1 to 1e22.
let tens : Array[Double] = {
  let out = [1.0]
  for _ in 1..<=22 {
    out.push(out[out.length() - 1] * 10)
  }
  out
}

///|
/// The commands of the path `d` as `sample` reads them: each command's character code, how many
/// arguments it has, then those arguments.
/// Any capital letter but `E` starts a command, and a number before the first one is dropped.
fn tokenize(d : String) -> Array[Double] {
  let out : Array[Double] = []
  let mut at = -1
  let mut i = 0
  while i < d.length() {
    let c = @util.code_at(d, i)
    if c >= 'A' && c <= 'Z' && c != 'E' {
      at = out.length() + 1
      out.push(c.to_double())
      out.push(0)
      i += 1
    } else if c == '-' || c == '.' || @util.is_digit(c) {
      let mut j = if c == '-' { i + 1 } else { i }
      let mut m = 0.0
      let mut places = -1
      while true {
        let k = @util.code_at(d, j)
        if k == '.' && places < 0 {
          places = 0
        } else if @util.is_digit(k) {
          m = m * 10 + (k - '0').to_double()
          if places >= 0 {
            places += 1
          }
        } else {
          break
        }
        j += 1
      }
      // Dividing an exact integer by an exact power of ten rounds as `Number()` reads the decimal,
      // which a number with an exponent or too many digits for either to be exact does not.
      let v = if (@util.code_at(d, j) | 32) == 'e' ||
        m > 9007199254740991 ||
        places > 22 {
        while true {
          let k = @util.code_at(d, j)
          let signed = (k == '-' || k == '+') &&
            (@util.code_at(d, j - 1) | 32) == 'e'
          guard k == '.' || k == 'e' || k == 'E' || @util.is_digit(k) || signed else {
            break
          }
          j += 1
        }
        @util.to_number(@util.slice(d, i, end=j))
      } else {
        let v = if places > 0 { m / tens[places] } else { m }
        if c == '-' {
          -v
        } else {
          v
        }
      }
      if at >= 0 {
        out.push(v)
        out[at] += 1
      }
      i = j
    } else {
      i += 1
    }
  }
  out
}

///|
/// The number `tokenize` reads back from `num(value)`.
fn written(value : Double) -> Double {
  let n = (value * 100).round()
  if n == 0 {
    0
  } else {
    n / 100
  }
}

///|
/// Pushes eight points along an unrotated arc from (`x1`, `y1`) to (`x2`, `y2`), or just its end when
/// it has no radius or no length, finding its center as SVG converts the end points of an arc.
fn sample_arc(
  out : Array[Double],
  x1 : Double,
  y1 : Double,
  rx : Double,
  ry : Double,
  large : Double,
  sweep : Double,
  x2 : Double,
  y2 : Double,
) -> Unit {
  let hx = (x1 - x2) / 2
  let hy = (y1 - y2) / 2
  if rx == 0 || ry == 0 || (hx == 0 && hy == 0) {
    out.push(x2)
    out.push(y2)
    return
  }
  let scale = @util.js_max(
    1,
    (hx * hx / (rx * rx) + hy * hy / (ry * ry)).sqrt(),
  )
  let rx = rx * scale
  let ry = ry * scale
  let k = (if large == sweep { -1.0 } else { 1.0 }) *
    @util.js_max(
      0,
      (rx * rx * ry * ry - rx * rx * hy * hy - ry * ry * hx * hx) /
      (rx * rx * hy * hy + ry * ry * hx * hx),
    ).sqrt()
  let cx = k * rx * hy / ry + (x1 + x2) / 2
  let cy = -k * ry * hx / rx + (y1 + y2) / 2
  let from = @math.atan2((y1 - cy) / ry, (x1 - cx) / rx)
  let mut turn = @math.atan2((y2 - cy) / ry, (x2 - cx) / rx) - from
  if sweep != 0 && turn < 0 {
    turn += 2 * @math.PI
  } else if sweep == 0 && turn > 0 {
    turn -= 2 * @math.PI
  }
  for i in 1..<=8 {
    let at = from + turn * i.to_double() / 8
    out.push(cx + rx * @math.cos(at))
    out.push(cy + ry * @math.sin(at))
  }
}

///|
/// Points along the path `tokenize` reads into `tokens`, as x, y pairs: its corners and eight
/// samples along each curve and arc.
/// A NaN pair separates subpaths, so no segment joins the end of one to the start of the next.
fn sample(tokens : Array[Double]) -> Array[Double] {
  let out : Array[Double] = []
  let mut x = 0.0
  let mut y = 0.0
  let mut i = 0
  while i < tokens.length() {
    let cmd = tokens[i].to_int()
    let s = i + 2
    let e = s + tokens[i + 1].to_int()
    i = e
    if cmd == 'H' || cmd == 'V' {
      for k in s..<e {
        if cmd == 'H' {
          x = tokens[k]
        } else {
          y = tokens[k]
        }
        out.push(x)
        out.push(y)
      }
    } else if cmd == 'C' || cmd == 'Q' {
      let cubic = cmd == 'C'
      let step = if cubic { 6 } else { 4 }
      let mut k = s
      while k + step <= e {
        let x1 = tokens[k]
        let y1 = tokens[k + 1]
        let x2 = tokens[k + 2]
        let y2 = tokens[k + 3]
        let x3 = if cubic { tokens[k + 4] } else { x2 }
        let y3 = if cubic { tokens[k + 5] } else { y2 }
        for n in 1..<=8 {
          let t = n.to_double() * 0.125
          // De Casteljau's steps in this order round as pele's do.
          let mut ax = x + (x1 - x) * t
          let mut ay = y + (y1 - y) * t
          let mut bx = x1 + (x2 - x1) * t
          let mut by = y1 + (y2 - y1) * t
          if cubic {
            let cx = x2 + (x3 - x2) * t
            let cy = y2 + (y3 - y2) * t
            ax += (bx - ax) * t
            ay += (by - ay) * t
            bx += (cx - bx) * t
            by += (cy - by) * t
          }
          out.push(ax + (bx - ax) * t)
          out.push(ay + (by - ay) * t)
        }
        x = x3
        y = y3
        k += step
      }
    } else if cmd == 'A' {
      let mut k = s
      while k + 7 <= e {
        sample_arc(
          out,
          x,
          y,
          tokens[k],
          tokens[k + 1],
          tokens[k + 3],
          tokens[k + 4],
          tokens[k + 5],
          tokens[k + 6],
        )
        x = tokens[k + 5]
        y = tokens[k + 6]
        k += 7
      }
    } else {
      let mut k = s
      while k + 2 <= e {
        if cmd == 'M' && k == s && out.length() > 0 {
          out.push(@double.not_a_number)
          out.push(@double.not_a_number)
        }
        x = tokens[k]
        y = tokens[k + 1]
        out.push(x)
        out.push(y)
        k += 2
      }
    }
  }
  out
}

///|
/// Points along the path `d`, as `sample` finds them.
fn path_points(d : String) -> Array[Double] {
  sample(tokenize(d))
}

///|
/// Whether the segment from (`x`, `y`) running (`dx`, `dy`) overlaps the box from (`l`, `t`) to
/// (`r`, `b`), as Liang-Barsky clipping tells.
fn clips(
  x : Double,
  y : Double,
  dx : Double,
  dy : Double,
  l : Double,
  t : Double,
  r : Double,
  b : Double,
) -> Bool {
  let mut lo = 0.0
  let mut hi = 1.0
  for side in 0..<4 {
    let (p, q) = match side {
      0 => (-dx, x - l)
      1 => (dx, r - x)
      2 => (-dy, y - t)
      _ => (dy, b - y)
    }
    if p == 0 {
      if q < 0 {
        hi = -1
      }
    } else if p < 0 {
      lo = @util.js_max(lo, q / p)
    } else {
      hi = @util.js_min(hi, q / p)
    }
  }
  lo < hi
}

///|
/// Whether any segment between the `points` of a path enters the box from (`l`, `t`) to (`r`, `b`).
fn enters(
  points : Array[Double],
  l : Double,
  t : Double,
  r : Double,
  b : Double,
) -> Bool {
  for k = 0; k + 2 < points.length(); k = k + 2 {
    let x = points[k]
    let y = points[k + 1]
    let x2 = points[k + 2]
    let y2 = points[k + 3]
    if (x < l && x2 < l) ||
      (x > r && x2 > r) ||
      (y < t && y2 < t) ||
      (y > b && y2 > b) {
      continue
    }
    if clips(x, y, x2 - x, y2 - y, l, t, r, b) {
      return true
    }
  }
  false
}
