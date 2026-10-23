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
/// The end of one family name at `at`, quoted or not, or -1.
fn family_end(list : String, at : Int32) -> Int32 {
  let quote = @util.code_at(list, at)
  if quote == '"'.to_int() || quote == '\''.to_int() {
    let mut i = at + 1
    while i < list.length() {
      let c = @util.code_at(list, i)
      if c == quote {
        return i + 1
      }
      if "\"'\\\n<>{}();:@".contains_code_unit(c.to_uint16()) {
        return -1
      }
      i += 1
    }
    return -1
  }
  let (first, next) = code_point_at(list, at)
  if !is_family_char(first, true) {
    return -1
  }
  let mut i = next
  while i < list.length() {
    let (c, after) = code_point_at(list, i)
    if !is_family_char(c, false) {
      break
    }
    i = after
  }
  i
}

///|
fn skip_space(text : String, from : Int32) -> Int32 {
  let mut i = from
  while @util.is_space(@util.code_at(text, i)) {
    i += 1
  }
  i
}

///|
/// Whether the list is font names, quoted or not, and nothing that could end the declaration
/// it is put in.
fn is_family_list(list : String) -> Bool {
  let mut pos = skip_space(list, 0)
  while true {
    pos = family_end(list, pos)
    if pos == -1 {
      return false
    }
    let after = skip_space(list, pos)
    if after == list.length() {
      return true
    }
    if @util.code_at(list, after) != ','.to_int() {
      return false
    }
    pos = skip_space(list, after + 1)
  }
  false
}

///|
fn families(list : String?, generic : String) -> String {
  match list {
    Some(list) if list != "" && is_family_list(list) => list
    _ => generic
  }
}

///|
/// The font declarations of the root element: the fonts labels were measured in, unless the page
/// names others, with the rest of what text inherits pinned, as none of it was measured.
pub fn font_style(size : Double, family : String?, mono : String?) -> String {
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
