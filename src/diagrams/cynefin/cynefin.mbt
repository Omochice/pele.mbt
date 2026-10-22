///|
/// The cynefin diagram type.
pub let cynefin : @types.Diagram = {
  kind: "cynefin",
  section: None,
  keep_comments: false,
  parse: (source, _, title, _, _) => {
    let model = build_cynefin(parse_cynefin(source), title)
    { render: (config, options) => render_cynefin(model, config, options), }
  },
}
