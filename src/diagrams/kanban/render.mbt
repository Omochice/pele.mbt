///|
/// Draws a board: a column for each section and a card for each item in it.
pub fn render_kanban(
  model : KanbanModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  ignore(model)
  ignore(config)
  ignore(options)
  { svg: "", width: 0, height: 0, links: [], }
}
