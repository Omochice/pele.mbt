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
