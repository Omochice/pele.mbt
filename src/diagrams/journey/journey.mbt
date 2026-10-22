///|
/// The user journey diagram type.
pub let journey : @types.Diagram = {
  kind: "journey",
  section: None,
  keep_comments: false,
  parse: (source, _, title, _, _) => {
    let db = JourneyDb::new(title)
    parse_journey(source, db)
    { render: (config, options) => render_journey(db, config, options), }
  },
}
