///|
/// The end of `<br\s*\/?>`, ignoring case, at `i`, or -1.
fn br_end(text : String, i : Int32) -> Int32 {
  if @util.code_at(text, i) != '<' ||
    (@util.code_at(text, i + 1) | 32) != 'b' ||
    (@util.code_at(text, i + 2) | 32) != 'r' {
    return -1
  }
  let mut k = i + 3
  while @util.is_space(@util.code_at(text, k)) {
    k += 1
  }
  if @util.code_at(text, k) == '/' {
    k += 1
  }
  if @util.code_at(text, k) == '>' {
    k + 1
  } else {
    -1
  }
}

///|
/// Escapes every `<` that does not start a `<br>`, and every `:fa-`, so that neither reads as markup.
fn plain_text(text : String) -> String {
  if !text.contains("<") && !text.contains(":fa-") {
    return text
  }
  let mut length = text.length()
  for i in 0..<text.length() {
    let c = text.unsafe_get(i)
    if c == '<' && br_end(text, i) == -1 {
      length += 3
    } else if c == ':' && @util.starts_with_at(text, ":fa-", i) {
      length += 6
    }
  }
  // Sized to the escaped text, because a doubling builder past 2^28 code units asks wasm for a
  // block of 1 GiB that it refuses, and a title of tens of millions of `<` escapes past that.
  let out = StringBuilder(size_hint=length * 2)
  let mut last = 0
  for i in 0..<text.length() {
    let c = text.unsafe_get(i)
    if c == '<' && br_end(text, i) == -1 {
      @util.write_range(out, text, last, i)
      out.write_string("&lt;")
      last = i + 1
    } else if c == ':' && @util.starts_with_at(text, ":fa-", i) {
      @util.write_range(out, text, last, i)
      out.write_string("&colon;")
      last = i + 1
    }
  }
  @util.write_range(out, text, last, text.length())
  out.to_string()
}

///|
/// Lays out text the way Mermaid's journey and timeline draw it: as plain text in which only `<br>` is markup,
/// so other tags and icon names show as written instead of being read as formatting.
pub fn plain_label(
  raw : String?,
  measurer : @text.TextMeasurer,
  size : Double,
  max : Double,
  base~ : Int32 = 0,
) -> @text.Label {
  @text.layout_label(raw.map(plain_text), false, measurer, size, max, base~)
}

///|
/// The end of `ﬂ°°?\w+¶ß` at `i`, or -1.
fn marker_end(text : String, i : Int32) -> Int32 {
  if @util.code_at(text, i) != 0xfb02 || @util.code_at(text, i + 1) != '°' {
    return -1
  }
  let mut k = i + 2
  if @util.code_at(text, k) == '°' {
    k += 1
  }
  let word = k
  while @util.is_word(@util.code_at(text, k)) {
    k += 1
  }
  if k > word && @util.starts_with_at(text, "¶ß", k) {
    k + 2
  } else {
    -1
  }
}

///|
/// The end of `&#?\w+;` at `i`, or -1.
fn entity_end(text : String, i : Int32) -> Int32 {
  if @util.code_at(text, i) != '&' {
    return -1
  }
  let mut k = i + 1
  if @util.code_at(text, k) == '#' {
    k += 1
  }
  let word = k
  while @util.is_word(@util.code_at(text, k)) {
    k += 1
  }
  if k > word && @util.code_at(text, k) == ';' {
    k + 1
  } else {
    -1
  }
}

///|
/// The end of the piece a word can be cut before at `i`: a line break, an encoded entity, a surrogate pair, or one character.
fn unit_end(text : String, i : Int32) -> Int32 {
  let br = br_end(text, i)
  if br != -1 {
    return br
  }
  let marker = marker_end(text, i)
  if marker != -1 {
    return marker
  }
  let entity = entity_end(text, i)
  if entity != -1 {
    return entity
  }
  let c = @util.code_at(text, i)
  let d = @util.code_at(text, i + 1)
  if c >= 0xd800 && c <= 0xdbff && d >= 0xdc00 && d <= 0xdfff {
    i + 2
  } else {
    i + 1
  }
}

///|
/// Lays out text as `plain_label` does, and for a box of fixed width also cuts any word too long to fit.
pub fn fit_label(
  raw : String?,
  measurer : @text.TextMeasurer,
  size : Double,
  max : Double,
  base~ : Int32 = 0,
) -> @text.Label {
  let label = plain_label(raw, measurer, size, max, base~)
  guard raw is Some(raw) && !(label.width <= max) else { return label }
  let out = StringBuilder()
  let mut width = 0.0
  let mut i = 0
  while i < raw.length() {
    let end = unit_end(raw, i)
    let unit = @util.slice(raw, i, end~)
    if @util.trim(unit) == "" || (unit.length() > 2 && unit.has_prefix("<")) {
      width = 0
    } else {
      let measured = if unit.length() > 2 { "x" } else { unit }
      let w = measurer.width(measured, size, base)
      if width > 0 && width + w > max {
        out.write_char('\n')
        width = 0
      }
      width += w
    }
    out.write_string(unit)
    i = end
  }
  plain_label(Some(out.to_string()), measurer, size, max, base~)
}
