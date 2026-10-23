///|
/// The tree view diagram type.
pub let treeview : @types.Diagram = {
  kind: "treeView",
  section: None,
  keep_comments: false,
  math: false,
  parse: (source, config, title, _, _) => {
    let model = build_treeview(read_treeview(source), title)
    { render: (_, options) => render_treeview(model, config, options), }
  },
}
