///|
/// Mermaid style declarations split by what they apply to.
/// `shape`, `line`, and `text` are ready-made `style` attributes, or empty.
pub(all) struct ResolvedStyle {
  shape : String
  line : String
  text : String
  stroke : String?
  bold : Bool
  italic : Bool
  font_size : Double?
}

///|
let shape_props : Array[String] = [
  "fill", "fill-opacity", "stroke", "stroke-width", "stroke-dasharray", "stroke-dashoffset",
  "stroke-linecap", "stroke-linejoin", "stroke-opacity", "opacity", "rx", "ry",
]

///|
let text_props : Array[String] = [
  "color", "font-size", "font-family", "font-weight", "font-style", "text-decoration",
  "letter-spacing", "word-spacing", "opacity",
]

///|
/// Properties in the order they were first set, as a JavaScript `Map` keeps them.
priv struct Properties {
  names : Array[String]
  values : Array[String]
}

///|
fn Properties::new() -> Properties {
  { names: [], values: [], }
}

///|
fn Properties::set(self : Properties, name : String, value : String) -> Unit {
  match self.names.search(name) {
    Some(at) => self.values[at] = value
    None => {
      self.names.push(name)
      self.values.push(value)
    }
  }
}

///|
fn Properties::get(self : Properties, name : String) -> String? {
  self.names.search(name).map(at => self.values[at])
}

///|
/// Lowercases ASCII letters; the Kelvin sign is the one other character that becomes ASCII.
fn lower_ascii(text : String, kelvin~ : Bool = false) -> String {
  let out = StringBuilder()
  for i in 0..<text.length() {
    let c = @util.code_at(text, i)
    if c >= 'A'.to_int() && c <= 'Z'.to_int() {
      out.write_char((c + 32).unsafe_to_char())
    } else if kelvin && c == 0x212a {
      out.write_char('k')
    } else {
      @util.write_range(out, text, i, i + 1)
    }
  }
  out.to_string()
}

///|
/// Does what `value.replace(/!important/gi, '')` does.
fn remove_important(value : String) -> String {
  let lower = lower_ascii(value)
  let out = StringBuilder()
  let mut i = 0
  while i < value.length() {
    if @util.starts_with_at(lower, "!important", i) {
      i += "!important".length()
    } else {
      @util.write_range(out, value, i, i + 1)
      i += 1
    }
  }
  out.to_string()
}

///|
/// Whether a `(` follows `word` at `at`, after any whitespace.
fn call_at(text : String, word : String, at : Int32) -> Bool {
  if !@util.starts_with_at(text, word, at) {
    return false
  }
  let mut i = at + word.length()
  while @util.is_space(@util.code_at(text, i)) {
    i += 1
  }
  @util.code_at(text, i) == '('.to_int()
}

///|
/// Whether `text` holds a character XML does not allow, or DEL.
/// Escaping drops them, which could join what is left of a checked value into something unsafe.
fn has_invalid_xml(text : String) -> Bool {
  let n = text.length()
  let mut i = 0
  while i < n {
    let c = text.unsafe_get(i).to_int()
    if c >= 0xd800 && c <= 0xdbff && i + 1 < n {
      let next = text.unsafe_get(i + 1).to_int()
      if next >= 0xdc00 && next <= 0xdfff {
        i += 2
        continue
      }
    }
    if c <= 8 ||
      c == 0xb ||
      c == 0xc ||
      (c >= 0xe && c <= 0x1f) ||
      c == 0x7f ||
      (c >= 0xd800 && c <= 0xdfff) ||
      c >= 0xfffe {
      return true
    }
    i += 1
  }
  false
}

///|
/// Does what `/url\s*\(|expression\s*\(|javascript:|[<>{};\\]|@import|image-set|\/\*/i` does.
fn is_unsafe(value : String) -> Bool {
  let lower = lower_ascii(value)
  for i in 0..<lower.length() {
    let c = @util.code_at(lower, i)
    if c == '<'.to_int() ||
      c == '>'.to_int() ||
      c == '{'.to_int() ||
      c == '}'.to_int() ||
      c == ';'.to_int() ||
      c == '\\'.to_int() ||
      call_at(lower, "url", i) ||
      call_at(lower, "expression", i) ||
      @util.starts_with_at(lower, "javascript:", i) ||
      @util.starts_with_at(lower, "@import", i) ||
      @util.starts_with_at(lower, "image-set", i) ||
      @util.starts_with_at(lower, "/*", i) {
      return true
    }
  }
  false
}

///|
/// Does what `/^[\d.]+(px)?$/.test(size)` does.
fn is_pixel_size(size : String) -> Bool {
  let mut i = 0
  while @util.is_digit(@util.code_at(size, i)) ||
        @util.code_at(size, i) == '.'.to_int() {
    i += 1
  }
  i > 0 &&
  (
    i == size.length() ||
    (i + 2 == size.length() && @util.slice(size, i) == "px")
  )
}

///|
fn declarations_css(
  properties : Properties,
  skip~ : (String) -> Bool = _ => false,
) -> String {
  let css = StringBuilder()
  for i, name in properties.names {
    if !skip(name) {
      css.write_string("\{name}:\{properties.values[i]};")
    }
  }
  css.to_string()
}

///|
fn attribute(css : String) -> String {
  if css == "" {
    ""
  } else {
    " style=\"\{esc(css)}\""
  }
}

///|
/// Splits Mermaid style declarations into what applies to a shape and what applies to its text.
/// Declarations that could escape the attribute or load something are dropped.
pub fn resolve_style(declarations : Array[String]) -> ResolvedStyle {
  let shape = Properties::new()
  let text = Properties::new()
  for declaration in declarations {
    let at = @util.index_of(declaration, ":")
    if at <= 0 {
      continue
    }
    let name = lower_ascii(
      @util.trim(@util.slice(declaration, 0, end=at)),
      kelvin=true,
    )
    let value = @util.trim(remove_important(@util.slice(declaration, at + 1)))
    if value == "" || is_unsafe(value) || has_invalid_xml(value) {
      continue
    }
    if shape_props.contains(name) {
      shape.set(name, value)
    }
    if text_props.contains(name) {
      text.set(if name == "color" { "fill" } else { name }, value)
    }
  }
  let weight = text.get("font-weight")
  let size = text.get("font-size")
  let font_size = match size {
    Some(size) if size != "" && is_pixel_size(size) => {
      let px = @util.parse_float(size)
      if px > 0 && px <= 200 {
        Some(px)
      } else {
        None
      }
    }
    _ => None
  }
  {
    shape: attribute(declarations_css(shape)),
    line: attribute(
      declarations_css(shape, skip=name => {
        name == "fill" || name == "fill-opacity"
      }),
    ),
    text: attribute(declarations_css(text)),
    stroke: shape.get("stroke"),
    bold: match weight {
      Some(weight) =>
        weight == "bold" || weight == "bolder" || @util.to_number(weight) >= 600
      None => false
    },
    italic: text.get("font-style") is Some("italic"),
    font_size,
  }
}
