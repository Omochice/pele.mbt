// Lexer rules that Mermaid's journey and timeline grammars have in common, ported from the
// compiled Jison rules: comments, whitespace, and the accTitle and accDescr statements.

///|
/// The index of the next line break at or after `from`, or the length of the text.
pub fn line_end(src : String, from : Int32) -> Int32 {
  let at = @util.index_of(src, "\n", from~)
  if at == -1 {
    src.length()
  } else {
    at
  }
}

///|
/// Skips comments and whitespace from `from`, stopping at a line break, which starts a NEWLINE token.
pub fn skip_trivia(src : String, from : Int32) -> Int32 {
  // Jison compiles `\%%` to a single `%`, so one percent sign starts a comment, and the second
  // comment rule takes any character before `%%` with it, a line break included.
  let n = src.length()
  let mut p = from
  while p < n {
    let c = @util.code_at(src, p)
    if c == '%' && @util.code_at(src, p + 1) != '{' {
      p = line_end(src, p)
    } else if c != '}' &&
      @util.code_at(src, p + 1) == '%' &&
      @util.code_at(src, p + 2) == '%' {
      p = line_end(src, p + 3)
    } else if c == '\n' {
      return p
    } else if @util.is_space(c) {
      p += 1
      while p < n && @util.is_space(@util.code_at(src, p)) {
        p += 1
      }
    } else if c == '#' {
      p = line_end(src, p)
    } else {
      return p
    }
  }
  p
}

///|
fn skip_space(src : String, from : Int32) -> Int32 {
  let mut p = from
  while @util.is_space(@util.code_at(src, p)) {
    p += 1
  }
  p
}

///|
/// Lexes an accTitle or accDescr statement of `out.src` at `p` into `out`, returning where it ends, or `p` if there is none.
/// The token types acc_title, acc_title_value, acc_descr, acc_descr_value and
/// acc_descr_multiline_value must be numbered consecutively from `first`.
pub fn accessibility(out : Tokens, p : Int32, first : Int32) -> Int32 {
  let src = out.src
  let descr = word_at(src, p, "accdescr")
  if !descr && !word_at(src, p, "acctitle") {
    return p
  }
  let n = src.length()
  let mut q = skip_space(src, p + 8)
  let c = @util.code_at(src, q)
  let emit = (kind : Int32, s : Int32, e : Int32) => {
    out.kinds.push(kind)
    out.starts.push(s)
    out.ends.push(e)
  }
  if c == ':' {
    q = skip_space(src, q + 1)
    let end = line_end(src, q)
    emit(if descr { first + 2 } else { first }, p, q)
    emit(if descr { first + 3 } else { first + 1 }, q, end)
    return end
  }
  if !descr || c != '{' {
    return p
  }
  q = skip_space(src, q + 1)
  while @util.code_at(src, q) != '}' {
    let mut end = @util.index_of(src, "}", from=q)
    if end == -1 {
      end = n
    }
    emit(first + 4, q, end)
    if q == n {
      return n
    }
    q = end
  }
  q + 1
}
