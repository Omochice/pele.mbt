///|
/// The Wardley map diagram type.
pub let wardley : @types.Diagram = {
  kind: "wardley",
  section: Some("wardley-beta"),
  keep_comments: false,
  math: false,
  parse: (source, config, title, _, _) => {
    let model = build_wardley(parse_wardley(source), title)
    { render: (_, options) => render_wardley(model, config, options), }
  },
}
