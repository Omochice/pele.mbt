///|
/// Reads an agentflow into `db`.
/// `raw` reads the text as it is, as Mermaid's generated parser does without the wrapper that trims spaces after a closing brace.
pub fn parse_agentflow(
  source : String,
  db : AgentflowDb,
  raw~ : Bool = false,
) -> Unit raise @errors.PeleError {
  ignore((source, db, raw))
  raise @errors.pele_error("agentflow is not read yet", kind="agentflow")
}
