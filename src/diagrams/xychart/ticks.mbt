///|
/// A step of 1, 2 or 5 times a power of ten that divides `span` into about `count` parts.
/// A step below one comes back as the negative of its inverse, which is a whole number.
pub fn tick_step(span : Double, count : Double) -> Double {
  ignore(span)
  ignore(count)
  0
}

///|
/// How many steps from zero `value` is.
pub fn tick_index(step : Double, value : Double) -> Double {
  ignore(step)
  value
}

///|
/// The value `index` steps from zero.
pub fn tick_value(step : Double, index : Double) -> Double {
  ignore(step)
  index
}

///|
/// The multiples of a step from `lo` to `hi`, both included.
pub fn ticks_between(lo : Double, hi : Double, step : Double) -> Array[Double] {
  ignore(tick_index(step, lo))
  ignore(hi)
  []
}
