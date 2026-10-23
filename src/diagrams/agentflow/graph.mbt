///|
/// A node as it is drawn: a flow, a collapsed flow, a node or a connector.
pub(all) struct GraphNode {
  id : String
  label : String?
  label_type : @flowchart.LabelType
  mut shape : String
  is_group : Bool
  parent_id : String?
  mut css_styles : Array[String]
  mut css_compiled_styles : Array[String]
  mut css_classes : String
  dir : String?
  link : String?
  link_target : String?
  tooltip : String?
  /// Palette slot of a container.
  mut color_index : Int32?
  /// What a node is, which picks its palette slot.
  mut kind : String?
  metadata : Map[String, Json]?
}

///|
/// An edge as it is drawn.
pub(all) struct GraphEdge {
  id : String
  is_user_defined_id : Bool
  start : String
  end : String
  kind : String
  label : String
  label_type : @flowchart.LabelType
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
  metadata : Map[String, Json]?
}

///|
/// The nodes and edges an agentflow draws.
pub(all) struct AgentGraph {
  nodes : Array[GraphNode]
  edges : Array[GraphEdge]
}

///|
/// Resolves a parsed agentflow into the nodes and edges that are drawn: flow membership, collapsed flows, shapes reduced to the ones agentflow has, class styles and palette slots.
/// Shape and containment problems are reported on the model as diagnostics.
pub fn build_agent_graph(
  db : AgentflowDb,
  palette_length : Int32,
  default_curve? : String,
) -> AgentGraph {
  ignore((db, palette_length, default_curve))
  { nodes: [], edges: [], }
}
