///|
/// A blank as Mermaid's reference regex `[^\S\n\r]` sees it: whitespace other than a line break.
fn is_blank(c : Int32) -> Bool {
  c != 10 && c != 13 && @util.is_space(c)
}

///|
/// Strips blanks at both ends of the text and collapses runs of line breaks, so that no row is empty.
/// Mermaid's first step is a regex that rescans every run of blanks; this does the same in one pass.
pub fn prepare_text_for_parsing(text : String) -> String {
  let mut start = 0
  let mut end = text.length()
  while start < end && is_blank(@util.code_at(text, start)) {
    start += 1
  }
  while end > start && is_blank(@util.code_at(text, end - 1)) {
    end -= 1
  }
  // The text is measured before it is copied, and trimmed only when it has to be, because a
  // source of hundreds of millions of characters copied into a doubling builder, or copied again
  // whole, would need more than wasm allocates.
  let mut length = 0
  let mut in_break = false
  for i in start..<end {
    let c = @util.code_at(text, i)
    if c == 10 || c == 13 {
      if !in_break {
        length += 1
      }
      in_break = true
    } else {
      in_break = false
      length += 1
    }
  }
  let out = StringBuilder(size_hint=length * 2)
  in_break = false
  for i in start..<end {
    let c = @util.code_at(text, i)
    if c == 10 || c == 13 {
      if !in_break {
        out.write_char('\n')
      }
      in_break = true
    } else {
      in_break = false
      @util.write_range(out, text, i, i + 1)
    }
  }
  let out = out.to_string()
  if out.length() > 0 &&
    !@util.is_space(@util.code_at(out, 0)) &&
    !@util.is_space(@util.code_at(out, out.length() - 1)) {
    out
  } else {
    @util.trim(out)
  }
}

///|
priv struct Reader {
  src : String
  tokens : Tokens
  mut i : Int32
}

///|
fn Reader::kind(self : Reader) -> Token {
  if self.i < self.tokens.types.length() {
    self.tokens.types[self.i]
  } else {
    End
  }
}

///|
fn Reader::fail(
  self : Reader,
  expected : String,
) -> Unit raise @errors.PeleError {
  let got = if self.kind() is Stuck {
    if self.i > 0 {
      self.tokens.types[self.i - 1].name()
    } else {
      "undefined"
    }
  } else {
    self.kind().name()
  }
  let offset = if self.i < self.tokens.starts.length() {
    self.tokens.starts[self.i]
  } else {
    self.src.length()
  }
  raise @errors.syntax_error(
    "sankey",
    self.src,
    offset,
    "Expecting \{expected}, got '\{got}'",
  )
}

///|
fn Reader::expect(
  self : Reader,
  kind : Token,
  also~ : String = "",
) -> Unit raise @errors.PeleError {
  if self.kind() != kind {
    self.fail("'\{kind.name()}'\{also}")
  }
  self.i += 1
}

///|
fn Reader::field(self : Reader) -> String raise @errors.PeleError {
  if self.kind() is NonEscapedText {
    let text = self.tokens.texts[self.i]
    self.i += 1
    return text
  }
  if !(self.kind() is Dquote) {
    self.fail("'DQUOTE', 'NON_ESCAPED_TEXT'")
  }
  self.i += 1
  if !(self.kind() is EscapedText) {
    self.fail("'ESCAPED_TEXT'")
  }
  let text = self.tokens.texts[self.i]
  self.i += 1
  self.expect(Dquote)
  text
}

///|
fn Reader::start(self : Reader) -> Int32 {
  if self.i < self.tokens.starts.length() {
    self.tokens.starts[self.i]
  } else {
    self.src.length()
  }
}

///|
fn Reader::name(self : Reader) -> String raise @errors.PeleError {
  let start = self.start()
  let text = @util.trim(self.field()).replace_all(old="\"\"", new="\"")
  // Entity codes can encode characters excluded by the lexer.
  if has_invalid_xml(@text.decode_entities(text)) {
    raise @errors.syntax_error(
      "sankey",
      self.src,
      start,
      "Invalid XML character in node name",
    )
  }
  text
}

///|
/// Whether `text` holds a control character, a lone surrogate or a noncharacter XML forbids.
fn has_invalid_xml(text : String) -> Bool {
  let n = text.length()
  let mut i = 0
  while i < n {
    let c = @util.code_at(text, i)
    if c <= 8 || c == 0xb || c == 0xc || (c >= 0xe && c <= 0x1f) || c >= 0xfffe {
      return true
    }
    if c >= 0xd800 && c <= 0xdbff {
      let low = if i + 1 < n { @util.code_at(text, i + 1) } else { 0 }
      if !(low >= 0xdc00 && low <= 0xdfff) {
        return true
      }
      i += 2
      continue
    }
    if c >= 0xdc00 && c <= 0xdfff {
      return true
    }
    i += 1
  }
  false
}

///|
/// Reads the rows of a sankey diagram into `db`.
/// Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_sankey(
  src : String,
  db : SankeyDb,
) -> Unit raise @errors.PeleError {
  let r = { src, tokens: tokenize(src), i: 0, }
  r.expect(Sankey)
  r.expect(Newline)
  while true {
    let from = r.name()
    r.expect(Comma, also=", 'NEWLINE', 'EOF'")
    let to = r.name()
    r.expect(Comma, also=", 'NEWLINE', 'EOF'")
    let start = r.start()
    // Keep Mermaid's numeric prefixes, but reject non-finite values.
    let value = @util.parse_float(r.field())
    if value.is_nan() || value.is_inf() {
      raise @errors.syntax_error("sankey", r.src, start, "Expecting a number")
    }
    let source = db.find_or_create_node(from)
    let target = db.find_or_create_node(to)
    db.add_link(source, target, value)
    if !(r.kind() is Newline) {
      break
    }
    r.i += 1
  }
  if r.kind() is Eof {
    r.i += 1
  }
  if !(r.kind() is End) {
    r.fail("'NEWLINE', 'EOF'")
  }
}
