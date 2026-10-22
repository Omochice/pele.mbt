///|
/// A tree entry as written: its indentation and name with the annotations after it.
pub(all) struct TreeNodeAst {
  /// `None` for an entry with no leading blanks.
  indent : Int32?
  name : String
  class_annotation : String?
  icon_annotation : String?
  desc_annotation : String?
}

///|
/// The statements of a tree view, as Mermaid's grammar reads them.
pub(all) struct TreeViewAst {
  title : String?
  acc_title : String?
  acc_descr : String?
  nodes : Array[TreeNodeAst]
}

///|
/// Reads the text of a tree view, which starts with the `treeView-beta` keyword.
/// Raises a syntax `PeleError` where the text does not follow the grammar.
pub fn parse_treeview(_source : String) -> TreeViewAst raise @errors.PeleError {
  raise @errors.pele_error("not implemented")
}
