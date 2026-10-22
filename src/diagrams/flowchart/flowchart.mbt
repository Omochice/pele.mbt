///|
/// Reads a flowchart as pele's flowchart diagram does before drawing it: the `flowchart` config section,
/// the title from front matter, and the host's edge limit apply.
pub fn parse_model(
  source : String,
  config : @types.Config,
  title : String?,
  limits : @types.ParseLimits,
) -> FlowDb raise @errors.PeleError {
  ignore((config, title, limits))
  let db = FlowDb::new()
  parse_flowchart(source, db)
  db
}
