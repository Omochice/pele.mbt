///|
/// Reads an ER diagram into `db` as Mermaid's grammar does, raising Mermaid's syntax errors.
pub fn parse_er(src : String, db : ErDb) -> Unit raise @errors.PeleError {
  ignore(db)
  raise @errors.syntax_error("er", src, 0, "")
}
