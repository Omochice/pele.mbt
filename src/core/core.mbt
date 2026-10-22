///|
/// Mermaid's default maxTextSize.
const DEFAULT_LIMIT : Double = 50000

///|
/// Renders Mermaid text to SVG.
/// Raises `PeleError` for text pele rejects.
pub fn render(
  source : String,
  options : @types.RenderOptions,
) -> @types.RenderResult raise @errors.PeleError {
  let limit = options.limit.unwrap_or(DEFAULT_LIMIT)
  if source.length().to_double() > limit {
    raise @errors.pele_error(
      "Diagram source is longer than the limit of \{limit} characters.",
      code=Limit,
    )
  }
  guard @detect.detect_diagram(source) is Some(found) else {
    raise @errors.pele_error(
      "No diagram type detected for the given text.",
      code=UnsupportedDiagram,
    )
  }
  raise @errors.pele_error(
    "Diagram type \"\{found.kind}\" is not supported yet.",
    code=UnsupportedDiagram,
    kind=found.kind,
    mermaid_type=found.mermaid_type,
  )
}
