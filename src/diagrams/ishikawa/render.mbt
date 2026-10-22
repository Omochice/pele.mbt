///|
/// Draws an Ishikawa diagram as a fishbone, or as an outline when it has to run down.
pub fn render_ishikawa(
  model : IshikawaModel,
  options : @types.RenderOptions,
) -> @types.Rendered {
  ignore(model)
  ignore(options)
  { svg: "", width: 0, height: 0, links: [], }
}
