///|
/// The tokens of a source: the type, start and end offset of each, ending in three `EOF`s.
pub(all) struct Tokens {
  types : Array[Int32]
  starts : Array[Int32]
  ends : Array[Int32]
}

///|
const WORD : Int32 = 1

///|
const PUNCTUATION : Int32 = 2

///|
let char_class : FixedArray[Int32] = build_char_class()

///|
fn build_char_class() -> FixedArray[Int32] {
  let classes = FixedArray::make(128, 0)
  for c in 48..<=57 {
    classes[c] = WORD
  }
  for c in 65..<=90 {
    classes[c] = WORD
    classes[c + 32] = WORD
  }
  classes[95] = WORD
  for c in "!#$&*+/=?^|~" {
    classes[c.to_int()] = PUNCTUATION
  }
  classes
}

///|
/// The length of each keyword, by token type.
let keyword_length : FixedArray[Int32] = [
  0, 12, 5, 14, 3, 9, 2, 2, 2, 2, 2, 4, 3, 4, 8, 5, 5, 7, 6, 4, 5,
]

///|
fn is_word_char(c : Int32) -> Bool {
  c >= 0 && c < 128 && (char_class[c] & WORD) != 0
}

///|
/// Mermaid's INCLUDE and EXTEND are the only keywords matched without regard to case.
fn starts_with_no_case(src : String, at : Int32, word : String) -> Bool {
  for k in 0..<word.length() {
    if (@util.code_at(src, at + k) | 32) != word.unsafe_get(k).to_int() {
      return false
    }
  }
  true
}

///|
/// The keyword that is a prefix of the text at `at`, tried in the order of Mermaid's token list.
fn keyword_at(src : String, at : Int32, c : Int32) -> Int32 {
  let starts = (word : String) => @util.starts_with_at(src, word, at)
  match c {
    97 => if starts("actor") { ACTOR } else { 0 }
    115 =>
      if starts("systemBoundary") {
        SYSTEM_BOUNDARY
      } else if starts("style") {
        STYLE
      } else {
        0
      }
    101 =>
      if starts("end") {
        END
      } else if starts_with_no_case(src, at, "extend") {
        EXTEND
      } else {
        0
      }
    69 => if starts_with_no_case(src, at, "extend") { EXTEND } else { 0 }
    100 => if starts("direction") { DIRECTION } else { 0 }
    84 => if starts("TD") { TD } else if starts("TB") { TB } else { 0 }
    66 => if starts("BT") { BT } else { 0 }
    76 => if starts("LR") { LR } else { 0 }
    82 => if starts("RL") { RL } else { 0 }
    110 => if starts("note") { NOTE } else { 0 }
    102 => if starts("for") { FOR } else if starts("false") { FALSE } else { 0 }
    106 => if starts("json") { JSON } else { 0 }
    99 =>
      if starts("classDef") {
        CLASS_DEF
      } else if starts("class") {
        CLASS
      } else {
        0
      }
    105 | 73 =>
      if starts_with_no_case(src, at, "include") {
        INCLUDE
      } else {
        0
      }
    116 => if starts("true") { TRUE } else { 0 }
    117 => if starts("usecase-beta") { USECASE } else { 0 }
    _ => 0
  }
}

///|
/// The line and column from 1 of `offset`, where `\r\n`, `\r` and `\n` each end a line.
fn line_column(src : String, offset : Int32) -> (Int32, Int32) {
  let mut line = 1
  let mut line_start = 0
  let mut i = 0
  while i < offset {
    let c = @util.code_at(src, i)
    if c == 10 || c == 13 {
      if c == 13 && i + 1 < offset && @util.code_at(src, i + 1) == 10 {
        i += 1
      }
      line += 1
      line_start = i + 1
    }
    i += 1
  }
  (line, offset - line_start + 1)
}

///|
/// The end of a quoted string that opens at `at`, or -1 when the line ends first.
fn string_end(src : String, at : Int32, quote : Int32) -> Int32 {
  for k in (at + 1)..<src.length() {
    let c = @util.code_at(src, k)
    if c == quote {
      return k + 1
    }
    if c == 10 || c == 13 {
      return -1
    }
  }
  -1
}

///|
fn starts_token(src : String, at : Int32) -> Bool {
  let c = @util.code_at(src, at)
  if c != 34 && c != 39 {
    return true
  }
  (c == 34 && @util.code_at(src, at + 1) == 96) || string_end(src, at, c) != -1
}

///|
/// Mermaid reports the first character no token starts with, and how many characters its lexer
/// skipped before one did.
fn lex_error(src : String, offset : Int32, length : Int32) -> @errors.PeleError {
  let (line, column) = line_column(src, offset)
  @errors.pele_error(
    "Error lexing usecase diagram: unexpected character: ->\{@util.slice(src, offset, end=offset + 1)}<- at offset: \{offset}, skipped \{length} characters. at line \{line}, column \{column} [\{offset},\{offset + length})",
    code=Syntax,
    kind="usecase",
    line~,
    column~,
  )
}

///|
fn is_line_break(c : Int32) -> Bool {
  c == 10 || c == 13
}

///|
/// Splits a use case diagram into the tokens of Mermaid's Chevrotain lexer: the first pattern in
/// its list that matches wins, a keyword gives way to a longer identifier, and `json id@` and `<<`
/// switch to modes that read a JSON object and a stereotype.
/// Raises a syntax error, in Mermaid's words, at a quote that does not close on its line or a `<<` that ends one.
pub fn tokenize(src : String) -> Tokens raise @errors.PeleError {
  let types : Array[Int32] = []
  let starts : Array[Int32] = []
  let ends : Array[Int32] = []
  let n = src.length()
  let at = (k : Int32) => @util.code_at(src, k)
  let mut i = 0
  // Whether only blanks came before on this line, where comments and accessibility lines may start.
  let mut line_start = true
  let mut no_brace = false
  while i < n {
    let c = at(i)
    if c == 32 || c == 9 {
      i += 1
      continue
    }
    let mut kind = 0
    let mut end = i + 1
    let mut fresh = false
    if is_word_char(c) {
      if c == 97 && line_start && @util.starts_with_at(src, "acc", i) {
        let descr = @util.starts_with_at(src, "Descr", i + 3)
        if descr || @util.starts_with_at(src, "Title", i + 3) {
          let mut j = i + 8
          while @util.is_blank(at(j)) {
            j += 1
          }
          let next = at(j)
          if next == 58 {
            kind = if descr { ACC_DESCR_LINE } else { ACC_TITLE_LINE }
            end = j + 1
            while end < n && !is_line_break(at(end)) {
              end += 1
            }
          } else if next == 123 && descr && !no_brace {
            let close = @util.index_of(src, "}", from=j + 1)
            if close == -1 {
              no_brace = true
            } else {
              kind = ACC_DESCR_BLOCK
              end = close + 1
            }
          }
        }
      } else if c == 106 &&
        @util.starts_with_at(src, "json", i) &&
        @util.is_blank(at(i + 4)) {
        let mut j = i + 5
        while @util.is_blank(at(j)) {
          j += 1
        }
        let id = j
        while is_word_char(at(j)) {
          j += 1
        }
        if j > id {
          while @util.is_blank(at(j)) {
            j += 1
          }
          if at(j) == 64 {
            j += 1
            while @util.is_blank(at(j)) {
              j += 1
            }
            if at(j) == 123 {
              types.push(JSON_DECLARATION_START)
              starts.push(i)
              ends.push(j)
              let mut depth = 0
              let mut quoted = false
              let mut escaped = false
              let mut k = j
              while k < n {
                let ch = at(k)
                if quoted {
                  if escaped {
                    escaped = false
                  } else if ch == 92 {
                    escaped = true
                  } else if ch == 34 {
                    quoted = false
                  }
                } else if ch == 34 {
                  quoted = true
                } else if ch == 123 {
                  depth += 1
                } else if ch == 125 {
                  depth -= 1
                  if depth == 0 {
                    break
                  }
                }
                k += 1
              }
              types.push(
                if k < n {
                  JSON_OBJECT_LITERAL
                } else {
                  UNCLOSED_JSON_OBJECT_LITERAL
                },
              )
              starts.push(j)
              i = if k < n { k + 1 } else { n }
              ends.push(i)
              line_start = false
              continue
            }
          }
        }
      }
      if kind == 0 {
        while end < n && is_word_char(at(end)) {
          end += 1
        }
        let keyword = keyword_at(src, i, c)
        if keyword != 0 {
          // A keyword that is only the start of a longer word is an identifier.
          if keyword == USECASE || end - i == keyword_length[keyword] {
            kind = keyword
            end = i + keyword_length[keyword]
          } else {
            kind = IDENTIFIER
          }
        } else if (c == 111 || c == 120) && at(i + 1) == 45 && at(i + 2) == 45 {
          kind = if c == 111 { BACKWARD_CIRCLE } else { BACKWARD_CROSS }
          end = i + 3
        } else if @util.is_digit(c) {
          // `1mg` is an identifier, and `1.5px` is a number because the identifier stops at the dot.
          let mut digits = i + 1
          while @util.is_digit(at(digits)) {
            digits += 1
          }
          if at(digits) == 46 && @util.is_digit(at(digits + 1)) {
            kind = NUMBER
            end = digits + 2
            while @util.is_digit(at(end)) {
              end += 1
            }
            while @util.is_letter(at(end)) {
              end += 1
            }
          } else {
            kind = IDENTIFIER
          }
        } else {
          kind = IDENTIFIER
          while at(end) == 45 && is_word_char(at(end + 1)) {
            kind = CSS_IDENTIFIER
            end += 2
            while is_word_char(at(end)) {
              end += 1
            }
          }
        }
      }
    } else if c == 10 {
      kind = NEWLINE
      fresh = true
    } else if c == 13 {
      kind = NEWLINE
      fresh = true
      if at(end) == 10 {
        end += 1
      }
    } else if c == 34 || c == 39 {
      if c == 34 && at(i + 1) == 96 {
        let close = @util.index_of(src, "`\"", from=i + 2)
        kind = if close == -1 {
          UNCLOSED_MARKDOWN_STRING
        } else {
          MARKDOWN_STRING
        }
        end = if close == -1 { n } else { close + 2 }
      } else {
        kind = PLAIN_STRING
        end = string_end(src, i, c)
        if end == -1 {
          let mut restart = i + 1
          while restart < n && !starts_token(src, restart) {
            restart += 1
          }
          raise lex_error(src, i, restart - i)
        }
      }
    } else if c == 37 {
      if line_start && at(end) == 37 {
        kind = COMMENT
        while end < n && !is_line_break(at(end)) {
          end += 1
        }
      } else {
        kind = PERCENT
      }
    } else if c == 45 {
      if at(end) != 45 {
        kind = DASH
      } else {
        while at(end) == 45 {
          end += 1
        }
        let next = at(end)
        let two = end - i == 2
        if two && next == 124 && at(end + 1) == 62 {
          kind = GENERALIZATION
          end += 2
        } else if next == 62 {
          kind = FORWARD_SOLID
          end += 1
        } else if two && (next == 111 || next == 120) {
          kind = if next == 111 { FORWARD_CIRCLE } else { FORWARD_CROSS }
          end += 1
        } else {
          kind = MARKERLESS_SOLID
        }
      }
    } else if c == 46 {
      let next = at(end)
      if next == 46 && at(end + 1) == 62 {
        kind = DEPENDENCY_ARROW
        end += 2
      } else if @util.is_digit(next) {
        kind = NUMBER
        while @util.is_digit(at(end)) {
          end += 1
        }
        while @util.is_letter(at(end)) {
          end += 1
        }
      } else {
        kind = DOT
      }
    } else if c == 60 {
      if at(end) == 60 {
        types.push(STEREOTYPE_START)
        starts.push(i)
        ends.push(i + 2)
        line_start = false
        i += 2
        if i >= n {
          break
        }
        if at(i) == 62 && at(i + 1) == 62 {
          kind = STEREOTYPE_END
          end = i + 2
        } else {
          let mut close = i
          let mut found = false
          while close < n {
            let ch = at(close)
            if is_line_break(ch) {
              break
            }
            if ch == 62 && at(close + 1) == 62 {
              found = true
              break
            }
            close += 1
          }
          if found && @util.trim(@util.slice(src, i, end=close)) != "" {
            types.push(STEREOTYPE_TEXT)
            starts.push(i)
            ends.push(close)
            kind = STEREOTYPE_END
            i = close
            end = close + 2
          } else {
            while close < n && !is_line_break(at(close)) {
              close += 1
            }
            if close == i {
              while close < n && is_line_break(at(close)) {
                close += 1
              }
              raise lex_error(src, i, close - i)
            }
            kind = UNCLOSED_STEREOTYPE_TEXT
            end = close
          }
        }
      } else if at(end) == 45 && at(end + 1) == 45 {
        kind = BACKWARD_SOLID
        end += 2
        while at(end) == 45 {
          end += 1
        }
      } else {
        kind = LABEL_PUNCTUATION
      }
    } else if c == 58 {
      if at(end) == 58 && at(end + 1) == 58 {
        kind = CLASS_SEPARATOR
        end += 2
      } else {
        kind = COLON
      }
    } else if c == 64 {
      if at(end) == 123 {
        kind = METADATA_START
        end += 1
      } else {
        kind = AT
      }
    } else if c == 123 {
      kind = LBRACE
    } else if c == 125 {
      kind = RBRACE
    } else if c == 91 {
      kind = LBRACKET
    } else if c == 93 {
      kind = RBRACKET
    } else if c == 40 {
      kind = LPAREN
    } else if c == 41 {
      kind = RPAREN
    } else if c == 44 {
      kind = COMMA
    } else if c == 35 {
      while @util.is_hex(at(end)) {
        end += 1
      }
      kind = if end > i + 1 { HASH_COLOR } else { CSS_PUNCTUATION }
    } else if c == 92 {
      if at(end) == 44 {
        kind = CSS_ESCAPED_COMMA
        end += 1
      } else {
        kind = LABEL_PUNCTUATION
      }
    } else if c < 127 && c > 32 {
      kind = if (char_class[c] & PUNCTUATION) != 0 {
        CSS_PUNCTUATION
      } else {
        LABEL_PUNCTUATION
      }
    } else {
      kind = LABEL_SYMBOL
      while end < n {
        let ch = at(end)
        if (ch >= 32 && ch < 127) || ch == 9 || ch == 10 || ch == 13 {
          break
        }
        end += 1
      }
    }
    types.push(kind)
    starts.push(i)
    ends.push(end)
    i = end
    line_start = fresh
  }
  for _ in 0..<3 {
    types.push(EOF)
    starts.push(n)
    ends.push(n)
  }
  { types, starts, ends, }
}
