///|
/// A flowchart's tokens as parallel arrays: the type of each, its text, and where it starts.
pub(all) struct Tokens {
  types : Array[Int32]
  texts : Array[String]
  starts : Array[Int32]
}

// Lexer states, numbered as pele's `const enum S`.

///|
const S_INITIAL : Int32 = 0

///|
const S_STRING : Int32 = 1

///|
const S_MD_STRING : Int32 = 2

///|
const S_ACC_TITLE : Int32 = 3

///|
const S_ACC_DESCR : Int32 = 4

///|
const S_ACC_DESCR_MULTILINE : Int32 = 5

///|
const S_DIR : Int32 = 6

///|
const S_TEXT : Int32 = 7

///|
const S_ELLIPSE_TEXT : Int32 = 8

///|
const S_TRAP_TEXT : Int32 = 9

///|
const S_EDGE_TEXT : Int32 = 10

///|
const S_THICK_EDGE_TEXT : Int32 = 11

///|
const S_DOTTED_EDGE_TEXT : Int32 = 12

///|
const S_CLICK : Int32 = 13

///|
const S_CALLBACKNAME : Int32 = 14

///|
const S_CALLBACKARGS : Int32 = 15

///|
const S_SHAPE_DATA : Int32 = 16

///|
const S_SHAPE_DATA_STR : Int32 = 17

///|
/// No code unit compares equal to this, as nothing equals the NaN that `charCodeAt` gives past the end.
const NO_CHAR : Int32 = -2

///|
/// The ASCII characters a NODE_STRING is made of, besides `-` which needs a look ahead.
pub fn is_node_char(c : Int32) -> Bool {
  @util.is_letter(c) ||
  @util.is_digit(c) ||
  c == '!' ||
  c == '"' ||
  c == '#' ||
  c == '$' ||
  c == '%' ||
  c == '&' ||
  c == '\'' ||
  c == '*' ||
  c == '+' ||
  c == '.' ||
  c == '`' ||
  c == '?' ||
  c == '\\' ||
  c == '_' ||
  c == '/'
}

///|
priv struct Lexer {
  src : String
  n : Int32
  types : Array[Int32]
  texts : Array[String]
  starts : Array[Int32]
  stack : Array[Int32]
  mut state : Int32
  mut p : Int32
  mut first_graph : Bool
  mut dir_next : Int32
  mut at_next : Int32
  mut line_end : Int32
  mut dir_failed : Int32
  mut run_end : Int32
  mut run_at : Int32
  mut ws_from : Int32
  mut ws_to : Int32
}

///|
fn Lexer::at(self : Lexer, i : Int32) -> Int32 {
  code(self.src, i)
}

///|
fn Lexer::emit(self : Lexer, kind : Int32, s : Int32, e : Int32) -> Unit {
  self.types.push(kind)
  self.texts.push(@util.slice(self.src, s, end=e))
  self.starts.push(s)
  self.p = e
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
fn Lexer::kw(self : Lexer, word : String) -> Bool {
  @util.starts_with_at(self.src, word, self.p) &&
  !@util.is_word(self.at(self.p + word.length()))
}

///|
/// The first offset after the run of whitespace at `q`, remembering the last run looked at.
fn Lexer::past_space(self : Lexer, q : Int32) -> Int32 {
  if q >= self.ws_from && q <= self.ws_to {
    return self.ws_to
  }
  if @util.is_space(self.at(q)) {
    let j = skip_space(self.src, q)
    self.ws_from = q
    self.ws_to = j
    return j
  }
  q
}

///|
/// First character after any run of whitespace starting at q, skipping one optional x, o or <.
fn Lexer::link_char(self : Lexer, q : Int32) -> Int32 {
  let j = self.past_space(q)
  let d = self.at(j)
  if is_link_prefix(d) {
    self.at(j + 1)
  } else {
    d
  }
}

///|
fn Lexer::invis_ahead(self : Lexer, q : Int32) -> Bool {
  self.at(self.past_space(q)) == '~'
}

///|
fn Lexer::quote(self : Lexer) -> Unit {
  if self.at(self.p + 1) == '`' {
    self.push(S_MD_STRING)
    self.p += 2
  } else {
    self.push(S_STRING)
    self.p += 1
  }
}

///|
fn Lexer::invis_link(self : Lexer) -> Bool {
  if !self.invis_ahead(self.p) {
    return false
  }
  let e = invisible_link_end(self.src, self.p)
  if e < 0 {
    return false
  }
  self.emit(LINK, self.p, e)
  true
}

///|
fn Lexer::opener(self : Lexer, c : Int32) -> Bool {
  let p = self.p
  let d = self.at(p + 1)
  if c == '(' {
    if d == '-' {
      self.push(S_ELLIPSE_TEXT)
      self.emit(ELLIPSE_START, p, p + 2)
    } else if d == '[' {
      self.push(S_TEXT)
      self.emit(STADIUMSTART, p, p + 2)
    } else if d == '(' && self.at(p + 2) == '(' {
      self.push(S_TEXT)
      self.emit(DOUBLECIRCLESTART, p, p + 3)
    } else {
      self.push(S_TEXT)
      self.emit(PS, p, p + 1)
    }
    return true
  }
  if c == '[' {
    if d == '[' {
      self.push(S_TEXT)
      self.emit(SUBROUTINESTART, p, p + 2)
    } else if d == '(' {
      self.push(S_TEXT)
      self.emit(CYLINDERSTART, p, p + 2)
    } else if d == '/' {
      self.push(S_TRAP_TEXT)
      self.emit(TRAPSTART, p, p + 2)
    } else if d == '\\' {
      self.push(S_TRAP_TEXT)
      self.emit(INVTRAPSTART, p, p + 2)
    } else {
      self.push(S_TEXT)
      self.emit(SQS, p, p + 1)
    }
    return true
  }
  if c == '|' {
    self.push(S_TEXT)
    self.emit(PIPE, p, p + 1)
    return true
  }
  if c == '{' {
    self.push(S_TEXT)
    self.emit(DIAMOND_START, p, p + 1)
    return true
  }
  false
}

///|
fn Lexer::graph(self : Lexer, len : Int32) -> Unit {
  if self.first_graph {
    self.first_graph = false
    self.push(S_DIR)
  }
  self.emit(GRAPH, self.p, self.p + len)
}

///|
fn Lexer::node_string(self : Lexer) -> Bool {
  let mut q = self.p
  while q < self.n {
    let ch = self.at(q)
    if ch < 128 && is_node_char(ch) {
      q += 1
    } else if ch == '-' && q + 1 < self.n {
      let d = self.at(q + 1)
      if d == '>' || d == '-' || d == '.' {
        break
      }
      q += 1
    } else {
      break
    }
  }
  if q == self.p {
    return false
  }
  self.emit(NODE_STRING, self.p, q)
  true
}

///|
fn Lexer::link(self : Lexer, c : Int32) -> Bool {
  let p = self.p
  let src = self.src
  let d = self.link_char(p)
  if d == '-' {
    let e = normal_link_end(src, p)
    if e >= 0 {
      self.emit(LINK, p, e)
      return true
    }
    let e = start_link_end(src, p, '-')
    if e >= 0 {
      self.push(S_EDGE_TEXT)
      self.emit(START_LINK, p, e)
      return true
    }
    let e = dotted_link_end(src, p)
    if e >= 0 {
      self.emit(LINK, p, e)
      return true
    }
    let e = dotted_start_end(src, p)
    if e >= 0 {
      self.push(S_DOTTED_EDGE_TEXT)
      self.emit(START_LINK, p, e)
      return true
    }
  } else if d == '=' {
    let e = thick_link_end(src, p)
    if e >= 0 {
      self.emit(LINK, p, e)
      return true
    }
    let e = start_link_end(src, p, '=')
    if e >= 0 {
      self.push(S_THICK_EDGE_TEXT)
      self.emit(START_LINK, p, e)
      return true
    }
  } else if d == '.' {
    let e = dotted_link_end(src, p)
    if e >= 0 {
      self.emit(LINK, p, e)
      return true
    }
  }
  c != '-' && c != '=' && c != '.' && self.invis_link()
}

///|
fn Lexer::keyword(self : Lexer, c : Int32) -> Bool {
  let p = self.p
  let src = self.src
  match c {
    'a' =>
      if @util.starts_with_at(src, "acc", p) {
        let e = keyword_punct_end(src, p, "accTitle", ':')
        if e >= 0 {
          self.push(S_ACC_TITLE)
          self.emit(ACC_TITLE, p, e)
          return true
        }
        let e = keyword_punct_end(src, p, "accDescr", ':')
        if e >= 0 {
          self.push(S_ACC_DESCR)
          self.emit(ACC_DESCR, p, e)
          return true
        }
        let e = keyword_punct_end(src, p, "accDescr", '{')
        if e >= 0 {
          self.push(S_ACC_DESCR_MULTILINE)
          self.p = e
          return true
        }
      }
    '@' =>
      if self.at(p + 1) == '{' {
        self.push(S_SHAPE_DATA)
        self.types.push(SHAPE_DATA)
        self.texts.push("")
        self.starts.push(p)
        self.p = p + 2
        return true
      }
    'c' => {
      let e = keyword_space_end(src, p, "call")
      if e >= 0 {
        self.push(S_CALLBACKNAME)
        self.p = e
        return true
      }
      if self.kw("classDef") {
        self.emit(CLASSDEF, p, p + 8)
        return true
      }
      if self.kw("class") {
        self.emit(CLASS, p, p + 5)
        return true
      }
      let e = keyword_space_end(src, p, "click")
      if e >= 0 {
        self.push(S_CLICK)
        self.p = e
        return true
      }
    }
    '"' => {
      self.quote()
      return true
    }
    's' => {
      if self.kw("style") {
        self.emit(STYLE, p, p + 5)
        return true
      }
      if self.kw("swimlane-beta") {
        self.graph(13)
        return true
      }
      if self.kw("subgraph") {
        self.emit(SUBGRAPH, p, p + 8)
        return true
      }
    }
    'd' =>
      if self.kw("default") {
        self.emit(DEFAULT, p, p + 7)
        return true
      }
    'l' =>
      if self.kw("linkStyle") {
        self.emit(LINKSTYLE, p, p + 9)
        return true
      }
    'i' =>
      if self.kw("interpolate") {
        self.emit(INTERPOLATE, p, p + 11)
        return true
      }
    'h' =>
      if @util.starts_with_at(src, "href", p) && @util.is_space(self.at(p + 4)) {
        self.emit(HREF, p, p + 5)
        return true
      }
    'f' => {
      if self.kw("flowchart-elk") {
        self.graph(13)
        return true
      }
      if self.kw("flowchart") {
        self.graph(9)
        return true
      }
    }
    'g' =>
      if self.kw("graph") {
        self.graph(5)
        return true
      }
    'e' =>
      if self.kw("end") {
        self.emit(SUBGRAPH_END, p, skip_space(src, p + 3))
        return true
      }
    '_' =>
      for target in ["_self", "_blank", "_parent", "_top"] {
        if self.kw(target) {
          self.emit(LINK_TARGET, p, p + target.length())
          return true
        }
      }
    _ => ()
  }
  false
}

///|
fn Lexer::direction(self : Lexer) -> Bool {
  let p = self.p
  if self.dir_next == -1 || p < self.dir_failed {
    return false
  }
  if self.dir_next < p {
    self.dir_next = @util.index_of(self.src, "direction", from=p)
  }
  if self.dir_next == -1 {
    return false
  }
  if self.line_end < p {
    let mut e = p
    while e < self.n && !@util.is_line_end(self.at(e)) {
      e += 1
    }
    self.line_end = e
  }
  if self.dir_next >= self.line_end {
    return false
  }
  for i, dir in ["TB", "BT", "RL", "LR", "TD"] {
    let e = direction_end(self.src, p, dir)
    if e >= 0 {
      self.emit(DIRECTION_TB + i, p, e)
      return true
    }
  }
  // No direction statement starts anywhere in the rest of this line either.
  self.dir_failed = self.line_end
  false
}

///|
/// A link id is a run of non-space characters up to its last `@` that is not followed by `{` or `"`.
fn Lexer::link_id(self : Lexer, c : Int32) -> Bool {
  if self.at_next == -1 || c == '"' || @util.is_space(c) {
    return false
  }
  let p = self.p
  let n = self.n
  if p >= self.run_end {
    if self.at_next < p {
      self.at_next = @util.index_of(self.src, "@", from=p)
    }
    let mut q = p
    while q < n {
      let ch = self.at(q)
      if ch == '"' || @util.is_space(ch) {
        break
      }
      q += 1
    }
    self.run_end = q
    self.run_at = -1
    if self.at_next != -1 && self.at_next < q {
      // pele starts one before min(q, n - 1), so an `@` in the last code unit is never a link id.
      let mut k = (if q < n - 1 { q } else { n - 1 }) - 1
      while k >= self.at_next {
        if self.at(k) == '@' {
          let after = self.at(k + 1)
          if after != '{' && after != '"' {
            self.run_at = k
            break
          }
        }
        k -= 1
      }
    }
  }
  if self.run_at > p {
    self.emit(LINK_ID, p, self.run_at + 1)
    return true
  }
  false
}

///|
fn Lexer::initial(self : Lexer, c : Int32) -> Bool {
  if self.keyword(c) || self.direction() || self.link_id(c) {
    return true
  }
  let p = self.p
  if @util.is_digit(c) {
    let mut q = p + 1
    while q < self.n && @util.is_digit(self.at(q)) {
      q += 1
    }
    self.emit(NUM, p, q)
    return true
  }
  match c {
    '#' => {
      self.emit(BRKT, p, p + 1)
      return true
    }
    ':' => {
      if self.at(p + 1) == ':' && self.at(p + 2) == ':' {
        self.emit(STYLE_SEPARATOR, p, p + 3)
      } else {
        self.emit(COLON, p, p + 1)
      }
      return true
    }
    '&' => {
      self.emit(AMP, p, p + 1)
      return true
    }
    ';' => {
      self.emit(SEMI, p, p + 1)
      return true
    }
    ',' => {
      self.emit(COMMA, p, p + 1)
      return true
    }
    '*' => {
      self.emit(MULT, p, p + 1)
      return true
    }
    'x' | 'o' => return self.link(c) || self.node_string()
    '<' => {
      if !self.link(c) {
        self.emit(TAGSTART, p, p + 1)
      }
      return true
    }
    '-' => {
      if !(self.link(c) || self.node_string()) {
        self.emit(MINUS, p, p + 1)
      }
      return true
    }
    '=' => return self.link(c)
    '.' => return self.link(c) || self.node_string()
    '~' => return self.invis_link()
    '(' => return self.opener(c)
    '[' => {
      if self.at(p + 1) == '|' {
        self.emit(VERTEX_WITH_PROPS_START, p, p + 2)
        return true
      }
      return self.opener(c)
    }
    '|' | '{' => return self.opener(c)
    '>' => {
      self.push(S_TEXT)
      self.emit(TAGEND, p, p + 1)
      return true
    }
    '^' => {
      self.emit(UP, p, p + 1)
      return true
    }
    '\\' => {
      if self.at(p + 1) == '|' {
        self.emit(SEP, p, p + 2)
        return true
      }
      return self.node_string()
    }
    'v' => {
      if !@util.is_word(self.at(p + 1)) {
        self.emit(DOWN, p, p + 1)
        return true
      }
      return self.node_string()
    }
    _ => ()
  }
  if @util.is_space(c) {
    if self.link(c) {
      return true
    }
    let e = newline_end(self.src, p)
    if e >= 0 {
      self.emit(NEWLINE, p, e)
      return true
    }
    let e = blank_end(self.src, p)
    if e >= 0 {
      self.emit(SPACE, p, e)
      return true
    }
    return false
  }
  if c < 128 {
    return self.node_string()
  }
  if @util.is_unicode_letter(c) {
    self.emit(UNICODE_TEXT, p, p + 1)
    return true
  }
  false
}

///|
fn Lexer::edge_text(
  self : Lexer,
  c : Int32,
  link_re : (String, Int32) -> Int32,
  a : Int32,
  b : Int32,
) -> Bool {
  if c == '"' {
    self.quote()
    return true
  }
  let p = self.p
  let d = self.link_char(p)
  if d == a || d == b {
    let e = link_re(self.src, p)
    if e >= 0 {
      self.pop()
      self.emit(LINK, p, e)
      return true
    }
  }
  if c == a && (a != '-' || self.at(p + 1) == '-') {
    return false
  }
  let mut q = p + 1
  while q < self.n {
    let ch = self.at(q)
    if ch == '"' {
      break
    }
    if ch == a {
      if a != '-' || self.at(q + 1) == '-' {
        break
      }
    } else if is_link_prefix(ch) || ch == b || @util.is_space(ch) {
      let dd = self.link_char(q)
      if (dd == a || dd == b) && link_re(self.src, q) >= 0 {
        break
      }
    }
    q += 1
  }
  self.emit(EDGE_TEXT, p, q)
  true
}

///|
fn Lexer::text(self : Lexer, c : Int32) -> Unit {
  let p = self.p
  let d = self.at(p + 1)
  match c {
    '"' => self.quote()
    '(' | '[' | '{' => ignore(self.opener(c))
    ']' => {
      self.pop()
      if d == ')' {
        self.emit(STADIUMEND, p, p + 2)
      } else if d == ']' {
        self.emit(SUBROUTINEEND, p, p + 2)
      } else {
        self.emit(SQE, p, p + 1)
      }
    }
    ')' => {
      self.pop()
      if d == ']' {
        self.emit(CYLINDEREND, p, p + 2)
      } else if d == ')' && self.at(p + 2) == ')' {
        self.emit(DOUBLECIRCLEEND, p, p + 3)
      } else {
        self.emit(PE, p, p + 1)
      }
    }
    '|' => {
      self.pop()
      self.emit(PIPE, p, p + 1)
    }
    '}' => {
      self.pop()
      self.emit(DIAMOND_STOP, p, p + 1)
    }
    _ => {
      if (c == '~' || @util.is_space(c)) && self.invis_link() {
        return
      }
      let mut q = p + 1
      while q < self.n {
        let ch = self.at(q)
        if ch == '[' ||
          ch == ']' ||
          ch == '(' ||
          ch == ')' ||
          ch == '{' ||
          ch == '}' ||
          ch == '|' ||
          ch == '"' {
          break
        }
        q += 1
      }
      self.emit(TEXT, p, q)
    }
  }
}

///|
fn Lexer::ellipse_text(self : Lexer, c : Int32) -> Bool {
  let p = self.p
  let d = self.at(p + 1)
  if c == '"' {
    self.quote()
  } else if (c == '~' || @util.is_space(c)) && self.invis_link() {
    ()
  } else if (c == '-' || c == '/' || c == ')') && d == ')' {
    self.pop()
    self.emit(ELLIPSE_END, p, p + 2)
  } else if c == '(' || c == '[' || c == '{' {
    ignore(self.opener(c))
  } else if c == ')' || c == ']' || c == '}' {
    return false
  } else {
    let mut q = p + 1
    while q < self.n {
      let ch = self.at(q)
      if ch == '"' ||
        ch == '(' ||
        ch == ')' ||
        ch == '[' ||
        ch == ']' ||
        ch == '{' ||
        ch == '}' {
        break
      }
      if (ch == '-' || ch == '/') && self.at(q + 1) == ')' {
        break
      }
      if (ch == '~' || @util.is_space(ch)) &&
        self.invis_ahead(q) &&
        invisible_link_end(self.src, q) >= 0 {
        break
      }
      q += 1
    }
    self.emit(TEXT, p, q)
  }
  true
}

///|
fn Lexer::trap_text(self : Lexer, c : Int32) -> Bool {
  let p = self.p
  let d = self.at(p + 1)
  if c == '"' {
    self.quote()
    return true
  }
  if (c == '~' || @util.is_space(c)) && self.invis_link() {
    return true
  }
  match c {
    '(' =>
      if d == '-' || d == '[' || (d == '(' && self.at(p + 2) == '(') {
        ignore(self.opener(c))
      } else if d == ']' {
        self.pop()
        self.emit(TRAPEND, p, p + 2)
      } else {
        ignore(self.opener(c))
      }
    '[' | '{' => ignore(self.opener(c))
    '\\' =>
      if d == ']' {
        self.pop()
        self.emit(TRAPEND, p, p + 2)
      } else {
        self.emit(TEXT, p, p + 1)
      }
    '/' =>
      if d == ']' {
        self.pop()
        self.emit(INVTRAPEND, p, p + 2)
      } else {
        self.emit(TEXT, p, p + 1)
      }
    ']' | ')' =>
      if d == ']' {
        self.pop()
        self.emit(TRAPEND, p, p + 2)
      } else {
        return false
      }
    '}' => return false
    _ => {
      if (c == '?' || c == '=') && d == ']' {
        self.pop()
        self.emit(TRAPEND, p, p + 2)
        return true
      }
      let mut q = p + 1
      while q < self.n {
        let ch = self.at(q)
        if ch == '\\' ||
          ch == '[' ||
          ch == ']' ||
          ch == '(' ||
          ch == ')' ||
          ch == '{' ||
          ch == '}' ||
          ch == '/' {
          break
        }
        q += 1
      }
      self.emit(TEXT, p, q)
    }
  }
  true
}

///|
fn Lexer::up_to(self : Lexer, kind : Int32, stop : String) -> Unit {
  let e = @util.index_of(self.src, stop, from=self.p)
  self.emit(kind, self.p, if e == -1 { self.n } else { e })
}

///|
/// Reads one token or state change at `p`; false where the text is unrecognized.
fn Lexer::step(self : Lexer, c : Int32) -> Bool {
  let p = self.p
  match self.state {
    S_INITIAL => return self.initial(c)
    S_STRING =>
      if c == '"' {
        if self.at(p + 1) == '`' {
          self.push(S_MD_STRING)
          self.p += 2
        } else {
          self.pop()
          self.p += 1
        }
      } else {
        self.up_to(STR, "\"")
      }
    S_MD_STRING =>
      if c == '`' {
        if self.at(p + 1) != '"' {
          return false
        }
        self.pop()
        self.p += 2
      } else if c == '"' {
        self.quote()
      } else {
        let mut q = p + 1
        while q < self.n {
          let ch = self.at(q)
          if ch == '`' || ch == '"' {
            break
          }
          q += 1
        }
        self.emit(MD_STR, p, q)
      }
    S_ACC_TITLE | S_ACC_DESCR => {
      let kind = if self.state == S_ACC_TITLE {
        ACC_TITLE_VALUE
      } else {
        ACC_DESCR_VALUE
      }
      self.pop()
      self.up_to(kind, "\n")
    }
    S_ACC_DESCR_MULTILINE =>
      if c == '}' {
        self.pop()
        self.p += 1
      } else {
        self.up_to(ACC_DESCR_MULTILINE_VALUE, "}")
      }
    S_DIR => {
      if c == '"' {
        self.quote()
        return true
      }
      let e = nodir_end(self.src, p)
      if e >= 0 {
        self.pop()
        self.emit(NODIR, p, e)
        return true
      }
      let mut e = dir_end(self.src, p)
      if e < 0 {
        e = dir_symbol_end(self.src, p)
      }
      if e < 0 {
        e = dir_v_end(self.src, p)
      }
      if e >= 0 {
        self.pop()
        self.emit(DIR, p, e)
        return true
      }
      return self.invis_link() || self.opener(c)
    }
    S_TEXT => self.text(c)
    S_ELLIPSE_TEXT => return self.ellipse_text(c)
    S_TRAP_TEXT => return self.trap_text(c)
    S_EDGE_TEXT => return self.edge_text(c, normal_link_end, '-', NO_CHAR)
    S_THICK_EDGE_TEXT => return self.edge_text(c, thick_link_end, '=', NO_CHAR)
    S_DOTTED_EDGE_TEXT => return self.edge_text(c, dotted_link_end, '.', '-')
    S_CLICK =>
      if c == '"' {
        self.quote()
      } else if @util.is_space(c) {
        self.pop()
        self.p += 1
      } else {
        let mut q = p + 1
        while q < self.n && !@util.is_space(self.at(q)) {
          q += 1
        }
        self.emit(CLICK, p, q)
      }
    S_CALLBACKNAME =>
      if c == '(' {
        let e = empty_call_end(self.src, p)
        self.pop()
        if e >= 0 {
          self.p = e
        } else {
          self.push(S_CALLBACKARGS)
          self.p += 1
        }
      } else {
        self.up_to(CALLBACKNAME, "(")
      }
    S_CALLBACKARGS =>
      if c == ')' {
        self.pop()
        self.p += 1
      } else {
        self.up_to(CALLBACKARGS, ")")
      }
    S_SHAPE_DATA =>
      if c == '"' {
        self.push(S_SHAPE_DATA_STR)
        self.emit(SHAPE_DATA, p, p + 1)
      } else if c == '}' {
        self.pop()
        self.p += 1
      } else if c == '^' {
        return false
      } else {
        let mut q = p + 1
        while q < self.n {
          let ch = self.at(q)
          if ch == '}' || ch == '^' || ch == '"' {
            break
          }
          q += 1
        }
        self.emit(SHAPE_DATA, p, q)
      }
    S_SHAPE_DATA_STR =>
      if c == '"' {
        self.pop()
        self.emit(SHAPE_DATA, p, p + 1)
      } else {
        let found = @util.index_of(self.src, "\"", from=p)
        let e = if found == -1 { self.n } else { found }
        self.types.push(SHAPE_DATA)
        self.texts.push(break_lines(@util.slice(self.src, p, end=e)))
        self.starts.push(p)
        self.p = e
      }
    _ => ()
  }
  true
}

///|
/// The token that a state left open at the end of the text produces, or -1 for none.
fn end_token(state : Int32) -> Int32 {
  match state {
    S_INITIAL => EOF
    S_ACC_TITLE => ACC_TITLE_VALUE
    S_ACC_DESCR => ACC_DESCR_VALUE
    S_ACC_DESCR_MULTILINE => ACC_DESCR_MULTILINE_VALUE
    S_CLICK => CLICK
    S_CALLBACKNAME => CALLBACKNAME
    S_CALLBACKARGS => CALLBACKARGS
    _ => -1
  }
}

///|
/// Splits flowchart text into tokens as Mermaid's lexer does.
/// Text the lexer cannot read ends the list with an `INVALID` token where it stops.
pub fn tokenize(src : String) -> Tokens {
  let lexer : Lexer = {
    src,
    n: src.length(),
    types: [],
    texts: [],
    starts: [],
    stack: [],
    state: S_INITIAL,
    p: 0,
    first_graph: true,
    dir_next: @util.index_of(src, "direction"),
    at_next: @util.index_of(src, "@"),
    line_end: -1,
    dir_failed: 0,
    run_end: 0,
    run_at: -1,
    ws_from: -1,
    ws_to: -1,
  }
  while true {
    if lexer.p >= lexer.n {
      let kind = end_token(lexer.state)
      if kind != -1 {
        lexer.emit(kind, lexer.n, lexer.n)
      }
      break
    }
    if !lexer.step(lexer.at(lexer.p)) {
      lexer.types.push(ERROR)
      lexer.texts.push("")
      lexer.starts.push(lexer.p)
      return { types: lexer.types, texts: lexer.texts, starts: lexer.starts, }
    }
  }
  lexer.types.push(END_OF_INPUT)
  lexer.texts.push("")
  lexer.starts.push(lexer.n)
  { types: lexer.types, texts: lexer.texts, starts: lexer.starts, }
}
