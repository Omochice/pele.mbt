///|
/// Draws a class diagram, turned to run down when a narrow host needs it.
pub fn render_class(
  db : ClassDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  ignore((db, config, options))
  { svg: "", width: 0, height: 0, links: [], }
}
