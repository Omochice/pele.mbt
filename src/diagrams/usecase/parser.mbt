///|
/// Parses a use case diagram into its model, with Mermaid's messages for what it rejects.
pub fn parse_usecase(
  _source : String,
  title? : String,
) -> UsecaseModel raise @errors.PeleError {
  ignore(title)
  raise @errors.pele_error("not implemented")
}
