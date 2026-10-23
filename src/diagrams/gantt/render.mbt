///|
/// Draws a gantt chart, scheduled against the time the options give.
pub fn render_gantt(
  model : GanttDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  ignore(config)
  let tasks = model.get_tasks(clock(options.now))
  { svg: "", width: tasks.length().to_double(), height: 0, links: [], }
}
