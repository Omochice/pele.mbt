///|
/// The pie chart diagram type.
pub let pie : @types.Diagram = {
  kind: "pie",
  section: None,
  keep_comments: false,
  math: false,
  parse: (source, _, title, _, _) => {
    let model = build_pie(parse_pie(source), title)
    { render: (config, options) => render_pie(model, config, options), }
  },
}
