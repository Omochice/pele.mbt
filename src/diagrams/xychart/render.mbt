///|
/// Draws an XY chart.
/// Raises a semantic `PeleError` when the chart has no series.
pub fn render_xychart(
  model : XyChartDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  ignore(model)
  ignore(config)
  ignore(options)
  raise @errors.pele_error("not drawn yet", code=Semantic, kind="xychart")
}
