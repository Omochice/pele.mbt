///|
/// Mermaid style declarations split by what they apply to.
/// `shape`, `line`, and `text` are ready-made `style` attributes, or empty.
pub(all) struct ResolvedStyle {
  shape : String
  line : String
  text : String
  stroke : String?
  bold : Bool
  italic : Bool
  font_size : Double?
}

///|
/// Splits Mermaid style declarations into what applies to a shape and what applies to its text.
/// Declarations that could escape the attribute or load something are dropped.
pub fn resolve_style(declarations : Array[String]) -> ResolvedStyle {
  ignore(declarations)
  {
    shape: "?",
    line: "?",
    text: "?",
    stroke: None,
    bold: false,
    italic: false,
    font_size: None,
  }
}
