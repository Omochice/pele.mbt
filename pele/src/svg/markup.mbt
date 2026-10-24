///|
/// The most code units the port holds while it builds a drawing.
/// The port holds the pieces, the string it makes of them and the answer's bytes at once, and a
/// drawing much longer than this would outgrow wasm's 4 GiB of memory while it does.
pub const HOLD_LIMIT : Int32 = 400000000

///|
/// The code units of small writes gathered into one piece.
const CHUNK_LENGTH : Int32 = 65536

///|
/// The shortest write kept as a piece of its own rather than copied.
const SHARED_LENGTH : Int32 = 1024

///|
/// SVG markup put together piece by piece, as pele concatenates it.
/// It keeps its pieces apart until it is turned into a string, because a `StringBuilder` doubles
/// its buffer and wasm's allocator refuses the block of 1 GiB that would follow 2^28 code units,
/// while a string allocated at its final size can be as long as the hold limit.
/// Past `HOLD_LIMIT` it drops its pieces and only counts, because holding, materializing and
/// answering with markup that long would outgrow wasm's memory; `markup_document` reports the
/// `limit` error for markup that is no longer held.
/// It counts in 64 bits, since markup that is only counted can pass what 32 bits hold.
struct Markup {
  mut pieces : Array[String]
  mut tail : StringBuilder
  mut tail_length : Int32
  mut length : Int64
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
/// The length of the markup in UTF-16 code units.
pub fn Markup::length(self : Markup) -> Int64 {
  self.length
}

///|
/// Whether nothing has been written.
pub fn Markup::is_empty(self : Markup) -> Bool {
  self.length == 0
}

///|
fn Markup::lengthen(self : Markup, count : Int64) -> Unit {
  self.length += count
  // Dropping the pieces frees them under reference counting, so holding never passes `HOLD_LIMIT`.
  if self.held && self.length > HOLD_LIMIT.to_int64() {
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
pub fn Markup::write(self : Markup, piece : String) -> Unit {
  self.lengthen(piece.length().to_int64())
  add_aliases(self.used, piece)
  self.append(piece)
}

///|
/// Appends `other`, sharing its pieces rather than copying them.
pub fn Markup::write_markup(self : Markup, other : Markup) -> Unit {
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
pub fn Markup::write_group(
  self : Markup,
  start : String,
  section : Markup,
  end : String,
) -> Unit {
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
/// Aborts for markup the port no longer holds, which `markup_document` leaves as a stand-in instead.
pub fn Markup::to_string(self : Markup) -> String {
  guard self.held else { abort("SVG markup past the port's hold limit") }
  let out = exact_builder(self.length.to_int())
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
/// Every held document begins with its root element, so one that begins with `UNHELD` is a stand-in.
pub fn is_held_document(document : String) -> Bool {
  !document.has_prefix(UNHELD)
}

///|
/// What a stand-in for a document the port does not hold begins with, which no drawing does.
const UNHELD : String = "\u{0}"

///|
/// The stand-in for a document of `length` code units that the port does not hold, which gives
/// the length in decimal after `UNHELD`.
fn unheld_document(length : Int64) -> String {
  UNHELD + length.to_string()
}

///|
/// The length in UTF-16 code units of the drawing a document from `markup_document` stands for,
/// whether the port holds it or not.
pub fn document_length(document : String) -> Int64 {
  if is_held_document(document) {
    return document.length().to_int64()
  }
  let mut length = 0L
  for i in UNHELD.length()..<document.length() {
    length = length * 10 + (document.unsafe_get(i).to_int() - '0').to_int64()
  }
  length
}

///|
/// Wraps diagram content in the root `svg` element, with its accessible name and description,
/// its theme aliases, and its fonts.
/// A document longer than the port can hold is left as a stand-in that only gives its length, for
/// `is_held_document` to tell apart and `document_length` to measure.
pub fn markup_document(
  kind : String,
  width : Double,
  height : Double,
  font_size : Double,
  options : @types.RenderOptions,
  acc_title : String?,
  acc_descr : String?,
  content : Markup,
) -> String {
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
  // Failing here would refuse a drawing that is only measured, as a diagram drawn again to fit a
  // narrow host measures its first drawing, where pele goes on to draw the next one.
  let length = start.length().to_int64() + body.length + end.length().to_int64()
  if !body.held {
    return unheld_document(length)
  }
  let out = exact_builder(length.to_int())
  out.write_string(start)
  body.write_to(out)
  out.write_string(end)
  out.to_string()
}
