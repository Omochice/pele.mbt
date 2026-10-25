///|
/// The token types of Mermaid's sankey grammar.
pub(all) enum Token {
  End
  /// Not a Jison token: the reference lexer would return the same empty token forever from here.
  Stuck
  Sankey
  Newline
  Comma
  Dquote
  NonEscapedText
  EscapedText
  Eof
}

///|
impl Eq for Token with fn equal(self, other) {
  self.name() == other.name()
}

///|
/// The name Mermaid's parser gives the token in its error messages.
pub fn Token::name(self : Token) -> String {
  match self {
    End => "$end"
    Stuck => "STUCK"
    Sankey => "SANKEY"
    Newline => "NEWLINE"
    Comma => "COMMA"
    Dquote => "DQUOTE"
    NonEscapedText => "NON_ESCAPED_TEXT"
    EscapedText => "ESCAPED_TEXT"
    Eof => "EOF"
  }
}

///|
/// The tokens of a text as parallel arrays of type, text, and start offset.
pub(all) struct Tokens {
  types : Array[Token]
  texts : Array[String]
  starts : Array[Int32]
}

///|
priv enum State {
  Initial
  Csv
  EscapedText
}

///|
/// RFC 4180 TEXTDATA extended to Unicode, excluding controls and invalid XML characters.
fn is_text_data(c : Int32) -> Bool {
  (c >= 32 && c <= 126 && c != 34 && c != 44) ||
  (c >= 0xa0 && c <= 0xd7ff) ||
  (c >= 0xe000 && c <= 0xfffd) ||
  (c >= 0x10000 && c <= 0x10ffff)
}

///|
fn push_token(
  tokens : Tokens,
  src : String,
  kind : Token,
  start : Int32,
  end : Int32,
) -> Unit {
  tokens.types.push(kind)
  tokens.texts.push(@util.slice(src, start, end~))
  tokens.starts.push(start)
}

///|
/// Whether the keyword `word` is at `at`, ignoring case as `toLowerCase` does, and ends at a non-word character.
/// The Kelvin sign is the one non-ASCII character that lowercases to an ASCII letter.
fn keyword_at(src : String, word : String, at : Int32) -> Bool {
  if at + word.length() > src.length() {
    return false
  }
  for i in 0..<word.length() {
    let c = @util.code_at(src, at + i)
    let lower = if c >= 'A'.to_int() && c <= 'Z'.to_int() {
      c + 32
    } else if c == 0x212a {
      'k'.to_int()
    } else {
      c
    }
    if lower != @util.code_at(word, i) {
      return false
    }
  }
  !@util.is_word(@util.code_at(src, at + word.length()))
}

///|
/// Splits a text into tokens as Mermaid's lexer does.
pub fn tokenize(src : String) -> Tokens {
  let n = src.length()
  let tokens = { types: [], texts: [], starts: [], }
  let stack : Array[State] = []
  let mut state = Initial
  let mut p = 0
  while p < n {
    let c = @util.code_at(src, p)
    let start = p
    let mut q = p
    if state is EscapedText {
      if c == 34 && @util.code_at(src, p + 1) != 34 {
        if stack.pop() is Some(previous) {
          state = previous
        }
        push_token(tokens, src, Dquote, p, p + 1)
        p += 1
        continue
      }
      while q < n {
        let (d, next) = @util.code_point_at(src, q)
        if is_text_data(d) || d == 44 || d == 13 || d == 10 {
          q = next
        } else if d == 34 && @util.code_at(src, q + 1) == 34 {
          q += 2
        } else {
          break
        }
      }
      push_token(tokens, src, EscapedText, p, q)
      p = q
    } else {
      if state is Initial && (c | 32) == 115 {
        let length = if keyword_at(src, "sankey-beta", p) {
          11
        } else if keyword_at(src, "sankey", p) {
          6
        } else {
          0
        }
        if length > 0 {
          stack.push(state)
          state = Csv
          push_token(tokens, src, Sankey, p, p + length)
          p += length
          continue
        }
      }
      if c == 10 || (c == 13 && @util.code_at(src, p + 1) == 10) {
        let end = if c == 10 { p + 1 } else { p + 2 }
        push_token(tokens, src, Newline, p, end)
        p = end
        continue
      }
      if c == 44 {
        push_token(tokens, src, Comma, p, p + 1)
        p += 1
        continue
      }
      if c == 34 {
        stack.push(state)
        state = EscapedText
        push_token(tokens, src, Dquote, p, p + 1)
        p += 1
        continue
      }
      while q < n {
        let (d, next) = @util.code_point_at(src, q)
        if !is_text_data(d) {
          break
        }
        q = next
      }
      push_token(tokens, src, NonEscapedText, p, q)
      p = q
    }
    // A character outside the CSV alphabet matches as empty text and is never consumed.
    if q == start {
      push_token(tokens, src, Stuck, p, p)
      return tokens
    }
  }
  push_token(
    tokens,
    src,
    if state is EscapedText {
      EscapedText
    } else {
      Eof
    },
    n,
    n,
  )
  push_token(tokens, src, End, n, n)
  tokens
}
