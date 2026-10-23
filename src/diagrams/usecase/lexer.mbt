///|
/// The tokens of a source: the type, start and end offset of each, ending in three `EOF`s.
pub(all) struct Tokens {
  types : Array[Int32]
  starts : Array[Int32]
  ends : Array[Int32]
}

///|
/// Splits a use case diagram into the tokens of Mermaid's Chevrotain lexer.
pub fn tokenize(_src : String) -> Tokens raise @errors.PeleError {
  raise @errors.pele_error("not implemented")
}
