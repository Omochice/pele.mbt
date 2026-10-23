///|
/// A node of an agentflow, or a connector, as each mention of its id leaves it.
pub(all) struct AgentNode {
  id : String
  mut text : String?
  mut label_type : @flowchart.LabelType
  mut kind : String?
  styles : Array[String]
  classes : Array[String]
  mut dir : String?
  mut props : Map[String, String]?
  mut link : String?
  mut link_target : String?
  mut metadata : Map[String, Json]?
  is_connector : Bool
}

///|
/// An edge of an agentflow.
/// `edge_semantic` is `sequence`, `reference` or `failure` for the three arrows agentflow knows.
pub(all) struct AgentEdge {
  start : String
  end : String
  mut kind : String?
  mut text : String
  mut label_type : @flowchart.LabelType
  mut stroke : String?
  mut edge_semantic : String?
  mut length : Int32?
  mut style : Array[String]?
  classes : Array[String]
  mut id : String
  mut is_user_defined_id : Bool
  mut interpolate : Json?
  mut animate : Json?
  mut animation : Json?
  mut metadata : Map[String, Json]?
}

///|
/// A span of the source, with lines from 1 and columns from 0, and the lines of front matter added.
/// Mermaid builds its parser without ranges, so the indexes are always zero.
pub(all) struct ElementPosition {
  start_line : Int32
  start_column : Int32
  mut end_line : Int32
  mut end_column : Int32
  start_index : Int32
  end_index : Int32
}

///|
/// Where a statement sits in the source.
/// `kind` is `vertex`, `edge`, `subgraph`, `connector` or `attachment`, the last for a metadata block on an id named before.
pub(all) struct ElementMapping {
  id : String
  mut kind : String
  position : ElementPosition
}

///|
/// A finding about the diagram's meaning, anchored on a node or an edge.
pub(all) struct Diagnostic {
  id : String
  severity : String
  message : String
  node_id : String?
  edge_id : String?
  position : ElementPosition?
}

///|
/// A node as tools that read the diagram's meaning see it.
pub(all) struct SemanticVertex {
  id : String
  label : String?
  shape : String?
  vertex_kind : String
  metadata : Map[String, Json]?
}

///|
/// An edge as tools that read the diagram's meaning see it.
pub(all) struct SemanticEdge {
  start : String
  end : String
  id : String?
  label : String?
  kind : String?
  stroke : String?
  edge_semantic : String?
  length : Int32?
  metadata : Map[String, Json]?
}

///|
/// A flow as tools that read the diagram's meaning see it.
pub(all) struct SemanticSubgraph {
  id : String
  title : String
  nodes : Array[String]
  direction : String?
  metadata : Map[String, Json]?
}

///|
/// A connector as tools that read the diagram's meaning see it.
pub(all) struct SemanticConnector {
  id : String
  title : String?
  metadata : Map[String, Json]?
}

///|
/// The diagram with presentation-only controls left out, for tools that read what it means.
pub(all) struct SemanticModel {
  direction : String?
  vertices : Array[SemanticVertex]
  edges : Array[SemanticEdge]
  subgraphs : Array[SemanticSubgraph]
  connectors : Array[SemanticConnector]
  diagnostics : Array[Diagnostic]
}

///|
/// A `flow` block.
pub(all) struct AgentSubgraph {
  id : String
  mut nodes : Array[String]
  mut title : String
  classes : Array[String]
  mut dir : String?
  label_type : @flowchart.LabelType
  mut metadata : Map[String, Json]?
}
