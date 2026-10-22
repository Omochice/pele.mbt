///|
/// A cynefin diagram ready to be drawn.
pub(all) struct CynefinModel {
  title : String?
  acc_title : String?
  acc_descr : String?
  /// The labels of the items of each domain the source declares, in declaration order.
  /// All five domains are drawn either way.
  domains : Map[String, Array[String]]
  transitions : Array[TransitionAst]
}

///|
/// Keeps the blocks by domain, where a later block replaces an earlier one, and the transitions that are not self loops.
/// `title` is the front matter title, used when the diagram has none.
pub fn build_cynefin(ast : CynefinAst, title : String?) -> CynefinModel {
  ignore(ast)
  ignore(title)
  abort("not implemented")
}
