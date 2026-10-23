///|
/// An agentflow's tokens as parallel arrays: the type of each, its text, where it starts, and its span.
/// `locs` holds four numbers per token, counted as Jison counts them: first line, first column, last line, last column, with lines from 1 and columns from 0.
pub(all) struct Tokens {
  types : Array[Int32]
  texts : Array[String]
  starts : Array[Int32]
  locs : Array[Int32]
}

///|
/// Splits an agentflow into tokens as Mermaid's generated lexer does, ending with an error token where it stops.
pub fn tokenize(src : String) -> Tokens {
  ignore(src)
  { types: [], texts: [], starts: [], locs: [], }
}
