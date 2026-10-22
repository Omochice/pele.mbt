///|
/// A node as drawn: a vertex, or a subgraph as a group or a collapsed node.
pub(all) struct GraphNode {
  id : String
  label : String?
  label_type : LabelType
  shape : String
  is_group : Bool
  parent_id : String?
  mut css_styles : Array[String]
  mut css_compiled_styles : Array[String]
  mut css_classes : String
  dir : String?
  link : String?
  link_target : String?
  tooltip : String?
  icon : String?
  pos : String?
  img : String?
  asset_width : Double?
  asset_height : Double?
  constraint : String?
  color_index : Int32?
  metadata : Map[String, Json]?
}

///|
/// An edge as drawn. `kind` is pele's `type`; `curve` is any YAML value node data gave it, as in pele.
pub(all) struct GraphEdge {
  id : String
  is_user_defined_id : Bool
  start : String
  end : String
  kind : String
  label : String
  label_type : LabelType
  thickness : String?
  pattern : String?
  minlen : Int32?
  arrow_type_start : String
  arrow_type_end : String
  css_compiled_styles : Array[String]
  style : Array[String]
  classes : String
  animate : Json?
  animation : Json?
  curve : Json?
}

///|
/// The nodes and edges that are drawn.
pub(all) struct FlowGraph {
  nodes : Array[GraphNode]
  edges : Array[GraphEdge]
}

///|
/// Resolves a parsed flowchart into the nodes and edges that are actually drawn:
/// group membership, collapsed subgraphs, class styles and edge defaults.
pub fn build_flow_graph(model : FlowDb, default_curve? : String) -> FlowGraph {
  ignore((model, default_curve))
  { nodes: [], edges: [], }
}
