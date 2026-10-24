///|
/// One step of the mulberry32 generator, as a number in `[0, 1)`.
/// The sum with the generator's increment is truncated to 32 bits as a whole, so a fractional seed behaves as in pele.
pub fn seeded_random(seed : Double) -> Double {
  let sum = seed + 1831565813.0
  let mut t = sum.to_int64().to_int().reinterpret_as_uint()
  t = (t ^ (t >> 15)) * (t | 1)
  t = t ^ (t + (t ^ (t >> 7)) * (t | 61))
  (t ^ (t >> 14)).to_double() / 4294967296.0
}

///|
/// Mermaid's string hash, a 32-bit integer.
pub fn hash_string(text : String) -> Int32 {
  let mut hash = 0
  for i in 0..<text.length() {
    hash = (hash << 5) - hash + @util.code_at(text, i)
  }
  hash
}

///|
/// A configured seed other than zero wins; otherwise the seed comes from the diagram's id.
pub fn resolve_seed(configured : Double?, id : String) -> Double {
  match configured {
    Some(seed) if !seed.is_nan() && !seed.is_inf() && seed != 0 => seed
    _ => hash_string(id).to_double()
  }
}

///|
/// How a wavy line is drawn along one axis.
pub(all) struct WaveOptions {
  segments : Int32
  vertical : Bool
  /// Multipliers Mermaid uses to vary the seed per point and per control point.
  point_step : Int32
  control_step : Int32
  control_shift : Int32
  pin_start : Bool
  pin_end : Bool
}

///|
pub let fold : WaveOptions = {
  segments: 7,
  vertical: true,
  point_step: 17,
  control_step: 31,
  control_shift: 7,
  pin_start: false,
  pin_end: false,
}

///|
pub let horizon : WaveOptions = {
  segments: 7,
  vertical: false,
  point_step: 23,
  control_step: 37,
  control_shift: 11,
  pin_start: false,
  pin_end: false,
}

///|
/// A wavy line along one axis from `from` to `to`, centered on `center` in the other axis.
/// Curves are flat lists of numbers: a start point, then six numbers per cubic segment.
/// Points jitter by up to the amplitude; a pinned end stays on the center line.
pub fn wave(
  from : Double,
  to : Double,
  center : Double,
  seed : Double,
  amplitude : Double,
  options : WaveOptions,
) -> Array[Double] {
  let step = (to - from) / options.segments.to_double()
  let along = []
  let across = []
  for i in 0..<=options.segments {
    let pinned = (i == 0 && options.pin_start) ||
      (i == options.segments && options.pin_end)
    along.push(from + i.to_double() * step)
    across.push(
      if pinned {
        center
      } else {
        let jitter = seeded_random(seed + (i * options.point_step).to_double())
        center + jitter * amplitude * 2 - amplitude
      },
    )
  }
  let out = if options.vertical {
    [across[0], along[0]]
  } else {
    [along[0], across[0]]
  }
  for i in 0..<options.segments {
    let mid = (along[i] + along[i + 1]) / 2
    let sign = if i % 2 == 0 { 1.0 } else { -1.0 }
    let varied = seeded_random(
      seed + (i * options.control_step + options.control_shift).to_double(),
    )
    let offset = amplitude * 1.5 * sign * varied
    if options.vertical {
      out.push(across[i] + offset)
      out.push(mid)
      out.push(across[i + 1] - offset)
      out.push(mid)
      out.push(across[i + 1])
      out.push(along[i + 1])
    } else {
      out.push(mid)
      out.push(across[i] + offset)
      out.push(mid)
      out.push(across[i + 1] - offset)
      out.push(along[i + 1])
      out.push(across[i + 1])
    }
  }
  out
}

///|
/// The cliff: a steep S from `(cx, top)` down to `(cx, bottom)`.
pub fn cliff(
  cx : Double,
  top : Double,
  bottom : Double,
  amplitude : Double,
) -> Array[Double] {
  let h = bottom - top
  [
    cx,
    top,
    cx + amplitude,
    top + h * 0.2,
    cx - amplitude * 1.5,
    top + h * 0.55,
    cx + amplitude * 0.5,
    top + h * 0.75,
    cx - amplitude,
    top + h * 0.85,
    cx + amplitude * 0.3,
    top + h * 0.95,
    cx,
    bottom,
  ]
}

///|
fn segment(
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  e : Double,
  f : Double,
) -> String {
  "C\{@svg.num(a)},\{@svg.num(b)} \{@svg.num(c)},\{@svg.num(d)} \{@svg.num(e)},\{@svg.num(f)}"
}

///|
/// Path commands that continue from the curve's start point to its end.
pub fn forward(curve : Array[Double]) -> String {
  let d = StringBuilder()
  let mut i = 2
  while i < curve.length() {
    d.write_string(
      segment(
        curve[i],
        curve[i + 1],
        curve[i + 2],
        curve[i + 3],
        curve[i + 4],
        curve[i + 5],
      ),
    )
    i += 6
  }
  d.to_string()
}

///|
/// Path commands that continue from the curve's end point back to its start.
pub fn backward(curve : Array[Double]) -> String {
  let d = StringBuilder()
  let mut i = curve.length() - 6
  while i >= 2 {
    d.write_string(
      segment(
        curve[i + 2],
        curve[i + 3],
        curve[i],
        curve[i + 1],
        curve[i - 2],
        curve[i - 1],
      ),
    )
    i -= 6
  }
  d.to_string()
}

///|
pub fn curve_path(curve : Array[Double]) -> String {
  "M\{@svg.num(curve[0])},\{@svg.num(curve[1])}\{forward(curve)}"
}

///|
pub fn ellipse_path(
  cx : Double,
  cy : Double,
  rx : Double,
  ry : Double,
) -> String {
  let r = "\{@svg.num(rx)},\{@svg.num(ry)}"
  let left = "\{@svg.num(cx - rx)},\{@svg.num(cy)}"
  let right = "\{@svg.num(cx + rx)},\{@svg.num(cy)}"
  "M\{left}A\{r} 0 1,1 \{right}A\{r} 0 1,1 \{left}Z"
}
