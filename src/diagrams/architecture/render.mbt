///|
/// Draws an architecture diagram.
pub fn render_architecture(
  model : ArchitectureDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  ignore((model, config, options))
  { svg: "", width: 0, height: 0, links: [], }
}
