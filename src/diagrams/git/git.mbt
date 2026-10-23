///|
/// The git graph diagram type.
pub let git : @types.Diagram = {
  kind: "gitGraph",
  section: None,
  keep_comments: false,
  math: false,
  parse: (source, config, title, _, _) => {
    let model = build_git(parse_git(source), config, title)
    {
      render: (render_config, options) => {
        render_git(model, render_config, options)
      },
    }
  },
}
