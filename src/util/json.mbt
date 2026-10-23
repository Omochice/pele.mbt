///|
/// JSON text that `JSON.parse` rejects: V8's message and the offset its parser stopped at.
pub(all) suberror JsonError {
  JsonError(String, Int32)
}

///|
/// A container being read: an object with the key whose value comes next, or an array.
priv struct JsonFrame {
  object : Map[String, Json]?
  items : Array[Json]
  mut key : String
}

///|
priv struct JsonReader {
  text : String
  mut at : Int32
}

///|
fn JsonReader::peek(self : JsonReader) -> Int32 {
  code_at(self.text, self.at)
}

///|
fn JsonReader::skip_whitespace(self : JsonReader) -> Unit {
  while self.at < self.text.length() {
    let c = self.peek()
    if c != 32 && c != 9 && c != 10 && c != 13 {
      return
    }
    self.at += 1
  }
}

///|
/// Whether `c` comes next after any whitespace, consuming it when it does.
fn JsonReader::check(self : JsonReader, c : Int32) -> Bool {
  self.skip_whitespace()
  if self.peek() == c {
    self.at += 1
    true
  } else {
    false
  }
}

///|
fn JsonReader::expect(
  self : JsonReader,
  c : Int32,
  message : String,
) -> Unit raise JsonError {
  if self.peek() == c {
    self.at += 1
  } else {
    self.fail(message)
  }
}

///|
fn JsonReader::expect_next(
  self : JsonReader,
  c : Int32,
  message : String,
) -> Unit raise JsonError {
  self.skip_whitespace()
  self.expect(c, message)
}

///|
/// V8's messages that name the position, with the line and column it counts itself.
fn[T] JsonReader::fail(
  self : JsonReader,
  message : String,
) -> T raise JsonError {
  let pos = self.at
  let mut line = 1
  let mut line_start = 0
  let mut k = 0
  while k < pos {
    let c = code_at(self.text, k)
    if c == 13 && k < pos - 1 && code_at(self.text, k + 1) == 10 {
      k += 1
    }
    let c = code_at(self.text, k)
    if c == 13 || c == 10 {
      line += 1
      line_start = k + 1
    }
    k += 1
  }
  raise JsonError(
    "\{message} at position \{pos} (line \{line} column \{pos - line_start + 1})",
    pos,
  )
}

///|
/// What V8 says of a character it did not expect: the end of the text, a number or string that
/// cannot start there, or any other character quoted with the text around it.
fn[T] JsonReader::unexpected(self : JsonReader) -> T raise JsonError {
  let text = self.text
  let pos = self.at
  let c = self.peek()
  if c == -1 {
    raise JsonError("Unexpected end of JSON input", pos)
  }
  if c == 45 || is_digit(c) {
    self.fail("Unexpected number in JSON")
  }
  if c == 34 {
    self.fail("Unexpected string in JSON")
  }
  let token = slice(text, pos, end=pos + 1)
  let length = text.length()
  let context = if length < 21 {
    "\"\{text}\""
  } else if pos < 10 {
    "\"\{slice(text, 0, end=pos + 10)}\"..."
  } else if pos < length - 10 {
    "...\"\{slice(text, pos - 10, end=pos + 10)}\"..."
  } else {
    "...\"\{slice(text, pos - 10)}\""
  }
  raise JsonError(
    "Unexpected token '\{token}', \{context} is not valid JSON",
    pos,
  )
}

///|
/// The rest of a literal whose first character matched.
fn JsonReader::literal(
  self : JsonReader,
  word : String,
) -> Unit raise JsonError {
  let remaining = self.text.length() - self.at
  if remaining >= word.length() && starts_with_at(self.text, word, self.at) {
    self.at += word.length()
    return
  }
  self.at += 1
  for i in 1..<@cmp.minimum(word.length(), remaining) {
    if self.peek() != word.unsafe_get(i).to_int() {
      self.unexpected()
    }
    self.at += 1
  }
  self.unexpected()
}

///|
fn JsonReader::digits(self : JsonReader) -> Unit {
  while is_digit(self.peek()) {
    self.at += 1
  }
}

///|
fn JsonReader::number(self : JsonReader) -> Double raise JsonError {
  let start = self.at
  if self.peek() == 45 {
    self.at += 1
  }
  if self.peek() == 48 {
    self.at += 1
    // A leading zero may only be followed by a fraction or an exponent.
    if is_digit(self.peek()) {
      self.unexpected()
    }
  } else {
    let first = self.at
    self.digits()
    if self.at == first {
      self.fail("No number after minus sign in JSON")
    }
  }
  if self.peek() == 46 {
    self.at += 1
    if !is_digit(self.peek()) {
      self.fail("Unterminated fractional number in JSON")
    }
    self.digits()
  }
  if (self.peek() | 32) == 101 {
    self.at += 1
    if self.peek() == 43 || self.peek() == 45 {
      self.at += 1
    }
    if !is_digit(self.peek()) {
      self.fail("Exponent part is missing a number in JSON")
    }
    self.digits()
  }
  parse_float(slice(self.text, start, end=self.at))
}

///|
/// The rest of a string whose opening quote was read.
fn JsonReader::string(self : JsonReader) -> String raise JsonError {
  let out = StringBuilder()
  while true {
    let c = self.peek()
    if c == -1 {
      self.fail("Unterminated string in JSON")
    }
    if c == 34 {
      self.at += 1
      break
    }
    if c < 0x20 {
      self.fail("Bad control character in string literal in JSON")
    }
    if c != 92 {
      out.write_char(self.text.unsafe_get(self.at).unsafe_to_char())
      self.at += 1
      continue
    }
    self.at += 1
    let escape = self.peek()
    if escape == -1 || escape > 0xff {
      self.unexpected()
    }
    match escape {
      34 | 92 | 47 => out.write_char(escape.unsafe_to_char())
      98 => out.write_char('\b')
      102 => out.write_char('\u{0c}')
      110 => out.write_char('\n')
      114 => out.write_char('\r')
      116 => out.write_char('\t')
      117 => {
        let mut unit = 0
        for _ in 0..<4 {
          self.at += 1
          let c = self.peek()
          let digit = if is_digit(c) {
            c - 48
          } else if c >= 65 && c <= 70 {
            c - 55
          } else if c >= 97 && c <= 102 {
            c - 87
          } else {
            self.fail("Bad Unicode escape in JSON")
          }
          unit = unit * 16 + digit
        }
        out.write_char(unit.unsafe_to_char())
      }
      _ => self.fail("Bad escaped character in JSON")
    }
    self.at += 1
  }
  out.to_string()
}

///|
fn JsonReader::key(
  self : JsonReader,
  frame : JsonFrame,
  message : String,
) -> Unit raise JsonError {
  self.expect_next(34, message)
  frame.key = self.string()
  self.expect_next(58, "Expected ':' after property name in JSON")
}

///|
/// Nesting is kept on a stack of its own, so depth is limited by memory and not by the call stack.
fn JsonReader::document(self : JsonReader) -> Json raise JsonError {
  let stack : Array[JsonFrame] = []
  while true {
    let mut value = Json::null()
    while true {
      self.skip_whitespace()
      match self.peek() {
        34 => {
          self.at += 1
          value = Json::string(self.string())
        }
        123 => {
          self.at += 1
          if self.check(125) {
            value = Json::object(Map([]))
          } else {
            let frame = { object: Some(Map([])), items: [], key: "", }
            stack.push(frame)
            self.key(frame, "Expected property name or '}' in JSON")
            continue
          }
        }
        91 => {
          self.at += 1
          if self.check(93) {
            value = Json::array([])
          } else {
            stack.push({ object: None, items: [], key: "", })
            continue
          }
        }
        116 => {
          self.literal("true")
          value = Json::boolean(true)
        }
        102 => {
          self.literal("false")
          value = Json::boolean(false)
        }
        110 => {
          self.literal("null")
          value = Json::null()
        }
        c if c == 45 || is_digit(c) => value = Json::number(self.number())
        _ => self.unexpected()
      }
      break
    }
    while true {
      guard stack.last() is Some(frame) else { return value }
      match frame.object {
        // A key written more than once keeps its first place and takes its last value.
        Some(object) => {
          object[frame.key] = value
          if self.check(44) {
            self.key(frame, "Expected double-quoted property name in JSON")
            break
          }
          value = Json::object(object)
          self.expect(125, "Expected ',' or '}' after property value in JSON")
        }
        None => {
          frame.items.push(value)
          if self.check(44) {
            break
          }
          value = Json::array(frame.items)
          self.expect(93, "Expected ',' or ']' after array element in JSON")
        }
      }
      stack.pop() |> ignore
    }
  }
  Json::null()
}

///|
/// Reads JSON text as V8's `JSON.parse` does, except that object keys stay in the order they were first written.
/// Raises `JsonError` with V8's message where V8 rejects the text.
pub fn parse_json(text : String) -> Json raise JsonError {
  let reader = { text, at: 0, }
  let value = reader.document()
  reader.skip_whitespace()
  if reader.at < text.length() {
    reader.fail("Unexpected non-whitespace character after JSON")
  }
  value
}
