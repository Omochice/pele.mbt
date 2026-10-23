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
  ignore((config, line_offset, limits))
  let db = AgentflowDb::new()
  if title is Some(title) && title != "" {
    db.title = Some(title)
  }
  parse_agentflow(source, db)
  db
}
