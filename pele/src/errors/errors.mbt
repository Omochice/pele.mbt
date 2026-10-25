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
/// An input range `[from, to)` replaced by `length` output characters.
pub type Edit = (Int32, Int32, Int32)

///|
/// Where the output offset `at` of one pass that made `edits` comes from in that pass's input.
/// An offset inside a replacement maps into what it replaced, no further than its last character.
fn step_input(edits : Array[Edit], at : Int32) -> Int32 {
  let mut shift = 0
  for edit in edits {
    let (from, to, length) = edit
    let start = from - shift
    if at < start {
      break
    }
    if at < start + length {
      let inside = at - start
      return from +
        (if inside < to - from - 1 { inside } else { to - from - 1 })
    }
    shift += to - from - length
  }
  at + shift
}

///|
/// Where the output offset `at` comes from in the input of the first of `steps`, each of which
/// lists the edits one pass made, in order.
pub fn input_offset(steps : Array[Array[Edit]], at : Int32) -> Int32 {
  let mut at = at
  for s = steps.length() - 1; s >= 0; s = s - 1 {
    at = step_input(steps[s], at)
  }
  at
}

///|
/// The text being parsed, and how to find an offset of it in the source as written.
pub(all) struct Origin {
  parsed : String
  find : (Int32) -> (String, Int32)
}

///|
let origin : Ref[Origin?] = { val: None, }

///|
/// Runs `run` with positions in `next.parsed` reported in the source it was made from.
pub fn[T] locating_in(
  next : Origin,
  run : () -> T raise PeleError,
) -> T raise PeleError {
  let outer = origin.val
  origin.val = Some(next)
  defer {
    origin.val = outer
  }
  run()
}

///|
/// The source as written and the offset in it that `offset` in `src` comes from, when `src` is
/// exactly the text being parsed; otherwise `src` and `offset` themselves.
pub fn written(src : String, offset : Int32) -> (String, Int32) {
  match origin.val {
    Some(found) if src.length() == found.parsed.length() && src == found.parsed =>
      (found.find)(offset)
    _ => (src, offset)
  }
}

///|
/// Where `offset` is in `src`: its line and column from 1, and its line with a caret under it.
pub fn locate(src : String, offset : Int32) -> (Int32, Int32, String) {
  let (src, offset) = written(src, offset)
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
