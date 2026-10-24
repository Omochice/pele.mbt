///|
/// The ACC_DESCR token for grammars where lexing goes on after an `accDescr {` that never
/// closes, because `accDescr` is also a name there.
/// Once a braced description finds no closing brace, none exists further on, so later braced
/// descriptions fail without reading the rest of the text again.
pub let resumable_acc_descr : TokenType = {
  name: "ACC_DESCR",
  scanner: () => {
    let mut unclosed = false
    (src, p) => {
      let start = skip_blanks(src, p)
      if !@util.starts_with_at(src, "accDescr", start) {
        return NO_MATCH
      }
      let after = start + "accDescr".length()
      let colon = skip_blanks(src, after)
      if @util.code_at(src, colon) == ':'.to_int() {
        return line_or_comment_end(src, colon + 1)
      }
      let mut brace = after
      while @util.is_space(@util.code_at(src, brace)) {
        brace += 1
      }
      if @util.code_at(src, brace) != '{'.to_int() || unclosed {
        return NO_MATCH
      }
      let close = @util.index_of(src, "}", from=brace + 1)
      unclosed = close == -1
      if unclosed {
        NO_MATCH
      } else {
        close + 1
      }
    }
  },
  first: Some("\t a"),
  hidden: false,
}
