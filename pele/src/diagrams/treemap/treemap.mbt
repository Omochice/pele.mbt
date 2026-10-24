///|
/// The treemap diagram type.
pub let treemap : @types.Diagram = {
  kind: "treemap",
  section: None,
  keep_comments: false,
  math: false,
  parse: (source, _, title, _, _) => {
    let model = build_treemap(parse_treemap(source), title)
    { render: (config, options) => render_treemap(model, config, options), }
  },
}
