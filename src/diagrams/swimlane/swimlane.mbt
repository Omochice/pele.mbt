///|
/// Reads a swimlane diagram, which has the flowchart's syntax and model.
/// The `flowchart` config section, the title from front matter and the host's edge limit apply, as they do to a flowchart.
pub fn parse_swimlane(
  source : String,
  config : @types.Config,
  title : String?,
  limits : @types.ParseLimits,
) -> @flowchart.FlowDb raise @errors.PeleError {
  ignore((source, config, title, limits))
  raise @errors.pele_error("Swimlane diagrams are not read yet.")
}

///|
/// The swimlane diagram type: a flowchart whose top-level subgraphs are lanes.
pub let swimlane : @types.Diagram = {
  kind: "swimlane",
  section: None,
  keep_comments: false,
  parse: (source, config, title, _, limits) => {
    ignore(parse_swimlane(source, config, title, limits))
    { render: (_, _) => { svg: "", width: 0, height: 0, links: [], }, }
  },
}
