///|
/// The pie chart diagram type.
pub let pie : @types.Diagram = {
  kind: "pie",
  section: None,
  keep_comments: false,
  parse: (_, _, _, _, _) => {
    render: (_, _) => { svg: "", width: 0, height: 0, links: [], },
  },
}
