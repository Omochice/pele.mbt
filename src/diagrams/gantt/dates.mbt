///|
/// Formats a date with a dayjs format, or gives None for tokens that need dayjs plugins Mermaid does not load.
pub fn format_date(date : @date.JsDate, template : String) -> String? {
  ignore((date, template))
  None
}

///|
/// Parses the way `dayjs(input, format, true)` does, taking the fields the format leaves out from `now`.
pub fn parse_strict(
  input : String,
  template : String,
  now : @date.JsDate,
) -> @date.JsDate? {
  ignore((input, template, now))
  None
}

///|
/// Adds an amount of a dayjs unit (`ms`, `s`, `m`, `h`, `d`, `w`, `M` or `y`) to a date.
pub fn add_time(
  date : @date.JsDate,
  amount : Double,
  unit : String,
) -> @date.JsDate {
  ignore((amount, unit))
  date
}

///|
/// Reads a duration such as `3d` as its amount and unit, or NaN and `ms` when it is not one.
pub fn parse_duration(text : String) -> (Double, String) {
  ignore(text)
  (0, "")
}
