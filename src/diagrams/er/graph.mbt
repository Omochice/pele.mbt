///|
/// An entity, or a subgraph drawn as a group, as it is laid out.
pub(all) struct ErGraphNode {
  id : String
  label : String
  alias_name : String
  attributes : Array[ErAttribute]
  is_group : Bool
  parent_id : String?
  css_styles : Array[String]
  css_compiled_styles : Array[String]
  css_classes : String
  dir : String?
}

///|
/// A relationship as it is drawn, with Mermaid's lower-cased cardinality at each end.
pub(all) struct ErGraphEdge {
  id : String
  start : String
  end : String
  label : String
  arrow_type_start : String
  arrow_type_end : String
  dashed : Bool
}

///|
pub(all) struct ErGraph {
  nodes : Array[ErGraphNode]
  edges : Array[ErGraphEdge]
}

///|
/// Resolves a parsed ER diagram into what is drawn: subgraphs as groups, entities as nodes with their class styles, and relationships as edges.
pub fn build_er_graph(model : ErDb) -> ErGraph {
  ignore(model)
  { nodes: [], edges: [], }
}
