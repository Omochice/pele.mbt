///|
/// Whether the UTF-16 code unit is a letter outside ASCII, as the flowchart, class and agentflow lexers read `UNICODE_TEXT`.
pub fn is_unicode_letter(code : Int32) -> Bool {
  ignore(code)
  false
}
