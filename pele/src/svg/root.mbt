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
/// The prefix of the ids of the accessible name and description.
fn id_prefix(options : @types.RenderOptions) -> String {
  esc(options.id_prefix.unwrap_or("pele"))
}

///|
/// The root `svg` element's start tag, for content that uses the aliases in `used`, with its theme
/// aliases and fonts, and pointing at the accessible name and description when there are any.
fn document_tag(
  kind : String,
  width : Double,
  height : Double,
  font_size : Double,
  options : @types.RenderOptions,
  acc_title : String?,
  acc_descr : String?,
  used : Set[String],
) -> String {
  let prefix = id_prefix(options)
  let aria = StringBuilder()
  if acc_title is Some(title) && title != "" {
    aria.write_string(" aria-labelledby=\"\{prefix}-title\"")
  }
  if acc_descr is Some(descr) && descr != "" {
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
  "<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-\{kind}\" viewBox=\"0 0 \{width} \{height}\" width=\"\{width}\" height=\"\{height}\" style=\"\{fit}\{ROOT_STYLE}\{extra.to_string()}\{fonts}\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"\{kind}\"\{aria.to_string()}>"
}

///|
/// Writes the accessible name and description, which follow the root `svg` element's start tag,
/// escaping each a piece at a time so that either can be as long as the markup holding it.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
fn write_document_head(
  out : Markup,
  options : @types.RenderOptions,
  acc_title : String?,
  acc_descr : String?,
) -> Unit raise @errors.PeleError {
  let prefix = id_prefix(options)
  if acc_title is Some(title) && title != "" {
    out.write("<title id=\"\{prefix}-title\">")
    out.write_esc(@text.decode_entities(title))
    out.write("</title>")
  }
  if acc_descr is Some(descr) && descr != "" {
    out.write("<desc id=\"\{prefix}-desc\">")
    out.write_esc(@text.decode_entities(descr))
    out.write("</desc>")
  }
}
