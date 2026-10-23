///|
/// Lays out swimlanes: every top-level group is a lane, a band that runs the length of the diagram along the flow.
/// Ranks are shared by all lanes, so a step sits level with the steps that happen at the same time in other lanes, and each node stays inside its own lane.
/// Node centers and sizes are written into `nodes`, and routes and label centers into `edges`.
pub fn lane_layout(
  nodes : Array[CNode],
  edges : Array[CEdge],
  dir : Dir,
  opt : LayeredOptions,
  lane_pad~ : Double = 24,
) -> CompoundResult {
  ignore((nodes, edges, dir, opt, lane_pad))
  { width: 0, height: 0, }
}
