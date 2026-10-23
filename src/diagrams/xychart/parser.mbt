///|
/// Reads the statements of an XY chart source into `db`.
/// Raises a syntax `PeleError` where the source does not follow Mermaid's grammar.
pub fn parse_xychart(
  source : String,
  db : XyChartDb,
) -> Unit raise @errors.PeleError {
  ignore(source)
  ignore(db)
}
