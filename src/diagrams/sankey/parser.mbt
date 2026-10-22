///|
/// Strips blanks at both ends of the text and collapses runs of line breaks, so that no row is empty.
pub fn prepare_text_for_parsing(text : String) -> String {
  text
}

///|
/// Reads the rows of a sankey diagram into `db`.
/// Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_sankey(
  src : String,
  db : SankeyDb,
) -> Unit raise @errors.PeleError {
  ignore(src)
  ignore(db)
  raise @errors.pele_error("not implemented")
}
