///|
/// The ER diagram type.
/// pele marks it as one whose labels may hold math; with no typesetter here, math stays text, as it does in pele without one.
pub let er : @types.Diagram = {
  kind: "er",
  section: None,
  keep_comments: false,
  parse: (source, _, title, _, _) => {
    let db = ErDb::new(title?)
    parse_er(source, db)
    { render: (config, options) => render_er(db, config, options), }
  },
}
