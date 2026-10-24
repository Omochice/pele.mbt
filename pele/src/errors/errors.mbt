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

///|
/// Where `offset` is in `src`: its line and column from 1, and its line with a caret under it.
pub fn locate(src : String, offset : Int32) -> (Int32, Int32, String) {
  let mut line = 1
  let mut line_start = 0
  let mut i = @util.index_of(src, "\n")
  while i != -1 && i < offset {
    line += 1
    line_start = i + 1
    i = @util.index_of(src, "\n", from=i + 1)
  }
  let found_end = @util.index_of(src, "\n", from=offset)
  let line_end = if found_end == -1 { src.length() } else { found_end }
  let column = offset - line_start + 1
  let text = src.view(start_offset=line_start, end_offset=line_end)
  // A line of a hundred million characters copied once for each piece added to it would be held
  // several times over, so the snippet is built at its final size, which needs no copy at the end.
  let dashes = if column > 1 { column - 1 } else { 0 }
  let snippet = StringBuilder(size_hint=(text.length() + 1 + dashes + 1) * 2)
  snippet.write_view(text)
  snippet.write_char('\n')
  for _ in 0..<dashes {
    snippet.write_char('-')
  }
  snippet.write_char('^')
  (line, column, snippet.to_string())
}

///|
/// A syntax `PeleError` at `offset` with Mermaid's wording, for a lexical error when `lexical`.
pub fn syntax_error(
  kind : String,
  src : String,
  offset : Int32,
  detail : String,
  lexical~ : Bool = false,
) -> PeleError {
  let (line, column, snippet) = locate(src, offset)
  let (head, tail) = if lexical {
    ("Lexical error on line \{line}. Unrecognized text.\n", "")
  } else {
    ("Parse error on line \{line}:\n", "\n\{detail}")
  }
  let message = StringBuilder(
    size_hint=(head.length() + snippet.length() + tail.length()) * 2,
  )
  message.write_string(head)
  message.write_string(snippet)
  message.write_string(tail)
  let message = message.to_string()
  pele_error(message, code=Syntax, kind~, line~, column~, snippet~)
}

///|
/// The `limit` error pele gives when deep input runs JavaScript out of stack.
pub fn nested_too_deeply() -> PeleError {
  pele_error("Diagram is nested too deeply.", code=Limit)
}
