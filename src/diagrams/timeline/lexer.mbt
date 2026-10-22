///|
/// The token types of Mermaid's timeline lexer, numbered as pele numbers them.
/// The five accessibility types must stay consecutive for `@common.accessibility`.
pub const T_END : Int32 = 0

///|
pub const T_EOF : Int32 = 1

///|
pub const T_INVALID : Int32 = 2

///|
pub const T_NEWLINE : Int32 = 3

///|
pub const T_TIMELINE : Int32 = 4

///|
pub const T_TIMELINE_LR : Int32 = 5

///|
pub const T_TIMELINE_TD : Int32 = 6

///|
pub const T_TITLE : Int32 = 7

///|
pub const T_ACC_TITLE : Int32 = 8

///|
pub const T_ACC_TITLE_VALUE : Int32 = 9

///|
pub const T_ACC_DESCR : Int32 = 10

///|
pub const T_ACC_DESCR_VALUE : Int32 = 11

///|
pub const T_ACC_DESCR_MULTILINE_VALUE : Int32 = 12

///|
pub const T_SECTION : Int32 = 13

///|
pub const T_PERIOD : Int32 = 14

///|
pub const T_EVENT : Int32 = 15

///|
/// Splits a timeline into tokens as Mermaid's lexer does.
pub fn tokenize(src : String) -> @common.Tokens {
  let n = src.length()
  let out : @common.Tokens = { kinds: [], starts: [], ends: [], src, }
  let mut p = 0
  let emit = (kind : Int32, e : Int32) => {
    out.kinds.push(kind)
    out.starts.push(p)
    out.ends.push(e)
    p = e
  }
  while true {
    p = @common.skip_trivia(src, p)
    if p >= n {
      break
    }
    let c = @util.code_at(src, p)
    if c == '\n' {
      let mut e = p + 1
      while @util.code_at(src, e) == '\n' {
        e += 1
      }
      emit(T_NEWLINE, e)
      continue
    }
    if @common.word_at(src, p, "timeline") {
      let mut e = p + 8
      while @util.code_at(src, e) == ' ' || @util.code_at(src, e) == '\t' {
        e += 1
      }
      let lr = @common.word_at(src, e, "lr")
      if e > p + 8 &&
        (lr || @common.word_at(src, e, "td")) &&
        !@util.is_word(@util.code_at(src, e + 2)) {
        emit(if lr { T_TIMELINE_LR } else { T_TIMELINE_TD }, e + 2)
        continue
      }
      if !@util.is_word(@util.code_at(src, p + 8)) {
        emit(T_TIMELINE, p + 8)
        continue
      }
    }
    // `\s` after a keyword also takes a line break, so `title` alone on a line takes the next line as its text.
    if @common.word_at(src, p, "title") &&
      @util.is_space(@util.code_at(src, p + 5)) &&
      p + 6 < n &&
      @util.code_at(src, p + 6) != '\n' {
      emit(T_TITLE, @common.line_end(src, p + 6))
      continue
    }
    let after = @common.accessibility(out, p, T_ACC_TITLE)
    if after != p {
      p = after
      continue
    }
    if @common.word_at(src, p, "section") &&
      @util.is_space(@util.code_at(src, p + 7)) {
      let mut e = p + 8
      while e < n &&
            @util.code_at(src, e) != ':' &&
            @util.code_at(src, e) != '\n' {
        e += 1
      }
      if e > p + 8 {
        emit(T_SECTION, e)
        continue
      }
    }
    if c != ':' {
      let mut e = p + 1
      while e < n {
        let k = @util.code_at(src, e)
        if k == '#' || k == ':' || k == '\n' {
          break
        }
        e += 1
      }
      emit(T_PERIOD, e)
      continue
    }
    // An event runs to the end of the line or to a colon that is followed by whitespace.
    if @util.is_space(@util.code_at(src, p + 1)) {
      let mut e = p + 2
      while e < n {
        let k = @util.code_at(src, e)
        if k == '\n' || (k == ':' && @util.is_space(@util.code_at(src, e + 1))) {
          break
        }
        e += 1
      }
      if e > p + 2 {
        emit(T_EVENT, e)
        continue
      }
    }
    emit(T_INVALID, p + 1)
  }
  // Jison marks its lexer done when a rule runs on empty input, so an accessibility value that
  // matches nothing at the very end of the text is followed by no EOF token.
  if out.starts.is_empty() || out.starts[out.starts.length() - 1] < n {
    emit(T_EOF, n)
  }
  emit(T_END, n)
  out
}
