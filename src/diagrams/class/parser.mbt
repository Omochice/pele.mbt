///|
/// Reads a class diagram into `db`, failing as Mermaid's grammar does.
pub fn parse_class(src : String, db : ClassDb) -> Unit raise @errors.PeleError {
  ignore(db)
  raise @errors.syntax_error("class", src, 0, "")
}
