///|
/// The state diagram type, for both `stateDiagram` and `stateDiagram-v2`.
/// pele marks it as one whose labels may hold math; with no typesetter here, math stays text, as it does in pele without one.
pub let state : @types.Diagram = {
  kind: "state",
  section: None,
  keep_comments: false,
  parse: (source, _, title, _, _) => {
    let db = StateDb::new(title?=title.filter(text => text != ""))
    ignore(parse_state(source, db))
    { render: (config, options) => render_state(db, config, options), }
  },
}
