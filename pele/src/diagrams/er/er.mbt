///|
/// The ER diagram type.
pub let er : @types.Diagram = {
  kind: "er",
  section: None,
  keep_comments: false,
  math: true,
  parse: (source, _, title, _, _) => {
    let db = ErDb::new(title?)
    parse_er(source, db)
    { render: (config, options) => render_er(db, config, options), }
  },
}
