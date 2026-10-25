///|
priv enum State {
  Initial
  AxisData
  AxisBandData
  Data
  DataInner
  Str
  AccTitle
  AccDescr
  AccDescrMultiline
} derive(Eq)

///|
/// The token each state gives for the empty rest of the input.
fn at_end(state : State) -> Tok {
  match state {
    Initial | AxisData | AxisBandData | Data | DataInner => Eof
    Str => Tok::Str
    AccTitle => AccTitleValue
    AccDescr => AccDescrValue
    AccDescrMultiline => AccDescrMultilineValue
  }
}

///|
/// Mermaid's grammar means to open a markdown string at `"` followed by a backtick, but its quoting turns
/// the rule into one that matches this text and leaves the current state.
/// Markdown strings are never read.
let broken_rule : String = "`)" +
  " ".repeat(36) +
  "{ this.pushstate(md_string); }\n<md_string>(?:(?!`\").)+" +
  " ".repeat(18) +
  "{ return md_str; }\n<md_string>(?:`"

///|
fn single_character(c : Int32) -> Tok? {
  match c {
    58 => Some(Colon)
    43 => Some(Plus)
    44 => Some(Comma)
    61 => Some(Equals)
    42 => Some(Mult)
    35 => Some(Brkt)
    95 => Some(Underscore)
    46 => Some(Dot)
    38 => Some(Amp)
    45 => Some(Minus)
    59 => Some(Semi)
    _ => None
  }
}

///|
priv struct Lexer {
  src : String
  n : Int32
  mut p : Int32
  mut state : State
  stack : Array[State]
  types : Array[Tok]
  texts : Array[String]
  starts : Array[Int32]
}

///|
fn Lexer::emit(self : Lexer, kind : Tok, start : Int32, end : Int32) -> Unit {
  self.types.push(kind)
  self.texts.push(@util.slice(self.src, start, end~))
  self.starts.push(start)
  self.p = end
}

///|
fn Lexer::push(self : Lexer, state : State) -> Unit {
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
    self.n
  } else {
    end
  }
}

///|
fn Lexer::skip_space(self : Lexer, from : Int32) -> Int32 {
  let mut q = from
  while q < self.n && @util.is_space(@util.code_at(self.src, q)) {
    q += 1
  }
  q
}

///|
fn Lexer::skip_digits(self : Lexer, from : Int32) -> Int32 {
  let mut q = from
  while @util.is_digit(@util.code_at(self.src, q)) {
    q += 1
  }
  q
}

///|
/// Whether the keyword is at the cursor and a word does not go on after it.
fn Lexer::keyword(self : Lexer, word : String) -> Bool {
  @common.word_at(self.src, self.p, word) &&
  !@util.is_word(@util.code_at(self.src, self.p + word.length()))
}

///|
/// Reads a keyword at the cursor, if one is there.
fn Lexer::read_keyword(self : Lexer) -> Bool {
  let p = self.p
  let src = self.src
  match @util.code_at(src, p).lor(32) {
    116 =>
      if self.keyword("title") {
        self.emit(Title, p, p + 5)
        return true
      }
    97 =>
      if @common.word_at(src, p, "acc") {
        let descr = @common.word_at(src, p + 3, "descr")
        if descr || @common.word_at(src, p + 3, "title") {
          let k = self.skip_space(p + 8)
          let d = @util.code_at(src, k)
          if d == 58 {
            self.emit(
              if descr {
                AccDescr
              } else {
                AccTitle
              },
              p,
              self.skip_space(k + 1),
            )
            self.push(if descr { State::AccDescr } else { State::AccTitle })
            return true
          }
          if d == 123 && descr {
            self.p = self.skip_space(k + 1)
            self.push(AccDescrMultiline)
            return true
          }
        }
      }
    120 => {
      if self.keyword("xychart-beta") {
        self.emit(Xychart, p, p + 12)
        return true
      }
      if self.keyword("xychart") {
        self.emit(Xychart, p, p + 7)
        return true
      }
      if self.keyword("x-axis") {
        self.emit(XAxis, p, p + 6)
        self.push(AxisData)
        return true
      }
    }
    121 =>
      if self.keyword("y-axis") {
        self.emit(YAxis, p, p + 6)
        self.push(AxisData)
        return true
      }
    118 =>
      if @common.word_at(src, p, "vertical") {
        self.emit(ChartOrientation, p, p + 8)
        return true
      }
    104 =>
      if @common.word_at(src, p, "horizontal") {
        self.emit(ChartOrientation, p, p + 10)
        return true
      }
    108 =>
      if self.keyword("line") {
        self.emit(Line, p, p + 4)
        self.push(Data)
        return true
      }
    98 =>
      if self.keyword("bar") {
        self.emit(Bar, p, p + 3)
        self.push(Data)
        return true
      }
    _ => ()
  }
  false
}

///|
/// Reads a number at the cursor, if one is there: an optional sign, then digits with an optional fraction or just a fraction.
fn Lexer::read_number(self : Lexer) -> Bool {
  let p = self.p
  let c = @util.code_at(self.src, p)
  let q = if c == 43 || c == 45 { p + 1 } else { p }
  let d = @util.code_at(self.src, q)
  let mut e = -1
  if @util.is_digit(d) {
    e = self.skip_digits(q + 1)
    if @util.code_at(self.src, e) == 46 &&
      @util.is_digit(@util.code_at(self.src, e + 1)) {
      e = self.skip_digits(e + 2)
    }
  } else if d == 46 && @util.is_digit(@util.code_at(self.src, q + 1)) {
    e = self.skip_digits(q + 2)
  }
  if e == -1 {
    return false
  }
  self.emit(NumberWithDecimal, p, e)
  true
}

///|
/// Reads one token or skipped text, and says whether the text had one at the cursor.
fn Lexer::step(self : Lexer) -> Bool {
  let src = self.src
  let p = self.p
  let c = @util.code_at(src, p)
  match self.state {
    Str => {
      if c == 34 {
        self.p += 1
        self.pop()
      } else {
        let e = @util.index_of(src, "\"", from=p)
        self.emit(Tok::Str, p, if e == -1 { self.n } else { e })
      }
      return true
    }
    AccTitle | AccDescr => {
      self.emit(at_end(self.state), p, self.line_end(p))
      self.pop()
      return true
    }
    AccDescrMultiline => {
      if c == 125 {
        self.p += 1
        self.pop()
      } else {
        let e = @util.index_of(src, "}", from=p)
        self.emit(AccDescrMultilineValue, p, if e == -1 { self.n } else { e })
      }
      return true
    }
    _ => ()
  }
  let next = @util.code_at(src, p + 1)
  if c == 37 && next == 37 {
    self.p = self.line_end(p + 2)
    return true
  }
  if c == 10 || c == 13 {
    // Only a line break that directly follows an axis or a series ends it.
    // One after spaces is skipped with them, and the state carries on to the next line.
    if (self.state == AxisData || self.state == Data) && (c == 10 || next == 10) {
      self.emit(Newline, p, if c == 10 { p + 1 } else { p + 2 })
      self.pop()
      return true
    }
    let mut e = p + 1
    while @util.code_at(src, e) == 10 || @util.code_at(src, e) == 13 {
      e += 1
    }
    self.emit(Newline, p, e)
    return true
  }
  if self.read_keyword() {
    return true
  }
  if c == 91 {
    if self.state == AxisData {
      self.push(AxisBandData)
    } else if self.state == Data {
      self.push(DataInner)
    }
    self.emit(SquareBracesStart, p, p + 1)
    return true
  }
  if c == 93 {
    if self.state == DataInner || self.state == AxisBandData {
      self.pop()
    }
    self.emit(SquareBracesEnd, p, p + 1)
    return true
  }
  if self.state == AxisData &&
    c == 45 &&
    next == 45 &&
    @util.code_at(src, p + 2) == 62 {
    self.emit(ArrowDelimiter, p, p + 3)
    return true
  }
  if (self.state == AxisData || self.state == DataInner) && self.read_number() {
    return true
  }
  if c == 96 && @common.word_at(src, p, broken_rule) {
    self.p += broken_rule.length()
    self.pop()
    return true
  }
  if c == 34 {
    self.p += 1
    self.push(Str)
    return true
  }
  if @util.is_letter(c) {
    let mut e = p + 1
    while @util.is_letter(@util.code_at(src, e)) {
      e += 1
    }
    self.emit(Alpha, p, e)
    return true
  }
  if @util.is_digit(c) {
    self.emit(Num, p, self.skip_digits(p + 1))
    return true
  }
  if @util.is_space(c) {
    self.p = self.skip_space(p + 1)
    return true
  }
  if single_character(c) is Some(kind) {
    self.emit(kind, p, p + 1)
    return true
  }
  false
}

///|
/// Splits the source into tokens.
/// Text that no rule matches ends the stream with an `Error` token and no `End`.
fn tokenize(source : String) -> Tokens {
  let lexer : Lexer = {
    src: source,
    n: source.length(),
    p: 0,
    state: Initial,
    stack: [],
    types: [],
    texts: [],
    starts: [],
  }
  while lexer.p < lexer.n && lexer.step() {

  }
  if lexer.p < lexer.n {
    lexer.types.push(Error)
    lexer.texts.push("")
    lexer.starts.push(lexer.p)
  } else {
    // Jison tries the rules of the current state once more against the empty rest of the input.
    lexer.types.push(at_end(lexer.state))
    lexer.texts.push("")
    lexer.starts.push(lexer.n)
    lexer.types.push(End)
    lexer.texts.push("")
    lexer.starts.push(lexer.n)
  }
  { types: lexer.types, texts: lexer.texts, starts: lexer.starts, }
}
