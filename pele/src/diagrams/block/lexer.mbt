///|
/// The tokens of a source, with the text and start offset of each.
pub(all) struct Tokens {
  types : Array[Tok]
  texts : Array[String]
  starts : Array[Int32]
}

///|
priv enum State {
  Initial
  Str
  MdStr
  Node
  BlockArrow
  ArrowDir
  LinkLabel
  ClassDef
  ClassDefId
  Class
  ClassStyle
  StyleStmnt
  StyleDefinition
  AccTitle
  AccDescr
  AccDescrMultiline
}

///|
let directions : Array[String] = ["right", "left", "x", "y", "up", "down"]

///|
/// Characters that end a node id: ( ) [ { } < > - : = and whitespace.
fn id_stop(c : Int32) -> Bool {
  if c < 128 {
    match c {
      9
      | 10
      | 11
      | 12
      | 13
      | 32
      | 40
      | 41
      | 45
      | 58
      | 60
      | 61
      | 62
      | 91
      | 123
      | 125 => true
      _ => false
    }
  } else {
    @util.is_space(c)
  }
}

///|
priv struct Lexer {
  src : String
  n : Int32
  types : Array[Tok]
  texts : Array[String]
  starts : Array[Int32]
  stack : Array[State]
  mut state : State
  mut p : Int32
}

///|
fn Lexer::at(self : Lexer, i : Int32) -> Int32 {
  @util.code_at(self.src, i)
}

///|
fn Lexer::put(self : Lexer, kind : Tok, text : String, end : Int32) -> Bool {
  self.types.push(kind)
  self.texts.push(text)
  self.starts.push(self.p)
  self.p = end
  true
}

///|
fn Lexer::emit(self : Lexer, kind : Tok, end : Int32) -> Bool {
  self.put(kind, @util.slice(self.src, self.p, end~), end)
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
fn Lexer::ws(self : Lexer, from : Int32) -> Int32 {
  let mut q = from
  while q < self.n && @util.is_space(self.at(q)) {
    q += 1
  }
  q
}

///|
fn Lexer::digits(self : Lexer, from : Int32) -> Int32 {
  let mut q = from
  while q < self.n && @util.is_digit(self.at(q)) {
    q += 1
  }
  q
}

///|
fn Lexer::word(self : Lexer, from : Int32) -> Int32 {
  let mut q = from
  while q < self.n && @util.is_word(self.at(q)) {
    q += 1
  }
  q
}

///|
fn Lexer::starts(self : Lexer, text : String, at : Int32) -> Bool {
  @util.starts_with_at(self.src, text, at)
}

///|
fn Lexer::keyword(self : Lexer, text : String) -> Bool {
  self.starts(text, self.p) && !@util.is_word(self.at(self.p + text.length()))
}

///|
fn Lexer::quote(self : Lexer) -> Bool {
  if self.at(self.p + 1) == 96 {
    self.push(MdStr)
    self.p += 2
  } else {
    self.push(Str)
    self.p += 1
  }
  true
}

///|
/// End of `.+-[xo>]?` at q, or -1.
fn Lexer::dotted(self : Lexer, from : Int32) -> Int32 {
  if self.at(from) != 46 {
    return -1
  }
  let mut q = from + 1
  while self.at(q) == 46 {
    q += 1
  }
  if self.at(q) != 45 {
    return -1
  }
  match self.at(q + 1) {
    120 | 111 | 62 => q + 2
    _ => q + 1
  }
}

///|
/// End of a complete link at q, before its trailing whitespace, or -1.
fn Lexer::link_end(self : Lexer, from : Int32) -> Int32 {
  let mut q = from
  if self.at(q) is (120 | 111 | 60) {
    q += 1
  }
  let line = self.at(q)
  if line == 46 {
    return self.dotted(q)
  }
  if line != 45 && line != 61 {
    return -1
  }
  let mut k = q + 1
  while self.at(k) == line {
    k += 1
  }
  if k - q == 1 {
    return if line == 45 { self.dotted(k) } else { -1 }
  }
  if self.at(k) is (120 | 111 | 62) {
    return k + 1
  }
  if k - q >= 3 {
    k
  } else {
    -1
  }
}

///|
fn Lexer::link(self : Lexer) -> Bool {
  let e = self.link_end(self.p)
  if e >= 0 {
    return self.emit(Link, self.ws(e))
  }
  let q = if self.at(self.p) == 60 { self.p + 1 } else { self.p }
  let a = self.at(q)
  let b = self.at(q + 1)
  if (a == 45 && (b == 45 || b == 46)) || (a == 61 && b == 61) {
    self.push(LinkLabel)
    return self.emit(StartLink, self.ws(q + 2))
  }
  false
}

///|
fn Lexer::line_state(self : Lexer, kind : Tok) -> Bool {
  let mut e = @util.index_of(self.src, "\n", from=self.p)
  if e == -1 {
    e = self.n
  }
  self.pop()
  self.emit(kind, e)
}

///|
/// `\w+(,\s*\w+)*`
fn Lexer::id_list(self : Lexer, kind : Tok, next : State) -> Bool {
  let mut k = self.word(self.p)
  if k == self.p {
    return false
  }
  while self.at(k) == 44 {
    let from = self.ws(k + 1)
    let to = self.word(from)
    if to == from {
      break
    }
    k = to
  }
  self.state = next
  self.emit(kind, k)
}

///|
fn Lexer::initial(self : Lexer, c : Int32) -> Bool {
  let p = self.p
  if @util.is_space(c) {
    self.p = self.ws(p + 1)
    return true
  }
  match c {
    98 =>
      if self.starts("block", p) {
        if self.keyword("block-beta") {
          return self.emit(Key, p + 10)
        }
        if self.at(p + 5) == 58 {
          return self.emit(IdBlock, p + 6)
        }
        if !@util.is_word(self.at(p + 5)) {
          return self.emit(Key, p + 5)
        }
      }
    99 =>
      if self.starts("columns", p) {
        let q = self.ws(p + 7)
        if q > p + 7 {
          if self.starts("auto", q) && !@util.is_word(self.at(q + 4)) {
            return self.put(Columns, "-1", q + 4)
          }
          let e = self.digits(q)
          if e > q {
            return self.put(Columns, @util.slice(self.src, q, end=e), e)
          }
        }
      } else if self.starts("class", p) {
        let def = self.starts("Def", p + 5)
        let from = if def { p + 8 } else { p + 5 }
        let q = self.ws(from)
        if q > from {
          self.push(if def { ClassDef } else { Class })
          return self.emit(if def { Tok::ClassDef } else { Tok::Class }, q)
        }
      }
    34 => return self.quote()
    115 =>
      if self.starts("space", p) {
        if self.at(p + 5) == 58 {
          let e = self.digits(p + 6)
          if e > p + 6 {
            return self.put(SpaceBlock, @util.slice(self.src, p + 6, end=e), e)
          }
        }
        if !@util.is_word(self.at(p + 5)) {
          return self.put(SpaceBlock, "1", p + 5)
        }
      } else if self.starts("style", p) {
        let q = self.ws(p + 5)
        if q > p + 5 {
          self.push(StyleStmnt)
          return self.emit(Style, q)
        }
      }
    100 => if self.keyword("default") { return self.emit(Default, p + 7) }
    108 => if self.keyword("linkStyle") { return self.emit(LinkStyle, p + 9) }
    105 =>
      if self.keyword("interpolate") {
        return self.emit(Interpolate, p + 11)
      }
    97 =>
      if self.starts("accTitle", p) {
        let q = self.ws(p + 8)
        if self.at(q) == 58 {
          self.push(AccTitle)
          return self.emit(Tok::AccTitle, self.ws(q + 1))
        }
      } else if self.starts("accDescr", p) {
        let q = self.ws(p + 8)
        let d = self.at(q)
        if d == 58 {
          self.push(AccDescr)
          return self.emit(Tok::AccDescr, self.ws(q + 1))
        }
        if d == 123 {
          self.push(AccDescrMultiline)
          self.p = self.ws(q + 1)
          return true
        }
      }
    101 => if self.keyword("end") { return self.emit(EndKw, self.ws(p + 3)) }
    45 => {
      if self.at(p + 1) == 41 {
        self.push(Node)
        return self.emit(NodeDStart, p + 2)
      }
      return self.link()
    }
    61 => return self.link()
    60 => {
      if self.at(p + 1) == 91 {
        self.push(BlockArrow)
        return self.emit(BlockArrowStart, p + 2)
      }
      return self.link()
    }
    40 => {
      let d = self.at(p + 1)
      let len = if d == 45 || d == 91 {
        2
      } else if d == 40 {
        if self.at(p + 2) == 40 {
          3
        } else {
          2
        }
      } else {
        1
      }
      self.push(Node)
      return self.emit(NodeDStart, p + len)
    }
    41 | 123 => {
      self.push(Node)
      return self.emit(
        NodeDStart,
        if self.at(p + 1) == c {
          p + 2
        } else {
          p + 1
        },
      )
    }
    62 => {
      self.push(Node)
      return self.emit(NodeDStart, p + 1)
    }
    91 => {
      let d = self.at(p + 1)
      self.push(Node)
      return self.emit(
        NodeDStart,
        if d is (91 | 124 | 40 | 92 | 47) {
          p + 2
        } else {
          p + 1
        },
      )
    }
    58 => {
      let e = self.digits(p + 1)
      if e > p + 1 {
        return self.put(Size, @util.slice(self.src, p + 1, end=e), e)
      }
      return false
    }
    _ => ()
  }
  let mut q = p
  while q < self.n && !id_stop(self.at(q)) {
    q += 1
  }
  q > p && self.emit(NodeId, q)
}

///|
fn Lexer::node_end(self : Lexer, c : Int32) -> Bool {
  let p = self.p
  let d = self.at(p + 1)
  let len = match c {
    34 => return self.quote()
    40 =>
      if d == 45 {
        2
      } else if d == 40 {
        if self.at(p + 2) == 40 {
          3
        } else {
          2
        }
      } else {
        1
      }
    41 =>
      if d == 41 {
        if self.at(p + 2) == 41 {
          3
        } else {
          2
        }
      } else if d == 93 {
        2
      } else {
        1
      }
    125 => if d == 125 { 2 } else { 1 }
    45 => if d == 41 { 2 } else { 0 }
    93 => if d is (93 | 41 | 62) { 2 } else { 1 }
    92 | 47 => if d == 93 { 2 } else { 0 }
    _ => 0
  }
  if len == 0 {
    return false
  }
  self.pop()
  self.emit(NodeDEnd, p + len)
}

///|
fn Lexer::arrow_dir(self : Lexer, c : Int32) -> Bool {
  let p = self.p
  if c == 41 {
    self.pop()
    self.pop()
    return self.put(BlockArrowEnd, "]>", self.ws(p + 1))
  }
  let from = self.ws(if c == 44 { p + 1 } else { p })
  for dir in directions {
    if self.starts(dir, from) {
      let e = self.ws(from + dir.length())
      return self.put(
        Dir,
        @util.slice(self.src, if c == 44 { from } else { p }, end=e),
        e,
      )
    }
  }
  false
}

///|
/// The token that ends the source in each state, or `None` where the grammar has none.
fn eof_token(state : State) -> Tok? {
  match state {
    Initial => Some(Eof)
    Str => Some(Tok::Str)
    ClassDefId => Some(ClassDefStyleOpts)
    ClassStyle => Some(StyleClass)
    StyleDefinition => Some(StyleDefinitionData)
    AccTitle => Some(AccTitleValue)
    AccDescr => Some(AccDescrValue)
    AccDescrMultiline => Some(AccDescrMultilineValue)
    _ => None
  }
}

///|
fn Lexer::step(self : Lexer, c : Int32) -> Bool {
  let p = self.p
  match self.state {
    Initial => self.initial(c)
    Str => {
      if c == 34 {
        self.pop()
        self.p += 1
      } else {
        let e = @util.index_of(self.src, "\"", from=p)
        self.emit(Tok::Str, if e == -1 { self.n } else { e }) |> ignore
      }
      true
    }
    MdStr =>
      if c == 96 {
        let ok = self.at(p + 1) == 34
        if ok {
          self.pop()
          self.p += 2
        }
        ok
      } else if c == 34 {
        false
      } else {
        let mut q = p + 1
        while q < self.n && !(self.at(q) is (96 | 34)) {
          q += 1
        }
        self.emit(Tok::MdStr, q)
      }
    Node => self.node_end(c)
    BlockArrow =>
      if c == 34 {
        self.quote()
      } else if c == 93 && self.at(p + 1) == 62 {
        let q = self.ws(p + 2)
        let ok = self.at(q) == 40
        if ok {
          self.push(ArrowDir)
          self.p = q + 1
        }
        ok
      } else {
        false
      }
    ArrowDir => self.arrow_dir(c)
    LinkLabel =>
      if c == 34 {
        if self.at(p + 1) == 96 {
          self.quote()
        } else {
          self.emit(Tok::LinkLabel, p + 1) |> ignore
          self.push(Str)
          true
        }
      } else {
        let e = self.link_end(self.ws(p))
        if e >= 0 {
          self.pop()
          self.emit(Link, self.ws(e))
        } else {
          false
        }
      }
    ClassDef => {
      let mut kind = DefaultClassDefId
      let mut k = if self.starts("DEFAULT", p) { p + 7 } else { p }
      let mut q = self.ws(k)
      if k == p || q == k {
        kind = ClassDefId
        k = self.word(p)
        q = self.ws(k)
      }
      let ok = k > p && q > k
      if ok {
        self.state = ClassDefId
        self.emit(kind, q) |> ignore
      }
      ok
    }
    ClassDefId => self.line_state(ClassDefStyleOpts)
    Class => self.id_list(ClassEntityIds, ClassStyle)
    ClassStyle => self.line_state(StyleClass)
    StyleStmnt => self.id_list(StyleEntityIds, StyleDefinition)
    StyleDefinition => self.line_state(StyleDefinitionData)
    AccTitle => self.line_state(AccTitleValue)
    AccDescr => self.line_state(AccDescrValue)
    AccDescrMultiline => {
      if c == 125 {
        self.pop()
        self.p += 1
      } else {
        let e = @util.index_of(self.src, "}", from=p)
        self.emit(AccDescrMultilineValue, if e == -1 { self.n } else { e })
        |> ignore
      }
      true
    }
  }
}

///|
/// Splits a block diagram into tokens as Mermaid's Jison lexer does.
/// A character no rule takes ends the stream with an `Error` token.
pub fn tokenize(src : String) -> Tokens {
  let lexer : Lexer = {
    src,
    n: src.length(),
    types: [],
    texts: [],
    starts: [],
    stack: [],
    state: Initial,
    p: 0,
  }
  while true {
    if lexer.p >= lexer.n {
      lexer.p = lexer.n
      if eof_token(lexer.state) is Some(kind) {
        lexer.put(kind, "", lexer.n) |> ignore
      }
      break
    }
    if !lexer.step(lexer.at(lexer.p)) {
      lexer.types.push(Error)
      lexer.texts.push("")
      lexer.starts.push(lexer.p)
      return { types: lexer.types, texts: lexer.texts, starts: lexer.starts, }
    }
  }
  lexer.types.push(End)
  lexer.texts.push("")
  lexer.starts.push(lexer.n)
  { types: lexer.types, texts: lexer.texts, starts: lexer.starts, }
}
