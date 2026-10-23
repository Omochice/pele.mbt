///|
/// The timeline diagram type.
pub let timeline : @types.Diagram = {
  kind: "timeline",
  section: None,
  keep_comments: false,
  math: false,
  parse: (source, _, title, _, _) => {
    let db = TimelineDb::new()
    db.title = title
    parse_timeline(source, db)
    { render: (config, options) => render_timeline(db, config, options), }
  },
}
