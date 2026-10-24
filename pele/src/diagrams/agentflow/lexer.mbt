///|
/// An agentflow's tokens as parallel arrays: the type of each, its text, where it starts, and its span.
/// The span is counted as Jison counts it, with lines from 1 and columns from 0.
/// Each number of the span has an array of its own rather than four sharing one, because an array
/// four times as long reaches the largest block wasm's allocator gives with a quarter of the tokens.
pub(all) struct Tokens {
  types : Array[Int32]
  texts : Array[String]
  starts : Array[Int32]
  first_lines : Array[Int32]
  first_columns : Array[Int32]
  last_lines : Array[Int32]
  last_columns : Array[Int32]
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
const S_CLICK : Int32 = 11

///|
const S_CALLBACKNAME : Int32 = 12

///|
const S_CALLBACKARGS : Int32 = 13

///|
const S_SHAPE_DATA : Int32 = 14

///|
const S_SHAPE_DATA_STR : Int32 = 15

///|
priv struct Lexer {
  src : String
  n : Int32
  types : Array[Int32]
  texts : Array[String]
  starts : Array[Int32]
  first_lines : Array[Int32]
  first_columns : Array[Int32]
  last_lines : Array[Int32]
  last_columns : Array[Int32]
  stack : Array[Int32]
  mut state : Int32
  mut p : Int32
  mut line : Int32
  mut col : Int32
  mut first_graph : Bool
  mut dir_next : Int32
  mut at_next : Int32
  mut line_end : Int32
  mut dir_failed : Int32
  mut run_end : Int32
  mut run_at : Int32
  mut ws_from : Int32
  mut ws_to : Int32
  mut blank_from : Int32
  mut blank_to : Int32
  mut no_link : Int32
  mut no_arrow : Int32
}

///|
fn Lexer::at(self : Lexer, i : Int32) -> Int32 {
  @util.code_at(self.src, i)
}

///|
/// Moves over one match.
/// Jison counts \r\n, \r and \n as one line break each, and after a break its column stops at the first U+2028 or U+2029.
fn Lexer::advance(self : Lexer, e : Int32) -> Unit {
  let mut brk = -1
  let mut k = self.p
  while k < e {
    let ch = self.at(k)
    if ch == '\n' {
      self.line += 1
      brk = k
    } else if ch == '\r' {
      if k + 1 < e && self.at(k + 1) == '\n' {
        k += 1
      }
      self.line += 1
      brk = k
    }
    k += 1
  }
  if brk < 0 {
    self.col += e - self.p
  } else {
    let mut k = brk + 1
    while k < e {
      let ch = self.at(k)
      if ch == 0x2028 || ch == 0x2029 {
        break
      }
      k += 1
    }
    self.col = k - brk - 1
  }
  self.p = e
}

///|
fn Lexer::open_token(
  self : Lexer,
  kind : Int32,
  text : String,
) -> Unit raise @errors.PeleError {
  // pele pushes a token's first line and column into one array with its last, so the push that
  // would pass V8's longest array throws as the token opens.
  if 4 * self.first_lines.length() + 2 > @util.JS_ARRAY_MAX_LENGTH {
    raise @errors.nested_too_deeply()
  }
  self.types.push(kind)
  self.texts.push(text)
  self.starts.push(self.p)
  self.first_lines.push(self.line)
  self.first_columns.push(self.col)
}

///|
fn Lexer::close_token(self : Lexer) -> Unit {
  self.last_lines.push(self.line)
  self.last_columns.push(self.col)
}

///|
fn Lexer::emit(
  self : Lexer,
  kind : Int32,
  e : Int32,
) -> Unit raise @errors.PeleError {
  self.open_token(kind, @util.slice(self.src, self.p, end=e))
  self.advance(e)
  self.close_token()
}

///|
/// For a token that cannot hold a line break.
fn Lexer::emit_flat(
  self : Lexer,
  kind : Int32,
  e : Int32,
) -> Unit raise @errors.PeleError {
  self.open_token(kind, @util.slice(self.src, self.p, end=e))
  self.col += e - self.p
  self.p = e
  self.close_token()
}

///|
/// For a run that Jison matches one character at a time, where \r\n counts as two line breaks.
fn Lexer::emit_chars(
  self : Lexer,
  kind : Int32,
  e : Int32,
) -> Unit raise @errors.PeleError {
  self.open_token(kind, @util.slice(self.src, self.p, end=e))
  for k in self.p..<e {
    let ch = self.at(k)
    if ch == '\n' || ch == '\r' {
      self.line += 1
      self.col = 0
    } else {
      self.col += 1
    }
  }
  self.p = e
  self.close_token()
}

///|
fn Lexer::emit_text(
  self : Lexer,
  kind : Int32,
  text : String,
  e : Int32,
) -> Unit raise @errors.PeleError {
  self.open_token(kind, text)
  self.advance(e)
  self.close_token()
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
/// End of the run of whitespace starting at q.
/// The last run is kept, so asking again from inside it costs nothing.
fn Lexer::ws_end(self : Lexer, q : Int32) -> Int32 {
  if q >= self.ws_from && q <= self.ws_to {
    return self.ws_to
  }
  let mut j = q
  while j < self.n && @util.is_space(self.at(j)) {
    j += 1
  }
  self.ws_from = q
  self.ws_to = j
  j
}

///|
fn Lexer::blank_end(self : Lexer, q : Int32) -> Int32 {
  if q >= self.blank_from && q <= self.blank_to {
    return self.blank_to
  }
  let mut j = q
  while j < self.n {
    let ch = self.at(j)
    if ch != ' ' && ch != '\t' {
      break
    }
    j += 1
  }
  self.blank_from = q
  self.blank_to = j
  j
}

///|
/// End of `\s*--+[x>]\s*` starting at q, or -1.
fn Lexer::arrow_end(self : Lexer, q : Int32) -> Int32 {
  let j = self.ws_end(q)
  if j == self.no_arrow || self.at(j) != '-' || self.at(j + 1) != '-' {
    return -1
  }
  let mut k = j + 2
  while self.at(k) == '-' {
    k += 1
  }
  let t = self.at(k)
  if t == 'x' || t == '>' {
    return self.ws_end(k + 1)
  }
  self.no_arrow = j
  -1
}

///|
fn Lexer::link(self : Lexer) -> Bool raise @errors.PeleError {
  let j = self.ws_end(self.p)
  if j == self.no_link || self.at(j) != '-' {
    return false
  }
  let d = self.at(j + 1)
  let mut k = j + 2
  if d == '-' {
    while self.at(k) == '-' {
      k += 1
    }
    let t = self.at(k)
    if t == 'x' || t == '>' {
      self.emit(LINK, self.ws_end(k + 1))
    } else {
      self.push(S_EDGE_TEXT)
      self.emit(START_LINK, self.ws_end(j + 2))
    }
    return true
  }
  if d == '.' {
    while self.at(k) == '.' {
      k += 1
    }
    if self.at(k) == '-' {
      self.emit(LINK, self.ws_end(k + 1))
      return true
    }
  }
  self.no_link = j
  false
}

///|
/// `%%` not followed by `{`, through the end of the line.
fn Lexer::comment_end(self : Lexer, q : Int32) -> Int32 {
  if self.at(q) != '%' || self.at(q + 1) != '%' || self.at(q + 2) == '{' {
    return -1
  }
  let e = @util.index_of(self.src, "\n", from=q + 2)
  if e == -1 {
    self.n
  } else {
    e
  }
}

///|
fn Lexer::quote(self : Lexer) -> Unit {
  if self.at(self.p + 1) == '`' {
    self.push(S_MD_STRING)
    self.advance(self.p + 2)
  } else {
    self.push(S_STRING)
    self.advance(self.p + 1)
  }
}

///|
fn Lexer::opener(self : Lexer, c : Int32) -> Bool raise @errors.PeleError {
  let p = self.p
  let d = self.at(p + 1)
  if c == '(' {
    if d == '-' {
      self.push(S_ELLIPSE_TEXT)
      self.emit_flat(ELLIPSE_START, p + 2)
    } else if d == '[' {
      self.push(S_TEXT)
      self.emit_flat(STADIUMSTART, p + 2)
    } else if d == '(' && self.at(p + 2) == '(' {
      self.push(S_TEXT)
      self.emit_flat(DOUBLECIRCLESTART, p + 3)
    } else {
      self.push(S_TEXT)
      self.emit_flat(PS, p + 1)
    }
    return true
  }
  if c == '[' {
    if d == '[' {
      self.push(S_TEXT)
      self.emit_flat(SUBROUTINESTART, p + 2)
    } else if d == '(' {
      self.push(S_TEXT)
      self.emit_flat(CYLINDERSTART, p + 2)
    } else if d == '/' {
      self.push(S_TRAP_TEXT)
      self.emit_flat(TRAPSTART, p + 2)
    } else if d == '\\' {
      self.push(S_TRAP_TEXT)
      self.emit_flat(INVTRAPSTART, p + 2)
    } else {
      self.push(S_TEXT)
      self.emit_flat(SQS, p + 1)
    }
    return true
  }
  if c == '|' {
    self.push(S_TEXT)
    self.emit_flat(PIPE, p + 1)
    return true
  }
  if c == '{' {
    self.push(S_TEXT)
    self.emit_flat(DIAMOND_START, p + 1)
    return true
  }
  false
}

///|
fn Lexer::node_string(self : Lexer) -> Bool raise @errors.PeleError {
  let mut q = self.p
  while q < self.n {
    let ch = self.at(q)
    if ch < 128 && @flowchart.is_node_char(ch) {
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
  self.emit_flat(NODE_STRING, q)
  true
}

///|
fn Lexer::blanks(self : Lexer, from : Int32) -> Int32 {
  let mut e = from
  while e < self.n {
    let ch = self.at(e)
    if ch != ' ' && ch != '\t' {
      break
    }
    e += 1
  }
  e
}

///|
/// The keywords of the initial state, by their first character.
fn Lexer::keyword(self : Lexer, c : Int32) -> Bool raise @errors.PeleError {
  let p = self.p
  let src = self.src
  match c {
    'a' => {
      if @util.starts_with_at(src, "acc", p) {
        let e = @flowchart.keyword_punct_end(src, p, "accTitle", ':')
        if e >= 0 {
          self.push(S_ACC_TITLE)
          self.emit(ACC_TITLE, e)
          return true
        }
        let e = @flowchart.keyword_punct_end(src, p, "accDescr", ':')
        if e >= 0 {
          self.push(S_ACC_DESCR)
          self.emit(ACC_DESCR, e)
          return true
        }
        let e = @flowchart.keyword_punct_end(src, p, "accDescr", '{')
        if e >= 0 {
          self.push(S_ACC_DESCR_MULTILINE)
          self.advance(e)
          return true
        }
      }
      if self.kw("agentflow-beta") {
        if self.first_graph {
          self.first_graph = false
          self.push(S_DIR)
        }
        self.emit_flat(GRAPH, p + 14)
        return true
      }
    }
    '@' =>
      if self.at(p + 1) == '{' {
        self.push(S_SHAPE_DATA)
        self.emit_text(SHAPE_DATA, "", p + 2)
        return true
      }
    'c' => {
      let e = @flowchart.keyword_space_end(src, p, "call")
      if e >= 0 {
        self.push(S_CALLBACKNAME)
        self.advance(e)
        return true
      }
      if self.kw("classDef") {
        self.emit_flat(CLASSDEF, p + 8)
        return true
      }
      if self.kw("class") {
        self.emit_flat(CLASS, p + 5)
        return true
      }
      let e = @flowchart.keyword_space_end(src, p, "click")
      if e >= 0 {
        self.push(S_CLICK)
        self.advance(e)
        return true
      }
      if self.kw("connector") {
        self.emit_flat(CONNECTOR, p + 9)
        return true
      }
    }
    '"' => {
      self.quote()
      return true
    }
    's' =>
      if self.kw("style") {
        self.emit_flat(STYLE, p + 5)
        return true
      }
    'd' =>
      if self.kw("default") {
        self.emit_flat(DEFAULT, p + 7)
        return true
      }
    'l' =>
      if self.kw("linkStyle") {
        self.emit_flat(LINKSTYLE, p + 9)
        return true
      }
    'i' =>
      if self.kw("interpolate") {
        self.emit_flat(INTERPOLATE, p + 11)
        return true
      }
    'h' =>
      if @util.starts_with_at(src, "href", p) && @util.is_space(self.at(p + 4)) {
        self.emit(HREF, p + 5)
        return true
      }
    'f' =>
      if self.kw("flow") {
        self.emit_flat(FLOW, p + 4)
        return true
      }
    'g' =>
      if self.kw("global") {
        self.emit_flat(GLOBAL, self.blanks(p + 6))
        return true
      }
    'e' =>
      if self.kw("end") {
        self.emit_flat(END, self.blanks(p + 3))
        return true
      }
    '_' =>
      for target in ["_self", "_blank", "_parent", "_top"] {
        if self.kw(target) {
          self.emit_flat(LINK_TARGET, p + target.length())
          return true
        }
      }
    _ => ()
  }
  false
}

///|
/// A direction statement starting here, as Mermaid's `.*direction\s+TB[^\n]*` and its siblings.
fn Lexer::direction(self : Lexer) -> Bool raise @errors.PeleError {
  if self.dir_next == -1 || self.p < self.dir_failed {
    return false
  }
  let p = self.p
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
  if self.dir_next < self.line_end {
    for i, dir in ["TB", "BT", "RL", "LR", "TD"] {
      let e = @flowchart.direction_end(self.src, p, dir)
      if e >= 0 {
        self.emit(DIRECTION_TB + i, e)
        return true
      }
    }
    // No direction statement starts anywhere in the rest of this line either.
    self.dir_failed = self.line_end
  }
  false
}

///|
/// A link id is a run of non-space characters up to its last `@` that is not followed by `{` or `"`.
fn Lexer::link_id(self : Lexer, c : Int32) -> Bool raise @errors.PeleError {
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
    self.emit_flat(LINK_ID, self.run_at + 1)
    return true
  }
  false
}

///|
fn Lexer::initial(self : Lexer, c : Int32) -> Bool raise @errors.PeleError {
  if self.keyword(c) || self.direction() || self.link_id(c) {
    return true
  }
  let p = self.p
  if c >= '0' && c <= '9' {
    let mut q = p + 1
    while q < self.n {
      let ch = self.at(q)
      if ch < '0' || ch > '9' {
        break
      }
      q += 1
    }
    self.emit_flat(NUM, q)
    return true
  }
  match c {
    '#' => {
      self.emit_flat(BRKT, p + 1)
      return true
    }
    ':' => {
      if self.at(p + 1) == ':' && self.at(p + 2) == ':' {
        self.emit_flat(STYLE_SEPARATOR, p + 3)
      } else {
        self.emit_flat(COLON, p + 1)
      }
      return true
    }
    '&' => {
      self.emit_flat(AMP, p + 1)
      return true
    }
    ';' => {
      self.emit_flat(SEMI, p + 1)
      return true
    }
    ',' => {
      self.emit_flat(COMMA, p + 1)
      return true
    }
    '*' => {
      self.emit_flat(MULT, p + 1)
      return true
    }
    '<' => {
      self.emit_flat(TAGSTART, p + 1)
      return true
    }
    '-' => {
      if self.link() || self.node_string() {
        return true
      }
      self.emit_flat(MINUS, p + 1)
      return true
    }
    '(' => return self.opener(c)
    '[' => {
      if self.at(p + 1) == '|' {
        self.emit_flat(VERTEX_WITH_PROPS_START, p + 2)
        return true
      }
      return self.opener(c)
    }
    '|' | '{' => return self.opener(c)
    '>' => {
      self.push(S_TEXT)
      self.emit_flat(TAGEND, p + 1)
      return true
    }
    '^' => {
      self.emit_flat(UP, p + 1)
      return true
    }
    '\\' => {
      if self.at(p + 1) == '|' {
        self.emit_flat(SEP, p + 2)
        return true
      }
      return self.node_string()
    }
    'v' => {
      if !@util.is_word(self.at(p + 1)) {
        self.emit_flat(DOWN, p + 1)
        return true
      }
      return self.node_string()
    }
    '%' => {
      let e = self.comment_end(p)
      if e >= 0 {
        self.emit(COMMENT, e)
        return true
      }
      return self.node_string()
    }
    _ => ()
  }
  if @util.is_space(c) {
    if self.link() {
      return true
    }
    if c == ' ' || c == '\t' {
      let e = self.comment_end(self.blank_end(p))
      if e >= 0 {
        self.emit(COMMENT, e)
        return true
      }
    }
    let mut e = p
    while true {
      let ch = self.at(e)
      if ch == '\n' {
        e += 1
      } else if ch == '\r' && self.at(e + 1) == '\n' {
        e += 2
      } else {
        break
      }
    }
    if e > p {
      self.emit(NEWLINE, e)
    } else {
      self.emit(SPACE, p + 1)
    }
    return true
  }
  if c < 128 {
    return self.node_string()
  }
  if @util.is_unicode_letter(c) {
    self.emit_flat(UNICODE_TEXT, p + 1)
    return true
  }
  false
}

///|
fn Lexer::string_state(self : Lexer, c : Int32) -> Unit raise @errors.PeleError {
  if c == '"' {
    if self.at(self.p + 1) == '`' {
      self.push(S_MD_STRING)
      self.advance(self.p + 2)
    } else {
      self.pop()
      self.advance(self.p + 1)
    }
  } else {
    let e = @util.index_of(self.src, "\"", from=self.p)
    self.emit(STR, if e == -1 { self.n } else { e })
  }
}

///|
fn Lexer::md_string_state(
  self : Lexer,
  c : Int32,
) -> Bool raise @errors.PeleError {
  if c == '`' {
    if self.at(self.p + 1) == '"' {
      self.pop()
      self.advance(self.p + 2)
    } else {
      return false
    }
  } else if c == '"' {
    self.quote()
  } else {
    let mut q = self.p + 1
    while q < self.n {
      let ch = self.at(q)
      if ch == '`' || ch == '"' {
        break
      }
      q += 1
    }
    self.emit(MD_STR, q)
  }
  true
}

///|
fn Lexer::dir_state(self : Lexer, c : Int32) -> Bool raise @errors.PeleError {
  let src = self.src
  let p = self.p
  if c == '"' {
    self.quote()
    return true
  }
  let e = @flowchart.nodir_end(src, p)
  if e >= 0 {
    self.pop()
    self.emit(NODIR, e)
    return true
  }
  let mut e = @flowchart.dir_end(src, p)
  if e < 0 {
    e = @flowchart.dir_symbol_end(src, p)
  }
  if e < 0 {
    e = @flowchart.dir_v_end(src, p)
  }
  if e >= 0 {
    self.pop()
    self.emit(DIR, e)
    return true
  }
  self.opener(c)
}

///|
fn is_text_stop(ch : Int32) -> Bool {
  ch == '[' ||
  ch == ']' ||
  ch == '(' ||
  ch == ')' ||
  ch == '{' ||
  ch == '}' ||
  ch == '|' ||
  ch == '"' ||
  ch == '%'
}

///|
fn Lexer::text_state(self : Lexer, c : Int32) -> Bool raise @errors.PeleError {
  let p = self.p
  let d = self.at(p + 1)
  match c {
    '"' => self.quote()
    '(' | '[' | '{' => ignore(self.opener(c))
    ']' => {
      self.pop()
      if d == ')' {
        self.emit_flat(STADIUMEND, p + 2)
      } else if d == ']' {
        self.emit_flat(SUBROUTINEEND, p + 2)
      } else {
        self.emit_flat(SQE, p + 1)
      }
    }
    ')' => {
      self.pop()
      if d == ']' {
        self.emit_flat(CYLINDEREND, p + 2)
      } else if d == ')' && self.at(p + 2) == ')' {
        self.emit_flat(DOUBLECIRCLEEND, p + 3)
      } else {
        self.emit_flat(PE, p + 1)
      }
    }
    '|' => {
      self.pop()
      self.emit_flat(PIPE, p + 1)
    }
    '}' => {
      self.pop()
      self.emit_flat(DIAMOND_STOP, p + 1)
    }
    '%' => {
      // Jison drops the lone `%` from Mermaid's text pattern, so only a comment may start with one.
      let e = self.comment_end(p)
      if e >= 0 {
        self.advance(e)
      } else {
        return false
      }
    }
    _ => {
      let mut q = p + 1
      while q < self.n && !is_text_stop(self.at(q)) {
        q += 1
      }
      self.emit(TEXT, q)
    }
  }
  true
}

///|
fn Lexer::ellipse_text_state(
  self : Lexer,
  c : Int32,
) -> Bool raise @errors.PeleError {
  let p = self.p
  let d = self.at(p + 1)
  if c == '"' {
    self.quote()
    return true
  }
  if c == '%' {
    let e = self.comment_end(p)
    if e >= 0 {
      self.advance(e)
      return true
    }
  }
  if (c == '-' || c == '/' || c == ')') && d == ')' {
    self.pop()
    self.emit_flat(ELLIPSE_END, p + 2)
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
      if ch == '%' && self.at(q + 1) == '%' && self.at(q + 2) != '{' {
        break
      }
      q += 1
    }
    self.emit_chars(TEXT, q)
  }
  true
}

///|
fn is_trap_stop(ch : Int32) -> Bool {
  ch == '\\' ||
  ch == '[' ||
  ch == ']' ||
  ch == '(' ||
  ch == ')' ||
  ch == '{' ||
  ch == '}' ||
  ch == '/' ||
  ch == '%'
}

///|
fn Lexer::trap_text_state(
  self : Lexer,
  c : Int32,
) -> Bool raise @errors.PeleError {
  let p = self.p
  let d = self.at(p + 1)
  if c == '"' {
    self.quote()
    return true
  }
  match c {
    '(' =>
      if d == ']' {
        self.pop()
        self.emit_flat(TRAPEND, p + 2)
      } else {
        ignore(self.opener(c))
      }
    '[' | '{' => ignore(self.opener(c))
    '\\' =>
      if d == ']' {
        self.pop()
        self.emit_flat(TRAPEND, p + 2)
      } else {
        self.emit_flat(TEXT, p + 1)
      }
    '/' =>
      if d == ']' {
        self.pop()
        self.emit_flat(INVTRAPEND, p + 2)
      } else {
        self.emit_flat(TEXT, p + 1)
      }
    ']' | ')' =>
      if d == ']' {
        self.pop()
        self.emit_flat(TRAPEND, p + 2)
      } else {
        return false
      }
    '}' => return false
    '%' => {
      let e = self.comment_end(p)
      if e >= 0 {
        self.advance(e)
      } else {
        return false
      }
    }
    _ => {
      if (c == '?' || c == '=') && d == ']' {
        self.pop()
        self.emit_flat(TRAPEND, p + 2)
        return true
      }
      let mut q = p + 1
      while q < self.n && !is_trap_stop(self.at(q)) {
        q += 1
      }
      self.emit(TEXT, q)
    }
  }
  true
}

///|
fn Lexer::edge_text_state(
  self : Lexer,
  c : Int32,
) -> Bool raise @errors.PeleError {
  if c == '"' {
    self.quote()
    return true
  }
  let e = self.arrow_end(self.p)
  if e >= 0 {
    self.pop()
    self.emit(LINK, e)
    return true
  }
  if c == '-' && self.at(self.p + 1) == '-' {
    return false
  }
  let mut q = self.p + 1
  while q < self.n {
    let ch = self.at(q)
    if ch == '"' {
      break
    }
    if ch == '-' {
      if self.at(q + 1) == '-' {
        break
      }
    } else if @util.is_space(ch) && self.arrow_end(q) >= 0 {
      break
    }
    q += 1
  }
  self.emit_chars(EDGE_TEXT, q)
  true
}

///|
fn Lexer::step(self : Lexer, c : Int32) -> Bool raise @errors.PeleError {
  let src = self.src
  let p = self.p
  match self.state {
    S_INITIAL => return self.initial(c)
    S_STRING => self.string_state(c)
    S_MD_STRING => return self.md_string_state(c)
    S_ACC_TITLE | S_ACC_DESCR => {
      let found = @util.index_of(src, "\n", from=p)
      let e = if found == -1 { self.n } else { found }
      let kind = if self.state == S_ACC_TITLE {
        ACC_TITLE_VALUE
      } else {
        ACC_DESCR_VALUE
      }
      self.pop()
      self.emit(kind, e)
    }
    S_ACC_DESCR_MULTILINE =>
      if c == '}' {
        self.pop()
        self.advance(p + 1)
      } else {
        let found = @util.index_of(src, "}", from=p)
        self.emit(
          ACC_DESCR_MULTILINE_VALUE,
          if found == -1 {
            self.n
          } else {
            found
          },
        )
      }
    S_DIR => return self.dir_state(c)
    S_TEXT => return self.text_state(c)
    S_ELLIPSE_TEXT => return self.ellipse_text_state(c)
    S_TRAP_TEXT => return self.trap_text_state(c)
    S_EDGE_TEXT => return self.edge_text_state(c)
    S_CLICK =>
      if c == '"' {
        self.quote()
      } else if @util.is_space(c) {
        self.pop()
        self.advance(p + 1)
      } else {
        let mut q = p + 1
        while q < self.n && !@util.is_space(self.at(q)) {
          q += 1
        }
        self.emit_flat(CLICK, q)
      }
    S_CALLBACKNAME =>
      if c == '(' {
        let e = @flowchart.empty_call_end(src, p)
        self.pop()
        if e >= 0 {
          self.advance(e)
        } else {
          self.push(S_CALLBACKARGS)
          self.advance(p + 1)
        }
      } else {
        let found = @util.index_of(src, "(", from=p)
        self.emit(CALLBACKNAME, if found == -1 { self.n } else { found })
      }
    S_CALLBACKARGS =>
      if c == ')' {
        self.pop()
        self.advance(p + 1)
      } else {
        let found = @util.index_of(src, ")", from=p)
        self.emit(CALLBACKARGS, if found == -1 { self.n } else { found })
      }
    S_SHAPE_DATA =>
      if c == '"' {
        self.push(S_SHAPE_DATA_STR)
        self.emit_flat(SHAPE_DATA, p + 1)
      } else if c == '}' {
        self.pop()
        self.advance(p + 1)
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
        self.emit(SHAPE_DATA, q)
      }
    _ =>
      if c == '"' {
        self.pop()
        self.emit_flat(SHAPE_DATA, p + 1)
      } else {
        let found = @util.index_of(src, "\"", from=p)
        let e = if found == -1 { self.n } else { found }
        self.emit_text(
          SHAPE_DATA,
          @flowchart.break_lines(@util.slice(src, p, end=e)),
          e,
        )
      }
  }
  true
}

///|
/// Splits an agentflow into tokens as Mermaid's generated lexer does, ending with an error token where it stops.
pub fn tokenize(src : String) -> Tokens raise @errors.PeleError {
  let lexer : Lexer = {
    src,
    n: src.length(),
    types: [],
    texts: [],
    starts: [],
    first_lines: [],
    first_columns: [],
    last_lines: [],
    last_columns: [],
    stack: [],
    state: S_INITIAL,
    p: 0,
    line: 1,
    col: 0,
    first_graph: true,
    dir_next: @util.index_of(src, "direction"),
    at_next: @util.index_of(src, "@"),
    line_end: -1,
    dir_failed: 0,
    run_end: 0,
    run_at: -1,
    ws_from: -1,
    ws_to: -1,
    blank_from: -1,
    blank_to: -1,
    no_link: -1,
    no_arrow: -1,
  }
  while lexer.p < lexer.n {
    if !lexer.step(lexer.at(lexer.p)) {
      lexer.open_token(ERROR, "")
      lexer.close_token()
      return lexer.tokens()
    }
  }
  let last = match lexer.state {
    S_INITIAL => EOF
    S_ACC_TITLE => ACC_TITLE_VALUE
    S_ACC_DESCR => ACC_DESCR_VALUE
    S_ACC_DESCR_MULTILINE => ACC_DESCR_MULTILINE_VALUE
    S_CLICK => CLICK
    S_CALLBACKNAME => CALLBACKNAME
    S_CALLBACKARGS => CALLBACKARGS
    _ => -1
  }
  if last != -1 {
    lexer.emit_flat(last, lexer.n)
  }
  lexer.open_token(END_OF_INPUT, "")
  lexer.close_token()
  lexer.tokens()
}

///|
fn Lexer::tokens(self : Lexer) -> Tokens {
  {
    types: self.types,
    texts: self.texts,
    starts: self.starts,
    first_lines: self.first_lines,
    first_columns: self.first_columns,
    last_lines: self.last_lines,
    last_columns: self.last_columns,
  }
}
