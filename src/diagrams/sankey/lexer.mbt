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
/// Splits a text into tokens as Mermaid's lexer does.
pub fn tokenize(src : String) -> Tokens {
  ignore(src)
  { types: [], texts: [], starts: [], }
}
