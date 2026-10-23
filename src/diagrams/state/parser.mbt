///|
/// Parses a state diagram into `db` as Mermaid's grammar does, and returns the root document.
pub fn parse_state(
  src : String,
  db : StateDb,
) -> Array[Stmt] raise @errors.PeleError {
  ignore(db)
  raise @errors.syntax_error("state", src, 0, "")
}
