///|
/// A color in sRGB, with red, green and blue from 0 to 255 and alpha from 0 to 1.
/// A component is `None` when it is missing, as CSS's `none` makes it.
/// The channels stay on the byte scale that hex codes and `rgb()` numbers are written in, so that a mix landing halfway between two bytes is not pushed off the tie by a division by 255.
priv struct Srgb {
  channels : Array[Double?]
  alpha : Double?
}

///|
fn clamp(value : Double, low : Double, high : Double) -> Double {
  if value < low {
    low
  } else if value > high {
    high
  } else {
    value
  }
}

///|
/// `text` with its ASCII capitals lowered, as CSS matches keywords, function names and hex digits.
fn ascii_lower(text : String) -> String {
  let out = StringBuilder()
  let mut copied = 0
  for i in 0..<text.length() {
    let c = @util.code_at(text, i)
    if c >= 'A' && c <= 'Z' {
      @util.write_range(out, text, copied, i)
      out.write_char((c + 32).unsafe_to_char())
      copied = i + 1
    }
  }
  @util.write_range(out, text, copied, text.length())
  out.to_string()
}

///|
/// The index of the parenthesis that closes the one at `open`, or `None` when it is not closed.
fn closing_paren(text : String, open : Int32) -> Int32? {
  let mut level = 0
  for i in open..<text.length() {
    match @util.code_at(text, i) {
      '(' => level += 1
      ')' => {
        level -= 1
        if level == 0 {
          return Some(i)
        }
      }
      _ => ()
    }
  }
  None
}

///|
/// The parts of `text` between the separators found outside parentheses, or `None` when its parentheses do not balance.
fn split_outside_parens(
  text : String,
  is_separator : (Int32) -> Bool,
) -> Array[String]? {
  let parts = []
  let mut level = 0
  let mut from = 0
  for i in 0..<text.length() {
    let c = @util.code_at(text, i)
    if c == '(' {
      level += 1
    } else if c == ')' {
      level -= 1
      if level < 0 {
        return None
      }
    } else if level == 0 && is_separator(c) {
      parts.push(@util.slice(text, from, end=i))
      from = i + 1
    }
  }
  if level != 0 {
    return None
  }
  parts.push(@util.slice(text, from))
  Some(parts)
}

///|
/// The component values of `text`, which whitespace outside parentheses separates.
/// A function's closing parenthesis also ends one, as CSS reads `rgb(0 0 0)50%` as two.
fn components(text : String) -> Array[String]? {
  let found = []
  let mut level = 0
  let mut from = -1
  for i in 0..<text.length() {
    let c = @util.code_at(text, i)
    if level == 0 && is_css_space(c) {
      if from >= 0 {
        found.push(@util.slice(text, from, end=i))
        from = -1
      }
      continue
    }
    if from < 0 {
      from = i
    }
    if c == '(' {
      level += 1
    } else if c == ')' {
      level -= 1
      if level < 0 {
        return None
      }
      if level == 0 {
        found.push(@util.slice(text, from, end=i + 1))
        from = -1
      }
    }
  }
  if level != 0 {
    return None
  }
  if from >= 0 {
    found.push(@util.slice(text, from))
  }
  Some(found)
}

///|
fn is_sign(c : Int32) -> Bool {
  c == '+' || c == '-'
}

///|
/// The value of `text` as a CSS `<number>`, or `None` when it is not one.
/// JavaScript's number syntax is looser, taking `5.` for one, so the text is checked before it is read.
fn css_number(text : String) -> Double? {
  let n = text.length()
  let mut i = 0
  if i < n && is_sign(@util.code_at(text, i)) {
    i += 1
  }
  let integer = i
  while i < n && @util.is_digit(@util.code_at(text, i)) {
    i += 1
  }
  let mut digits = i - integer
  if i < n && @util.code_at(text, i) == '.' {
    i += 1
    let fraction = i
    while i < n && @util.is_digit(@util.code_at(text, i)) {
      i += 1
    }
    if i == fraction {
      return None
    }
    digits += i - fraction
  }
  if digits == 0 {
    return None
  }
  if i < n && (@util.code_at(text, i) == 'e' || @util.code_at(text, i) == 'E') {
    let mut j = i + 1
    if j < n && is_sign(@util.code_at(text, j)) {
      j += 1
    }
    let exponent = j
    while j < n && @util.is_digit(@util.code_at(text, j)) {
      j += 1
    }
    if j > exponent {
      i = j
    }
  }
  guard i == n else { return None }
  Some(@util.parse_float(text))
}

///|
/// The number of `text` as a CSS `<percentage>`, or `None` when it is not one.
fn css_percentage(text : String) -> Double? {
  guard text.has_suffix("%") else { return None }
  css_number(@util.slice(text, 0, end=text.length() - 1))
}

///|
/// An alpha written as a number or a percentage, clamped to 0 to 1.
fn alpha_value(text : String) -> Double? {
  match css_number(text) {
    Some(value) => Some(clamp(value, 0, 1))
    None => css_percentage(text).map(value => clamp(value / 100, 0, 1))
  }
}

///|
/// A channel written as a number of 0 to 255 or as a percentage of it, clamped to that range.
fn channel_value(text : String) -> Double? {
  match css_number(text) {
    Some(value) => Some(clamp(value, 0, 255))
    None => css_percentage(text).map(value => clamp(value * 255 / 100, 0, 255))
  }
}

///|
fn hex_digit(c : Int32) -> Int32 {
  if c <= '9' {
    c - '0'
  } else {
    c - 'a' + 10
  }
}

///|
/// The color of the lowercase hex code `digits`, written without its `#`.
fn hex_color(digits : String) -> Srgb? {
  let n = digits.length()
  guard n == 3 || n == 4 || n == 6 || n == 8 else { return None }
  let values = []
  for i in 0..<n {
    let c = @util.code_at(digits, i)
    guard @util.is_hex(c) else { return None }
    values.push(hex_digit(c))
  }
  let bytes = if n <= 4 {
    values.map(v => v * 17)
  } else {
    Array::makei(n / 2, i => values[2 * i] * 16 + values[2 * i + 1])
  }
  Some({
    channels: [
      Some(bytes[0].to_double()),
      Some(bytes[1].to_double()),
      Some(bytes[2].to_double()),
    ],
    alpha: Some(
      if bytes.length() == 4 {
        bytes[3].to_double() / 255
      } else {
        1
      },
    ),
  })
}

///|
/// The color of the arguments of an `rgb()` or `rgba()` in the comma separated form, where every channel is a number or every channel is a percentage.
fn legacy_rgb(arguments : Array[String]) -> Srgb? {
  guard arguments.length() == 3 || arguments.length() == 4 else { return None }
  let channels = arguments[:3].map(argument => css_trim(argument))
  let numbers = channels.all(channel => css_number(channel) is Some(_))
  let percentages = channels.all(channel => css_percentage(channel) is Some(_))
  guard numbers || percentages else { return None }
  let alpha = if arguments.length() == 4 {
    guard alpha_value(css_trim(arguments[3])) is Some(alpha) else {
      return None
    }
    alpha
  } else {
    1
  }
  Some({ channels: channels.map(channel_value), alpha: Some(alpha), })
}

///|
/// A component of the space separated form, which may be `none`.
fn modern_component(text : String, read : (String) -> Double?) -> Double?? {
  if text == "none" {
    Some(None)
  } else {
    read(text).map(value => Some(value))
  }
}

///|
/// The color of the arguments of an `rgb()` or `rgba()` in the space separated form, with an optional alpha after a `/`.
fn modern_rgb(body : String) -> Srgb? {
  guard split_outside_parens(body, c => c == '/') is Some(halves) &&
    halves.length() <= 2 &&
    components(halves[0]) is Some(written) &&
    written.length() == 3 else {
    return None
  }
  let channels = []
  for channel in written {
    guard modern_component(channel, channel_value) is Some(value) else {
      return None
    }
    channels.push(value)
  }
  let alpha = if halves.length() == 2 {
    guard components(halves[1]) is Some([written]) &&
      modern_component(written, alpha_value) is Some(alpha) else {
      return None
    }
    alpha
  } else {
    Some(1.0)
  }
  Some({ channels, alpha, })
}

///|
/// The color that the lowercase CSS `<color>` `text` computes to, or `None` when it is not one this module evaluates.
fn parse_color(text : String) -> Srgb? {
  let text = css_trim(text)
  if text.has_prefix("#") {
    return hex_color(@util.slice(text, 1))
  }
  if named_colors.get(text) is Some(hex) {
    return hex_color(@util.slice(hex, 1))
  }
  guard text.find("(") is Some(open) &&
    closing_paren(text, open) is Some(close) &&
    close == text.length() - 1 else {
    return None
  }
  let body = @util.slice(text, open + 1, end=close)
  match @util.slice(text, 0, end=open) {
    "rgb" | "rgba" =>
      match split_outside_parens(body, c => c == ',') {
        Some([_]) => modern_rgb(body)
        Some(arguments) => legacy_rgb(arguments)
        None => None
      }
    "color-mix" => color_mix(body)
    _ => None
  }
}

///|
/// The byte that `value`, from 0 to 255, is drawn with.
/// A decimal such as `0.2` has no exact binary value, so the value is first snapped to a millionth, which keeps the ties CSS computes as ties rather than letting them fall either way.
/// Ties round up, as Chrome rounds the channels of `rgb()`.
fn to_byte(value : Double) -> Int32 {
  let snapped = (value * 1000000 + 0.5).floor() / 1000000
  clamp((snapped + 0.5).floor(), 0, 255).to_int()
}

///|
fn write_byte(out : StringBuilder, byte : Int32) -> Unit {
  let digits = "0123456789abcdef"
  out.write_char(digits[byte / 16].unsafe_to_char())
  out.write_char(digits[byte % 16].unsafe_to_char())
}

///|
/// The color as a hex code, with its alpha only when it is not opaque.
/// A missing component is drawn as zero.
fn Srgb::to_hex(self : Srgb) -> String {
  let out = StringBuilder()
  out.write_char('#')
  for channel in self.channels {
    write_byte(out, to_byte(channel.unwrap_or(0)))
  }
  let alpha = to_byte(self.alpha.unwrap_or(0) * 255)
  if alpha < 255 {
    write_byte(out, alpha)
  }
  out.to_string()
}
