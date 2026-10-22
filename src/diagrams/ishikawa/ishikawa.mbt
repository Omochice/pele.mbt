///|
/// The Ishikawa diagram type.
pub let ishikawa : @types.Diagram = {
  kind: "ishikawa",
  section: None,
  keep_comments: false,
  parse: (source, _, title, _, _) => {
    let model = parse_ishikawa(source, title?)
    { render: (_, options) => render_ishikawa(model, options), }
  },
}
