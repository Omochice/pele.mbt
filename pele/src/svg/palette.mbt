///|
/// The series colors a diagram's Mermaid palette theme variables set.
pub struct Palette {
  /// The `--pele-series-*` declarations for the root `style` attribute, escaped.
  style : String
  /// The label color for text on each series, where the contrast of its color is known.
  inks : Array[String?]
}

///|
let no_palette : Palette = { style: "", inks: [], }

///|
/// How many series colors a palette sets.
const SLOTS : Int32 = 8

///|
/// Mermaid's palette theme variables of a diagram type: their prefix, the number of the variable
/// for the first series, and whether the palette repeats the colors it sets.
/// Mindmap branches start at `cScale1`, as `cScale0` is the root's in Mermaid's styles.
fn palette_variables(kind : String) -> (String, Int32, Bool)? {
  match kind {
    "pie" => Some(("pie", 1, false))
    "gitGraph" => Some(("git", 0, false))
    "timeline" | "radar" | "treemap" => Some(("cScale", 0, false))
    "mindmap" => Some(("cScale", 1, false))
    "venn" => Some(("venn", 1, true))
    _ => None
  }
}

///|
let color_functions : Array[String] = [
  "rgb", "rgba", "hsl", "hsla", "hwb", "lab", "lch", "oklab", "oklch", "color", "color-mix",
  "light-dark", "var",
]

///|
fn record(value : Json?) -> Map[String, Json] {
  match value {
    Some(Object(fields)) => fields
    _ => {}
  }
}

///|
fn is_name_char(c : Int32) -> Bool {
  @util.is_word(c) || c == '-'
}

///|
/// Whether every code unit of `color` is one `/^[\w\s#%.,+\-/()]{1,200}$/` allows, and there are 1 to 200 of them.
fn has_color_chars(color : String) -> Bool {
  let n = color.length()
  guard n >= 1 && n <= 200 else { return false }
  for i in 0..<n {
    let c = @util.code_at(color, i)
    guard @util.is_word(c) ||
      @util.is_space(c) ||
      c is ('#' | '%' | '.' | ',' | '+' | '-' | '/' | '(' | ')') else {
      return false
    }
  }
  true
}

///|
/// Whether every name `/([\w-]*)\s*\(/g` finds before a `(` is a color function.
fn calls_only_colors(color : String) -> Bool {
  let n = color.length()
  let mut at = 0
  while at < n {
    let mut name_end = at
    while name_end < n && is_name_char(@util.code_at(color, name_end)) {
      name_end += 1
    }
    let mut open = name_end
    while open < n && @util.is_space(@util.code_at(color, open)) {
      open += 1
    }
    if @util.code_at(color, open) != '(' {
      at += 1
      continue
    }
    let name = lower_ascii(@util.slice(color, at, end=name_end))
    if !color_functions.contains(name) {
      return false
    }
    at = open + 1
  }
  true
}

///|
/// Whether every name `/var\(\s*([\w-]*)/gi` finds is one of pele's own properties.
fn reads_only_pele_vars(color : String) -> Bool {
  let n = color.length()
  let mut at = 0
  while at + 4 <= n {
    if lower_ascii(@util.slice(color, at, end=at + 4)) != "var(" {
      at += 1
      continue
    }
    let mut start = at + 4
    while start < n && @util.is_space(@util.code_at(color, start)) {
      start += 1
    }
    let mut end = start
    while end < n && is_name_char(@util.code_at(color, end)) {
      end += 1
    }
    if !@util.slice(color, start, end~).has_prefix("--pele-") {
      return false
    }
    at = end
  }
  true
}

///|
/// A color that can't load a resource, end its declaration or read the page's own variables.
/// Values outside functions are checked as colors, so a typo keeps the theme color.
fn safe_color(value : Json?) -> String? {
  guard value is Some(String(raw)) else { return None }
  let color = @util.trim(raw)
  guard has_color_chars(color) else { return None }
  if !color.contains("(") {
    return if plain_color(color) { Some(color) } else { None }
  }
  let mut depth = 0
  for i in 0..<color.length() {
    match @util.code_at(color, i) {
      '(' => depth += 1
      ')' => {
        depth -= 1
        if depth < 0 {
          return None
        }
      }
      _ => ()
    }
  }
  guard depth == 0 && calls_only_colors(color) && reads_only_pele_vars(color) else {
    return None
  }
  Some(color)
}

///|
/// Splits at the commas between colors, not those inside `rgb()` and other functions.
fn split_list(value : String) -> Array[Json?] {
  let parts : Array[Json?] = []
  let mut depth = 0
  let mut start = 0
  for i in 0..<value.length() {
    match @util.code_at(value, i) {
      '(' => depth += 1
      ')' => depth -= 1
      ',' if depth == 0 => {
        parts.push(
          Some(Json::string(@util.trim(@util.slice(value, start, end=i)))),
        )
        start = i + 1
      }
      _ => ()
    }
  }
  parts.push(Some(Json::string(@util.trim(@util.slice(value, start)))))
  parts
}

///|
/// The palette entries the theme variables `vars` set for a diagram of type `kind`, and whether
/// the palette repeats them.
fn palette_entries(
  kind : String,
  vars : Map[String, Json],
) -> (Array[Json?], Bool)? {
  if kind == "xychart" {
    return match record(vars.get("xyChart")).get("plotColorPalette") {
      Some(String(list)) => Some((split_list(list), true))
      _ => None
    }
  }
  guard palette_variables(kind) is Some((prefix, first, repeat)) else {
    return None
  }
  let list : Array[Json?] = []
  for i in 0..<SLOTS {
    let value = vars.get(prefix + (first + i).to_string())
    if repeat && value is (None | Some(Null) | Some(String(""))) {
      continue
    }
    list.push(value)
  }
  Some((list, repeat))
}

///|
/// The palette that a diagram's theme variables set, in the `--pele-series-*` declarations of the
/// root element.
/// An entry that isn't a usable color leaves its series in the theme's color.
pub fn palette(kind : String, config : @types.Config) -> Palette {
  guard palette_entries(kind, record(config.get("themeVariables")))
    is Some((list, repeat)) &&
    !list.is_empty() else {
    return no_palette
  }
  let style = StringBuilder()
  let inks : Array[String?] = Array::make(SLOTS, None)
  for i in 0..<SLOTS {
    if !repeat && i >= list.length() {
      break
    }
    guard safe_color(list[i % list.length()]) is Some(color) else { continue }
    style.write_string(";--pele-series-\{i + 1}:\{color}")
    inks[i] = ink(";fill:" + color)
  }
  if style.is_empty() {
    return no_palette
  }
  { style: esc(style.to_string()), inks, }
}

///|
/// The palette of the render in progress.
/// pele keeps it in module state rather than passing it down, as only the root element and a few
/// labels read it.
let current_palette : Ref[Palette] = { val: no_palette, }

///|
/// Runs `run` with `palette` as the palette of the diagram it draws.
pub fn[T] with_palette(palette : Palette, run : () -> T raise?) -> T raise? {
  let outer = current_palette.val
  current_palette.val = palette
  defer {
    current_palette.val = outer
  }
  run()
}

///|
/// The root element's declarations of the palette of the render in progress.
fn palette_style() -> String {
  current_palette.val.style
}

///|
/// The `fill` attribute of a label on the color of series `index`, when the palette sets a color
/// whose contrast is known, or nothing.
pub fn series_ink_fill(index : Int32) -> String {
  match current_palette.val.inks.get((index % SLOTS + SLOTS) % SLOTS) {
    Some(Some(color)) => " fill=\"\{color}\""
    _ => ""
  }
}
