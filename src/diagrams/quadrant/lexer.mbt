///|
const S_INITIAL : Int32 = 0

///|
const S_TITLE : Int32 = 1

///|
const S_ACC_TITLE : Int32 = 2

///|
const S_ACC_DESCR : Int32 = 3

///|
const S_ACC_DESCR_MULTILINE : Int32 = 4

///|
const S_STRING : Int32 = 5

///|
const S_MD_STRING : Int32 = 6

///|
const S_CLASS_NAME : Int32 = 7

///|
const S_POINT_START : Int32 = 8

///|
const S_POINT_X : Int32 = 9

///|
const S_POINT_Y : Int32 = 10

///|
/// The tokens of a chart, with the text of each and where it starts.
priv struct Tokens {
  types : Array[Int32]
  texts : Array[String]
  starts : Array[Int32]
}

///|
/// The token each state gives for the empty rest of the input, where it gives one.
fn at_end(state : Int32) -> Int32? {
  match state {
    S_INITIAL => Some(EOF)
    S_TITLE => Some(TITLE_VALUE)
    S_ACC_TITLE => Some(ACC_TITLE_VALUE)
    S_ACC_DESCR => Some(ACC_DESCR_VALUE)
    S_ACC_DESCR_MULTILINE => Some(ACC_DESCR_MULTILINE_VALUE)
    S_STRING => Some(STR)
    _ => None
  }
}

///|
/// The token a character of its own gives, or 0 for none.
fn single(c : Int32) -> Int32 {
  match c {
    58 => COLON
    43 => PLUS
    44 => COMMA
    61 => EQUALS
    42 => MULT
    35 => BRKT
    95 => UNDERSCORE
    46 => DOT
    38 => AMP
    45 => MINUS
    32 | 9 | 11 | 12 => SPACE
    59 => SEMI
    33 | 36 | 37 | 39 | 96 | 63 | 92 | 47 => PUNCTUATION
    _ => 0
  }
}

///|
priv struct Lexer {
  src : String
  length : Int32
  tokens : Tokens
  stack : Array[Int32]
  mut state : Int32
  mut at : Int32
  // The last run scanned of each kind, so that a long run is not scanned again from each of its characters.
  mut space_from : Int32
  mut space_to : Int32
  mut dash_from : Int32
  mut dash_to : Int32
  mut blank_from : Int32
  mut blank_to : Int32
  mut gap_from : Int32
  mut gap_to : Int32
}

///|
fn Lexer::emit(self : Lexer, type_ : Int32, start : Int32, end : Int32) -> Unit {
  self.tokens.types.push(type_)
  self.tokens.texts.push(@util.slice(self.src, start, end~))
  self.tokens.starts.push(start)
  self.at = end
}

///|
fn Lexer::push(self : Lexer, state : Int32) -> Unit {
  self.stack.push(self.state)
  self.state = state
}

///|
fn Lexer::pop(self : Lexer) -> Unit {
  if self.stack.pop() is Some(state) {
    self.state = state
  }
}

///|
fn Lexer::line_end(self : Lexer, from : Int32) -> Int32 {
  let end = @util.index_of(self.src, "\n", from~)
  if end == -1 {
    self.length
  } else {
    end
  }
}

///|
fn Lexer::spaces(self : Lexer, from : Int32) -> Int32 {
  let mut q = from
  while @util.code_at(self.src, q) == 32 {
    q += 1
  }
  q
}

///|
/// Skips whitespace as `\s*` does.
fn Lexer::run(self : Lexer, from : Int32) -> Int32 {
  let mut q = from
  while q < self.length && @util.is_space(@util.code_at(self.src, q)) {
    q += 1
  }
  q
}

///|
/// Mermaid's `(1)|(0(.\d+)?)`, where the dot is any character within a line.
/// Returns where the coordinate ends, or -1 when there is none.
fn Lexer::coordinate(self : Lexer, from : Int32) -> Int32 {
  let src = self.src
  let c = @util.code_at(src, from)
  if c == 49 {
    return from + 1
  }
  if c != 48 {
    return -1
  }
  let mut end = from + 1
  if end < self.length &&
    !@util.is_line_end(@util.code_at(src, end)) &&
    @util.is_digit(@util.code_at(src, end + 1)) {
    end += 2
    while @util.is_digit(@util.code_at(src, end)) {
      end += 1
    }
  }
  end
}

///|
/// Reads one token, or none where it is in the middle of a state's skipping.
/// Returns false where no rule matches the text.
fn Lexer::step(self : Lexer) -> Bool {
  let src = self.src
  let at = self.at
  let c = @util.code_at(src, at)
  let next = @util.code_at(src, at + 1)
  match self.state {
    S_INITIAL => ()
    S_TITLE | S_ACC_TITLE | S_ACC_DESCR => {
      let type_ = at_end(self.state).unwrap()
      self.emit(type_, at, self.line_end(at))
      self.pop()
      return true
    }
    S_ACC_DESCR_MULTILINE => {
      if c == 125 {
        self.at += 1
        self.pop()
      } else {
        let end = @util.index_of(src, "}", from=at)
        self.emit(
          ACC_DESCR_MULTILINE_VALUE,
          at,
          if end == -1 {
            self.length
          } else {
            end
          },
        )
      }
      return true
    }
    S_STRING => {
      if c == 34 {
        self.at += 1
        self.pop()
      } else {
        let end = @util.index_of(src, "\"", from=at)
        self.emit(STR, at, if end == -1 { self.length } else { end })
      }
      return true
    }
    S_MD_STRING => {
      if c == 96 && next == 34 {
        self.at += 2
        self.pop()
        return true
      }
      if c != 96 && c != 34 {
        let mut end = at + 1
        while end < self.length &&
              @util.code_at(src, end) != 96 &&
              @util.code_at(src, end) != 34 {
          end += 1
        }
        self.emit(MD_STR, at, end)
        return true
      }
      return false
    }
    S_CLASS_NAME => {
      if @util.is_word(c) {
        let mut end = at + 1
        while @util.is_word(@util.code_at(src, end)) {
          end += 1
        }
        self.emit(CLASS_NAME, at, end)
        self.pop()
        return true
      }
      return false
    }
    S_POINT_START => {
      let end = self.coordinate(at)
      if end != -1 {
        self.emit(POINT_X, at, end)
        self.push(S_POINT_X)
        return true
      }
      let k = self.run(at)
      if @util.code_at(src, k) == 93 {
        self.at = self.spaces(k + 1)
        self.pop()
        return true
      }
      return false
    }
    S_POINT_X => {
      let k = self.run(at)
      if @util.code_at(src, k) == 44 {
        self.at = self.run(k + 1)
        self.state = S_POINT_Y
        return true
      }
      return false
    }
    S_POINT_Y => {
      let end = self.coordinate(at)
      if end != -1 {
        self.emit(POINT_Y, at, end)
        self.pop()
        return true
      }
      return false
    }
    _ => ()
  }
  if c == 37 && next == 37 {
    self.at = self.line_end(at + 2)
    return true
  }
  // Mermaid's second comment rule takes any character before `%%` with it, a line break included.
  if c != 125 && next == 37 && @util.code_at(src, at + 2) == 37 {
    self.at = self.line_end(at + 3)
    return true
  }
  if c == 10 || c == 13 {
    let mut end = at + 1
    while @util.code_at(src, end) == 10 || @util.code_at(src, end) == 13 {
      end += 1
    }
    self.emit(NEWLINE, at, end)
    return true
  }
  let lower = c | 32
  if lower == 116 &&
    @common.word_at(src, at, "title") &&
    !@util.is_word(@util.code_at(src, at + 5)) {
    self.emit(TITLE, at, at + 5)
    self.push(S_TITLE)
    return true
  }
  if lower == 97 && @common.word_at(src, at, "acc") {
    let descr = @common.word_at(src, at + 3, "descr")
    if descr || @common.word_at(src, at + 3, "title") {
      let k = self.run(at + 8)
      let d = @util.code_at(src, k)
      if d == 58 {
        self.emit(
          if descr {
            ACC_DESCR
          } else {
            ACC_TITLE
          },
          at,
          self.run(k + 1),
        )
        self.push(if descr { S_ACC_DESCR } else { S_ACC_TITLE })
        return true
      }
      if d == 123 && descr {
        self.at = self.run(k + 1)
        self.push(S_ACC_DESCR_MULTILINE)
        return true
      }
    }
  }
  // Axis, quadrant and chart keywords and the axis arrow take the spaces around them.
  let mut j = at
  if c == 32 {
    if at < self.space_from || at >= self.space_to {
      self.space_from = at
      self.space_to = self.spaces(at)
    }
    j = self.space_to
  }
  let d = @util.code_at(src, j)
  let dl = d | 32
  let mut type_ = 0
  let mut end = 0
  if dl == 120 && @common.word_at(src, j, "x-axis") {
    type_ = X_AXIS
    end = j + 6
  } else if dl == 121 && @common.word_at(src, j, "y-axis") {
    type_ = Y_AXIS
    end = j + 6
  } else if d == 45 {
    if j < self.dash_from || j >= self.dash_to {
      self.dash_from = j
      self.dash_to = j
      while @util.code_at(src, self.dash_to) == 45 {
        self.dash_to += 1
      }
    }
    if self.dash_to - j >= 2 && @util.code_at(src, self.dash_to) == 62 {
      type_ = DELIMITER
      end = self.dash_to + 1
    }
  } else if dl == 113 && @common.word_at(src, j, "quadrant") {
    let q = @util.code_at(src, j + 9)
    if @util.code_at(src, j + 8) == 45 && q >= 49 && q <= 52 {
      type_ = QUADRANT_1 + q - 49
      end = j + 10
    } else if @common.word_at(src, j + 8, "chart") {
      type_ = QUADRANT
      end = j + 13
    }
  }
  if type_ != 0 {
    self.emit(type_, at, self.spaces(end))
    return true
  }
  if lower == 99 &&
    @common.word_at(src, at, "classdef") &&
    !@util.is_word(@util.code_at(src, at + 8)) {
    self.emit(CLASSDEF, at, at + 8)
    return true
  }
  if c == 34 {
    if next == 96 {
      self.at += 2
      self.push(S_MD_STRING)
    } else {
      self.at += 1
      self.push(S_STRING)
    }
    return true
  }
  if c == 58 && next == 58 && @util.code_at(src, at + 2) == 58 {
    self.at += 3
    self.push(S_CLASS_NAME)
    return true
  }
  // A point's `: [`, with any whitespace before, between and after, line breaks included.
  if c == 58 || @util.is_space(c) {
    let mut k = at
    if c != 58 {
      if at < self.blank_from || at >= self.blank_to {
        self.blank_from = at
        self.blank_to = self.run(at)
      }
      k = self.blank_to
    }
    if @util.code_at(src, k) == 58 {
      if k + 1 < self.gap_from || k + 1 >= self.gap_to {
        self.gap_from = k + 1
        self.gap_to = self.run(k + 1)
      }
      if @util.code_at(src, self.gap_to) == 91 {
        self.emit(POINT_START, at, self.run(self.gap_to + 1))
        self.push(S_POINT_START)
        return true
      }
    }
  }
  if @util.is_letter(c) {
    let mut end = at + 1
    while @util.is_letter(@util.code_at(src, end)) {
      end += 1
    }
    self.emit(ALPHA, at, end)
    return true
  }
  if c >= 128 {
    let mut end = at + 1
    while @util.code_at(src, end) >= 128 {
      end += 1
    }
    self.emit(UNICODE_TEXT, at, end)
    return true
  }
  if @util.is_digit(c) {
    let mut end = at + 1
    while @util.is_digit(@util.code_at(src, end)) {
      end += 1
    }
    self.emit(NUM, at, end)
    return true
  }
  let own = single(c)
  if own != 0 {
    self.emit(own, at, at + 1)
    return true
  }
  false
}

///|
/// Splits a chart into tokens as Mermaid's lexer does.
/// Where no rule matches, the tokens end with an `ERROR` that starts at the text.
fn tokenize(src : String) -> Tokens {
  let lexer = {
    src,
    length: src.length(),
    tokens: { types: [], texts: [], starts: [], },
    stack: [],
    state: S_INITIAL,
    at: 0,
    space_from: 0,
    space_to: 0,
    dash_from: 0,
    dash_to: 0,
    blank_from: 0,
    blank_to: 0,
    gap_from: 0,
    gap_to: 0,
  }
  let tokens = lexer.tokens
  while lexer.at < lexer.length {
    if !lexer.step() {
      break
    }
  }
  if lexer.at < lexer.length {
    tokens.types.push(ERROR)
    tokens.texts.push("")
    tokens.starts.push(lexer.at)
    return tokens
  }
  // Jison tries the rules of the current state once more against the empty rest of the input.
  if at_end(lexer.state) is Some(type_) {
    tokens.types.push(type_)
    tokens.texts.push("")
    tokens.starts.push(lexer.length)
  }
  tokens.types.push(END)
  tokens.texts.push("")
  tokens.starts.push(lexer.length)
  tokens
}
