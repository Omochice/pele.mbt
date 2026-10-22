///|
/// Reads a timeline into `db`.
/// Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_timeline(
  src : String,
  db : TimelineDb,
) -> Unit raise @errors.PeleError {
  ignore((src, db))
  raise @errors.pele_error("not implemented")
}
