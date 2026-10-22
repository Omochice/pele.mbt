///|
/// What kind of failure a `PeleError` reports, as pele's `PeleErrorCode`.
pub(all) enum ErrorCode {
  UnsupportedDiagram
  Syntax
  Semantic
  Limit
}

///|
/// The code as pele spells it.
pub fn ErrorCode::to_string(self : ErrorCode) -> String {
  match self {
    UnsupportedDiagram => "unsupported-diagram"
    Syntax => "syntax"
    Semantic => "semantic"
    Limit => "limit"
  }
}

///|
/// The details of a rejected diagram.
/// `kind` and `mermaid_type` are `None` until the diagram type is known.
pub(all) struct Failure {
  message : String
  code : ErrorCode
  kind : String?
  mermaid_type : String?
  line : Int32
  column : Int32
  snippet : String
}

///|
/// A diagram that pele cannot render, with the same codes and messages as pele's `PeleError`.
pub(all) suberror PeleError {
  PeleError(Failure)
}

///|
/// Builds a `PeleError`; `code` defaults to `Syntax` as in pele.
pub fn pele_error(
  message : String,
  code~ : ErrorCode = Syntax,
  kind? : String,
  mermaid_type? : String,
  line~ : Int32 = 0,
  column~ : Int32 = 0,
  snippet~ : String = "",
) -> PeleError {
  PeleError({ message, code, kind, mermaid_type, line, column, snippet, })
}
