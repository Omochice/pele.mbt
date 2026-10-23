///|
/// One leaf of a JSON node: `key` is blank on the second and later values of an array, and
/// `accessible_key` is the key again for every row.
pub(all) struct JsonRow {
  key : String
  accessible_key : String
  value : String
}

///|
/// What is drawn for an actor, use case, note, JSON table or boundary; `shape` is Mermaid's shape name.
pub(all) struct UsecaseGraphNode {
  id : String
  label : String
  label_type : String
  shape : String
  is_group : Bool
  padding : Double
  css_classes : String
  css_styles : Array[String]
  css_compiled_styles : Array[String]
  actor_type : String?
  business : Bool?
  icon : String?
  stereotype : String?
  parent_id : String?
  note_target : String?
  json_rows : Array[JsonRow]?
  boundary_type : String?
}

///|
/// What is drawn for a relationship or the dotted line from a note to what it is about (`internal`).
pub(all) struct UsecaseGraphEdge {
  id : String
  start : String
  end : String
  relationship_type : String
  pattern : String
  arrow_type_start : String
  arrow_type_end : String
  label : String?
  label_type : String?
  classes : String
  style : Array[String]
  css_compiled_styles : Array[String]
  animate : Bool
  animation : String?
  minlen : Int32
  explicit_id : Bool
  internal : Bool
}

///|
/// The nodes and edges of a use case diagram.
pub(all) struct UsecaseGraph {
  nodes : Array[UsecaseGraphNode]
  edges : Array[UsecaseGraphEdge]
}

///|
/// Resolves a parsed use case diagram into what is drawn.
pub fn build_usecase_graph(_model : UsecaseModel) -> UsecaseGraph {
  { nodes: [], edges: [], }
}
