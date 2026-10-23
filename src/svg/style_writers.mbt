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
  write_esc(out, css)
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
  write_esc(out, css)
  out.write("\"")
}

///|
/// What stands in for the escaped CSS of a shape's fill and border while `draw_shape` draws it.
/// No drawing holds a NUL, which XML forbids.
const SHAPE_CSS : String = "\u{0}a\u{0}"

///|
/// What stands in for the escaped CSS of a shape's inner strokes while `draw_shape` draws it.
const LINE_CSS : String = "\u{0}l\u{0}"

///|
fn stand_in(css : String, mark : String) -> String {
  if css == "" {
    ""
  } else {
    " style=\"" + mark + "\""
  }
}

///|
/// Writes the outline `draw_shape` draws when `a` and `line` are each followed by the `style`
/// attribute `resolve_style` makes of `a_css` and `line_css`, escaping the CSS a piece at a time.
/// The shape is drawn around stand-ins for the CSS, which a drawing only looks past, as `rounded`
/// does to find where the `style` attribute starts.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_shape_styled(
  out : Markup,
  shape : String,
  w : Double,
  h : Double,
  a : String,
  a_css : String,
  line : String,
  line_css : String,
) -> Unit raise @errors.PeleError {
  let drawn = draw_shape(
    shape,
    w,
    h,
    a + stand_in(a_css, SHAPE_CSS),
    line + stand_in(line_css, LINE_CSS),
  )
  let mut from = 0
  let mut i = 0
  while i < drawn.length() {
    if drawn.unsafe_get(i).to_int() != 0 {
      i += 1
      continue
    }
    out.write(@util.slice(drawn, from, end=i))
    write_esc(
      out,
      if drawn.unsafe_get(i + 1) == 'a' {
        a_css
      } else {
        line_css
      },
    )
    i += SHAPE_CSS.length()
    from = i
  }
  out.write(@util.slice(drawn, from))
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

///|
/// Writes the marker `marker` draws in the color `esc` makes of `color`, escaping it a piece at a
/// time, since a color from the source can be tens of millions of `&` long.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_marker_esc(
  out : Markup,
  type_ : String,
  x : Double,
  y : Double,
  dx : Double,
  dy : Double,
  color : String,
) -> Unit raise @errors.PeleError {
  let drawn = marker(type_, x, y, dx, dy, SHAPE_CSS)
  let mut from = 0
  while from < drawn.length() {
    let at = @util.index_of(drawn, SHAPE_CSS, from~)
    if at < 0 {
      break
    }
    out.write(@util.slice(drawn, from, end=at))
    write_esc(out, color)
    from = at + SHAPE_CSS.length()
  }
  out.write(@util.slice(drawn, from))
}
