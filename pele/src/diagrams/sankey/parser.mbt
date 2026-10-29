///|
/// The blank runs at the edges of rows outside quoted fields, which are removed, and where the
/// blanks at the end of the text start.
/// A blank first field is kept, because Mermaid reads it as an empty name.
fn row_edges(text : String) -> (Array[@errors.Edit], Int32) {
  let mut end = text.length()
  while end > 0 && @util.is_inline_space(@util.code_at(text, end - 1)) {
    end -= 1
  }
  let removed = []
  let mut quoted = false
  let mut i = 0
  while i < end {
    let c = @util.code_at(text, i)
    if quoted {
      if c == '"'.to_int() {
        if @util.code_at(text, i + 1) == '"'.to_int() {
          i += 1
        } else {
          quoted = false
        }
      }
      i += 1
    } else if c == '"'.to_int() {
      quoted = true
      i += 1
    } else if @util.is_inline_space(c) {
      let mut j = i + 1
      while @util.is_inline_space(@util.code_at(text, j)) {
        j += 1
      }
      let p = @util.code_at(text, i - 1)
      let q = @util.code_at(text, j)
      if i == 0 ||
        q == 10 ||
        q == 13 ||
        ((p == 10 || p == 13) && q != ','.to_int()) {
        removed.push((i, j, 0))
      }
      i = j
    } else {
      i += 1
    }
  }
  (removed, end)
}

///|
/// Strips blanks at the edges of rows and collapses runs of line breaks, so that no row is empty.
/// Unlike Mermaid, which strips blanks only at both ends of the text, it also trims the edges of
/// rows outside quoted fields, as pele does.
/// The edits are appended to `steps`, as three passes, when it is given.
pub fn prepare_text_for_parsing(
  text : String,
  steps? : Array[Array[@errors.Edit]],
) -> String {
  let (removed, end) = row_edges(text)
  // The text is measured before it is copied, and trimmed only when it has to be, because a
  // source of hundreds of millions of characters copied into a doubling builder, or copied again
  // whole, would need more than wasm allocates.
  let mut length = 0
  let mut in_break = false
  let mut r = 0
  let mut i = 0
  while i < end {
    if r < removed.length() && removed[r].0 == i {
      i = removed[r].1
      r += 1
      continue
    }
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
    i += 1
  }
  let recording = steps is Some(_)
  let collapsing = []
  // Positions in the text with the row edges removed, where line breaks are collapsed.
  let mut at = 0
  let mut run = 0
  let out = StringBuilder(size_hint=length * 2)
  in_break = false
  r = 0
  i = 0
  while i < end {
    if r < removed.length() && removed[r].0 == i {
      i = removed[r].1
      r += 1
      continue
    }
    let c = @util.code_at(text, i)
    if c == 10 || c == 13 {
      if !in_break {
        out.write_char('\n')
        run = at
      }
      in_break = true
    } else {
      if recording && in_break {
        collapsing.push((run, at, 1))
      }
      in_break = false
      @util.write_range(out, text, i, i + 1)
    }
    i += 1
    at += 1
  }
  let out = out.to_string()
  if steps is Some(steps) {
    if in_break {
      collapsing.push((run, at, 1))
    }
    let lead = out.length() - @util.trim_start(out).length()
    let trimmed = @util.trim(out).length()
    if end < text.length() {
      removed.push((end, text.length(), 0))
    }
    steps.push(removed)
    steps.push(collapsing)
    steps.push([(0, lead, 0), (lead + trimmed, out.length(), 0)])
  }
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
  /// The text before `prepare_text_for_parsing`, in which errors are reported.
  source : String
  tokens : Tokens
  mut i : Int32
}

///|
fn Reader::error(
  self : Reader,
  at : Int32,
  detail : String,
) -> @errors.PeleError {
  let steps = []
  if self.source != self.src {
    prepare_text_for_parsing(self.source, steps~) |> ignore
  }
  // The end of the text is mapped from before the trailing blanks that were trimmed.
  let offset = if at > 0 && at >= self.src.length() {
    @errors.input_offset(steps, self.src.length() - 1) + 1
  } else {
    @errors.input_offset(steps, at)
  }
  @errors.syntax_error("sankey", self.source, offset, detail)
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
  raise self.error(offset, "Expecting \{expected}, got '\{got}'")
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
    raise self.error(start, "Invalid XML character in node name")
  }
  text
}

///|
/// Whether `text` holds a control character, a lone surrogate or a noncharacter XML forbids.
fn has_invalid_xml(text : String) -> Bool {
  let mut i = 0
  while i < text.length() {
    let (c, next) = @util.code_point_at(text, i)
    if c <= 8 ||
      c == 0xb ||
      c == 0xc ||
      (c >= 0xe && c <= 0x1f) ||
      (c >= 0xd800 && c <= 0xdfff) ||
      c == 0xfffe ||
      c == 0xffff {
      return true
    }
    i = next
  }
  false
}

///|
/// Reads the rows of a sankey diagram into `db`.
/// Errors are reported in `source`, the text before `prepare_text_for_parsing` made `src` of it.
/// Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_sankey(
  src : String,
  db : SankeyDb,
  source? : String,
) -> Unit raise @errors.PeleError {
  let r = { src, source: source.unwrap_or(src), tokens: tokenize(src), i: 0, }
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
      raise r.error(start, "Expecting a number")
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
