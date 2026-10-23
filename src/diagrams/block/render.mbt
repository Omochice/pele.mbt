///|
/// Draws a block diagram.
pub fn render_block(
  db : BlockDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  ignore(config)
  ignore(options)
  let (width, height) = layout(cell(0, 0), db.blocks.length().to_double())
  { svg: "", width, height, links: [], }
}
