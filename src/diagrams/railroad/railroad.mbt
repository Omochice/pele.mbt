///|
/// The railroad diagram type, in all four of Mermaid's notations.
pub let railroad : @types.Diagram = {
  kind: "railroad",
  section: None,
  keep_comments: false,
  parse: (source, _, title, _, _) => {
    let model = parse_railroad(source, title)
    { render: (config, options) => render_railroad(model, config, options), }
  },
}
