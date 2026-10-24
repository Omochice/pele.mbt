///|
/// The architecture diagram type.
pub let architecture : @types.Diagram = {
  kind: "architecture",
  section: None,
  keep_comments: false,
  math: false,
  parse: (source, _, title, _, _) => {
    let db = ArchitectureDb::new()
    if title is Some(title) && title != "" {
      db.title = Some(title)
    }
    populate(parse_architecture(source), db)
    { render: (config, options) => render_architecture(db, config, options), }
  },
}
