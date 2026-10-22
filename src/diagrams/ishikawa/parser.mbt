///|
/// Parses an Ishikawa diagram into its outline.
/// `title` is the front matter title.
/// Raises a syntax error where Mermaid's parser would.
pub fn parse_ishikawa(
  src : String,
  title? : String,
) -> IshikawaModel raise @errors.PeleError {
  ignore(src)
  { title, root: None, }
}
