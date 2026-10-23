///|
/// Reads a swimlane diagram, which has the flowchart's syntax and model.
/// The `flowchart` config section, the title from front matter and the host's edge limit apply, as they do to a flowchart.
pub fn parse_swimlane(
  source : String,
  config : @types.Config,
  title : String?,
  limits : @types.ParseLimits,
) -> @flowchart.FlowDb raise @errors.PeleError {
  @flowchart.parse_model(source, config, title, limits)
}

///|
/// The swimlane diagram type: a flowchart whose top-level subgraphs are lanes.
pub let swimlane : @types.Diagram = {
  kind: "swimlane",
  section: None,
  keep_comments: false,
  math: true,
  parse: (source, config, title, _, limits) => {
    let db = parse_swimlane(source, config, title, limits)
    { render: (config, options) => render_swimlane(db, config, options), }
  },
}
