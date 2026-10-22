///|
/// Draws a packet diagram.
pub fn render_packet(
  model : PacketModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  ignore((model, config, options))
  { svg: "", width: 0, height: 0, links: [], }
}
