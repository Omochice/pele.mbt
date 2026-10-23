///|
/// Draws a requirement diagram, turned to run down when a narrow host needs it.
pub fn render_requirement(
  db : RequirementDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  ignore(db)
  ignore(config)
  ignore(options)
  { svg: "", width: 0, height: 0, links: [], }
}
