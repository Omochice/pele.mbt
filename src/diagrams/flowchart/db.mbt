///|
/// The model a flowchart is parsed into, as pele's FlowDb.
pub struct FlowDb {
  mut direction : String?
  nodes : Map[String, FlowNode]
  edges : Array[FlowEdge]
  subgraphs : Array[FlowSubgraph]
  classes : Map[String, FlowClassDef]
  tooltips : Map[String, String]
  mut default_edge_style : Array[String]?
  mut default_interpolate : String?
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
  priv subgraph_lookup : Map[String, FlowSubgraph]
  priv members : Map[String, Unit]
  priv edge_by_id : Map[String, FlowEdge]
  priv pair_count : Map[String, Int32]
  priv mut sub_count : Int32
  priv max_edges : Int32?
  priv inherit_dir : Bool
  priv base_direction : String?
}

///|
/// An empty model. `max_edges` limits the edges, `inherit_dir` gives subgraphs the chart's direction, and `direction` stands in for a chart without one.
pub fn FlowDb::new(
  max_edges? : Int32,
  inherit_dir~ : Bool = false,
  direction? : String,
) -> FlowDb {
  {
    direction: None,
    nodes: Map([]),
    edges: [],
    subgraphs: [],
    classes: Map([]),
    tooltips: Map([]),
    default_edge_style: None,
    default_interpolate: None,
    title: None,
    acc_title: None,
    acc_descr: None,
    subgraph_lookup: Map([]),
    members: Map([]),
    edge_by_id: Map([]),
    pair_count: Map([]),
    sub_count: 0,
    max_edges,
    inherit_dir,
    base_direction: direction,
  }
}
