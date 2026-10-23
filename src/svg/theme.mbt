///|
/// Private aliases set once on the root element, so each use is short and the public
/// `--pele-*` tokens keep their fallbacks.
pub const ROOT_STYLE : String = "--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg)"

///|
/// The corner radius token.
pub const RADIUS : String = "var(--pele-radius,4px)"

///|
/// The corner radius as a style attribute.
/// It is set through CSS rather than the `rx` attribute to support older browsers.
pub const ROUNDED : String = " style=\"rx:var(--_r)\""

///|
/// Adds the rounded corner radius to shape attributes, ahead of any style they already have so that
/// style can override it.
pub fn rounded(attrs : String) -> String {
  let at = @util.index_of(attrs, " style=\"")
  if at < 0 {
    attrs + ROUNDED
  } else {
    @util.slice(attrs, 0, end=at + 8) +
    "rx:var(--_r);" +
    @util.slice(attrs, at + 8)
  }
}

///|
/// The color of what a diagram marks as critical.
/// It is not one of the series colors, as a theme may put those in any order.
pub const CRITICAL : String = "var(--pele-critical,#e45756)"

///|
/// The code point at `i` and where the next one starts, reading surrogate pairs as the `u` flag does.
fn code_point_at(text : String, i : Int32) -> (Int32, Int32) {
  let c = @util.code_at(text, i)
  if c >= 0xd800 && c <= 0xdbff {
    let low = @util.code_at(text, i + 1)
    if low >= 0xdc00 && low <= 0xdfff {
      return (0x10000 + ((c - 0xd800) << 10) + (low - 0xdc00), i + 2)
    }
  }
  (c, i + 1)
}

///|
fn is_family_char(c : Int32, first : Bool) -> Bool {
  @util.is_letter_or_number(c) ||
  c == '_'.to_int() ||
  c == '-'.to_int() ||
  (!first && (c == ' '.to_int() || c == '.'.to_int()))
}

///|
/// The end of one family name at `at`, quoted or not, or -1, and the slots of V8's backtracking stack reading it takes, as `family_list_slots` counts them.
fn family_end(list : String, at : Int32, wide : Bool) -> (Int32, Int64) {
  let quote = @util.code_at(list, at)
  if quote == '"'.to_int() || quote == '\''.to_int() {
    let mut i = at + 1
    let mut steps = 0L
    while i < list.length() {
      let c = @util.code_at(list, i)
      if c == quote {
        return (i + 1, if wide { 2L * steps } else { 0L })
      }
      if "\"'\\\n<>{}();:@".contains_code_unit(c.to_uint16()) {
        break
      }
      i = code_point_at(list, i).1
      steps += 1
    }
    return (-1, if wide { 2L * steps + 4 } else { 4L })
  }
  let (first, next) = code_point_at(list, at)
  if !is_family_char(first, true) {
    return (-1, 0L)
  }
  let mut i = next
  let mut steps = 0L
  while i < list.length() {
    let (c, after) = code_point_at(list, i)
    if !is_family_char(c, false) {
      break
    }
    i = after
    steps += 1
  }
  (i, if wide { 4L * steps } else { 0L })
}

///|
/// Whether the list is font names, quoted or not, and nothing that could end the declaration
/// it is put in.
/// Raises the error pele reports where its pattern for the list runs out of V8's backtracking stack, see `family_list_slots`.
fn is_family_list(list : String) -> Bool raise @errors.PeleError {
  let (fits, slots) = family_list_slots(list)
  if @util.backtrack_stack_overflows(slots) {
    raise @errors.nested_too_deeply()
  }
  fits
}

///|
/// Whether the list is font names, and the most slots of V8's backtracking stack pele's `u` pattern for it fills.
/// V8 matches a list of Latin-1 characters with code that takes eleven slots for each font tried after the first and nothing for its characters.
/// A list with a character past Latin-1 is two-byte text, matched with code that takes four slots for each font tried after the first, two for each blank and each quoted character, and four for each unquoted character after a font's first.
/// Either takes four more for a quoted font left unclosed.
fn family_list_slots(list : String) -> (Bool, Int64) {
  let wide = list.iter().any(c => c.to_int() > 0xff)
  let blank = if wide { 2L } else { 0L }
  let mut depth = 2L
  let mut at = 0
  while @util.is_space(@util.code_at(list, at)) {
    at += 1
    depth += blank
  }
  let (first_end, first_slots) = family_end(list, at, wide)
  if first_end == -1 {
    return (false, depth + first_slots)
  }
  depth += first_slots
  let mut end = first_end
  while true {
    let mut tried = if wide { 4L } else { 11L }
    let mut i = end
    while @util.is_space(@util.code_at(list, i)) {
      i += 1
      tried += blank
    }
    if @util.code_at(list, i) != ','.to_int() {
      return (i == list.length(), depth + tried)
    }
    i += 1
    while @util.is_space(@util.code_at(list, i)) {
      i += 1
      tried += blank
    }
    let (next, slots) = family_end(list, i, wide)
    if next == -1 {
      return (false, depth + tried + slots)
    }
    depth += tried + slots
    end = next
  }
  (false, depth)
}

///|
fn families(list : String?, generic : String) -> String raise @errors.PeleError {
  match list {
    Some(list) if list != "" && is_family_list(list) => list
    _ => generic
  }
}

///|
/// The font declarations of the root element: the fonts labels were measured in, unless the page
/// names others, with the rest of what text inherits pinned, as none of it was measured.
/// Raises the limit error where pele's pattern for a font list runs out of V8's backtracking stack.
pub fn font_style(
  size : Double,
  family : String?,
  mono : String?,
) -> String raise @errors.PeleError {
  ";--_fm:var(--pele-font-mono,\{families(mono, "monospace")});font:\{size}px sans-serif;" +
  "letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;" +
  "font-family:var(--pele-font,\{families(family, "sans-serif")})"
}

///|
/// A class list reduced to word characters and hyphens, with a leading space unless it is empty.
pub fn class_names(raw : String) -> String {
  let out = StringBuilder()
  let mut gap = true
  for i in 0..<raw.length() {
    let c = @util.code_at(raw, i)
    if @util.is_word(c) || c == '-' {
      if gap {
        out.write_char(' ')
      }
      gap = false
      @util.write_range(out, raw, i, i + 1)
    } else {
      gap = true
    }
  }
  out.to_string()
}

///|
/// A node's classes as `class_names` writes them, without the `default` class every node carries first, as `/^default\s?/` removes it.
pub fn node_class_names(classes : String) -> String {
  let rest = if classes.has_prefix("default") {
    let after = @util.slice(classes, 7)
    if @util.is_space(@util.code_at(after, 0)) {
      @util.slice(after, 1)
    } else {
      after
    }
  } else {
    classes
  }
  class_names(rest)
}

///|
let series : Array[String] = [
  "#4c78a8", "#f58518", "#54a24b", "#e45756", "#72b7b2", "#eeca3b", "#b279a2", "#9d755d",
]

///|
/// The color of the nth data series in a chart, cycling through eight tokens.
pub fn series_color(index : Int32) -> String {
  let k = (index % 8 + 8) % 8
  "var(--pele-series-\{k + 1},\{series[k]})"
}
