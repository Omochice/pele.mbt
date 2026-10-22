///|
/// Reads a journey into `db`. Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_journey(
  source : String,
  db : JourneyDb,
) -> Unit raise @errors.PeleError {
  ignore(db)
  raise @errors.syntax_error("journey", source, 0, "not implemented")
}
