///|
/// Reads an agentflow as pele's agentflow diagram does before drawing it.
/// Mermaid reads `inheritDir` from the `flowchart` section for agentflow too, and the host's edge limit applies.
pub fn parse_model(
  source : String,
  config : @types.Config,
  title : String?,
  line_offset : Int32,
  limits : @types.ParseLimits,
) -> AgentflowDb raise @errors.PeleError {
  ignore(line_offset)
  let inherit_dir = match config.get("flowchart") {
    Some(Object(flow)) => flow.get("inheritDir") is Some(True)
    _ => false
  }
  let direction = match config.get("direction") {
    Some(String(direction)) => Some(direction)
    _ => None
  }
  let db = AgentflowDb::new(
    max_edges=limits.max_edges,
    inherit_dir~,
    direction?,
  )
  if title is Some(title) && title != "" {
    db.title = Some(title)
  }
  parse_agentflow(source, db)
  db
}
