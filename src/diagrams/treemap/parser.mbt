///|
/// A row of a treemap that names a section or a leaf.
pub(all) enum ItemAst {
  /// A name, and the class applied with `:::`.
  Section(String, String?)
  /// A name, a value, and the class applied with `:::`.
  Leaf(String, Double, String?)
}

///|
/// A line of a treemap, with the width of the whitespace before it when there is some.
pub(all) enum RowAst {
  Item(Int32?, ItemAst)
  /// A class name and the text of its declarations.
  ClassDef(Int32?, String, String?)
}

///|
/// The statements of a treemap, as Mermaid's grammar reads them.
pub(all) struct TreemapAst {
  title : String?
  acc_title : String?
  acc_descr : String?
  rows : Array[RowAst]
}

///|
/// Reads a treemap. Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_treemap(source : String) -> TreemapAst raise @errors.PeleError {
  raise @errors.syntax_error("treemap", source, 0, "not implemented")
}
