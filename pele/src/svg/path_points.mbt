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
/// Points along a path as x, y pairs: its corners, eight samples along each curve, and the end of
/// each arc.
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
    } else {
      let step = if cmd == 'A' { 7 } else { 2 }
      let mut k = 0
      while k + step <= args.length() {
        if cmd == 'M' && k == 0 && out.length() > 0 {
          out.push(@double.not_a_number)
          out.push(@double.not_a_number)
        }
        x = args[k + step - 2]
        y = args[k + step - 1]
        out.push(x)
        out.push(y)
        k += step
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

///|
/// Whether a path runs inside any of the boxes, given four numbers each as left, top, right and
/// bottom.
/// A path along a border does not count.
pub fn runs_inside(d : String, boxes : Array[Double]) -> Bool {
  if boxes.is_empty() {
    return false
  }
  let points = path_points(d)
  for b = 0; b < boxes.length(); b = b + 4 {
    if enters(
        points,
        boxes[b] + 0.5,
        boxes[b + 1] + 0.5,
        boxes[b + 2] - 0.5,
        boxes[b + 3] - 0.5,
      ) {
      return true
    }
  }
  false
}
