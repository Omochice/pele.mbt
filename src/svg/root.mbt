///|
/// The weights of bold text, each set only in a diagram that has such text.
let weights : Array[(String, String)] = [
  ("tw", "title"),
  ("hw", "heading"),
  ("w", "bold"),
]

///|
/// Adds the private aliases `var(--_r)`, `var(--_tw)`, `var(--_hw)`, and `var(--_w)` that `content` uses to `used`.
fn add_aliases(used : Set[String], content : String) -> Unit {
  let mut at = @util.index_of(content, "var(--_")
  while at != -1 && used.length() < 4 {
    let name = at + "var(--_".length()
    for token in ["r", "tw", "hw", "w"] {
      if @util.starts_with_at(content, token + ")", name) {
        used.add(token)
        break
      }
    }
    at = @util.index_of(content, "var(--_", from=name)
  }
}

///|
/// The root `svg` element up to its content, for content that uses the aliases in `used`: the
/// start tag with its theme aliases and fonts, then the accessible name and description.
fn document_start(
  kind : String,
  width : Double,
  height : Double,
  font_size : Double,
  options : @types.RenderOptions,
  acc_title : String?,
  acc_descr : String?,
  used : Set[String],
) -> String {
  let prefix = esc(options.id_prefix.unwrap_or("pele"))
  let head = StringBuilder()
  let aria = StringBuilder()
  if acc_title is Some(title) && title != "" {
    head.write_string(
      "<title id=\"\{prefix}-title\">\{esc_text(title)}</title>",
    )
    aria.write_string(" aria-labelledby=\"\{prefix}-title\"")
  }
  if acc_descr is Some(descr) && descr != "" {
    head.write_string("<desc id=\"\{prefix}-desc\">\{esc_text(descr)}</desc>")
    aria.write_string(" aria-describedby=\"\{prefix}-desc\"")
  }
  let fit = if options.responsive is Some(false) {
    ""
  } else {
    "max-width:100%;height:auto;"
  }
  let extra = StringBuilder()
  if used.contains("r") {
    extra.write_string(";--_r:\{RADIUS}")
  }
  for weight in weights {
    let (token, name) = weight
    if used.contains(token) {
      extra.write_string(";--_\{token}:var(--pele-\{name}-weight,bold)")
    }
  }
  let fonts = esc(
    font_style(font_size, options.font_family, options.font_family_mono),
  )
  "<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-\{kind}\" viewBox=\"0 0 \{width} \{height}\" width=\"\{width}\" height=\"\{height}\" style=\"\{fit}\{ROOT_STYLE}\{extra.to_string()}\{fonts}\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"\{kind}\"\{aria.to_string()}>" +
  head.to_string()
}

///|
/// Wraps diagram content in the root `svg` element, with its accessible name and description,
/// its theme aliases, and its fonts.
pub fn svg_document(
  kind : String,
  width : Double,
  height : Double,
  font_size : Double,
  options : @types.RenderOptions,
  acc_title : String?,
  acc_descr : String?,
  content : String,
) -> String {
  let used : Set[String] = Set([])
  add_aliases(used, content)
  document_start(
    kind, width, height, font_size, options, acc_title, acc_descr, used,
  ) +
  content +
  "</svg>"
}
