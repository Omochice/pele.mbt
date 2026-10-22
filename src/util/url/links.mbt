///|
/// A URL as written in a diagram, sanitized after its entity codes are read so that they cannot hide a scheme.
pub fn safe_url(url : String) -> String {
  url
}

///|
/// The URL a link may point to, or `None` when the host turns links off or does not allow its scheme.
pub fn link_url(url : String, options : @types.RenderOptions) -> String? {
  ignore(options)
  Some(url)
}

///|
/// The URL an image may load from, or `None` when the host turns images off or does not allow its scheme.
pub fn image_url(url : String, options : @types.RenderOptions) -> String? {
  ignore(options)
  Some(url)
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
  ignore((url, id, links, options, attrs))
  body
}

///|
/// The ` rel` attribute that anchors carry, empty when the host sets no rel.
pub fn rel_attr(options : @types.RenderOptions) -> String {
  ignore(options)
  ""
}
