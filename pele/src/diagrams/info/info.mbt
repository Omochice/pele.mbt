///|
/// The info diagram type.
pub let info : @types.Diagram = {
  kind: "info",
  section: None,
  keep_comments: false,
  math: false,
  parse: (source, _, title, _, _) => {
    let model = build_info(parse_info(source), title)
    { render: (_, options) => render_info(model, options), }
  },
}
