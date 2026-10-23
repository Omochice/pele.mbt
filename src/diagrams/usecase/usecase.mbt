///|
/// The use case diagram type.
/// pele marks it as one whose labels may hold math; with no typesetter here, math stays text, as it does in pele without one.
pub let usecase : @types.Diagram = {
  kind: "usecase",
  section: None,
  keep_comments: false,
  parse: (source, _, title, _, _) => {
    let model = parse_usecase(source, title?)
    { render: (config, options) => render_usecase(model, config, options), }
  },
}
