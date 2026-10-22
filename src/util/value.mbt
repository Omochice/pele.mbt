///|
/// The value as JavaScript's `String()` writes it.
pub fn js_string(value : Json) -> String {
  match value {
    Null => "null"
    True => "true"
    False => "false"
    Number(number, ..) => number.to_string()
    String(text) => text
    Array(items) => {
      let out = StringBuilder()
      for i, item in items {
        if i > 0 {
          out.write_string(",")
        }
        if !(item is Null) {
          out.write_string(js_string(item))
        }
      }
      out.to_string()
    }
    Object(_) => "[object Object]"
  }
}

///|
/// Whether JavaScript treats the value as true in a condition.
pub fn js_truthy(value : Json) -> Bool {
  match value {
    Null | False => false
    Number(number, ..) => !(number == 0 || number.is_nan())
    String(text) => text != ""
    _ => true
  }
}

///|
/// The value as JavaScript's `Number()` converts it.
pub fn js_number(value : Json) -> Double {
  match value {
    Null | False => 0
    True => 1
    Number(number, ..) => number
    String(text) => string_to_number(text)
    Array(_) => string_to_number(js_string(value))
    Object(_) => @double.not_a_number
  }
}

///|
/// The digits of an `0x`, `0o` or `0b` literal, or NaN when one is not a digit of the radix.
fn prefixed_value(digits : String, radix : Int32) -> Double {
  if digits == "" {
    return @double.not_a_number
  }
  let mut value = 0.0
  for i in 0..<digits.length() {
    let c = code_at(digits, i)
    let d = if is_hex(c) { digit_value(c) } else { radix }
    if d >= radix {
      return @double.not_a_number
    }
    value = value * radix.to_double() + d.to_double()
  }
  value
}

///|
/// The end of a run of ASCII digits at `from`.
fn digits_end(text : String, from : Int32) -> Int32 {
  let mut i = from
  while is_digit(code_at(text, i)) {
    i += 1
  }
  i
}

///|
/// `Number(text)` for a string: StringToNumber of the ECMAScript specification.
fn string_to_number(text : String) -> Double {
  let s = trim(text)
  if s == "" {
    return 0
  }
  match slice(s, 0, end=2) {
    "0x" | "0X" => return prefixed_value(slice(s, 2), 16)
    "0o" | "0O" => return prefixed_value(slice(s, 2), 8)
    "0b" | "0B" => return prefixed_value(slice(s, 2), 2)
    _ => ()
  }
  let sign = code_at(s, 0)
  let negative = sign == '-'
  let body = if sign == '-' || sign == '+' { slice(s, 1) } else { s }
  if body == "Infinity" {
    return if negative { -@double.infinity } else { @double.infinity }
  }
  let int_end = digits_end(body, 0)
  let mut i = int_end
  let mut frac_end = int_end
  if code_at(body, i) == '.' {
    frac_end = digits_end(body, i + 1)
    i = frac_end
  }
  let has_digits = int_end > 0 || frac_end > int_end + 1
  if !has_digits {
    return @double.not_a_number
  }
  let mut exponent = ""
  let e = code_at(body, i)
  if e == 'e' || e == 'E' {
    let mut j = i + 1
    let exp_sign = code_at(body, j)
    if exp_sign == '+' || exp_sign == '-' {
      j += 1
    }
    let exp_end = digits_end(body, j)
    if exp_end == j {
      return @double.not_a_number
    }
    exponent = "e" + slice(body, i + 1, end=exp_end)
    i = exp_end
  }
  if i < body.length() {
    return @double.not_a_number
  }
  let whole = if int_end == 0 { "0" } else { slice(body, 0, end=int_end) }
  let fraction = if frac_end > int_end + 1 {
    "." + slice(body, int_end + 1, end=frac_end)
  } else {
    ""
  }
  // parse_double rejects values outside the double range, which Number() rounds to Infinity or 0.
  let value = @string.parse_double(whole + fraction + exponent) catch {
    _ => if exponent.has_prefix("e-") { 0 } else { @double.infinity }
  }
  if negative {
    -value
  } else {
    value
  }
}
