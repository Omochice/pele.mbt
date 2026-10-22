///|
/// Mermaid's default maxTextSize.
const DEFAULT_LIMIT : Double = 50000

///|
/// Renders Mermaid text to SVG with the given diagram types.
/// Raises `PeleError` for text pele rejects.
pub fn render(
  diagrams : ArrayView[@types.Diagram],
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
  let pre = @preprocess.preprocess(source)
  guard @detect.detect_diagram(pre.text) is Some(found) else {
    raise @errors.pele_error(
      "No diagram type detected for the given text.",
      code=UnsupportedDiagram,
    )
  }
  guard diagrams.iter().find_first(d => d.kind == found.kind) is Some(_) else {
    raise @errors.pele_error(
      "Diagram type \"\{found.kind}\" is not supported yet.",
      code=UnsupportedDiagram,
      kind=found.kind,
      mermaid_type=found.mermaid_type,
    )
  }
  raise @errors.pele_error(
    "Diagram type \"\{found.kind}\" is not supported yet.",
    code=UnsupportedDiagram,
    kind=found.kind,
    mermaid_type=found.mermaid_type,
  )
}
