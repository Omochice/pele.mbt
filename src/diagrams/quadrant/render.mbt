///|
fn render_quadrant(
  db : QuadrantDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  ignore((db, config, options))
  raise @errors.pele_error("not implemented")
}
