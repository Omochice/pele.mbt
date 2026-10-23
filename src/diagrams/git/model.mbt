///|
/// A git graph ready to be drawn.
pub(all) struct GitModel {
  title : String?
  acc_title : String?
  acc_descr : String?
  direction : GitDirection
  /// Keyed by commit id, in the order the ids first appeared.
  commits : Map[String, GitCommit]
  /// The id of each branch's latest commit, or `None` while the branch has none.
  branches : Map[String, String?]
  /// Branch names in drawing order: by `order`, then by creation.
  lanes : Array[String]
  current_branch : String
  head : GitCommit?
  warnings : Array[String]
}

///|
/// Plays the statements of a graph on a database of commits and branches.
/// `title` is the front matter title, used when the graph has none.
/// Raises a semantic `PeleError` for a statement that Mermaid rejects.
pub fn build_git(
  ast : GitGraphAst,
  config : @types.Config,
  title : String?,
) -> GitModel raise @errors.PeleError {
  ignore(ast)
  ignore(config)
  ignore(title)
  raise @errors.pele_error("not implemented")
}
