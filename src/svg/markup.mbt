///|
/// The longest string V8 makes on a 64-bit host, in UTF-16 code units, as node's
/// `buffer.constants.MAX_STRING_LENGTH` gives it.
/// pele builds its SVG by concatenation, which throws a `RangeError` past this length, and pele
/// reports that as a diagram nested too deeply.
pub const MAX_STRING_LENGTH : Int32 = 536870888

///|
/// The most code units a `StringBuilder` holds in wasm.
/// Growing it further asks the allocator for a block of 1 GiB, which the allocator refuses with a trap.
const HELD_LENGTH : Int32 = 268435456

///|
/// SVG markup put together piece by piece, as pele concatenates it.
/// It fails as pele does where V8 could not hold the markup, and past what a `StringBuilder` can
/// hold it only counts, so that failure is found without trapping on an allocation.
struct Markup {
  mut buf : StringBuilder
  mut length : Int32
  mut held : Bool
  used : Set[String]
}

///|
/// Empty markup.
pub fn Markup::new() -> Markup {
  { buf: StringBuilder(), length: 0, held: true, used: Set([]), }
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
  if self.held && self.length > HELD_LENGTH {
    self.held = false
    self.buf = StringBuilder()
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
  if self.held {
    self.buf.write_string(piece)
  }
}

///|
/// Appends `other`.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn Markup::write_markup(
  self : Markup,
  other : Markup,
) -> Unit raise @errors.PeleError {
  self.lengthen(other.length)
  for token in other.used {
    self.used.add(token)
  }
  // Markup that is no longer held is longer than `HELD_LENGTH`, so `lengthen` has dropped this one too.
  if self.held {
    self.buf.write_string(other.buf.to_string())
  }
}

///|
/// The markup as a string.
/// Aborts when it is longer than a `StringBuilder` can hold.
pub fn Markup::to_string(self : Markup) -> String {
  guard self.held else { abort("SVG markup longer than wasm can hold") }
  self.buf.to_string()
}

///|
/// Wraps diagram content in the root `svg` element as `svg_document` does.
/// Raises pele's `limit` error, before concatenating, when the document would be longer than V8 allows.
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
  let start = document_start(
    kind,
    width,
    height,
    font_size,
    options,
    acc_title,
    acc_descr,
    content.used,
  )
  let end = "</svg>"
  if start.length() + end.length() > MAX_STRING_LENGTH - content.length {
    raise @errors.nested_too_deeply()
  }
  start + content.to_string() + end
}
