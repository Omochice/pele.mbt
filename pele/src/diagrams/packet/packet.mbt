///|
/// The packet diagram type.
pub let packet : @types.Diagram = {
  kind: "packet",
  section: None,
  keep_comments: false,
  math: false,
  parse: (source, config, title, _, _) => {
    let model = build_packet(parse_packet(source), config, title)
    { render: (config, options) => render_packet(model, config, options), }
  },
}
