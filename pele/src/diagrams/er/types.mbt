///|
/// How many of one entity relate to the other, in Mermaid's names.
pub(all) enum Cardinality {
  ZeroOrOne
  ZeroOrMore
  OneOrMore
  OnlyOne
  MdParent
}

///|
/// Mermaid's name for the cardinality, such as `ZERO_OR_MORE`.
pub fn Cardinality::name(self : Cardinality) -> String {
  match self {
    ZeroOrOne => "ZERO_OR_ONE"
    ZeroOrMore => "ZERO_OR_MORE"
    OneOrMore => "ONE_OR_MORE"
    OnlyOne => "ONLY_ONE"
    MdParent => "MD_PARENT"
  }
}

///|
/// Whether a relationship identifies the child entity, which Mermaid draws as a solid line.
pub(all) enum Identification {
  NonIdentifying
  Identifying
}

///|
/// One row of an entity's attribute table.
pub(all) struct ErAttribute {
  data_type : String
  name : String
  keys : Array[String]
  comment : String
}

///|
/// An entity, keyed in the model by the name it was written with.
pub(all) struct ErEntity {
  id : String
  label : String
  mut alias_name : String
  attributes : Array[ErAttribute]
  mut css_classes : String
  css_styles : Array[String]
}

///|
/// The two cardinalities of a relationship and its identification.
/// `card_b` sits at entity A's end of the line and `card_a` at entity B's, as in Mermaid.
pub(all) struct RelSpec {
  card_a : Cardinality
  rel_type : Identification
  card_b : Cardinality
}

///|
/// A relationship between two entities.
/// Each end holds an entity's id, or a subgraph's id when the name was a subgraph at the time.
pub(all) struct ErRelationship {
  entity_a : String
  role_a : String
  entity_b : String
  rel_spec : RelSpec
}

///|
/// The styles a `classDef` gives a class; `text_styles` are those that color text.
pub(all) struct ErClassDef {
  id : String
  styles : Array[String]
  text_styles : Array[String]
}

///|
/// A subgraph and the names it holds.
/// pele also keeps a label type, which its parser always sets to markdown and nothing reads.
pub(all) struct ErSubgraph {
  id : String
  nodes : Array[String]
  title : String
  classes : Array[String]
  css_styles : Array[String]
  dir : String?
}

///|
/// A statement inside a subgraph as Mermaid's grammar hands it over: a name, or a direction.
pub(all) enum DocItem {
  Name(String)
  Dir(String)
}
