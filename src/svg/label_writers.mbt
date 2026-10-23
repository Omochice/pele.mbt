///|
/// Writes a measured label as `write_label` does under the attributes `attrs` followed by the
/// `style` attribute `resolve_style` makes of `css`, which is escaped a piece at a time.
/// Math under such a label takes its color from the attributes written whole, so a label with
/// math still escapes all of `css` at once.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_label_styled(
  out : Markup,
  label : @text.Label,
  cx : Double,
  cy : Double,
  attrs : String,
  css : String,
  icons? : @types.IconResolver,
) -> Unit raise @errors.PeleError {
  write_label_parts(
    out,
    label,
    cx,
    cy,
    out => {
      out.write(attrs)
      write_style(out, css)
    },
    // An escaped style holds no `"`, so it neither holds nor completes ` font-weight="` or
    // ` font-style="`.
    () => attrs.contains(" font-weight=\""),
    () => attrs.contains(" font-style=\""),
    () => attrs + attribute(css),
    icons?,
  )
}

///|
/// Writes a measured label as `write_label_styled` does under the attributes `before`, the id
/// `esc_text` makes of `id`, and `after`, escaping the id a piece at a time as well.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_label_with_id(
  out : Markup,
  label : @text.Label,
  cx : Double,
  cy : Double,
  before : String,
  id : String,
  after : String,
  css : String,
  icons? : @types.IconResolver,
) -> Unit raise @errors.PeleError {
  let attrs = before + after
  write_label_parts(
    out,
    label,
    cx,
    cy,
    out => {
      out.write(before)
      write_esc_text(out, id)
      out.write(after)
      write_style(out, css)
    },
    () => attrs.contains(" font-weight=\""),
    () => attrs.contains(" font-style=\""),
    () => attrs + attribute(css),
    icons?,
  )
}
