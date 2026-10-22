///|
/// The parts of a specifier that are read.
/// Fill, alignment, width and zero padding are accepted and ignored.
priv struct Spec {
  plus : Bool
  dollar : Bool
  comma : Bool
  precision : Int32?
  tilde : Bool
  /// The code of the type letter, or -1 when there is none.
  kind : Int32
}

///|
fn is_align(c : Int32) -> Bool {
  c == '<'.to_int() ||
  c == '>'.to_int() ||
  c == '='.to_int() ||
  c == '^'.to_int()
}

///|
/// Reads what follows the optional fill and alignment of
/// `[sign]['$']['0'][digits][',']['.' digits]['~'][type]`, which must reach the end of `spec`.
/// Nothing in it can be given back to make the rest match, so reading it once is enough.
fn read_rest(spec : String, from : Int32) -> Spec? {
  let mut i = from
  let sign = @util.code_at(spec, i)
  let plus = sign == '+'.to_int()
  if plus ||
    sign == '-'.to_int() ||
    sign == '('.to_int() ||
    sign == ' '.to_int() {
    i += 1
  }
  let dollar = @util.code_at(spec, i) == '$'.to_int()
  if dollar {
    i += 1
  }
  while @util.is_digit(@util.code_at(spec, i)) {
    i += 1
  }
  let comma = @util.code_at(spec, i) == ','.to_int()
  if comma {
    i += 1
  }
  let mut precision = None
  if @util.code_at(spec, i) == '.'.to_int() &&
    @util.is_digit(@util.code_at(spec, i + 1)) {
    let start = i + 1
    i = start
    while @util.is_digit(@util.code_at(spec, i)) {
      i += 1
    }
    let digits = @util.to_number(@util.slice(spec, start, end=i))
    precision = Some(@util.js_min(digits, 20).to_int())
  }
  let tilde = @util.code_at(spec, i) == '~'.to_int()
  if tilde {
    i += 1
  }
  let letter = @util.code_at(spec, i)
  let mut kind = -1
  if letter == '%'.to_int() ||
    (letter >= 'a'.to_int() && letter <= 'z'.to_int()) ||
    (letter >= 'A'.to_int() && letter <= 'Z'.to_int()) {
    kind = letter
    i += 1
  }
  if i == spec.length() {
    Some({ plus, dollar, comma, precision, tilde, kind, })
  } else {
    None
  }
}

///|
/// Reads a specifier as `^(?:.?[<>=^])?([-+( ])?(\$)?0?\d*(,)?(?:\.(\d+))?(~)?([a-zA-Z%])?$` does.
/// The fill and alignment are tried with a fill, without one, and then left out, as a regex
/// backtracks through them.
fn read_spec(spec : String) -> Spec? {
  let first = @util.code_at(spec, 0)
  if first != -1 &&
    !@util.is_line_end(first) &&
    is_align(@util.code_at(spec, 1)) {
    if read_rest(spec, 2) is Some(found) {
      return Some(found)
    }
  }
  if is_align(first) {
    if read_rest(spec, 1) is Some(found) {
      return Some(found)
    }
  }
  read_rest(spec, 0)
}

///|
fn group(digits : String) -> String {
  let parts = []
  let mut i = digits.length()
  while i > 0 {
    parts.push(
      @util.slice(digits, @util.js_max(0, (i - 3).to_double()).to_int(), end=i),
    )
    i -= 3
  }
  parts.rev().join(",")
}

///|
/// Does what `text.replace(/\.?0+$/, '')` does.
fn strip_trailing_zeros(text : String) -> String {
  let mut end = text.length()
  while end > 0 && @util.code_at(text, end - 1) == '0'.to_int() {
    end -= 1
  }
  if end == text.length() {
    return text
  }
  if end > 0 && @util.code_at(text, end - 1) == '.'.to_int() {
    end -= 1
  }
  @util.slice(text, 0, end~)
}

///|
/// Does what `String(Number(x.toPrecision(count)))` does, for a non-negative `x`.
fn to_shortest(x : Double, count : Int32) -> String {
  if x.is_nan() || x.is_inf() {
    return x.to_string()
  }
  let (digits, exponent) = significant(x, count)
  let value = @string.parse_double("\{digits}e\{exponent - count + 1}") catch {
    _ => x
  }
  value.to_string()
}

///|
/// Makes the function that writes a treemap's values for a d3-format style specifier.
/// Only `$`, `,`, a precision, and the types `f`, `%`, `d`, `e`, or none are understood.
/// A specifier that is not understood formats like `,`.
pub fn formatter(spec : String) -> (Double) -> String {
  let source = if spec == "$0,0" { "$," } else { spec }
  let spec = match read_spec(source) {
    Some(read) => read
    None => read_spec(",").unwrap()
  }
  value => {
    let abs = value.abs()
    let mut suffix = ""
    let mut body = match spec.kind {
      102 => to_fixed(abs, spec.precision.unwrap_or(6))
      37 => {
        suffix = "%"
        to_fixed(abs * 100, spec.precision.unwrap_or(6))
      }
      // util's to_fixed0 writes the shortest digits for values past 2^53, where toFixed writes the exact ones.
      100 => to_fixed(abs.round(), 0)
      101 => to_exponential(abs, spec.precision.unwrap_or(6))
      _ =>
        to_shortest(
          abs,
          @util.js_max(1, spec.precision.unwrap_or(12).to_double()).to_int(),
        )
    }
    if spec.tilde && body.contains(".") && !body.contains("e") {
      body = strip_trailing_zeros(body)
    }
    if spec.comma && !body.contains("e") {
      let dot = @util.index_of(body, ".")
      body = if dot == -1 {
        group(body)
      } else {
        group(@util.slice(body, 0, end=dot)) + @util.slice(body, dot)
      }
    }
    (if value < 0 { "-" } else if spec.plus { "+" } else { "" }) +
    (if spec.dollar { "$" } else { "" }) +
    body +
    suffix
  }
}
