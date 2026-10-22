///|
/// A section, which has children that may be none, or a leaf, which has a value.
pub(all) struct TreemapNode {
  name : String
  children : Array[TreemapNode]?
  value : Double?
  class_selector : String?
  css_compiled_styles : Array[String]?
}

///|
/// A row of the treemap with its indentation, before it is placed in the hierarchy.
pub(all) struct TreemapItem {
  level : Int32
  name : String
  leaf : Bool
  value : Double?
  class_selector : String?
  css_compiled_styles : Array[String]?
}

///|
/// A treemap ready to be laid out.
pub(all) struct TreemapModel {
  title : String?
  acc_title : String?
  acc_descr : String?
  roots : Array[TreemapNode]
  /// The declarations of each class, in the order the classes were first defined.
  classes : Map[String, Array[String]]
}

///|
/// Places each row under the nearest section above it that is indented less.
pub fn build_hierarchy(items : Array[TreemapItem]) -> Array[TreemapNode] {
  ignore(items)
  []
}

///|
/// Builds the hierarchy of a treemap, with each class's declarations given to the rows that use it.
/// `title` is the front matter title, used when the treemap has none.
pub fn build_treemap(ast : TreemapAst, title : String?) -> TreemapModel {
  ignore(ast)
  { title, acc_title: None, acc_descr: None, roots: [], classes: {}, }
}
