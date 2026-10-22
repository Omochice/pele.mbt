///|
pub(all) enum NodeKind {
  Service
  Junction
}

///|
/// A service or a junction; only a service has an icon, an icon text, or a title.
pub(all) struct ArchNode {
  id : String
  kind : NodeKind
  icon : String?
  icon_text : String?
  title : String?
  parent : String?
}

///|
pub(all) struct ArchGroup {
  id : String
  icon : String?
  title : String?
  parent : String?
}

///|
/// An edge between two nodes; `into` is an arrowhead at that end, and `group` says the edge
/// meets the border of the node's group instead of the node.
pub(all) struct ArchEdge {
  lhs_id : String
  lhs_dir : Side
  lhs_into : Bool
  lhs_group : Bool
  rhs_id : String
  rhs_dir : Side
  rhs_into : Bool
  rhs_group : Bool
  title : String?
}

///|
/// An `align` statement; `direction` is `row` or `column`.
pub(all) struct ArchLayoutHint {
  direction : String
  members : Array[String]
}

///|
/// An architecture diagram ready to be laid out, built as Mermaid's database builds it.
pub struct ArchitectureDb {
  title : String?
  acc_title : String?
  acc_descr : String?
  nodes : Map[String, ArchNode]
  groups : Map[String, ArchGroup]
  edges : Array[ArchEdge]
  layout_hints : Array[ArchLayoutHint]
}

///|
pub fn ArchitectureDb::new() -> ArchitectureDb {
  {
    title: None,
    acc_title: None,
    acc_descr: None,
    nodes: {},
    groups: {},
    edges: [],
    layout_hints: [],
  }
}

///|
/// Adds a service.
/// Raises a semantic `PeleError` for an id in use or a parent that is not a declared group.
pub fn ArchitectureDb::add_service(
  self : ArchitectureDb,
  id : String,
  icon? : String,
  icon_text? : String,
  title? : String,
  parent? : String,
) -> Unit raise @errors.PeleError {
  ignore((self, id, icon, icon_text, title, parent))
  raise @errors.pele_error("not implemented")
}

///|
/// Adds a junction.
/// Raises a semantic `PeleError` for an id in use or a parent that is not a declared group.
pub fn ArchitectureDb::add_junction(
  self : ArchitectureDb,
  id : String,
  parent? : String,
) -> Unit raise @errors.PeleError {
  ignore((self, id, parent))
  raise @errors.pele_error("not implemented")
}

///|
/// Adds a group.
/// Raises a semantic `PeleError` for an id in use or a parent that is not a declared group.
pub fn ArchitectureDb::add_group(
  self : ArchitectureDb,
  id : String,
  icon? : String,
  title? : String,
  parent? : String,
) -> Unit raise @errors.PeleError {
  ignore((self, id, icon, title, parent))
  raise @errors.pele_error("not implemented")
}

///|
/// Adds an edge.
/// Raises a semantic `PeleError` for an end that is not a declared node, or a `{group}` end of
/// an edge that stays within one group.
pub fn ArchitectureDb::add_edge(
  self : ArchitectureDb,
  edge : ArchEdge,
) -> Unit raise @errors.PeleError {
  ignore((self, edge))
  raise @errors.pele_error("not implemented")
}

///|
/// Adds an alignment.
/// Raises a semantic `PeleError` unless it names at least two distinct nodes.
pub fn ArchitectureDb::add_layout_hint(
  self : ArchitectureDb,
  hint : ArchLayoutHint,
) -> Unit raise @errors.PeleError {
  ignore((self, hint))
  raise @errors.pele_error("not implemented")
}

///|
/// Fills `db` from the statements of a diagram, as Mermaid's `populateDb` does.
/// Raises a semantic `PeleError` where a statement contradicts an earlier one.
pub fn populate(
  ast : ArchitectureAst,
  db : ArchitectureDb,
) -> Unit raise @errors.PeleError {
  ignore((ast, db))
  raise @errors.pele_error("not implemented")
}
