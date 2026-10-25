///|
const T_END : Int32 = 0

///|
const T_ERROR : Int32 = 1

///|
const T_EOF : Int32 = 2

///|
const T_NEWLINE : Int32 = 3

///|
const T_VENN : Int32 = 4

///|
const T_TITLE : Int32 = 5

///|
const T_SET : Int32 = 6

///|
const T_UNION : Int32 = 7

///|
const T_TEXT : Int32 = 8

///|
const T_INDENT_TEXT : Int32 = 9

///|
const T_STYLE : Int32 = 10

///|
const T_BRACKET_LABEL : Int32 = 11

///|
const T_NUMERIC : Int32 = 12

///|
const T_HEXCOLOR : Int32 = 13

///|
const T_RGBCOLOR : Int32 = 14

///|
const T_RGBACOLOR : Int32 = 15

///|
const T_IDENTIFIER : Int32 = 16

///|
const T_STRING : Int32 = 17

///|
const T_COMMA : Int32 = 18

///|
const T_COLON : Int32 = 19

///|
let token_names : Array[String] = [
  "$end", "INVALID", "EOF", "NEWLINE", "VENN", "TITLE", "SET", "UNION", "TEXT", "INDENT_TEXT",
  "STYLE", "BRACKET_LABEL", "NUMERIC", "HEXCOLOR", "RGBCOLOR", "RGBACOLOR", "IDENTIFIER",
  "STRING", "COMMA", "COLON",
]

///|
let keywords : Array[(String, Int32)] = [
  ("venn-beta", T_VENN),
  ("set", T_SET),
  ("union", T_UNION),
  ("text", T_TEXT),
  ("style", T_STYLE),
]

///|
/// Reads tokens one at a time, as Mermaid's Jison lexer for venn diagrams does: every rule
/// ignores case, the first rule that matches wins, and a keyword must end at a word boundary.
/// An indented `text` line is a different token after a set or union than anywhere else, so the
/// lexer asks the model, which the parser keeps up to date.
priv struct VennLexer {
  src : String
  db : VennDb
  /// The text and position of the token `next` returned last.
  mut text : String
  mut start : Int32
  mut at : Int32
  mut line_start : Bool
  mut ended : Bool
}

///|
fn VennLexer::new(src : String, db : VennDb) -> VennLexer {
  { src, db, text: "", start: 0, at: 0, line_start: false, ended: false, }
}

///|
fn VennLexer::word(self : VennLexer, at : Int32, word : String) -> Bool {
  for k in 0..<word.length() {
    let c = @util.code_at(self.src, at + k)
    let w = @util.code_at(word, k)
    if c != w && (c + 32 != w || c < 65 || c > 90) {
      return false
    }
  }
  true
}

///|
fn VennLexer::keyword(self : VennLexer, at : Int32, word : String) -> Bool {
  self.word(at, word) &&
  !@util.is_word(@util.code_at(self.src, at + word.length()))
}

///|
/// The end of `rgb(1, 2, 3)` or `rgba(1, 2, 3, 0.5)` whose parenthesis opens at `at`, or -1.
fn VennLexer::color(self : VennLexer, at : Int32, parts : Int32) -> Int32 {
  let src = self.src
  let mut i = at + 1
  for part in 0..<parts {
    while @util.is_space(@util.code_at(src, i)) {
      i += 1
    }
    let from = i
    while @util.is_digit(@util.code_at(src, i)) ||
          @util.code_at(src, i) == '.'.to_int() {
      i += 1
    }
    if i == from {
      return -1
    }
    while @util.is_space(@util.code_at(src, i)) {
      i += 1
    }
    let closer = if part == parts - 1 { ')' } else { ',' }
    if @util.code_at(src, i) != closer.to_int() {
      return -1
    }
    i += 1
  }
  i
}

///|
fn VennLexer::line_end(self : VennLexer, from : Int32) -> Int32 {
  let end = @util.index_of(self.src, "\n", from~)
  if end == -1 {
    self.src.length()
  } else {
    end
  }
}

///|
fn VennLexer::token(self : VennLexer, type_ : Int32, end : Int32) -> Int32 {
  self.text = @util.slice(self.src, self.at, end~)
  self.at = end
  type_
}

///|
fn digits_from(src : String, from : Int32) -> Int32 {
  let mut i = from
  while @util.is_digit(@util.code_at(src, i)) {
    i += 1
  }
  i
}

///|
/// Returns the type of the next token; its text is in `text` and where it starts in `start`.
fn VennLexer::next(self : VennLexer) -> Int32 {
  let src = self.src
  let n = src.length()
  while true {
    let mut i = self.at
    self.start = i
    self.text = ""
    if i >= n {
      if self.ended {
        return T_END
      }
      self.ended = true
      return T_EOF
    }
    let c = @util.code_at(src, i)
    if c == 37 &&
      @util.code_at(src, i + 1) == 37 &&
      @util.code_at(src, i + 2) != 123 {
      self.at = self.line_end(i + 2)
      continue
    }
    if self.line_start {
      if c == 32 || c == 9 {
        let mut j = i + 1
        while @util.code_at(src, j) == 32 || @util.code_at(src, j) == 9 {
          j += 1
        }
        self.at = j
        if self.keyword(j, "text") && self.db.indent {
          // The word `text` itself is dropped; the indentation stands for it.
          self.at = j + 4
          self.line_start = false
          self.text = @util.slice(src, i, end=j)
          return T_INDENT_TEXT
        }
        continue
      }
      if c != 10 && c != 13 {
        self.db.indent = false
        self.line_start = false
      }
    }
    if c == 10 || c == 13 {
      i += 1
      while @util.code_at(src, i) == 10 || @util.code_at(src, i) == 13 {
        i += 1
      }
      self.line_start = true
      return self.token(T_NEWLINE, i)
    }
    if c == 37 && @util.code_at(src, i + 1) == 37 {
      self.at = self.line_end(i)
      continue
    }
    if c == 32 || c == 9 {
      i += 1
      while @util.code_at(src, i) == 32 || @util.code_at(src, i) == 9 {
        i += 1
      }
      self.at = i
      continue
    }
    if ((c | 32) >= 97 && (c | 32) <= 122) || c == 95 {
      let sep = @util.code_at(src, i + 5)
      if self.word(i, "title") && @util.is_space(sep) && sep != 10 && sep != 13 {
        let mut end = i + 6
        while end < n {
          let ch = @util.code_at(src, end)
          if ch == 35 || ch == 10 || ch == 59 {
            break
          }
          end += 1
        }
        if end > i + 6 {
          return self.token(T_TITLE, end)
        }
      }
      for entry in keywords {
        let (word, type_) = entry
        if self.keyword(i, word) {
          return self.token(type_, i + word.length())
        }
      }
      if self.word(i, "rgb") {
        let alpha = (@util.code_at(src, i + 3) | 32) == 97
        let open = i + (if alpha { 4 } else { 3 })
        let end = if @util.code_at(src, open) == 40 {
          self.color(open, if alpha { 4 } else { 3 })
        } else {
          -1
        }
        if end != -1 {
          return self.token(if alpha { T_RGBACOLOR } else { T_RGBCOLOR }, end)
        }
      }
      i += 1
      while @util.is_word(@util.code_at(src, i)) || @util.code_at(src, i) == 45 {
        i += 1
      }
      return self.token(T_IDENTIFIER, i)
    }
    if c == 91 {
      if @util.code_at(src, i + 1) == 34 {
        let quote = @util.index_of(src, "\"", from=i + 2)
        if quote == -1 || @util.code_at(src, quote + 1) != 93 {
          return T_ERROR
        }
        self.at = quote + 2
        self.text = @util.slice(src, i + 2, end=quote)
        return T_BRACKET_LABEL
      }
      let mut end = i + 1
      while end < n &&
            @util.code_at(src, end) != 93 &&
            @util.code_at(src, end) != 34 {
        end += 1
      }
      if end == i + 1 || @util.code_at(src, end) != 93 {
        return T_ERROR
      }
      self.at = end + 1
      self.text = @util.trim(@util.slice(src, i + 1, end~))
      return T_BRACKET_LABEL
    }
    if @util.is_digit(c) || c == 46 || c == 43 || c == 45 {
      if c == 43 || c == 45 {
        i += 1
      }
      let from = i
      i = digits_from(src, i)
      if i > from {
        if @util.code_at(src, i) == 46 &&
          @util.is_digit(@util.code_at(src, i + 1)) {
          i = digits_from(src, i + 2)
        }
      } else if @util.code_at(src, i) == 46 &&
        @util.is_digit(@util.code_at(src, i + 1)) {
        i = digits_from(src, i + 2)
      } else {
        return T_ERROR
      }
      return self.token(T_NUMERIC, i)
    }
    if c == 35 {
      let mut end = i + 1
      while end < i + 9 && @util.is_hex(@util.code_at(src, end)) {
        end += 1
      }
      return if end >= i + 4 { self.token(T_HEXCOLOR, end) } else { T_ERROR }
    }
    if c == 34 {
      let quote = @util.index_of(src, "\"", from=i + 1)
      return if quote == -1 { T_ERROR } else { self.token(T_STRING, quote + 1) }
    }
    if c == 44 {
      return self.token(T_COMMA, i + 1)
    }
    if c == 58 {
      return self.token(T_COLON, i + 1)
    }
    return T_ERROR
  }
  T_ERROR
}
