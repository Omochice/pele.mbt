///|
/// The use case diagram type.
pub let usecase : @types.Diagram = {
  kind: "usecase",
  section: None,
  keep_comments: false,
  math: true,
  parse: (source, _, title, _, _) => {
    let model = parse_usecase(source, title?)
    { render: (config, options) => render_usecase(model, config, options), }
  },
}
