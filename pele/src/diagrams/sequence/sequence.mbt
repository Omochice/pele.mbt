///|
/// The sequence diagram type.
pub let sequence : @types.Diagram = {
  kind: "sequence",
  section: None,
  keep_comments: false,
  math: true,
  parse: (source, config, title, _, _) => {
    let wrap = match config.get("wrap") {
      Some(True) => Some(true)
      Some(False) => Some(false)
      _ => None
    }
    let sequence_wrap = match config.get("sequence") {
      Some(Object(section)) => section.get("wrap") is Some(True)
      _ => false
    }
    let db = SeqDb::new(wrap?, sequence_wrap~)
    if title is Some(title) && title != "" {
      db.set_diagram_title(title)
    }
    parse_sequence(source, db)
    { render: (config, options) => render_sequence(db, config, options), }
  },
}
