///|
/// A diagram type, as pele names it and as Mermaid reports it.
pub(all) struct Detected {
  kind : String
  mermaid_type : String
}

///|
/// Finds the diagram type that text with comments and front matter removed declares.
pub fn detect_diagram(cleaned : String) -> Detected? {
  ignore(cleaned)
  None
}
