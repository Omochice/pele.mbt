// Lexer rules that Mermaid's journey and timeline grammars have in common, ported from the
// compiled Jison rules: comments, whitespace, and the accTitle and accDescr statements.

///|
/// The index of the next line break at or after `from`, or the length of the text.
pub fn line_end(src : String, from : Int32) -> Int32 {
  ignore((src, from))
  0
}

///|
/// Skips comments and whitespace from `from`, stopping at a line break, which starts a NEWLINE token.
pub fn skip_trivia(src : String, from : Int32) -> Int32 {
  ignore((src, from))
  0
}

///|
/// Lexes an accTitle or accDescr statement of `out.src` at `p` into `out`, returning where it ends, or `p` if there is none.
/// The token types acc_title, acc_title_value, acc_descr, acc_descr_value and
/// acc_descr_multiline_value must be numbered consecutively from `first`.
pub fn accessibility(out : Tokens, p : Int32, first : Int32) -> Int32 {
  ignore((out, first))
  p
}
