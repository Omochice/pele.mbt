///|
/// The inside of a JSON string, as UTF-8, counted or written straight into a block of bytes.
/// It escapes as `Json::stringify` does and encodes as `@utf8.encode` does, so the answer holds
/// the bytes it held when the SVG was first put into a JSON string and that into bytes, without
/// either copy.
priv struct JsonText {
  /// The block written into, or an empty one while only counting.
  out : FixedArray[Byte]
  /// The offset of the next byte, which is the number of bytes counted when only counting.
  mut at : Int64
  /// A leading surrogate waiting for the code unit after it, or -1.
  mut lead : Int32
}

///|
/// Text that only counts its bytes.
fn JsonText::counter() -> JsonText {
  { out: [], at: 0, lead: -1, }
}

///|
/// Text written into `out` from `at`.
fn JsonText::writer(out : FixedArray[Byte], at : Int32) -> JsonText {
  { out, at: at.to_int64(), lead: -1, }
}

///|
fn JsonText::byte(self : JsonText, value : Int32) -> Unit {
  if self.out.length() > 0 {
    self.out[self.at.to_int()] = value.to_byte()
  }
  self.at += 1
}

///|
fn JsonText::ascii(self : JsonText, text : String) -> Unit {
  for i in 0..<text.length() {
    self.byte(text.unsafe_get(i).to_int())
  }
}

///|
fn hex_digit(value : Int32) -> Int32 {
  if value < 10 {
    '0' + value
  } else {
    'a' + value - 10
  }
}

///|
fn JsonText::unit(self : JsonText, code : Int32) -> Unit {
  if self.lead >= 0 {
    guard code >= 0xdc00 && code <= 0xdfff else {
      abort("a leading surrogate without its trailing one")
    }
    let scalar = ((self.lead - 0xd800) << 10) + (code - 0xdc00) + 0x10000
    self.byte(0xf0 | (scalar >> 18))
    self.byte(0x80 | ((scalar >> 12) & 0x3f))
    self.byte(0x80 | ((scalar >> 6) & 0x3f))
    self.byte(0x80 | (scalar & 0x3f))
    self.lead = -1
    return
  }
  match code {
    '"' => self.ascii("\\\"")
    '\\' => self.ascii("\\\\")
    '\n' => self.ascii("\\n")
    '\r' => self.ascii("\\r")
    '\b' => self.ascii("\\b")
    '\t' => self.ascii("\\t")
    0x0c => self.ascii("\\f")
    _ if code < 0x20 => {
      self.ascii("\\u00")
      self.byte(hex_digit(code >> 4))
      self.byte(hex_digit(code & 0xf))
    }
    _ if code < 0x80 => self.byte(code)
    _ if code < 0x800 => {
      self.byte(0xc0 | (code >> 6))
      self.byte(0x80 | (code & 0x3f))
    }
    _ if code >= 0xd800 && code <= 0xdbff => self.lead = code
    _ if code >= 0xdc00 && code <= 0xdfff =>
      abort("a trailing surrogate without its leading one")
    _ => {
      self.byte(0xe0 | (code >> 12))
      self.byte(0x80 | ((code >> 6) & 0x3f))
      self.byte(0x80 | (code & 0x3f))
    }
  }
}

///|
/// Ends the text, which must not stop between the two halves of a surrogate pair.
fn JsonText::finish(self : JsonText) -> Unit {
  if self.lead >= 0 {
    abort("a leading surrogate without its trailing one")
  }
}

///|
impl Logger for JsonText with fn write_view(self, view) {
  let data = view.data()
  let start = view.start_offset()
  for i in start..<(start + view.length()) {
    self.unit(data.unsafe_get(i).to_int())
  }
}

///|
impl Logger for JsonText with fn write_string(self, text) {
  Logger::write_view(self, text.view())
}

///|
impl Logger for JsonText with fn write_char(self, c) {
  Logger::write_string(self, c.to_string())
}
