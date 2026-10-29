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
/// Stricter than Mermaid, which lets any scheme but three through: a diagram in a shared note could otherwise open a local file, a network share, or another application.
fn allowed(url : String, schemes : Array[String]) -> Bool {
  if is_slash(@util.code_at(url, 0)) && is_slash(@util.code_at(url, 1)) {
    return false
  }
  match scheme_name(url) {
    None => true
    Some(scheme) => schemes.contains(scheme.to_lower())
  }
}

///|
/// The decoded URL is checked too, for an app that decodes the href before opening it.
fn allow(url : String, schemes : Array[String]) -> String? {
  guard unwrap(url, percent=true) is Some(decoded) &&
    allowed(url, schemes) &&
    allowed(decoded, schemes) else {
    return None
  }
  Some(url)
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
/// Whether a note `name` may be the `href` of an internal link, which keeps the name as written.
/// Sanitizing alone is not enough, so the name is also checked as a browser reads it once
/// escaping has dropped the characters XML does not allow.
pub fn internal_link(name : String, options : @types.RenderOptions) -> Bool {
  let url = sanitize_url(name)
  if url == blank || link_url(url, options) is None {
    return false
  }
  let seen = StringBuilder()
  let kept = @svg.without_invalid_xml(name)
  for i in 0..<kept.length() {
    match kept.unsafe_get(i).to_int() {
      '\t' | '\n' | '\r' => ()
      _ => @util.write_range(seen, kept, i, i + 1)
    }
  }
  let seen = seen.to_string()
  let mut start = 0
  while start < seen.length() && seen.unsafe_get(start).to_int() <= 0x20 {
    start += 1
  }
  link_url(@util.slice(seen, start), options) is Some(_)
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
  match link_start(url, id, links, options, attrs~) {
    Some(start) => start + body + "</a>"
    None => body
  }
}

///|
/// The start tag of the anchor `linked` wraps a body in, with the link recorded in `links`, or
/// `None` when the link is refused.
pub fn link_start(
  url : String,
  id : String,
  links : Array[@types.LinkInfo],
  options : @types.RenderOptions,
  attrs~ : String = "",
) -> String? {
  guard link_url(url, options) is Some(href) else { return None }
  links.push({ id, href, internal: false, })
  Some("<a href=\"\{@svg.esc(href)}\"\{attrs}\{rel_attr(options)}>")
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

///|
/// Writes the start tag of the anchor `link_start` makes to `out`, with the address escaped a
/// piece at a time, and records the link in `links`.
/// An address of tens of millions of `&` escapes to more than a doubling StringBuilder holds.
/// Returns whether the anchor was started, which it is not when the link is refused.
pub fn write_link_start(
  out : @svg.Markup,
  url : String,
  id : String,
  links : Array[@types.LinkInfo],
  options : @types.RenderOptions,
  attrs~ : String = "",
) -> Bool {
  guard link_url(url, options) is Some(href) else { return false }
  links.push({ id, href, internal: false, })
  out.write("<a href=\"")
  out.write_esc(href)
  out.write("\"\{attrs}\{rel_attr(options)}>")
  true
}
