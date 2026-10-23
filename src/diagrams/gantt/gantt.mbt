///|
/// The gantt chart diagram type.
pub let gantt : @types.Diagram = {
  kind: "gantt",
  section: None,
  keep_comments: false,
  parse: (source, config, title, _, _) => {
    let db = GanttDb::new()
    if title is Some(text) && text != "" {
      db.title = Some(text)
    }
    if config.get("gantt") is Some(Object(settings)) &&
      settings.get("displayMode") is Some(String(mode)) {
      db.display_mode = mode
    }
    parse_gantt(source, db)
    { render: (config, options) => render_gantt(db, config, options), }
  },
}
