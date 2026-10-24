///|
/// Writes `text` to `out` escaped as `esc` escapes it, a piece at a time, so that text whose
/// escaped form is longer than a StringBuilder grows to is written rather than trapping.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_esc(out : Markup, text : String) -> Unit raise @errors.PeleError {
  out.write_esc(text)
}

///|
/// Writes `text` to `out` escaped as `esc_text` escapes it, a piece at a time.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_esc_text(
  out : Markup,
  text : String,
) -> Unit raise @errors.PeleError {
  write_esc(out, @text.decode_entities(text))
}

///|
/// Writes ` data-id="…"` with `id` escaped as `esc_text` escapes it, a piece at a time.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_data_id(out : Markup, id : String) -> Unit raise @errors.PeleError {
  out.write(" data-id=\"")
  write_esc_text(out, id)
  out.write("\"")
}
