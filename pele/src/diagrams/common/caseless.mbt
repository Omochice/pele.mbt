///|
/// Whether `word`, written in lower case, is at `at`.
/// Only ASCII letters match in either case, as with the `i` flag on a regular expression without the `u` flag.
pub fn word_at(src : String, at : Int32, word : String) -> Bool {
  for k in 0..<word.length() {
    let c = @util.code_at(src, at + k)
    let w = word.unsafe_get(k).to_int()
    if c != w && !(w >= 97 && w <= 122 && c == w - 32) {
      return false
    }
  }
  true
}
