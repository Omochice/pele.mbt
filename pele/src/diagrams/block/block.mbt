///|
/// The block diagram type.
pub let block : @types.Diagram = {
  kind: "block",
  section: None,
  keep_comments: false,
  math: true,
  parse: (source, _, title, _, _) => {
    let db = BlockDb::new(title?)
    parse_block(source, db)
    { render: (config, options) => render_block(db, config, options), }
  },
}
