///|
/// The venn diagram type.
pub let venn : @types.Diagram = {
  kind: "venn",
  section: None,
  keep_comments: false,
  math: false,
  parse: (source, _, title, _, _) => {
    let model = parse_venn(source)
    // A `title` statement in the diagram wins over the one in the front matter.
    if model.title is None && title is Some(text) && text != "" {
      model.title = title
    }
    { render: (_, options) => render_venn(model, options), }
  },
}
