///|
/// The kanban diagram type.
pub let kanban : @types.Diagram = {
  kind: "kanban",
  section: None,
  keep_comments: false,
  math: true,
  parse: (source, _, title, _, _) => {
    let model = parse_kanban(source, title)
    { render: (config, options) => render_kanban(model, config, options), }
  },
}
