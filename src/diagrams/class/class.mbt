///|
/// The class diagram type.
pub let class : @types.Diagram = {
  kind: "class",
  section: None,
  keep_comments: false,
  math: true,
  parse: (source, _, title, _, _) => {
    let db = ClassDb::new(
      title?=match title {
        Some(text) if text != "" => Some(text)
        _ => None
      },
    )
    parse_class(source, db)
    { render: (config, options) => render_class(db, config, options), }
  },
}
