///|
/// Writes the start tag of the anchor `link_start` makes to `out`, with the address escaped a
/// piece at a time, and records the link in `links`.
/// An address of tens of millions of `&` escapes to more than a doubling StringBuilder holds.
/// Returns whether the anchor was started, which it is not when the link is refused.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_link_start(
  out : @svg.Markup,
  url : String,
  id : String,
  links : Array[@types.LinkInfo],
  options : @types.RenderOptions,
  attrs~ : String = "",
) -> Bool raise @errors.PeleError {
  guard link_url(url, options) is Some(href) else { return false }
  links.push({ id, href, internal: false, })
  out.write("<a href=\"")
  @svg.write_esc(out, href)
  out.write("\"\{attrs}\{rel_attr(options)}>")
  true
}
