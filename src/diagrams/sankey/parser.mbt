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
  let out = StringBuilder()
  let mut in_break = false
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
  @util.trim(out.to_string())
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
fn Reader::name(self : Reader) -> String raise @errors.PeleError {
  @util.trim(self.field()).replace_all(old="\"\"", new="\"")
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
    let amount = r.field()
    let source = db.find_or_create_node(from)
    let target = db.find_or_create_node(to)
    db.add_link(source, target, @util.parse_float(@util.trim(amount)))
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
