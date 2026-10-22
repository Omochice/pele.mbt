///|
const END : Int32 = 0

///|
const EOF : Int32 = 1

///|
const INVALID : Int32 = 2

///|
const NEWLINE : Int32 = 3

///|
const JOURNEY : Int32 = 4

///|
const TITLE : Int32 = 5

///|
/// The first of the accessibility token types, numbered as `@common.accessibility` requires.
const ACC_TITLE : Int32 = 6

///|
const ACC_DESCR : Int32 = 8

///|
const ACC_DESCR_MULTILINE_VALUE : Int32 = 10

///|
const SECTION : Int32 = 11

///|
const TASK_NAME : Int32 = 12

///|
const TASK_DATA : Int32 = 13

///|
const COLON : Int32 = 14

///|
let token_names : Array[String] = [
  "$end", "EOF", "INVALID", "NEWLINE", "journey", "title", "acc_title", "acc_title_value",
  "acc_descr", "acc_descr_value", "acc_descr_multiline_value", "section", "taskName",
  "taskData", ":",
]

///|
/// `#`, a line break, and `;` end every kind of text; a colon also ends a task name or a section.
fn text_end(src : String, from : Int32, colon : Bool) -> Int32 {
  let n = src.length()
  let mut e = from
  while e < n {
    let c = @util.code_at(src, e)
    if c == '#'.to_int() ||
      c == '\n'.to_int() ||
      c == ';'.to_int() ||
      (colon && c == ':'.to_int()) {
      break
    }
    e += 1
  }
  e
}

///|
fn emit(out : @common.Tokens, kind : Int32, start : Int32, end : Int32) -> Unit {
  out.kinds.push(kind)
  out.starts.push(start)
  out.ends.push(end)
}

///|
/// Splits a journey into tokens as Mermaid's Jison lexer does.
fn tokenize(src : String) -> @common.Tokens {
  let n = src.length()
  let out : @common.Tokens = { kinds: [], starts: [], ends: [], src, }
  let mut p = 0
  while true {
    p = @common.skip_trivia(src, p)
    if p >= n {
      break
    }
    let c = @util.code_at(src, p)
    if c == '\n'.to_int() {
      let mut e = p + 1
      while @util.code_at(src, e) == '\n'.to_int() {
        e += 1
      }
      emit(out, NEWLINE, p, e)
      p = e
      continue
    }
    if @common.word_at(src, p, "journey") &&
      !@util.is_word(@util.code_at(src, p + 7)) {
      emit(out, JOURNEY, p, p + 7)
      p += 7
      continue
    }
    // `\s` after a keyword also takes a line break, so `title` alone on a line takes the next line as its text.
    if @common.word_at(src, p, "title") &&
      @util.is_space(@util.code_at(src, p + 5)) {
      let e = text_end(src, p + 6, false)
      if e > p + 6 {
        emit(out, TITLE, p, e)
        p = e
        continue
      }
    }
    let after = @common.accessibility(out, p, ACC_TITLE)
    if after != p {
      p = after
      continue
    }
    if @common.word_at(src, p, "section") &&
      @util.is_space(@util.code_at(src, p + 7)) {
      let e = text_end(src, p + 8, true)
      if e > p + 8 {
        emit(out, SECTION, p, e)
        p = e
        continue
      }
    }
    if c == ':'.to_int() {
      let e = text_end(src, p + 1, false)
      if e > p + 1 {
        emit(out, TASK_DATA, p, e)
        p = e
      } else {
        emit(out, COLON, p, p + 1)
        p += 1
      }
    } else if c == ';'.to_int() {
      emit(out, INVALID, p, p + 1)
      p += 1
    } else {
      let e = text_end(src, p + 1, true)
      emit(out, TASK_NAME, p, e)
      p = e
    }
  }
  // Jison marks its lexer done when a rule runs on empty input, so an accessibility value that
  // matches nothing at the very end of the text is followed by no EOF token.
  if out.starts.is_empty() || out.starts[out.starts.length() - 1] < n {
    emit(out, EOF, n, n)
  }
  emit(out, END, n, n)
  out
}
