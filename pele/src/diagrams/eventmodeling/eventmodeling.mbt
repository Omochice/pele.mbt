///|
/// The event modeling diagram type.
pub let eventmodeling : @types.Diagram = {
  kind: "eventmodeling",
  section: None,
  keep_comments: true,
  math: false,
  parse: (source, _, title, _, _) => {
    let model = build_event_model(read_event_model(source), title)
    { render: (config, options) => render_event_model(model, config, options), }
  },
}
