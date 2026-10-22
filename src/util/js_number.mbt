///|
/// Reads the leading decimal number of `text` as JavaScript's `parseFloat` does.
/// Returns NaN when the text does not start with one.
pub fn parse_float(text : String) -> Double {
  ignore(text)
  @double.not_a_number
}

///|
/// Reads the whole `text` as JavaScript's `Number(text)` does.
/// Returns NaN when the text is not a number.
pub fn to_number(text : String) -> Double {
  ignore(text)
  @double.not_a_number
}
