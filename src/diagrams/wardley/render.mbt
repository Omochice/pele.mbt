///|
/// Draws a Wardley map.
pub fn render_wardley(
  model : WardleyModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  ignore((model, config, options))
  { svg: "", width: 0, height: 0, links: [], }
}
