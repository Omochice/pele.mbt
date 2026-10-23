///|
/// The code units of text escaped into one piece, whose escaped form stays far below what a
/// doubling StringBuilder holds.
const ESCAPE_CHUNK : Int32 = 1048576

///|
/// How far before a chunk's end a cut is looked for.
const CUT_REACH : Int32 = 64

///|
/// The code units of the private aliases `var(--_r)`, `var(--_tw)`, `var(--_hw)` and `var(--_w)`.
const ALIAS_UNITS : String = "var(--_twh)"

///|
/// Whether a cut after `c` could split a private alias, which `Markup` finds only within a piece.
/// A control character counts, because escaping drops it and so joins what is around it.
fn in_alias(c : Int32) -> Bool {
  for i in 0..<ALIAS_UNITS.length() {
    if ALIAS_UNITS.unsafe_get(i).to_int() == c {
      return true
    }
  }
  is_xml_forbidden(c)
}

///|
/// Where to end the chunk of `text` from `start`, at a code unit no alias runs across.
fn chunk_end(text : String, start : Int32) -> Int32 {
  let end = start + ESCAPE_CHUNK
  if end >= text.length() {
    return text.length()
  }
  for at = end; at > end - CUT_REACH; at = at - 1 {
    if !in_alias(@util.code_at(text, at - 1)) {
      return at
    }
  }
  end
}

///|
/// Writes `text` to `out` escaped as `esc` escapes it, a piece at a time, so that text whose
/// escaped form is longer than a StringBuilder grows to is written rather than trapping.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_esc(out : Markup, text : String) -> Unit raise @errors.PeleError {
  if text.length() <= ESCAPE_CHUNK {
    out.write(esc(text))
    return
  }
  let mut start = 0
  while start < text.length() {
    let end = chunk_end(text, start)
    out.write(esc(@util.slice(text, start, end~)))
    start = end
  }
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
