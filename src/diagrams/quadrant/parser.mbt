///|
/// Reads a quadrant chart into `db`.
/// Raises a syntax `PeleError` with Mermaid's message on text its grammar does not accept, or what `db` raises for a style it rejects.
pub fn parse_quadrant(
  source : String,
  db : QuadrantDb,
) -> Unit raise @errors.PeleError {
  ignore(db)
  raise @errors.syntax_error("quadrantChart", source, 0, "not implemented")
}
