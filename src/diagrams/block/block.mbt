///|
/// The block diagram type.
/// pele marks it as one whose labels may hold math; with no typesetter here, math stays text, as it does in pele without one.
pub let block : @types.Diagram = {
  kind: "block",
  section: None,
  keep_comments: false,
  parse: (source, _, title, _, _) => {
    let db = BlockDb::new(title?)
    parse_block(source, db)
    { render: (config, options) => render_block(db, config, options), }
  },
}
