///|
/// A flowchart's tokens as parallel arrays: the type of each, its text, and where it starts.
pub(all) struct Tokens {
  types : Array[Int32]
  texts : Array[String]
  starts : Array[Int32]
}

///|
/// Splits flowchart text into tokens as Mermaid's lexer does.
/// Text the lexer cannot read ends the list with an `INVALID` token where it stops.
pub fn tokenize(src : String) -> Tokens {
  ignore(src)
  { types: [], texts: [], starts: [], }
}
