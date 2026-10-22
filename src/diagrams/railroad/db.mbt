///|
/// Does what `text.replace(/\n\s+/g, '\n')` does.
fn join_indented_lines(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    @util.write_range(out, text, i, i + 1)
    if @util.code_at(text, i) == '\n'.to_int() &&
      @util.is_space(@util.code_at(text, i + 1)) {
      i += 1
      while @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
    } else {
      i += 1
    }
  }
  out.to_string()
}

///|
fn non_empty(value : String?) -> String? {
  match value {
    Some("") => None
    _ => value
  }
}

///|
fn lower(c : Int32) -> Int32 {
  if c >= 'A'.to_int() && c <= 'Z'.to_int() {
    c + 32
  } else {
    c
  }
}

///|
/// Whether `text` holds `word` at `at`, ignoring ASCII case.
fn word_at(text : String, word : String, at : Int32) -> Bool {
  if at + word.length() > text.length() {
    return false
  }
  for i in 0..<word.length() {
    if lower(@util.code_at(text, at + i)) != @util.code_at(word, i) {
      return false
    }
  }
  true
}

///|
/// The notation named by the keyword, as `/^\s*railroad-(ebnf-|abnf-|peg-)?beta/i` reads it.
/// Mermaid has a detector per keyword, each matching without regard to case.
fn notation_of(source : String) -> Notation? {
  let mut at = 0
  while @util.is_space(@util.code_at(source, at)) {
    at += 1
  }
  guard word_at(source, "railroad-", at) else { return None }
  at += "railroad-".length()
  for infix in [("ebnf-", Ebnf), ("abnf-", Abnf), ("peg-", Peg)] {
    if word_at(source, infix.0, at) {
      return if word_at(source, "beta", at + infix.0.length()) {
        Some(infix.1)
      } else {
        None
      }
    }
  }
  if word_at(source, "beta", at) {
    Some(Railroad)
  } else {
    None
  }
}

///|
/// Reads a railroad diagram in any of the four notations.
/// `title` is the front matter title, used when the diagram has none.
/// Raises a syntax `PeleError` on invalid text.
pub fn parse_railroad(
  source : String,
  title : String?,
) -> RailroadModel raise @errors.PeleError {
  guard notation_of(source) is Some(notation) else {
    raise @errors.pele_error(
      "No railroad diagram keyword found.",
      code=Syntax,
      kind="railroad",
    )
  }
  let ast = match notation {
    Railroad => parse_ir(source)
    Ebnf => parse_ebnf(source)
    Abnf => parse_abnf(source)
    _ => abort("not ported yet")
  }
  {
    notation,
    title: match non_empty(ast.title) {
      Some(_) as own => own
      None => non_empty(title)
    },
    acc_title: non_empty(ast.acc_title).map(@util.trim_start),
    acc_descr: non_empty(ast.acc_descr).map(join_indented_lines),
    rules: ast.rules,
  }
}
