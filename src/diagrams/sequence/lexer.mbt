///|
/// The tokens of a source, with the text and start offset of each.
pub(all) struct Tokens {
  types : Array[Tok]
  texts : Array[String]
  starts : Array[Int32]
}

///|
/// Splits a sequence diagram into tokens as Mermaid's Jison lexer does.
pub fn tokenize(_src : String) -> Tokens {
  { types: [], texts: [], starts: [], }
}
