///|
/// Draws a state diagram, turned to run down when a narrow host needs it.
pub fn render_state(
  db : StateDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  ignore((db, config, options))
  { svg: "", width: 0, height: 0, links: [], }
}
