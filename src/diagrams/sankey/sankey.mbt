///|
/// The sankey diagram type.
pub let sankey : @types.Diagram = {
  kind: "sankey",
  section: None,
  keep_comments: false,
  parse: (source, _, title, _, _) => {
    let db = SankeyDb::new()
    if title is Some(text) && text != "" {
      db.title = title
    }
    parse_sankey(prepare_text_for_parsing(source), db)
    { render: (_, _) => { svg: "", width: 0, height: 0, links: [], }, }
  },
}
