///|
/// Limits set by the host. A diagram's own configuration cannot change them.
pub(all) struct ParseLimits {
  max_edges : Int32
}

///|
/// A diagram that has been read and can be drawn.
pub(all) struct Parsed {
  render : (Config, RenderOptions) -> Rendered raise @errors.PeleError
}

///|
/// What a diagram type provides, as pele's `Diagram`.
/// `parse` is given text that has been through preprocessing and entity encoding and ends with
/// a newline, the config, the front matter title, and the number of front matter lines.
pub(all) struct Diagram {
  kind : String
  /// The name of this type's section in Mermaid's config, when it is not the type's own name.
  section : String?
  /// Whether `parse` is given the text with its `%%` comment lines kept.
  keep_comments : Bool
  parse : (String, Config, String?, Int32, ParseLimits) -> Parsed raise @errors.PeleError
}
