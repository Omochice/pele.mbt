///|
/// The tokens of a C4 source: token `i` is `types[i]`, over `src[starts[i]:ends[i]]`.
pub(all) struct C4Tokens {
  types : Array[Int32]
  starts : Array[Int32]
  ends : Array[Int32]
}

///|
/// The name Jison's error messages give a token type.
pub fn token_name(type_ : Int32) -> String {
  ignore(type_)
  ""
}

///|
/// Splits a C4 source into tokens as the lexer Jison compiles from c4Diagram.jison does.
pub fn tokenize(src : String) -> C4Tokens {
  ignore(src)
  { types: [], starts: [], ends: [], }
}
