///|
/// The radar chart diagram type.
pub let radar : @types.Diagram = {
  kind: "radar",
  section: None,
  keep_comments: false,
  parse: (source, _, title, _, _) => {
    let model = build_radar(parse_radar(source), title)
    { render: (config, options) => render_radar(model, config, options), }
  },
}
