///|
let default_link_schemes : Array[String] = ["http", "https", "mailto", "tel"]

///|
let default_image_schemes : Array[String] = ["http", "https"]

///|
/// A URL as written in a diagram, sanitized after its entity codes are read so that they cannot hide a scheme.
pub fn safe_url(url : String) -> String {
  sanitize_url(@text.decode_entities(url))
}

///|
/// The scheme that `/^([a-z][a-z0-9+.-]*):/i` finds at the start of `url`.
fn scheme_name(url : String) -> String? {
  guard @util.is_letter(@util.code_at(url, 0)) else { return None }
  let mut i = 1
  while true {
    let c = @util.code_at(url, i)
    if @util.is_letter(c) ||
      @util.is_digit(c) ||
      c == '+'.to_int() ||
      c == '.'.to_int() ||
      c == '-'.to_int() {
      i += 1
    } else if c == ':'.to_int() {
      return Some(@util.slice(url, 0, end=i))
    } else {
      return None
    }
  }
  None
}

///|
fn is_slash(c : Int32) -> Bool {
  c == '/'.to_int() || c == '\\'.to_int()
}

///|
/// Stricter than Mermaid, which lets any scheme but three through: a diagram in a shared note
/// could otherwise open a local file, a network share, or another application.
fn allow(url : String, schemes : Array[String]) -> String? {
  if is_slash(@util.code_at(url, 0)) && is_slash(@util.code_at(url, 1)) {
    return None
  }
  match scheme_name(url) {
    None => Some(url)
    Some(scheme) =>
      if schemes.contains(scheme.to_lower()) {
        Some(url)
      } else {
        None
      }
  }
}

///|
/// The URL a link may point to, or `None` when the host turns links off or does not allow its scheme.
pub fn link_url(url : String, options : @types.RenderOptions) -> String? {
  if options.links == Some(false) {
    return None
  }
  allow(url, options.link_schemes.unwrap_or(default_link_schemes))
}

///|
/// The URL an image may load from, or `None` when the host turns images off or does not allow its scheme.
pub fn image_url(url : String, options : @types.RenderOptions) -> String? {
  if options.images == Some(false) {
    return None
  }
  allow(url, options.image_schemes.unwrap_or(default_image_schemes))
}

///|
/// `body` wrapped in an anchor to `url`, which is recorded in `links`; `body` alone when the link is refused.
pub fn linked(
  body : String,
  url : String,
  id : String,
  links : Array[@types.LinkInfo],
  options : @types.RenderOptions,
  attrs~ : String = "",
) -> String {
  guard link_url(url, options) is Some(href) else { return body }
  links.push({ id, href, internal: false, })
  "<a href=\"\{@svg.esc(href)}\"\{attrs}\{rel_attr(options)}>\{body}</a>"
}

///|
/// The ` rel` attribute that anchors carry, empty when the host sets no rel.
pub fn rel_attr(options : @types.RenderOptions) -> String {
  let rel = options.link_rel.unwrap_or("noopener")
  if rel == "" {
    ""
  } else {
    " rel=\"\{@svg.esc(rel)}\""
  }
}
