///|
/// How much wider a casing is than the edge it lies under.
const CASE : Double = 4

///|
/// The trimmed value of the first declaration of `name` in a `style` attribute that has a value and
/// ends with a `;`, as `/[";]name:([^;"]+);/` finds it.
fn declaration(attrs : String, name : String) -> String? {
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
      if end > start && end < attrs.length() && @util.code_at(attrs, end) == ';' {
        return Some(@util.trim(@util.slice(attrs, start, end~)))
      }
    }
    at = @util.index_of(attrs, key, from=at + 1)
  }
  None
}

///|
/// `declaration` of the `style` attribute `resolve_style` makes of the raw CSS `css`, as it reads
/// in the escaped attribute, without escaping all of `css`.
/// A value ends at a `;`, or at a character escaping changes with what its escape writes before the
/// `;` that ends it.
fn raw_declaration(css : String, name : String) -> String? {
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
          return Some(@util.trim(@util.slice(css, start, end~) + head))
        }
        end += 1
      }
      if end > start && end < css.length() {
        return Some(@util.trim(@util.slice(css, start, end~)))
      }
    }
    at = @util.index_of(css, key, from=at + 1)
  }
  None
}

///|
/// Whether a stroke width is a plain number of pixels, as `/^[\d.]+(?:px)?$/` tells.
fn plain_width(width : String) -> Bool {
  let digits = if width.has_suffix("px") {
    @util.slice(width, 0, end=width.length() - 2)
  } else {
    width
  }
  digits != "" && digits.iter().all(c => c == '.' || (c >= '0' && c <= '9'))
}

///|
/// A wider stroke in the page color under the path `d` and its `markers`, as faint as the edge's
/// line style makes the edge, read from it by `decl`.
/// The markers drop their class so that styles of markers leave the casing alone.
fn casing_by(
  d : String,
  markers : String,
  decl : (String) -> String?,
  thick : Bool,
) -> String {
  if decl("stroke") is Some("none" | "transparent") {
    return ""
  }
  let width = if thick { Some("2.5") } else { decl("stroke-width") }
  let mut attrs = ""
  let style = StringBuilder()
  match width {
    Some(width) if plain_width(width) => {
      let value = @util.parse_float(width)
      if value != 1 {
        attrs = " stroke-width=\"\{num(value + CASE)}\""
      }
    }
    Some(width) => style.write_string("stroke-width:calc(\{width} + 4px);")
    None => ()
  }
  for prop in ["opacity", "stroke-opacity"] {
    if decl(prop) is Some(value) {
      style.write_string("\{prop}:\{value};")
    }
  }
  let body = "<path d=\"\{d}\"/>" +
    markers.replace_all(old=" class=\"pele-marker\"", new="")
  let style = style.to_string()
  if attrs == "" && style == "" {
    body
  } else if style == "" {
    "<g\{attrs}>\{body}</g>"
  } else {
    "<g\{attrs} style=\"\{style}\">\{body}</g>"
  }
}

///|
/// A wider stroke in the page color under the path `d` and its `markers`, as wide and as faint as
/// the edge's line style `line` makes it, so the edge stands out where it runs over a fill.
/// `thick` edges are drawn 2.5 wide whatever their style says.
/// Returns an empty string for an edge whose style draws no stroke.
/// Styles come from `resolve_style`.
pub fn casing(
  d : String,
  markers : String,
  line~ : String = "",
  thick~ : Bool = false,
) -> String {
  casing_by(d, markers, name => declaration(line, name), thick)
}

///|
/// `casing` of an edge whose line style is the raw CSS `css`.
/// Styles come from `resolve_raw_style`.
pub fn raw_casing(
  d : String,
  markers : String,
  css~ : String,
  thick~ : Bool = false,
) -> String {
  casing_by(d, markers, name => raw_declaration(css, name), thick)
}

///|
/// Markers of `start_type` and `end_type` at the ends of `path`, drawn in the page color.
fn page_markers(
  path : EdgePath,
  start_type : String,
  end_type : String,
) -> String {
  marker(
    start_type,
    path.sx,
    path.sy,
    path.sdx,
    path.sdy,
    "var(--_bg)",
    stroke="var(--_bg)",
  ) +
  marker(
    end_type,
    path.ex,
    path.ey,
    path.edx,
    path.edy,
    "var(--_bg)",
    stroke="var(--_bg)",
  )
}

///|
/// The `casing` of an edge drawn along `path` with markers of `start_type` and `end_type`.
pub fn edge_casing(
  path : EdgePath,
  start_type : String,
  end_type : String,
  line~ : String = "",
  thick~ : Bool = false,
) -> String {
  casing(path.d, page_markers(path, start_type, end_type), line~, thick~)
}

///|
/// `edge_casing` of an edge whose line style is the raw CSS `css`.
pub fn raw_edge_casing(
  path : EdgePath,
  start_type : String,
  end_type : String,
  css~ : String,
  thick~ : Bool = false,
) -> String {
  raw_casing(path.d, page_markers(path, start_type, end_type), css~, thick~)
}

///|
/// Writes the casings under a diagram's edges, if there are any.
pub fn write_casings(out : Markup, casings : Markup) -> Unit {
  if casings.is_empty() {
    return
  }
  out.write_group(
    "<g class=\"pele-casings\" fill=\"none\" stroke=\"var(--_bg)\" stroke-width=\"\{num(1 + CASE)}\" stroke-linecap=\"round\" stroke-linejoin=\"round\" pointer-events=\"none\">",
    casings,
    "</g>",
  )
}
