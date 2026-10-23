///|
/// The class diagram type.
/// pele marks it as one whose labels may hold math; with no typesetter here, math stays text, as it does in pele without one.
pub let class : @types.Diagram = {
  kind: "class",
  section: None,
  keep_comments: false,
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
