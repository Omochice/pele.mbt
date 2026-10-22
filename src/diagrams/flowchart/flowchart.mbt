///|
/// Reads a flowchart as pele's flowchart diagram does before drawing it: the `flowchart` config section, the title from front matter, and the host's edge limit apply.
pub fn parse_model(
  source : String,
  config : @types.Config,
  title : String?,
  limits : @types.ParseLimits,
) -> FlowDb raise @errors.PeleError {
  let inherit_dir = match config.get("flowchart") {
    Some(Object(flow)) => flow.get("inheritDir") is Some(True)
    _ => false
  }
  let db = FlowDb::new(max_edges=limits.max_edges, inherit_dir~)
  if title is Some(title) && title != "" {
    db.title = Some(title)
  }
  parse_flowchart(source, db)
  db
}

///|
/// The flowchart diagram type.
pub let flowchart : @types.Diagram = {
  kind: "flowchart",
  section: None,
  keep_comments: false,
  parse: (source, config, title, _, limits) => {
    let db = parse_model(source, config, title, limits)
    { render: (config, options) => render_flowchart(db, config, options), }
  },
}
