///|
/// Draws an event model as SVG, lanes across with time running to the right or, when the host's width asks for it, down.
pub fn render_event_model(
  _model : EventModelingModel,
  _config : @types.Config,
  _options : @types.RenderOptions,
) -> @types.Rendered {
  { svg: "", width: 0, height: 0, links: [], }
}
