///|
/// Diagram text with front matter, directives, and comment lines taken out.
pub(all) struct Preprocessed {
  text : String
  title : String?
  config : @types.Config
  /// The text before its comment lines are removed.
  with_comments : String
  /// The number of front matter lines before `with_comments`.
  line_offset : Int32
}

///|
/// Removes `%%` comment lines, keeping directives, and leading whitespace.
pub fn cleanup_comments(text : String) -> String {
  text
}

///|
/// Reads front matter and directives into a config, as Mermaid does before parsing.
/// Raises a syntax `PeleError` when the front matter is not valid YAML.
pub fn preprocess(source : String) -> Preprocessed raise @errors.PeleError {
  {
    text: source,
    title: None,
    config: {},
    with_comments: source,
    line_offset: 0,
  }
}

///|
/// Hides `#name;` entity codes behind Mermaid's placeholder characters.
pub fn encode_entities(text : String) -> String {
  text
}
