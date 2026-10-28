///|
/// Whether `c` starts one of the path commands `path_points` reads.
fn is_path_command(c : Int32) -> Bool {
  c == 'M' ||
  c == 'L' ||
  c == 'H' ||
  c == 'V' ||
  c == 'C' ||
  c == 'Q' ||
  c == 'A'
}

///|
/// Where the number that starts at `from` in `text` ends, as
/// `/-?(?:\d+\.?\d*|\.\d+)(?:e[-+]?\d+)?/i` matches one there.
fn path_number_end(text : String, from : Int32) -> Int32? {
  let n = text.length()
  let mut i = from
  if i < n && @util.code_at(text, i) == '-' {
    i += 1
  }
  let whole = digits_end(text, i)
  if whole > i {
    i = whole
    if i < n && @util.code_at(text, i) == '.' {
      i = digits_end(text, i + 1)
    }
  } else if i < n &&
    @util.code_at(text, i) == '.' &&
    digits_end(text, i + 1) > i + 1 {
    i = digits_end(text, i + 1)
  } else {
    return None
  }
  if i < n && (@util.code_at(text, i) == 'e' || @util.code_at(text, i) == 'E') {
    let mut j = i + 1
    if j < n && (@util.code_at(text, j) == '-' || @util.code_at(text, j) == '+') {
      j += 1
    }
    let exponent = digits_end(text, j)
    if exponent > j {
      i = exponent
    }
  }
  Some(i)
}

///|
/// The numbers in the text between `from` and `end`, read left to right as `path_number_end` finds them.
fn path_numbers(text : String, from : Int32, end : Int32) -> Array[Double] {
  let out = []
  let mut i = from
  while i < end {
    match path_number_end(text, i) {
      Some(stop) => {
        out.push(@util.parse_float(@util.slice(text, i, end=stop)))
        i = stop
      }
      None => i += 1
    }
  }
  out
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
/// Points along a path as x, y pairs: its corners and eight samples along each curve and arc.
/// A NaN pair separates subpaths, so no segment joins the end of one to the start of the next.
fn path_points(d : String) -> Array[Double] {
  let out : Array[Double] = []
  let mut x = 0.0
  let mut y = 0.0
  let n = d.length()
  let mut at = 0
  while at < n && !is_path_command(@util.code_at(d, at)) {
    at += 1
  }
  while at < n {
    let cmd = @util.code_at(d, at)
    let mut end = at + 1
    while end < n && !is_path_command(@util.code_at(d, end)) {
      end += 1
    }
    let args = path_numbers(d, at + 1, end)
    if cmd == 'H' || cmd == 'V' {
      for v in args {
        if cmd == 'H' {
          x = v
        } else {
          y = v
        }
        out.push(x)
        out.push(y)
      }
    } else if cmd == 'C' || cmd == 'Q' {
      let step = if cmd == 'C' { 6 } else { 4 }
      let mut k = 0
      while k + step <= args.length() {
        let xs = [x]
        let ys = [y]
        for i = 0; i < step; i = i + 2 {
          xs.push(args[k + i])
          ys.push(args[k + i + 1])
        }
        for s in 1..<=8 {
          let t = s.to_double() * 0.125
          let px = xs.copy()
          let py = ys.copy()
          for m = px.length() - 1; m > 0; m = m - 1 {
            for i in 0..<m {
              px[i] += (px[i + 1] - px[i]) * t
              py[i] += (py[i + 1] - py[i]) * t
            }
          }
          out.push(px[0])
          out.push(py[0])
        }
        x = xs[xs.length() - 1]
        y = ys[ys.length() - 1]
        k += step
      }
    } else if cmd == 'A' {
      let mut k = 0
      while k + 7 <= args.length() {
        sample_arc(
          out,
          x,
          y,
          args[k],
          args[k + 1],
          args[k + 3],
          args[k + 4],
          args[k + 5],
          args[k + 6],
        )
        x = args[k + 5]
        y = args[k + 6]
        k += 7
      }
    } else {
      let mut k = 0
      while k + 2 <= args.length() {
        if cmd == 'M' && k == 0 && out.length() > 0 {
          out.push(@double.not_a_number)
          out.push(@double.not_a_number)
        }
        x = args[k]
        y = args[k + 1]
        out.push(x)
        out.push(y)
        k += 2
      }
    }
    at = end
  }
  out
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
    let dx = points[k + 2] - x
    let dy = points[k + 3] - y
    let mut lo = 0.0
    let mut hi = 1.0
    for side in [(-dx, x - l), (dx, r - x), (-dy, y - t), (dy, b - y)] {
      let (p, q) = side
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
    if lo < hi {
      return true
    }
  }
  false
}
