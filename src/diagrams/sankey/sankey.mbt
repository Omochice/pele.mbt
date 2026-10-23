///|
/// The sankey diagram type.
pub let sankey : @types.Diagram = {
  kind: "sankey",
  section: None,
  keep_comments: false,
  math: false,
  parse: (source, _, title, _, _) => {
    let db = SankeyDb::new()
    if title is Some(text) && text != "" {
      db.title = title
    }
    parse_sankey(prepare_text_for_parsing(source), db)
    { render: (config, options) => render_sankey(db, config, options), }
  },
}
