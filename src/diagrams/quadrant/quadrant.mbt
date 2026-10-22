///|
/// The quadrant chart diagram type.
pub let quadrant : @types.Diagram = {
  kind: "quadrantChart",
  section: None,
  keep_comments: false,
  parse: (source, _, title, _, _) => {
    let db = QuadrantDb::new(title)
    parse_quadrant(source, db)
    { render: (config, options) => render_quadrant(db, config, options), }
  },
}
