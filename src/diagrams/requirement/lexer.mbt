///|
/// The token stream of a requirement diagram: each token's type, text and offset.
pub(all) struct Tokens {
  types : Array[Int32]
  texts : Array[String]
  starts : Array[Int32]
}

///|
/// Splits a requirement diagram into tokens as Mermaid's lexer does.
pub fn tokenize(src : String) -> Tokens {
  ignore(src)
  { types: [], texts: [], starts: [], }
}
