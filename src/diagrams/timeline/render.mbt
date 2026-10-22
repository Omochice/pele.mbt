///|
/// Draws a timeline as SVG.
pub fn render_timeline(
  model : TimelineDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  ignore((model, config, options))
  { svg: "", width: 0, height: 0, links: [], }
}
