///|
fn skip_decimal_digits(text : String, from : Int32) -> Int32 {
  let mut i = from
  while is_digit(code_at(text, i)) {
    i += 1
  }
  i
}

///|
/// The end of the unsigned decimal literal at `from`, or `from` when there is none.
/// An exponent without digits is left out of the literal, as `parseFloat` leaves it.
fn decimal_literal_end(text : String, from : Int32) -> Int32 {
  let whole = skip_decimal_digits(text, from)
  let mut end = whole
  if code_at(text, whole) == '.'.to_int() {
    end = skip_decimal_digits(text, whole + 1)
  }
  let has_digits = whole > from || end > whole + 1
  if !has_digits {
    return from
  }
  let e = code_at(text, end)
  if e == 'e'.to_int() || e == 'E'.to_int() {
    let sign = code_at(text, end + 1)
    let at = if sign == '+'.to_int() || sign == '-'.to_int() {
      end + 2
    } else {
      end + 1
    }
    let stop = skip_decimal_digits(text, at)
    if stop > at {
      end = stop
    }
  }
  end
}

///|
/// The value of an unsigned decimal literal, written the way `parse_double` accepts.
fn decimal_literal_value(text : String, from : Int32, end : Int32) -> Double {
  let whole = skip_decimal_digits(text, from)
  let int_part = slice(text, from, end=whole)
  let mut at = whole
  let mut fraction = ""
  if code_at(text, at) == '.'.to_int() {
    let stop = skip_decimal_digits(text, at + 1)
    fraction = slice(text, at + 1, end=stop)
    at = stop
  }
  let exponent = if at < end { slice(text, at, end~) } else { "" }
  let normalized = (if int_part == "" { "0" } else { int_part }) +
    "." +
    (if fraction == "" { "0" } else { fraction }) +
    exponent
  // `parse_double` raises on a value beyond the range of a double instead of rounding it.
  @string.parse_double(normalized) catch {
    _ => {
      let significant = int_part.contains_any(chars="123456789") ||
        fraction.contains_any(chars="123456789")
      if significant && !exponent.contains("-") {
        @double.infinity
      } else {
        0.0
      }
    }
  }
}

///|
fn with_sign(negative : Bool, value : Double) -> Double {
  if negative {
    -value
  } else {
    value
  }
}

///|
/// Reads the leading decimal number of `text` as JavaScript's `parseFloat` does.
/// Returns NaN when the text does not start with one.
pub fn parse_float(text : String) -> Double {
  let mut start = 0
  while is_space(code_at(text, start)) {
    start += 1
  }
  let sign = code_at(text, start)
  let negative = sign == '-'.to_int()
  if negative || sign == '+'.to_int() {
    start += 1
  }
  if starts_with_at(text, "Infinity", start) {
    return with_sign(negative, @double.infinity)
  }
  let end = decimal_literal_end(text, start)
  if end == start {
    return @double.not_a_number
  }
  with_sign(negative, decimal_literal_value(text, start, end))
}

///|
fn radix_value(text : String, from : Int32, radix : Int32) -> Double {
  if from >= text.length() {
    return @double.not_a_number
  }
  let mut value = 0.0
  for i in from..<text.length() {
    let c = code_at(text, i)
    let digit = if is_digit(c) {
      c - 48
    } else if c >= 'a'.to_int() && c <= 'z'.to_int() {
      c - 87
    } else if c >= 'A'.to_int() && c <= 'Z'.to_int() {
      c - 55
    } else {
      99
    }
    if digit >= radix {
      return @double.not_a_number
    }
    value = value * radix.to_double() + digit.to_double()
  }
  value
}

///|
/// Reads the whole `text` as JavaScript's `Number(text)` does.
/// Returns NaN when the text is not a number.
pub fn to_number(text : String) -> Double {
  let trimmed = trim(text)
  if trimmed == "" {
    return 0.0
  }
  if code_at(trimmed, 0) == '0'.to_int() {
    match code_at(trimmed, 1) {
      120 | 88 => return radix_value(trimmed, 2, 16)
      111 | 79 => return radix_value(trimmed, 2, 8)
      98 | 66 => return radix_value(trimmed, 2, 2)
      _ => ()
    }
  }
  let sign = code_at(trimmed, 0)
  let negative = sign == '-'.to_int()
  let start = if negative || sign == '+'.to_int() { 1 } else { 0 }
  if slice(trimmed, start) == "Infinity" {
    return with_sign(negative, @double.infinity)
  }
  let end = decimal_literal_end(trimmed, start)
  if end == start || end != trimmed.length() {
    return @double.not_a_number
  }
  with_sign(negative, decimal_literal_value(trimmed, start, end))
}
