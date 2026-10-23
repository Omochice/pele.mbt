///|
/// The model an agentflow is parsed into, as pele's AgentflowDb.
pub struct AgentflowDb {
  direction : String?
  nodes : Map[String, AgentNode]
  edges : Array[AgentEdge]
  subgraphs : Array[AgentSubgraph]
  connectors : Map[String, AgentNode]
  classes : Map[String, @flowchart.FlowClassDef]
  tooltips : Map[String, String]
  default_edge_style : Array[String]?
  default_interpolate : String?
  mut title : String?
  acc_title : String?
  acc_descr : String?
}

///|
/// An empty model.
/// `max_edges` limits the edges, `inherit_dir` gives flows the diagram's direction, and `direction` stands in for a diagram without one.
pub fn AgentflowDb::new(
  max_edges? : Int32,
  inherit_dir~ : Bool = false,
  direction? : String,
) -> AgentflowDb {
  ignore((max_edges, inherit_dir, direction))
  {
    direction: None,
    nodes: Map([]),
    edges: [],
    subgraphs: [],
    connectors: Map([]),
    classes: Map([]),
    tooltips: Map([]),
    default_edge_style: None,
    default_interpolate: None,
    title: None,
    acc_title: None,
    acc_descr: None,
  }
}
