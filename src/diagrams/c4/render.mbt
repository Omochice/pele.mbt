///|
/// Draws a C4 diagram, narrowed to the host's width when it allows that.
/// Raises when a relation names something that is not drawn, as Mermaid does.
pub fn render_c4(
  db : C4Db,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  ignore((db, config, options))
  raise @errors.pele_error("C4 diagrams are not drawn yet", kind="c4")
}
