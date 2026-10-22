///|
/// Splits a timeline into tokens as Mermaid's lexer does.
pub fn tokenize(src : String) -> @common.Tokens {
  { kinds: [], starts: [], ends: [], src, }
}
