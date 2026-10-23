///|
/// Reads a requirement diagram as pele's requirement diagram does, with the title from front matter.
pub fn parse_model(
  source : String,
  title : String?,
) -> RequirementDb raise @errors.PeleError {
  let db = RequirementDb::new()
  if title is Some(title) && title != "" {
    db.title = Some(title)
  }
  parse_requirement(source, db)
  db
}

///|
/// The requirement diagram type.
pub let requirement : @types.Diagram = {
  kind: "requirement",
  section: None,
  keep_comments: false,
  parse: (source, _, title, _, _) => {
    let db = parse_model(source, title)
    { render: (config, options) => render_requirement(db, config, options), }
  },
}
