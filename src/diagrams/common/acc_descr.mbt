///|
/// The ACC_DESCR token for grammars where lexing goes on after an `accDescr {` that never
/// closes, because `accDescr` is also a name there.
pub let resumable_acc_descr : TokenType = pattern(
  "ACC_DESCR",
  (_, _) => NO_MATCH,
  first="\t a",
)
