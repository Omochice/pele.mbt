///|
/// The side of a service or junction an edge leaves from or arrives at.
pub(all) enum Side {
  L
  R
  T
  B
}

///|
/// The letter that names the side in the source.
pub fn Side::name(self : Side) -> String {
  match self {
    L => "L"
    R => "R"
    T => "T"
    B => "B"
  }
}

///|
/// A group as written; `parent` is the group named after `in`.
pub(all) struct GroupAst {
  id : String
  icon : String?
  title : String?
  parent : String?
}

///|
/// A service as written; it carries an icon or an icon text, not both.
pub(all) struct ServiceAst {
  id : String
  icon : String?
  icon_text : String?
  title : String?
  parent : String?
}

///|
pub(all) struct JunctionAst {
  id : String
  parent : String?
}

///|
/// An edge as written: `into` is an arrowhead at that end, and `group` a `{group}` modifier.
pub(all) struct EdgeAst {
  lhs_id : String
  lhs_group : Bool
  lhs_dir : Side
  lhs_into : Bool
  title : String?
  rhs_into : Bool
  rhs_dir : Side
  rhs_id : String
  rhs_group : Bool
}

///|
/// An `align` statement; `direction` is `row` or `column`.
pub(all) struct AlignmentAst {
  direction : String
  members : Array[String]
}

///|
/// The statements of an architecture diagram, as Mermaid's grammar reads them, by kind.
pub(all) struct ArchitectureAst {
  title : String?
  acc_title : String?
  acc_descr : String?
  groups : Array[GroupAst]
  services : Array[ServiceAst]
  junctions : Array[JunctionAst]
  edges : Array[EdgeAst]
  alignments : Array[AlignmentAst]
}

///|
/// Reads an architecture diagram, which starts with `architecture-beta`.
/// Raises a syntax `PeleError` with Mermaid's message where the text does not follow the grammar.
pub fn parse_architecture(
  _source : String,
) -> ArchitectureAst raise @errors.PeleError {
  raise @errors.pele_error("not implemented")
}
