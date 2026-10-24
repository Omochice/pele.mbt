///|
/// The state diagram type, for both `stateDiagram` and `stateDiagram-v2`.
pub let state : @types.Diagram = {
  kind: "state",
  section: None,
  keep_comments: false,
  math: true,
  parse: (source, _, title, _, _) => {
    let db = StateDb::new(title?=title.filter(text => text != ""))
    ignore(parse_state(source, db))
    { render: (config, options) => render_state(db, config, options), }
  },
}
