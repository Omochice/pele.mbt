///|
/// `10 ** power` for a whole `power`, which V8 gives as the nearest double.
/// `@math.pow` is a fdlibm port that is off by one in the last place for some of these (10 ** 29).
fn pow10(power : Double) -> Double {
  if power.is_nan() {
    power
  } else if power > 400 {
    @double.infinity
  } else if power < -400 {
    0
  } else {
    @util.to_number("1e" + power.to_int().to_string())
  }
}

///|
/// A step of 1, 2 or 5 times a power of ten that divides `span` into about `count` parts.
/// A step below one comes back as the negative of its inverse, which is a whole number, so that
/// tick values are found by division and print without rounding noise (0.3, not 0.30000000000000004).
pub fn tick_step(span : Double, count : Double) -> Double {
  let raw = span / @util.js_max(count, 1)
  let power = @math.log10(raw).floor()
  let unit = raw / pow10(power)
  let factor = if unit >= 7.07 {
    10.0
  } else if unit >= 3.16 {
    5.0
  } else if unit >= 1.41 {
    2.0
  } else {
    1.0
  }
  if power < 0 {
    -pow10(-power) / factor
  } else {
    factor * pow10(power)
  }
}

///|
/// How many steps from zero `value` is.
pub fn tick_index(step : Double, value : Double) -> Double {
  if step > 0 {
    value / step
  } else {
    value * -step
  }
}

///|
/// The value `index` steps from zero.
pub fn tick_value(step : Double, index : Double) -> Double {
  if step > 0 {
    index * step
  } else {
    index / -step
  }
}

///|
/// The multiples of a step from `lo` to `hi`, both included.
pub fn ticks_between(lo : Double, hi : Double, step : Double) -> Array[Double] {
  let mut first = tick_index(step, lo).round()
  if tick_value(step, first) < lo {
    first += 1
  }
  let mut last = tick_index(step, hi).round()
  if tick_value(step, last) > hi {
    last -= 1
  }
  let out = []
  let mut i = first
  while i <= last && out.length() < 100 {
    out.push(tick_value(step, i))
    i += 1
  }
  out
}
