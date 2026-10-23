///|
/// A gantt chart's tokens, with the text and start offset of each.
pub(all) struct Tokens {
  types : Array[Tok]
  texts : Array[String]
  starts : Array[Int32]
}

///|
/// Splits a gantt chart into tokens as Mermaid's Jison lexer does.
pub fn tokenize(src : String) -> Tokens {
  ignore(src)
  { types: [], texts: [], starts: [], }
}
