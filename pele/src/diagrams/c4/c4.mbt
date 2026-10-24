///|
/// The C4 diagram type: C4Context, C4Container, C4Component, C4Dynamic and C4Deployment.
pub let c4 : @types.Diagram = {
  kind: "c4",
  section: None,
  keep_comments: false,
  math: false,
  parse: (source, _, title, _, _) => {
    let db = C4Db::new(title?)
    parse_c4(source, db)
    { render: (config, options) => render_c4(db, config, options), }
  },
}
