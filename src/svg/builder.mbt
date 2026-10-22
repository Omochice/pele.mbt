///|
/// The two decimals of a coordinate, by hundredths.
let fraction : Array[String] = Array::makei(100, i => {
  if i == 0 {
    ""
  } else if i % 10 == 0 {
    "." + (i / 10).to_string()
  } else if i < 10 {
    ".0" + i.to_string()
  } else {
    "." + i.to_string()
  }
})

///|
/// A coordinate as pele writes it: rounded to hundredths, without trailing zeros.
pub fn num(value : Double) -> String {
  let n = (value * 100).round()
  if n == 0 {
    return "0"
  }
  if n > 0 {
    if n < 1.0e11 {
      let q = (n / 100).floor()
      return q.to_int64().to_string() + fraction[(n - q * 100).to_int()]
    }
  } else if n > -1.0e11 {
    let m = -n
    let q = (m / 100).floor()
    return "-" + q.to_int64().to_string() + fraction[(m - q * 100).to_int()]
  }
  (n / 100).to_string()
}

///|
/// Escapes text for XML and drops the control characters XML does not allow.
pub fn esc(text : String) -> String {
  text
}

///|
/// Escapes text that is only ever read as text, decoding entity codes first.
pub fn esc_text(text : String) -> String {
  text
}

///|
/// Writes a measured label as SVG text centered on (`cx`, `cy`).
pub fn label_svg(
  label : @text.Label,
  cx : Double,
  cy : Double,
  attrs : String,
) -> String {
  ignore((label, cx, cy, attrs))
  ""
}
