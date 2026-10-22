///|
/// Whether `word`, written in lower case, is at `at`.
/// Only ASCII letters match in either case, as with the `i` flag on a regular expression without the `u` flag.
pub fn word_at(src : String, at : Int32, word : String) -> Bool {
  ignore((src, at, word))
  false
}
