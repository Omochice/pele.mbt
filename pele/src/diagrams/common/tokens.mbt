// Tokenizer for the diagram types Mermaid defines with Langium grammars. Token types are tried
// in order and the first match wins, as in Chevrotain.
// pele matches most token types with sticky regexes; without a regex engine each pattern is a
// hand-written scanner that answers as the regex does, including its backtracking.

///|
/// Matches a token at an index: returns where the match ends, `NO_MATCH`, or `NO_CLOSER`.
/// The last argument is the type index of the last visible token, or -1 at the start.
/// Raises where pele's pattern for the token throws instead of answering.
pub type Scanner = (String, Int32, Int32) -> Int32 raise @errors.PeleError

///|
/// The token does not match here.
pub const NO_MATCH : Int32 = -1

///|
/// The start of a construct that needs a closer matched, but no closer exists in the rest of
/// the text, so the type is not tried again.
pub const NO_CLOSER : Int32 = -2

///|
/// A token type of a diagram's lexer.
pub(all) struct TokenType {
  name : String
  /// Makes the scanner for one text, so a scanner may remember what it has scanned.
  scanner : () -> Scanner
  /// Every ASCII character a match can start with, when that is known.
  /// The type is then tried only at those characters and at characters outside ASCII.
  first : String?
  hidden : Bool
}

///|
/// The tokens of a text: parallel arrays of type index, start, and end, closed by a -1 kind.
pub(all) struct Tokens {
  kinds : Array[Int32]
  starts : Array[Int32]
  ends : Array[Int32]
  src : String
}

///|
fn stateless(scan : Scanner) -> () -> Scanner {
  () => scan
}

///|
/// A token type that matches a fixed string.
pub fn literal(name : String, text : String) -> TokenType {
  {
    name,
    scanner: stateless((src, p, _) => {
      if @util.starts_with_at(src, text, p) {
        p + text.length()
      } else {
        NO_MATCH
      }
    }),
    first: Some(@util.slice(text, 0, end=1)),
    hidden: false,
  }
}

///|
/// Mermaid ends a keyword only at whitespace, a comment, or the end of input.
pub fn keyword(word : String) -> TokenType {
  {
    name: word,
    scanner: stateless((src, p, _) => {
      if !@util.starts_with_at(src, word, p) {
        return NO_MATCH
      }
      let end = p + word.length()
      let next = @util.code_at(src, end)
      if next == -1 ||
        @util.is_space(next) ||
        @util.starts_with_at(src, "%%", end) {
        end
      } else {
        NO_MATCH
      }
    }),
    first: Some(@util.slice(word, 0, end=1)),
    hidden: false,
  }
}

///|
/// Builds a token type from a scanner that needs no memory between calls.
pub fn pattern(
  name : String,
  scan : (String, Int32) -> Int32,
  first? : String,
  hidden~ : Bool = false,
) -> TokenType {
  { name, scanner: stateless((src, p, _) => scan(src, p)), first, hidden, }
}

///|
fn skip_blanks(src : String, from : Int32) -> Int32 {
  let mut i = from
  while @util.is_blank(@util.code_at(src, i)) {
    i += 1
  }
  i
}

///|
fn line_end_from(src : String, from : Int32) -> Int32 {
  let mut i = from
  while i < src.length() {
    let c = @util.code_at(src, i)
    if c == '\n'.to_int() || c == '\r'.to_int() {
      break
    }
    i += 1
  }
  i
}

///|
/// The end of `[^\n\r]*?(?=%%)|[^\n\r]*` from `from`: before the first `%%` on the line, or the line end.
fn line_or_comment_end(src : String, from : Int32) -> Int32 {
  let end = line_end_from(src, from)
  let comment = @util.index_of(src, "%%", from~)
  if comment != -1 && comment + 2 <= end {
    comment
  } else {
    end
  }
}

///|
/// The end of `(?:\r?\n|(?!\S))` at `at`, or -1.
fn line_break_or_space(src : String, at : Int32) -> Int32 {
  let c = @util.code_at(src, at)
  if c == '\r'.to_int() && @util.code_at(src, at + 1) == '\n'.to_int() {
    at + 2
  } else if c == '\n'.to_int() {
    at + 1
  } else if c == -1 || @util.is_space(c) {
    at
  } else {
    -1
  }
}

///|
/// `[\t ]*accDescr(?:[\t ]*:([^\n\r]*?(?=%%)|[^\n\r]*)|\s*{([^}]*)})`
pub let acc_descr : TokenType = pattern(
  "ACC_DESCR",
  (src, p) => {
    let start = skip_blanks(src, p)
    if !@util.starts_with_at(src, "accDescr", start) {
      return NO_MATCH
    }
    let after = start + "accDescr".length()
    let colon = skip_blanks(src, after)
    if @util.code_at(src, colon) == ':'.to_int() {
      return line_or_comment_end(src, colon + 1)
    }
    let mut brace = after
    while @util.is_space(@util.code_at(src, brace)) {
      brace += 1
    }
    if @util.code_at(src, brace) != '{'.to_int() {
      return NO_MATCH
    }
    let close = @util.index_of(src, "}", from=brace + 1)
    if close == -1 {
      NO_MATCH
    } else {
      close + 1
    }
  },
  first="\t a",
)

///|
/// `[\t ]*accTitle[\t ]*:(?:[^\n\r]*?(?=%%)|[^\n\r]*)`
pub let acc_title : TokenType = pattern(
  "ACC_TITLE",
  (src, p) => {
    let start = skip_blanks(src, p)
    if !@util.starts_with_at(src, "accTitle", start) {
      return NO_MATCH
    }
    let colon = skip_blanks(src, start + "accTitle".length())
    if @util.code_at(src, colon) != ':'.to_int() {
      return NO_MATCH
    }
    line_or_comment_end(src, colon + 1)
  },
  first="\t a",
)

///|
/// `[\t ]*title(?:[\t ][^\n\r]*?(?=%%)|[\t ][^\n\r]*|)`
pub let title : TokenType = pattern(
  "TITLE",
  (src, p) => {
    let start = skip_blanks(src, p)
    if !@util.starts_with_at(src, "title", start) {
      return NO_MATCH
    }
    let after = start + "title".length()
    if @util.is_blank(@util.code_at(src, after)) {
      line_or_comment_end(src, after + 1)
    } else {
      after
    }
  },
  first="\t t",
)

///|
/// Where `"([^"\\]|\\.)*"`, or its single-quoted twin, matches the string whose quote is at `p`: its end, or -1.
pub fn quoted_span(src : String, p : Int32) -> Int32 {
  let quote = @util.code_at(src, p)
  let mut i = p + 1
  while i < src.length() {
    let c = @util.code_at(src, i)
    if c == quote {
      return i + 1
    }
    if c == '\\'.to_int() {
      let next = @util.code_at(src, i + 1)
      if next == -1 || @util.is_line_end(next) {
        break
      }
      i += 2
    } else {
      i += 1
    }
  }
  -1
}

///|
/// `"([^"\\]|\\.)*"|'([^'\\]|\\.)*'`
pub let string : TokenType = {
  name: "STRING",
  scanner: stateless((src, p, _) => {
    let quote = @util.code_at(src, p)
    if quote != '"'.to_int() && quote != '\''.to_int() {
      return NO_MATCH
    }
    let end = quoted_span(src, p)
    if end == -1 {
      NO_MATCH
    } else {
      end
    }
  }),
  first: Some("\"'"),
  hidden: false,
}

///|
/// `\r?\n`
pub let newline : TokenType = pattern(
  "NEWLINE",
  (src, p) => {
    let c = @util.code_at(src, p)
    if c == '\n'.to_int() {
      p + 1
    } else if c == '\r'.to_int() && @util.code_at(src, p + 1) == '\n'.to_int() {
      p + 2
    } else {
      NO_MATCH
    }
  },
  first="\r\n",
)

///|
/// `[\t ]+`, skipped.
pub let whitespace : TokenType = pattern(
  "WHITESPACE",
  (src, p) => {
    let end = skip_blanks(src, p)
    if end > p {
      end
    } else {
      NO_MATCH
    }
  },
  first="\t ",
  hidden=true,
)

///|
/// `---[\t ]*\r?\n(?:[\S\s]*?\r?\n)?---(?:\r?\n|(?!\S))`, skipped.
pub let yaml : TokenType = pattern(
  "YAML",
  (src, p) => {
    if !@util.starts_with_at(src, "---", p) {
      return NO_MATCH
    }
    let mut a = skip_blanks(src, p + 3)
    if @util.code_at(src, a) == '\r'.to_int() {
      a += 1
    }
    if @util.code_at(src, a) != '\n'.to_int() {
      return NO_MATCH
    }
    a += 1
    // The optional group is tried first, so the closing fence is the first one after a line break.
    let mut nl = @util.index_of(src, "\n---", from=a)
    while nl != -1 {
      let end = line_break_or_space(src, nl + 4)
      if end != -1 {
        return end
      }
      nl = @util.index_of(src, "\n---", from=nl + 1)
    }
    if @util.starts_with_at(src, "---", a) {
      let end = line_break_or_space(src, a + 3)
      if end != -1 {
        return end
      }
    }
    NO_CLOSER
  },
  first="-",
  hidden=true,
)

///|
/// `[\t ]*%%{[\S\s]*?}%%(?:\r?\n|(?!\S))`, skipped.
pub let directive : TokenType = pattern(
  "DIRECTIVE",
  (src, p) => {
    let start = skip_blanks(src, p)
    if !@util.starts_with_at(src, "%%{", start) {
      return NO_MATCH
    }
    let mut close = @util.index_of(src, "}%%", from=start + 3)
    while close != -1 {
      let end = line_break_or_space(src, close + 3)
      if end != -1 {
        return end
      }
      close = @util.index_of(src, "}%%", from=close + 1)
    }
    NO_CLOSER
  },
  first="\t %",
  hidden=true,
)

///|
/// `[\t ]*%%[^\n\r]*`, skipped.
pub let single_line_comment : TokenType = pattern(
  "SINGLE_LINE_COMMENT",
  (src, p) => {
    let start = skip_blanks(src, p)
    if !@util.starts_with_at(src, "%%", start) {
      return NO_MATCH
    }
    line_end_from(src, start + 2)
  },
  first="\t %",
  hidden=true,
)

///|
/// Splits `src` into tokens of `types`.
/// Raises a lexical syntax error naming `diagram` where no type matches.
pub fn tokenize(
  src : String,
  types : ArrayView[TokenType],
  diagram : String,
) -> Tokens raise @errors.PeleError {
  let every = Array::makei(types.length(), k => k)
  let starting = Array::makei(128, c => {
    every.filter(k => {
      match types[k].first {
        Some(first) => first.contains_code_unit(c.to_uint16())
        None => true
      }
    })
  })
  let scanners = types.map(t => (t.scanner)())
  let dead = Array::make(types.length(), false)
  let kinds = []
  let starts = []
  let ends = []
  let n = src.length()
  let mut p = 0
  while p < n {
    let c = @util.code_at(src, p)
    let candidates = if c < 128 { starting[c] } else { every }
    let previous = match kinds.last() {
      Some(kind) => kind
      None => -1
    }
    let mut matched = false
    for k in candidates {
      if dead[k] {
        continue
      }
      let end = scanners[k](src, p, previous)
      if end == NO_CLOSER {
        dead[k] = true
        continue
      }
      if end <= p {
        continue
      }
      if !types[k].hidden {
        kinds.push(k)
        starts.push(p)
        ends.push(end)
      }
      p = end
      matched = true
      break
    }
    if !matched {
      raise @errors.syntax_error(diagram, src, p, "", lexical=true)
    }
  }
  kinds.push(-1)
  starts.push(n)
  ends.push(n)
  { kinds, starts, ends, src, }
}

///|
/// Reads tokens for a hand-written parser, with Chevrotain-style messages on failure.
pub(all) struct TokenReader {
  tokens : Tokens
  types : ArrayView[TokenType]
  diagram : String
  mut i : Int32
}

///|
/// Starts reading at the first token.
pub fn TokenReader::new(
  tokens : Tokens,
  types : ArrayView[TokenType],
  diagram : String,
) -> TokenReader {
  { tokens, types, diagram, i: 0, }
}

///|
/// The type index of the current token, or -1 at the end of input.
pub fn TokenReader::kind(self : TokenReader) -> Int32 {
  self.tokens.kinds[self.i]
}

///|
/// The text of the token at `index`, the current one by default.
pub fn TokenReader::text(self : TokenReader, index? : Int32) -> String {
  let at = index.unwrap_or(self.i)
  @util.slice(self.tokens.src, self.tokens.starts[at], end=self.tokens.ends[at])
}

///|
/// The text of the current token, moving past it.
pub fn TokenReader::take(self : TokenReader) -> String {
  let text = self.text()
  self.i += 1
  text
}

///|
/// Moves past the current token when it is of type `kind`.
pub fn TokenReader::accept(self : TokenReader, kind : Int32) -> Bool {
  if self.kind() != kind {
    return false
  }
  self.i += 1
  true
}

///|
/// The text of the current token, which must be of type `kind`, moving past it.
pub fn TokenReader::expect(
  self : TokenReader,
  kind : Int32,
) -> String raise @errors.PeleError {
  if self.kind() != kind {
    self.fail("token of type '\{self.types[kind].name}'")
  }
  self.take()
}

///|
fn is_only_space(src : String, from : Int32, to : Int32) -> Bool {
  for i in from..<to {
    if !@util.is_space(src.unsafe_get(i).to_int()) {
      return false
    }
  }
  true
}

///|
/// Raises a parse error saying what was expected at the current token.
pub fn[T] TokenReader::fail(
  self : TokenReader,
  expected : String,
) -> T raise @errors.PeleError {
  let found = if self.kind() == -1 {
    "end of input"
  } else {
    "`\{self.text()}`"
  }
  let { src, starts, ends, .. } = self.tokens
  let mut at = starts[self.i]
  if self.kind() == -1 {
    // Hidden comments leave no token, so the end of input is placed after the last token with
    // content rather than at the end of the text.
    let mut k = self.i
    while k > 0 && is_only_space(src, starts[k - 1], ends[k - 1]) {
      k -= 1
    }
    if k > 0 {
      at = ends[k - 1]
    }
  }
  raise @errors.syntax_error(
    self.diagram,
    src,
    at,
    "Expecting \{expected} but found \{found}.",
  )
}
