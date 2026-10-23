///|
/// Draws a git graph.
pub fn render_git(
  model : GitModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  ignore(model)
  ignore(config)
  ignore(options)
  { svg: "", width: 0, height: 0, links: [], }
}
