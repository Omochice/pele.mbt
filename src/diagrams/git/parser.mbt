///|
/// The type a commit is written with.
pub(all) enum CommitTypeName {
  Normal
  Reverse
  Highlight
}

///|
pub(all) struct CommitAst {
  id : String?
  message : String?
  tags : Array[String]
  commit_type : CommitTypeName?
}

///|
pub(all) struct BranchAst {
  name : String
  order : Double?
}

///|
pub(all) struct MergeAst {
  branch : String
  id : String?
  tags : Array[String]
  commit_type : CommitTypeName?
}

///|
pub(all) struct CheckoutAst {
  branch : String
}

///|
pub(all) struct CherryPickingAst {
  id : String?
  tags : Array[String]
  parent : String?
}

///|
pub(all) enum StatementAst {
  Commit(CommitAst)
  Branch(BranchAst)
  Merge(MergeAst)
  Checkout(CheckoutAst)
  CherryPicking(CherryPickingAst)
}

///|
/// The direction a graph is drawn in.
pub(all) enum GitDirection {
  LR
  TB
  BT
}

///|
/// The statements of a git graph, as Mermaid's grammar reads them.
pub(all) struct GitGraphAst {
  dir : GitDirection?
  title : String?
  acc_title : String?
  acc_descr : String?
  statements : Array[StatementAst]
}

///|
/// Reads a git graph. Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_git(source : String) -> GitGraphAst raise @errors.PeleError {
  raise @errors.pele_error("not implemented \{source.length()}")
}
