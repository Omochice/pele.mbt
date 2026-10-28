///|
/// The named colors that `#fff` contrasts with more than `#1f1f1f` does.
let dark_names : Array[String] = [
  "black", "blue", "blueviolet", "brown", "crimson", "darkblue", "darkcyan", "darkgreen",
  "darkmagenta", "darkolivegreen", "darkorchid", "darkred", "darkslateblue", "darkslategray",
  "darkviolet", "dimgray", "firebrick", "forestgreen", "green", "indigo", "maroon",
  "mediumblue", "mediumslateblue", "mediumvioletred", "midnightblue", "navy", "olive",
  "purple", "rebeccapurple", "royalblue", "saddlebrown", "seagreen", "sienna", "slateblue",
  "steelblue", "teal",
]

///|
/// The other named colors.
let light_names : Array[String] = [
  "aliceblue", "antiquewhite", "aqua", "aquamarine", "azure", "beige", "bisque",
  "blanchedalmond", "burlywood", "cadetblue", "chartreuse", "chocolate", "coral",
  "cornflowerblue", "cornsilk", "cyan", "darkgoldenrod", "darkgray", "darkkhaki",
  "darkorange", "darksalmon", "darkseagreen", "darkturquoise", "deeppink", "deepskyblue",
  "dodgerblue", "floralwhite", "fuchsia", "gainsboro", "ghostwhite", "gold", "goldenrod",
  "gray", "greenyellow", "honeydew", "hotpink", "indianred", "ivory", "khaki", "lavender",
  "lavenderblush", "lawngreen", "lemonchiffon", "lightblue", "lightcoral", "lightcyan",
  "lightgoldenrodyellow", "lightgray", "lightgreen", "lightpink", "lightsalmon",
  "lightseagreen", "lightskyblue", "lightslategray", "lightsteelblue", "lightyellow",
  "lime", "limegreen", "linen", "magenta", "mediumaquamarine", "mediumorchid", "mediumpurple",
  "mediumseagreen", "mediumspringgreen", "mediumturquoise", "mintcream", "mistyrose",
  "moccasin", "navajowhite", "oldlace", "olivedrab", "orange", "orangered", "orchid",
  "palegoldenrod", "palegreen", "paleturquoise", "palevioletred", "papayawhip", "peachpuff",
  "peru", "pink", "plum", "powderblue", "red", "rosybrown", "salmon", "sandybrown",
  "seashell", "silver", "skyblue", "slategray", "snow", "springgreen", "tan", "thistle",
  "tomato", "turquoise", "violet", "wheat", "white", "whitesmoke", "yellow", "yellowgreen",
]

///|
/// The color of text on a light fill the source sets.
pub const ON_LIGHT : String = "var(--pele-fg-on-light,#1f1f1f)"

///|
/// The color of text on a dark fill the source sets.
pub const ON_DARK : String = "var(--pele-fg-on-dark,#fff)"

///|
fn linear(c : Double) -> Double {
  if c <= 0.04045 {
    c / 12.92
  } else {
    @math.pow((c + 0.055) / 1.055, 2.4)
  }
}

///|
fn luminance(r : Double, g : Double, b : Double) -> Double {
  0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
}

///|
fn clamp_unit(n : Double) -> Double {
  @util.js_min(@util.js_max(n, 0), 1)
}

///|
/// The luminance at which `#1f1f1f` and `#fff` contrast equally.
let even : Double = (1.05 *
  (luminance(31.0 / 255, 31.0 / 255, 31.0 / 255) + 0.05)).sqrt() -
  0.05

///|
fn digits_end(text : String, from : Int32) -> Int32 {
  let mut i = from
  while i < text.length() && @util.is_digit(@util.code_at(text, i)) {
    i += 1
  }
  i
}

///|
/// The unit of `raw` in lowercase, empty when it has none, when `raw` is a number as
/// `/^[+-]?(?:\d+(?:\.\d+)?|\.\d+)(?:e[+-]?\d+)?(%|deg|grad|rad|turn)?$/i` reads one.
fn number_unit(raw : String) -> String? {
  let n = raw.length()
  let mut i = 0
  if n > 0 && (@util.code_at(raw, 0) == '+' || @util.code_at(raw, 0) == '-') {
    i = 1
  }
  let whole = digits_end(raw, i)
  if whole > i {
    i = whole
    if i < n && @util.code_at(raw, i) == '.' {
      let fraction = digits_end(raw, i + 1)
      if fraction > i + 1 {
        i = fraction
      }
    }
  } else if i < n && @util.code_at(raw, i) == '.' {
    let fraction = digits_end(raw, i + 1)
    guard fraction > i + 1 else { return None }
    i = fraction
  } else {
    return None
  }
  if i < n && (@util.code_at(raw, i) == 'e' || @util.code_at(raw, i) == 'E') {
    let mut j = i + 1
    if j < n && (@util.code_at(raw, j) == '+' || @util.code_at(raw, j) == '-') {
      j += 1
    }
    let exponent = digits_end(raw, j)
    if exponent > j {
      i = exponent
    }
  }
  let unit = lower_ascii(@util.slice(raw, i))
  match unit {
    "" | "%" | "deg" | "grad" | "rad" | "turn" => Some(unit)
    _ => None
  }
}

///|
/// A plain number over `full`, or a percentage, between 0 and 1.
fn amount(raw : String, full : Double) -> Double {
  match number_unit(raw) {
    Some("") => clamp_unit(@util.parse_float(raw) / full)
    Some("%") => clamp_unit(@util.parse_float(raw) / 100)
    _ => @double.not_a_number
  }
}

///|
/// An angle in degrees.
fn hue(raw : String) -> Double {
  let n = @util.parse_float(raw)
  match number_unit(raw) {
    Some("" | "deg") => n
    Some("turn") => n * 360
    Some("rad") => n * 180 / @math.PI
    Some("grad") => n * 0.9
    _ => @double.not_a_number
  }
}

///|
fn split_at(text : String, separator : Int32) -> Array[String] {
  let parts = []
  let mut from = 0
  for i in 0..<text.length() {
    if @util.code_at(text, i) == separator {
      parts.push(@util.slice(text, from, end=i))
      from = i + 1
    }
  }
  parts.push(@util.slice(text, from))
  parts
}

///|
/// The text split at runs of whitespace, as `split(/\s+/)` splits text that is already trimmed.
fn split_spaces(text : String) -> Array[String] {
  let parts = []
  let mut from = 0
  let mut i = 0
  while i < text.length() {
    if @util.is_space(@util.code_at(text, i)) {
      parts.push(@util.slice(text, from, end=i))
      while i < text.length() && @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
      from = i
    } else {
      i += 1
    }
  }
  parts.push(@util.slice(text, from))
  parts
}

///|
/// The channels of an `rgb()` or `hsl()` body, then its alpha if it has one.
/// The comma syntax takes no `none`, rgb() channels all or none in %, and hsl() saturation and lightness in %.
fn color_args(body : String, hsl : Bool) -> Array[String]? {
  let legacy = body.contains(",")
  let mut main = body
  let mut alpha = None
  if !legacy {
    let parts = split_at(body, '/')
    guard parts.length() <= 2 else { return None }
    main = parts[0]
    alpha = parts.get(1)
  }
  let trimmed = @util.trim(main)
  let list = if legacy {
    split_at(trimmed, ',').map(@util.trim)
  } else {
    split_spaces(trimmed)
  }
  let fits = if legacy {
    list.length() >= 3 && list.length() <= 4
  } else {
    list.length() == 3
  }
  guard fits else { return None }
  if alpha is Some(alpha) {
    list.push(@util.trim(alpha))
  }
  if !legacy {
    return Some(list.map(c => if c == "none" { "0" } else { c }))
  }
  let mut percent = 0
  for i in (if hsl { 1 } else { 0 })..<3 {
    if list[i].has_suffix("%") {
      percent += 1
    }
  }
  if percent == (if hsl { 2 } else { 3 }) || (!hsl && percent == 0) {
    Some(list)
  } else {
    None
  }
}

///|
fn hex_digit(c : Int32) -> Int32 {
  if c <= 57 {
    c - 48
  } else {
    c - 87
  }
}

///|
/// The digits of a hex color in lowercase, eight of them for one with an alpha and six otherwise,
/// or `None` when `value` is not one.
fn hex_digits(value : String) -> String? {
  let n = value.length() - 1
  guard n == 3 || n == 4 || n == 6 || n == 8 else { return None }
  guard @util.code_at(value, 0) == '#' else { return None }
  for i in 1..<=n {
    guard @util.is_hex(@util.code_at(value, i)) else { return None }
  }
  if n >= 6 {
    return Some(@util.slice(value, 1))
  }
  let doubled = StringBuilder()
  for i in 1..<=n {
    @util.write_range(doubled, value, i, i + 1)
    @util.write_range(doubled, value, i, i + 1)
  }
  Some(doubled.to_string())
}

///|
/// The name and body of `value` when it is `rgb()`, `rgba()`, `hsl()` or `hsla()` around a body without parentheses.
fn color_function(value : String) -> (String, String)? {
  guard value.find("(") is Some(open) else { return None }
  let name = @util.slice(value, 0, end=open)
  guard name is ("rgb" | "rgba" | "hsl" | "hsla") else { return None }
  guard value.has_suffix(")") && value.length() > open + 1 else { return None }
  let body = @util.slice(value, open + 1, end=value.length() - 1)
  guard !body.contains("(") && !body.contains(")") else { return None }
  Some((name, body))
}

///|
/// The luminance and alpha of a color; named colors use 0 or 1 to preserve the contrast choice.
fn tone(raw : String) -> (Double, Double)? {
  let value = lower_ascii(@util.trim(raw), kelvin=true)
  let name = value.replace(old="grey", new="gray")
  if dark_names.contains(name) {
    return Some((0, 1))
  }
  if light_names.contains(name) {
    return Some((1, 1))
  }
  if hex_digits(value) is Some(digits) {
    let channel = (i : Int32) => {
      let high = hex_digit(@util.code_at(digits, 2 * i))
      let low = hex_digit(@util.code_at(digits, 2 * i + 1))
      (high * 16 + low).to_double() / 255
    }
    let alpha = if digits.length() == 8 { channel(3) } else { 1 }
    return Some((luminance(channel(0), channel(1), channel(2)), alpha))
  }
  guard color_function(value) is Some((fn_name, body)) else { return None }
  let hsl = fn_name.has_prefix("hsl")
  guard color_args(body, hsl) is Some(list) else { return None }
  let alpha = if list.length() == 4 { amount(list[3], 1) } else { 1 }
  let (r, g, b) = if !hsl {
    (amount(list[0], 255), amount(list[1], 255), amount(list[2], 255))
  } else {
    let h = (hue(list[0]) % 360 + 360) % 360 / 30
    let s = amount(list[1], 100)
    let l = amount(list[2], 100)
    let a = s * @util.js_min(l, 1 - l)
    let channel = (k : Double) => {
      let t = (k + h) % 12
      l - a * @util.js_max(-1, @util.js_min(@util.js_min(t - 3, 9 - t), 1))
    }
    (channel(0), channel(8), channel(4))
  }
  let lum = luminance(r, g, b)
  if (lum + alpha).is_nan() {
    None
  } else {
    Some((lum, alpha))
  }
}

///|
/// The label color over `fill` drawn at `opacity`, as the text of a declaration of each.
/// Fills below half opacity depend on an unknown background.
fn ink_over(fill : String?, opacity : String?) -> String? {
  guard fill is Some(fill) && tone(fill) is Some((lum, alpha)) else {
    return None
  }
  // An opacity that isn't a plain number, such as calc() or var(), may still be low.
  let factor = match opacity {
    Some(opacity) => amount(@util.trim(opacity), 1)
    None => 1
  }
  if !(alpha * factor >= 0.5) {
    return None
  }
  Some(if lum > even { ON_LIGHT } else { ON_DARK })
}

///|
/// The value of the first declaration of `name` in a `style` attribute, as `/[";]name:([^;"]*)/` finds it.
fn attribute_value(attrs : String, name : String) -> String? {
  let key = name + ":"
  let mut at = @util.index_of(attrs, key)
  while at >= 0 {
    if at > 0 &&
      (
        @util.code_at(attrs, at - 1) == '"' ||
        @util.code_at(attrs, at - 1) == ';'
      ) {
      let start = at + key.length()
      let mut end = start
      while end < attrs.length() &&
            @util.code_at(attrs, end) != ';' &&
            @util.code_at(attrs, end) != '"' {
        end += 1
      }
      return Some(@util.slice(attrs, start, end~))
    }
    at = @util.index_of(attrs, key, from=at + 1)
  }
  None
}

///|
/// The escape of a character escaping changes, without the `;` that ends it.
fn escape_head(c : Int32) -> String? {
  match c {
    '&' => Some("&amp")
    '<' => Some("&lt")
    '>' => Some("&gt")
    '"' => Some("&quot")
    _ => None
  }
}

///|
/// The value of the first declaration of `name` in the `style` attribute made of the raw `css`, as
/// `attribute_value` finds it there, without escaping all of `css`.
/// Escaping ends each `&`, `<`, `>` and `"` with a `;`, so a declaration may seem to start after one,
/// and a value ends at one with what its escape writes before the `;`.
fn raw_value(css : String, name : String) -> String? {
  let key = name + ":"
  let mut at = @util.index_of(css, key)
  while at >= 0 {
    if at == 0 ||
      @util.code_at(css, at - 1) == ';' ||
      escape_head(@util.code_at(css, at - 1)) is Some(_) {
      let start = at + key.length()
      let mut end = start
      while end < css.length() {
        let c = @util.code_at(css, end)
        if c == ';' {
          break
        }
        if escape_head(c) is Some(head) {
          return Some(@util.slice(css, start, end~) + head)
        }
        end += 1
      }
      return Some(@util.slice(css, start, end~))
    }
    at = @util.index_of(css, key, from=at + 1)
  }
  None
}

///|
/// The label color that contrasts most with the fill the `style` attribute `shape` sets, unless the
/// text's own `style` attribute `text` sets a color, or `None` when it sets no fill this can read.
/// Styles come from `resolve_style`.
pub fn ink(shape : String, text~ : String = "") -> String? {
  let fill = match attribute_value(text, "fill") {
    Some(_) => None
    None => attribute_value(shape, "fill")
  }
  ink_over(fill, attribute_value(shape, "fill-opacity"))
}

///|
/// `ink` of the `style` attributes `resolve_style` makes of the raw CSS `shape` and `text`.
/// Styles come from `resolve_raw_style`.
pub fn raw_ink(shape : String, text~ : String = "") -> String? {
  let fill = match raw_value(text, "fill") {
    Some(_) => None
    None => raw_value(shape, "fill")
  }
  ink_over(fill, raw_value(shape, "fill-opacity"))
}

///|
/// Whether `fill` drawn at `opacity`, as the text of a declaration of each, covers what is under it.
/// Unknown fill colors and opacities are treated as opaque.
fn paints_over(fill : String?, opacity : String?) -> Bool {
  guard fill is Some(fill) else { return false }
  let fill = @util.trim(fill)
  if lower_ascii(fill) is ("" | "none" | "transparent") {
    return false
  }
  let scale = match opacity {
    Some(opacity) => amount(@util.trim(opacity), 1)
    None => 1
  }
  let alpha = match tone(fill) {
    Some((_, alpha)) => alpha
    None => 1
  }
  alpha * (if scale.is_nan() { 1 } else { scale }) > 0
}

///|
/// Whether the fill the `style` attribute `shape` sets covers what is under it.
/// Styles come from `resolve_style`.
pub fn paints(shape : String) -> Bool {
  paints_over(
    attribute_value(shape, "fill"),
    attribute_value(shape, "fill-opacity"),
  )
}

///|
/// `paints` of the `style` attribute `resolve_style` makes of the raw CSS `css`.
/// Styles come from `resolve_raw_style`.
pub fn raw_paints(css : String) -> Bool {
  paints_over(raw_value(css, "fill"), raw_value(css, "fill-opacity"))
}

///|
fn fill_attribute(color : String?, fallback : String?) -> String {
  match (color, fallback) {
    (Some(color), _) | (None, Some(color)) if color != "" =>
      " fill=\"\{color}\""
    _ => ""
  }
}

///|
/// The `fill` attribute of a label on a shape drawn in `style`, in the color `ink` picks, else
/// `fallback`, else nothing.
pub fn ink_fill(style : ResolvedStyle, fallback? : String) -> String {
  fill_attribute(ink(style.shape, text=style.text), fallback)
}

///|
/// `ink_fill` of a style from `resolve_raw_style`.
pub fn raw_ink_fill(style : RawStyle, fallback? : String) -> String {
  fill_attribute(raw_ink(style.shape, text=style.text), fallback)
}
