///|
/// The longest string V8 makes on a 64-bit host, in UTF-16 code units, as node's
/// `buffer.constants.MAX_STRING_LENGTH` gives it.
/// pele builds its SVG by concatenation, which throws a `RangeError` past this length, and pele
/// reports that as a diagram nested too deeply.
pub const MAX_STRING_LENGTH : Int32 = 536870888

///|
/// The most code units the port holds while it builds a drawing, below the length a `String`
/// could reach, because the port holds the pieces, the string it makes of them and the answer's
/// bytes at once, which near V8's longest string would outgrow wasm's 4 GiB of memory.
/// pele draws up to V8's longest string; the port stops here, which is its one platform-imposed
/// difference from pele.
pub const HOLD_LIMIT : Int32 = 400000000

///|
/// The code units of small writes gathered into one piece.
const CHUNK_LENGTH : Int32 = 65536

///|
/// The shortest write kept as a piece of its own rather than copied.
const SHARED_LENGTH : Int32 = 1024

///|
/// SVG markup put together piece by piece, as pele concatenates it.
/// It fails as pele does where V8 could not hold the markup.
/// It keeps its pieces apart until it is turned into a string, because a `StringBuilder` doubles
/// its buffer and wasm's allocator refuses the block of 1 GiB that would follow 2^28 code units,
/// while a string allocated at its final size can be as long as V8's longest.
/// Past `HOLD_LIMIT` it drops its pieces and only counts, because holding, materializing and
/// answering with markup that long would outgrow wasm's memory; `markup_document` reports the
/// `limit` error for markup that is no longer held.
struct Markup {
  mut pieces : Array[String]
  mut tail : StringBuilder
  mut tail_length : Int32
  mut length : Int32
  mut held : Bool
  used : Set[String]
}

///|
/// Empty markup.
pub fn Markup::new() -> Markup {
  {
    pieces: [],
    tail: StringBuilder(),
    tail_length: 0,
    length: 0,
    held: true,
    used: Set([]),
  }
}

///|
/// Whether the markup still holds its pieces, which it does up to `HOLD_LIMIT`.
pub fn Markup::is_held(self : Markup) -> Bool {
  self.held
}

///|
/// The length of the markup in UTF-16 code units.
pub fn Markup::length(self : Markup) -> Int32 {
  self.length
}

///|
/// Whether nothing has been written.
pub fn Markup::is_empty(self : Markup) -> Bool {
  self.length == 0
}

///|
fn Markup::lengthen(
  self : Markup,
  count : Int32,
) -> Unit raise @errors.PeleError {
  if count > MAX_STRING_LENGTH - self.length {
    raise @errors.nested_too_deeply()
  }
  self.length += count
  // Dropping the pieces frees them under reference counting, so holding never passes `HOLD_LIMIT`.
  if self.held && self.length > HOLD_LIMIT {
    self.held = false
    self.pieces = []
    self.tail = StringBuilder()
    self.tail_length = 0
  }
}

///|
fn Markup::flush(self : Markup) -> Unit {
  if self.tail_length > 0 {
    self.pieces.push(self.tail.to_string())
    self.tail = StringBuilder()
    self.tail_length = 0
  }
}

///|
fn Markup::append(self : Markup, piece : String) -> Unit {
  if !self.held {
    return
  }
  if piece.length() >= SHARED_LENGTH {
    self.flush()
    self.pieces.push(piece)
    return
  }
  self.tail.write_string(piece)
  self.tail_length += piece.length()
  if self.tail_length >= CHUNK_LENGTH {
    self.flush()
  }
}

///|
/// Appends `piece`.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn Markup::write(
  self : Markup,
  piece : String,
) -> Unit raise @errors.PeleError {
  self.lengthen(piece.length())
  add_aliases(self.used, piece)
  self.append(piece)
}

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
/// Appends `other`, sharing its pieces rather than copying them.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn Markup::write_markup(
  self : Markup,
  other : Markup,
) -> Unit raise @errors.PeleError {
  self.lengthen(other.length)
  for token in other.used {
    self.used.add(token)
  }
  for piece in other.pieces {
    self.append(piece)
  }
  if other.tail_length > 0 {
    self.append(other.tail.to_string())
  }
}

///|
/// Appends `section` between `start` and `end`, as a group of markup is written.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn Markup::write_group(
  self : Markup,
  start : String,
  section : Markup,
  end : String,
) -> Unit raise @errors.PeleError {
  self.write(start)
  self.write_markup(section)
  self.write(end)
}

///|
fn Markup::write_to(self : Markup, out : StringBuilder) -> Unit {
  for piece in self.pieces {
    out.write_string(piece)
  }
  if self.tail_length > 0 {
    out.write_string(self.tail.to_string())
  }
}

///|
/// A builder that holds exactly `length` code units, which turns into a string without a copy
/// once it is full.
fn exact_builder(length : Int32) -> StringBuilder {
  StringBuilder(size_hint=length * 2)
}

///|
/// The markup as a string.
/// Aborts for markup the port no longer holds, which `markup_document` leaves empty instead.
pub fn Markup::to_string(self : Markup) -> String {
  guard self.held else { abort("SVG markup past the port's hold limit") }
  let out = exact_builder(self.length)
  self.write_to(out)
  out.to_string()
}

///|
/// The `limit` error for a drawing the port cannot hold, naming its hold limit.
pub fn too_large_to_hold() -> @errors.PeleError {
  @errors.pele_error(
    "Diagram output is too large for the wasm port: it would hold more than \{HOLD_LIMIT} code units, the most the port can hold at once.",
    code=Limit,
  )
}

///|
/// Whether a document from `markup_document` holds its drawing, which one longer than the port can
/// hold does not, though a diagram drawn more than once may still measure it.
/// Every held document has its root element, so only one that is not held is empty.
pub fn is_held_document(document : String) -> Bool {
  !document.is_empty()
}

///|
/// Wraps diagram content in the root `svg` element as `svg_document` does.
/// Raises pele's `limit` error, before concatenating, when the document would be longer than V8
/// allows.
/// A document longer than the port can hold is left empty, for `is_held_document` to tell apart.
pub fn markup_document(
  kind : String,
  width : Double,
  height : Double,
  font_size : Double,
  options : @types.RenderOptions,
  acc_title : String?,
  acc_descr : String?,
  content : Markup,
) -> String raise @errors.PeleError {
  let start = document_tag(
    kind,
    width,
    height,
    font_size,
    options,
    acc_title,
    acc_descr,
    content.used,
  )
  // The accessible text is held with the content, because it grows with the source as the
  // content does, while the start tag and the end are bounded.
  let body = Markup::new()
  write_document_head(body, options, acc_title, acc_descr)
  body.write_markup(content)
  let end = "</svg>"
  if start.length() + end.length() > MAX_STRING_LENGTH - body.length {
    raise @errors.nested_too_deeply()
  }
  // Failing here would refuse a drawing that is only measured, as a diagram drawn again to fit a
  // narrow host measures its first drawing, where pele goes on to draw the next one.
  if !body.held {
    return ""
  }
  let out = exact_builder(start.length() + body.length + end.length())
  out.write_string(start)
  body.write_to(out)
  out.write_string(end)
  out.to_string()
}
