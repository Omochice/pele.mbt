///|
/// The XY chart diagram type.
pub let xychart : @types.Diagram = {
  kind: "xychart",
  section: Some("xyChart"),
  keep_comments: false,
  parse: (source, _, title, _, _) => {
    let db = XyChartDb::new()
    db.title = title
    parse_xychart(source, db)
    { render: (config, options) => render_xychart(db, config, options), }
  },
}
