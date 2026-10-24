///|
/// A commit statement as the database receives it.
pub(all) struct CommitDb {
  msg : String
  id : String?
  commit_type : CommitType
  tags : Array[String]
}

///|
/// A branch statement as the database receives it.
pub(all) struct BranchDb {
  name : String
  order : Double
}

///|
/// A merge statement as the database receives it.
pub(all) struct MergeDb {
  branch : String
  /// Empty when the merge was not given an id.
  id : String
  commit_type : CommitType?
  tags : Array[String]
}

///|
/// A cherry-pick statement as the database receives it.
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
fn commit_type_of(name : CommitTypeName) -> CommitType {
  match name {
    Normal => Normal
    Reverse => Reverse
    Highlight => Highlight
  }
}

///|
/// Hands the statements of a graph to a database, in order.
pub fn[Db : GitDbParseProvider] populate(
  ast : GitGraphAst,
  db : Db,
) -> Unit raise @errors.PeleError {
  if ast.dir is Some(dir) {
    db.set_direction(dir)
  }
  for statement in ast.statements {
    parse_statement(statement, db)
  }
}

///|
/// Hands one statement to a database.
pub fn[Db : GitDbParseProvider] parse_statement(
  statement : StatementAst,
  db : Db,
) -> Unit raise @errors.PeleError {
  match statement {
    Commit(c) =>
      db.commit({
        id: c.id,
        msg: c.message.unwrap_or(""),
        commit_type: c.commit_type.map(commit_type_of).unwrap_or(Normal),
        tags: c.tags,
      })
    Branch(b) => db.branch({ name: b.name, order: b.order.unwrap_or(0), })
    Merge(m) =>
      db.merge({
        branch: m.branch,
        id: m.id.unwrap_or(""),
        commit_type: m.commit_type.map(commit_type_of),
        tags: m.tags,
      })
    Checkout(c) => db.checkout(c.branch)
    CherryPicking(c) =>
      db.cherry_pick({
        id: c.id,
        target_id: "",
        parent: c.parent,
        tags: if c.tags.is_empty() {
          None
        } else {
          Some(c.tags)
        },
      })
  }
}
