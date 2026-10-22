///|
/// Draws a journey.
/// Raises nothing today; the signature matches the other diagrams' renderers.
pub fn render_journey(
  model : JourneyDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  ignore(model)
  ignore(config)
  ignore(options)
  raise @errors.pele_error("not implemented")
}
