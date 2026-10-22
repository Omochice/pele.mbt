///|
/// The mindmap diagram type.
pub let mindmap : @types.Diagram = {
  kind: "mindmap",
  section: None,
  keep_comments: false,
  parse: (source, _, title, _, _) => {
    let model = parse_mindmap(source, title)
    { render: (config, options) => render_mindmap(model, config, options), }
  },
}
