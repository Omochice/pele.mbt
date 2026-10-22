///|
pub(all) struct CommitDb {
  msg : String
  id : String?
  commit_type : CommitType
  tags : Array[String]
}

///|
pub(all) struct BranchDb {
  name : String
  order : Double
}

///|
pub(all) struct MergeDb {
  branch : String
  /// Empty when the merge was not given an id.
  id : String
  commit_type : CommitType?
  tags : Array[String]
}

///|
pub(all) struct CherryPickDb {
  id : String?
  target_id : String
  parent : String?
  /// `None` for the default tag.
  tags : Array[String]?
}

///|
/// The calls Mermaid's gitGraphParser makes on its database, under the same names.
pub(open) trait GitDbParseProvider {
  fn set_direction(Self, GitDirection) -> Unit
  fn commit(Self, CommitDb) -> Unit raise @errors.PeleError
  fn branch(Self, BranchDb) -> Unit raise @errors.PeleError
  fn merge(Self, MergeDb) -> Unit raise @errors.PeleError
  fn cherry_pick(Self, CherryPickDb) -> Unit raise @errors.PeleError
  fn checkout(Self, String) -> Unit raise @errors.PeleError
}

///|
/// Hands the statements of a graph to a database, in order.
pub fn[Db : GitDbParseProvider] populate(
  ast : GitGraphAst,
  db : Db,
) -> Unit raise @errors.PeleError {
  ignore(ast)
  db.checkout("")
  raise @errors.pele_error("not implemented")
}

///|
/// Hands one statement to a database.
pub fn[Db : GitDbParseProvider] parse_statement(
  statement : StatementAst,
  db : Db,
) -> Unit raise @errors.PeleError {
  ignore(statement)
  db.checkout("")
  raise @errors.pele_error("not implemented")
}
