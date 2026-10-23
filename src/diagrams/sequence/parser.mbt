///|
/// Parses a sequence diagram into `db`, as Mermaid's grammar does.
/// Raises `PeleError` for text the grammar or the model rejects.
pub fn parse_sequence(src : String, db : SeqDb) -> Unit raise @errors.PeleError {
  ignore(src)
  ignore(db)
  raise @errors.pele_error("not implemented")
}
