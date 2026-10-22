///|
/// Draws a sankey diagram.
/// Raises a semantic `PeleError` when the links form a cycle.
pub fn render_sankey(
  db : SankeyDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  ignore(db)
  ignore(config)
  ignore(options)
  raise @errors.pele_error("not implemented")
}
