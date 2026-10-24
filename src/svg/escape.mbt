///|
/// The longest alias `add_aliases` finds, `var(--_tw)`, less one code unit: the most of one piece
/// an alias split across two pieces can lie in.
const ALIAS_OVERLAP : Int32 = 9

///|
/// Appends `text` escaped as `esc` escapes it.
/// It escapes a piece of `text` at a time, because escaping all of it at once would make a
/// string up to five times as long, past what a doubling `StringBuilder` holds.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn Markup::write_esc(
  self : Markup,
  text : String,
) -> Unit raise @errors.PeleError {
  if text.length() <= CHUNK_LENGTH {
    self.write(esc(text))
    return
  }
  let mut from = 0
  let mut carry = ""
  while from < text.length() {
    let to = from + CHUNK_LENGTH
    let piece = esc(@util.slice(text, from, end=to))
    self.lengthen(piece.length())
    // Escaping drops control characters, so an alias can be split by one in `text` and whole in
    // the markup; the pieces are therefore searched as escaped, with the end of the one before.
    let searched = carry + piece
    add_aliases(self.used, searched)
    carry = @util.slice(searched, -ALIAS_OVERLAP)
    self.append(piece)
    from = to
  }
}

///|
/// Appends `text` escaped as `esc_text` escapes it, a piece at a time.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn Markup::write_esc_text(
  self : Markup,
  text : String,
) -> Unit raise @errors.PeleError {
  self.write_esc(@text.decode_entities(text))
}

///|
/// Appends ` data-id="…"` with `id` escaped as `esc_text` escapes it, a piece at a time.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn Markup::write_data_id(
  self : Markup,
  id : String,
) -> Unit raise @errors.PeleError {
  self.write(" data-id=\"")
  self.write_esc_text(id)
  self.write("\"")
}
