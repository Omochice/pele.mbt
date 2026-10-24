///|
/// Mermaid style declarations split as `resolve_style` splits them, with `shape`, `line` and
/// `text` kept as the CSS of a `style` attribute before it is escaped, or empty.
/// The CSS is escaped only as it is written, a piece at a time, because a value of tens of
/// millions of `&` escapes to more than a doubling StringBuilder holds.
pub(all) struct RawStyle {
  shape : String
  line : String
  text : String
  stroke : String?
  bold : Bool
  italic : Bool
  font_size : Double?
}

///|
/// The declarations split as `resolve_style` splits them, before any of them is escaped.
pub fn resolve_raw_style(declarations : Array[String]) -> RawStyle {
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
    if value == "" || is_unsafe(value) {
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
    shape: declarations_css(shape),
    line: declarations_css(shape, skip=name => {
      name == "fill" || name == "fill-opacity"
    }),
    text: declarations_css(text),
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

///|
/// Writes the `style` attribute `resolve_style` makes of `css`, escaping it a piece at a time.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_style(out : Markup, css : String) -> Unit raise @errors.PeleError {
  if css == "" {
    return
  }
  out.write(" style=\"")
  out.write_esc(css)
  out.write("\"")
}

///|
/// Writes the `style` attribute of `css` with the corner radius first, as `rounded` adds it to
/// attributes whose only `style` attribute is the one `resolve_style` makes of `css`.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_rounded_style(
  out : Markup,
  css : String,
) -> Unit raise @errors.PeleError {
  if css == "" {
    out.write(ROUNDED)
    return
  }
  out.write(" style=\"rx:var(--_r);")
  out.write_esc(css)
  out.write("\"")
}

///|
/// Where the escaped CSS of a shape's fill and border goes in markup put together as a string and
/// written with `write_styled`.
/// Each stand-in begins with a NUL, which escaping drops and XML forbids, so no escaped text and
/// no markup the port makes holds one.
pub const SHAPE_CSS : String = "\u{0}s"

///|
/// Where the escaped CSS of a shape's inner lines goes, as `SHAPE_CSS` stands for its shape's.
pub const LINE_CSS : String = "\u{0}l"

///|
/// Where the escaped CSS of a text goes, as `SHAPE_CSS` stands for its shape's.
pub const TEXT_CSS : String = "\u{0}t"

///|
/// Where the escaped stroke color goes, as `SHAPE_CSS` stands for the shape's CSS.
pub const STROKE_CSS : String = "\u{0}k"

///|
fn slot_attribute(css : String, slot : String) -> String {
  if css == "" {
    ""
  } else {
    " style=\"" + slot + "\""
  }
}

///|
/// The attributes `resolve_style` makes of the same declarations, with each escaped CSS left as its
/// stand-in, for markup put together as a string and written with `write_styled`.
/// A drawing only looks past a stand-in, as `rounded` does to find where the `style` attribute
/// starts, so the markup is drawn as it is around the escaped CSS.
/// The stroke is left as the declarations give it, unescaped, for telling whether there is one.
pub fn RawStyle::slots(self : RawStyle) -> ResolvedStyle {
  {
    shape: slot_attribute(self.shape, SHAPE_CSS),
    line: slot_attribute(self.line, LINE_CSS),
    text: slot_attribute(self.text, TEXT_CSS),
    stroke: self.stroke,
    bold: self.bold,
    italic: self.italic,
    font_size: self.font_size,
  }
}

///|
/// The text the stand-in in `template` at `at` stands for, unescaped.
fn slot_value(template : String, at : Int32, css : RawStyle) -> String {
  match @util.code_at(template, at + 1) {
    's' => css.shape
    'l' => css.line
    't' => css.text
    'k' => css.stroke.unwrap_or("")
    _ => abort("not a style stand-in")
  }
}

///|
/// Writes `template` to `out` with each stand-in replaced by the CSS of `css` it stands for, escaped
/// a piece at a time, since a style value of tens of millions of `&` escapes to more than a
/// doubling StringBuilder holds.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_styled(
  out : Markup,
  template : String,
  css : RawStyle,
) -> Unit raise @errors.PeleError {
  let mut from = 0
  let mut at = @util.index_of(template, "\u{0}")
  while at >= 0 {
    out.write(@util.slice(template, from, end=at))
    out.write_esc(slot_value(template, at, css))
    from = at + 2
    at = @util.index_of(template, "\u{0}", from~)
  }
  out.write(@util.slice(template, from))
}

///|
/// Whether the `style` attribute `resolve_style` makes of `css` contains `needle`, found in the
/// escaped attribute as it would be written, without escaping all of `css` at once.
pub fn style_contains(css : String, needle : String) -> Bool {
  let n = needle.length()
  if n == 0 {
    return true
  }
  if css == "" {
    return false
  }
  let ring = FixedArray::make(n, 0)
  let mut count = 0
  let found = (c : Int32) => {
    ring[count % n] = c
    count += 1
    if count < n {
      return false
    }
    for k in 0..<n {
      if ring[(count - n + k) % n] != needle.unsafe_get(k).to_int() {
        return false
      }
    }
    true
  }
  let feed = (text : String) => {
    for i in 0..<text.length() {
      if found(text.unsafe_get(i).to_int()) {
        return true
      }
    }
    false
  }
  if feed(" style=\"") {
    return true
  }
  for i in 0..<css.length() {
    let c = @util.code_at(css, i)
    let hit = match c {
      0x26 => feed("&amp;")
      0x3c => feed("&lt;")
      0x3e => feed("&gt;")
      0x22 => feed("&quot;")
      _ => if is_xml_forbidden(c) { false } else { found(c) }
    }
    if hit {
      return true
    }
  }
  feed("\"")
}
