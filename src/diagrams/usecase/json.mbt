///|
/// A value of a `json` node, with the keys of each object in the order they were first written.
pub(all) enum JsonValue {
  JsonNull
  JsonBool(Bool)
  JsonNumber(Double)
  JsonString(String)
  JsonArray(Array[JsonValue])
  /// A key written more than once keeps its first place and takes its last value, as `JSON.parse` does.
  JsonObject(Array[(String, JsonValue)])
}

///|
/// The message V8 gives and the offset its parser stopped at.
priv suberror BadJson {
  BadJson(String, Int32)
}

///|
/// A container being read: an object with the key whose value comes next, or an array.
priv struct Frame {
  object : Bool
  entries : Array[(String, JsonValue)]
  places : Map[String, Int32]
  items : Array[JsonValue]
  mut key : String
}

///|
/// Reads JSON as V8's `JSON.parse` does, keeping the order keys were written in, and fails where
/// and as V8 fails. pele parses with `JSON.parse` and then walks the text again for the key order;
/// one reader does both here.
priv struct Reader {
  text : String
  mut at : Int32
}

///|
fn Reader::peek(self : Reader) -> Int32 {
  @util.code_at(self.text, self.at)
}

///|
fn Reader::skip_whitespace(self : Reader) -> Unit {
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
fn Reader::check(self : Reader, c : Int32) -> Bool {
  self.skip_whitespace()
  if self.peek() == c {
    self.at += 1
    true
  } else {
    false
  }
}

///|
fn Reader::expect(
  self : Reader,
  c : Int32,
  message : String,
) -> Unit raise BadJson {
  if self.peek() == c {
    self.at += 1
  } else {
    self.fail(message)
  }
}

///|
fn Reader::expect_next(
  self : Reader,
  c : Int32,
  message : String,
) -> Unit raise BadJson {
  self.skip_whitespace()
  self.expect(c, message)
}

///|
/// V8's messages that name the position, with the line and column it counts itself.
fn[T] Reader::fail(self : Reader, message : String) -> T raise BadJson {
  let pos = self.at
  let mut line = 1
  let mut line_start = 0
  let mut k = 0
  while k < pos {
    let c = @util.code_at(self.text, k)
    if c == 13 && k < pos - 1 && @util.code_at(self.text, k + 1) == 10 {
      k += 1
    }
    let c = @util.code_at(self.text, k)
    if c == 13 || c == 10 {
      line += 1
      line_start = k + 1
    }
    k += 1
  }
  raise BadJson(
    "\{message} at position \{pos} (line \{line} column \{pos - line_start + 1})",
    pos,
  )
}

///|
/// What V8 says of a character it did not expect: the end of the text, a number or string that
/// cannot start there, or any other character quoted with the text around it.
fn[T] Reader::unexpected(self : Reader) -> T raise BadJson {
  let text = self.text
  let pos = self.at
  let c = self.peek()
  if c == -1 {
    raise BadJson("Unexpected end of JSON input", pos)
  }
  if c == 45 || @util.is_digit(c) {
    self.fail("Unexpected number in JSON")
  }
  if c == 34 {
    self.fail("Unexpected string in JSON")
  }
  let token = @util.slice(text, pos, end=pos + 1)
  let length = text.length()
  let context = if length < 21 {
    "\"\{text}\""
  } else if pos < 10 {
    "\"\{@util.slice(text, 0, end=pos + 10)}\"..."
  } else if pos < length - 10 {
    "...\"\{@util.slice(text, pos - 10, end=pos + 10)}\"..."
  } else {
    "...\"\{@util.slice(text, pos - 10)}\""
  }
  raise BadJson(
    "Unexpected token '\{token}', \{context} is not valid JSON",
    pos,
  )
}

///|
/// The rest of a literal whose first character matched.
fn Reader::literal(self : Reader, word : String) -> Unit raise BadJson {
  let remaining = self.text.length() - self.at
  if remaining >= word.length() &&
    @util.starts_with_at(self.text, word, self.at) {
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
fn Reader::digits(self : Reader) -> Unit {
  while @util.is_digit(self.peek()) {
    self.at += 1
  }
}

///|
fn Reader::number(self : Reader) -> Double raise BadJson {
  let start = self.at
  if self.peek() == 45 {
    self.at += 1
  }
  if self.peek() == 48 {
    self.at += 1
    // A leading zero may only be followed by a fraction or an exponent.
    if @util.is_digit(self.peek()) {
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
    if !@util.is_digit(self.peek()) {
      self.fail("Unterminated fractional number in JSON")
    }
    self.digits()
  }
  if (self.peek() | 32) == 101 {
    self.at += 1
    if self.peek() == 43 || self.peek() == 45 {
      self.at += 1
    }
    if !@util.is_digit(self.peek()) {
      self.fail("Exponent part is missing a number in JSON")
    }
    self.digits()
  }
  @util.parse_float(@util.slice(self.text, start, end=self.at))
}

///|
/// The rest of a string whose opening quote was read.
fn Reader::string(self : Reader) -> String raise BadJson {
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
          let digit = if @util.is_digit(c) {
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
fn Frame::put(self : Frame, value : JsonValue) -> Unit {
  match self.places.get(self.key) {
    Some(place) => self.entries[place] = (self.key, value)
    None => {
      self.places.set(self.key, self.entries.length())
      self.entries.push((self.key, value))
    }
  }
}

///|
fn Reader::key(
  self : Reader,
  frame : Frame,
  message : String,
) -> Unit raise BadJson {
  self.expect_next(34, message)
  frame.key = self.string()
  self.expect_next(58, "Expected ':' after property name in JSON")
}

///|
/// Nesting is kept on a stack of its own, so depth is limited by memory and not by the call stack.
fn Reader::document(self : Reader) -> JsonValue raise BadJson {
  let stack : Array[Frame] = []
  let open = (object : Bool) => {
    object,
    entries: [],
    places: Map([]),
    items: [],
    key: "",
  }
  while true {
    let mut value = JsonNull
    while true {
      self.skip_whitespace()
      match self.peek() {
        34 => {
          self.at += 1
          value = JsonString(self.string())
        }
        123 => {
          self.at += 1
          if self.check(125) {
            value = JsonObject([])
          } else {
            let frame = open(true)
            stack.push(frame)
            self.key(frame, "Expected property name or '}' in JSON")
            continue
          }
        }
        91 => {
          self.at += 1
          if self.check(93) {
            value = JsonArray([])
          } else {
            stack.push(open(false))
            continue
          }
        }
        116 => {
          self.literal("true")
          value = JsonBool(true)
        }
        102 => {
          self.literal("false")
          value = JsonBool(false)
        }
        110 => {
          self.literal("null")
          value = JsonNull
        }
        c if c == 45 || @util.is_digit(c) => value = JsonNumber(self.number())
        _ => self.unexpected()
      }
      break
    }
    while true {
      guard stack.last() is Some(frame) else { return value }
      if frame.object {
        frame.put(value)
        if self.check(44) {
          self.key(frame, "Expected double-quoted property name in JSON")
          break
        }
        value = JsonObject(frame.entries)
        self.expect(125, "Expected ',' or '}' after property value in JSON")
      } else {
        frame.items.push(value)
        if self.check(44) {
          break
        }
        value = JsonArray(frame.items)
        self.expect(93, "Expected ',' or ']' after array element in JSON")
      }
      stack.pop() |> ignore
    }
  }
  JsonNull
}

///|
/// The line and column of `offset` in `text`, which starts at `line` and `column`.
fn location_at(
  text : String,
  offset : Int32,
  line : Int32,
  column : Int32,
) -> (Int32, Int32) {
  let mut line = line
  let mut column = column
  let end = @cmp.minimum(@cmp.maximum(offset, 0), text.length())
  for i in 0..<end {
    let c = @util.code_at(text, i)
    if c == 13 {
      line += 1
      column = 1
    } else if c == 10 {
      if i == 0 || @util.code_at(text, i - 1) != 13 {
        line += 1
        column = 1
      }
    } else {
      column += 1
    }
  }
  (line, column)
}

///|
fn json_error(
  message : String,
  line : Int32,
  column : Int32,
) -> @errors.PeleError {
  @errors.pele_error(
    "\{message} (line \{line}, column \{column})",
    code=Syntax,
    kind="usecase",
    line~,
    column~,
  )
}

///|
/// Reads the body of a `json` node, which has to be an object.
/// `origin` gives the line and column the text starts at in the diagram, for the error.
pub fn parse_ordered_json(
  text : String,
  origin : () -> (Int32, Int32),
) -> Array[(String, JsonValue)] raise @errors.PeleError {
  let reader = { text, at: 0, }
  let value = try {
    let value = reader.document()
    reader.skip_whitespace()
    if reader.at < text.length() {
      reader.fail("Unexpected non-whitespace character after JSON")
    }
    value
  } catch {
    BadJson(message, offset) => {
      // pele finds the place from V8's message when it names one, and otherwise where its own walk
      // of the text stops, which is where V8 stopped too.
      let (line, column) = origin()
      let (line, column) = location_at(text, offset, line, column)
      raise json_error("Invalid JSON: \{message}", line, column)
    }
  }
  guard value is JsonObject(entries) else {
    let (line, column) = origin()
    raise json_error("JSON value must have an object root", line, column)
  }
  entries
}
