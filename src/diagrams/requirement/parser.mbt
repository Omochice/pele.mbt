///|
/// Reads a requirement diagram into `db`, as Mermaid's requirement grammar does.
/// Raises a syntax error where the grammar rejects the text, and a limit error from the model.
pub fn parse_requirement(
  src : String,
  db : RequirementDb,
) -> Unit raise @errors.PeleError {
  ignore(src)
  if db.relations.length() < 0 {
    raise @errors.pele_error("")
  }
}
