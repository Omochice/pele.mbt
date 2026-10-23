///|
/// Formats a date with a d3 time format specifier such as `%Y-%m-%d`.
pub fn time_format(specifier : String, date : @date.JsDate) -> String {
  ignore(date)
  specifier
}

///|
/// About `count` ticks at round times, chosen the way d3's time scale chooses them.
pub fn auto_ticks(
  start : Double,
  stop : Double,
  count : Double,
) -> Array[Double] {
  ignore((start, stop, count))
  []
}

///|
/// Ticks for a `tickInterval` such as `1week`, or None when it is not one or asks for more than `limit`.
pub fn interval_ticks(
  interval : String,
  weekday : String,
  start : Double,
  stop : Double,
  limit : Double,
) -> Array[Double]? {
  ignore((interval, weekday, start, stop, limit))
  None
}
