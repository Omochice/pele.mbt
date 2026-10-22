///|
/// Renders Mermaid text to SVG.
/// Raises `PeleError` for text pele rejects.
pub fn render(
  source : String,
  options : @types.RenderOptions,
) -> @types.RenderResult raise @errors.PeleError {
  ignore(source)
  ignore(options)
  raise @errors.pele_error(
    "No diagram type is ported yet.",
    code=UnsupportedDiagram,
  )
}
