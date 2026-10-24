///|
/// The token stream of a requirement diagram: each token's type, text and offset.
pub(all) struct Tokens {
  types : Array[Int32]
  texts : Array[String]
  starts : Array[Int32]
}

///|
/// Every keyword, in lower case: each is matched without regard to case and must end at a word boundary.
let keywords : Map[String, Int32] = {
  "requirementdiagram": T_RD,
  "id": T_ID,
  "text": T_TEXT,
  "risk": T_RISK,
  "verifymethod": T_VERIFYMTHD,
  "requirement": T_REQUIREMENT,
  "functionalrequirement": T_FUNCTIONAL_REQUIREMENT,
  "interfacerequirement": T_INTERFACE_REQUIREMENT,
  "performancerequirement": T_PERFORMANCE_REQUIREMENT,
  "physicalrequirement": T_PHYSICAL_REQUIREMENT,
  "designconstraint": T_DESIGN_CONSTRAINT,
  "low": T_LOW_RISK,
  "medium": T_MED_RISK,
  "high": T_HIGH_RISK,
  "analysis": T_VERIFY_ANALYSIS,
  "demonstration": T_VERIFY_DEMONSTRATION,
  "inspection": T_VERIFY_INSPECTION,
  "test": T_VERIFY_TEST,
  "element": T_ELEMENT,
  "contains": T_CONTAINS,
  "copies": T_COPIES,
  "derives": T_DERIVES,
  "satisfies": T_SATISFIES,
  "verifies": T_VERIFIES,
  "refines": T_REFINES,
  "traces": T_TRACES,
  "type": T_TYPE,
  "docref": T_DOCREF,
  "style": T_STYLE,
  "classdef": T_CLASSDEF,
  "class": T_CLASS,
}

///|
const LONGEST_KEYWORD : Int32 = 22

///|
const S_INITIAL : Int32 = 0

///|
const S_STRING : Int32 = 1

///|
const S_STYLE : Int32 = 2

///|
const S_ACC_TITLE : Int32 = 3

///|
const S_ACC_DESCR : Int32 = 4

///|
const S_ACC_DESCR_MULTILINE : Int32 = 5

///|
/// A character that ends an unquoted string: `:,{<>-=` and line breaks.
fn is_stop(c : Int32) -> Bool {
  c == ':' ||
  c == ',' ||
  c == '\r' ||
  c == '\n' ||
  c == '{' ||
  c == '<' ||
  c == '>' ||
  c == '-' ||
  c == '='
}

///|
/// Whether `word`, in lower case, is at `at` in any case.
/// Under the `i` flag without `u`, no character outside ASCII matches an ASCII letter.
fn word_at(src : String, at : Int32, word : String) -> Bool {
  for k in 0..<word.length() {
    let c = @util.code_at(src, at + k)
    let w = word.unsafe_get(k).to_int()
    if c != w && (c < 65 || c > 90 || c + 32 != w) {
      return false
    }
  }
  true
}

///|
fn lower_ascii(text : String) -> String {
  let out = StringBuilder()
  for i in 0..<text.length() {
    let c = text.unsafe_get(i).to_int()
    out.write_char(
      Int32::unsafe_to_char(if c >= 65 && c <= 90 { c + 32 } else { c }),
    )
  }
  out.to_string()
}

///|
/// Where `keyword\s*<close>\s*` matched at `at` without regard to case ends, or -1.
fn keyword_then(
  src : String,
  at : Int32,
  keyword : String,
  close : Int32,
) -> Int32 {
  if !word_at(src, at, keyword) {
    return -1
  }
  let mut q = at + keyword.length()
  while @util.is_space(@util.code_at(src, q)) {
    q += 1
  }
  if @util.code_at(src, q) != close {
    return -1
  }
  q += 1
  while @util.is_space(@util.code_at(src, q)) {
    q += 1
  }
  q
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
  /// Where each kind of direction statement starts and where its keyword ends, in the order
  /// TB, BT, RL, LR, found in one pass.
  dir_starts : Array[Array[Int32]]
  dir_ends : Array[Array[Int32]]
  dir_seen : Array[Int32]
  mut any_dir : Bool
  mut line_end : Int32
}

///|
/// Finds every match of `/direction\s+(?:(TB)|(BT)|(RL)|LR)/gi`.
/// Giving back whitespace cannot help the match, as the letters that follow are not whitespace.
fn Lexer::find_directions(self : Lexer) -> Unit {
  let src = self.src
  let mut i = 0
  while i < self.n {
    if word_at(src, i, "direction") && @util.is_space(@util.code_at(src, i + 9)) {
      let mut j = i + 10
      while @util.is_space(@util.code_at(src, j)) {
        j += 1
      }
      let a = @util.code_at(src, j) | 32
      let b = @util.code_at(src, j + 1) | 32
      let kind = if a == 't' && b == 'b' {
        0
      } else if a == 'b' && b == 't' {
        1
      } else if a == 'r' && b == 'l' {
        2
      } else if a == 'l' && b == 'r' {
        3
      } else {
        -1
      }
      if kind >= 0 {
        self.dir_starts[kind].push(i)
        self.dir_ends[kind].push(j + 2)
        self.any_dir = true
        i = j + 2
        continue
      }
    }
    i += 1
  }
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
fn Lexer::line_break(self : Lexer, q : Int32) -> Int32 {
  let e = @util.index_of(self.src, "\n", from=q)
  if e == -1 {
    self.n
  } else {
    e
  }
}

///|
/// `.*direction\s+XX[^\n]*`: the last such statement that starts on this line decides the token.
fn Lexer::direction(self : Lexer) -> Bool {
  if self.line_end < self.p {
    let mut q = self.p
    while q < self.n && !@util.is_line_end(@util.code_at(self.src, q)) {
      q += 1
    }
    self.line_end = q
    for k in 0..<4 {
      let list = self.dir_starts[k]
      let mut j = self.dir_seen[k]
      while j < list.length() && list[j] <= self.line_end {
        j += 1
      }
      self.dir_seen[k] = j
    }
  }
  for k in 0..<4 {
    let j = self.dir_seen[k] - 1
    if j >= 0 && self.dir_starts[k][j] >= self.p {
      self.emit(
        T_DIRECTION_TB + k,
        self.p,
        self.line_break(self.dir_ends[k][j]),
      )
      return true
    }
  }
  false
}

///|
fn Lexer::initial(self : Lexer, c : Int32) -> Bool {
  let src = self.src
  let p = self.p
  let n = self.n
  let lower = c | 32
  if lower == 't' &&
    word_at(src, p + 1, "itle") &&
    @util.is_space(@util.code_at(src, p + 5)) {
    let mut q = p + 6
    while q < n {
      let d = @util.code_at(src, q)
      if d == '#' || d == '\n' || d == ';' {
        break
      }
      q += 1
    }
    if q > p + 6 {
      self.emit(T_TITLE, p, q)
      return true
    }
  }
  if lower == 'a' &&
    (@util.code_at(src, p + 1) | 32) == 'c' &&
    (@util.code_at(src, p + 2) | 32) == 'c' {
    let e = keyword_then(src, p, "acctitle", ':')
    if e >= 0 {
      self.push(S_ACC_TITLE)
      self.emit(T_ACC_TITLE, p, e)
      return true
    }
    let e = keyword_then(src, p, "accdescr", ':')
    if e >= 0 {
      self.push(S_ACC_DESCR)
      self.emit(T_ACC_DESCR, p, e)
      return true
    }
    let e = keyword_then(src, p, "accdescr", '{')
    if e >= 0 {
      self.push(S_ACC_DESCR_MULTILINE)
      self.p = e
      return true
    }
  }
  if self.any_dir && !@util.is_line_end(c) && self.direction() {
    return true
  }
  if c == '\n' || (c == '\r' && @util.code_at(src, p + 1) == '\n') {
    let mut q = p
    while q < n {
      let d = @util.code_at(src, q)
      if d == '\n' {
        q += 1
      } else if d == '\r' && @util.code_at(src, q + 1) == '\n' {
        q += 2
      } else {
        break
      }
    }
    self.emit(T_NEWLINE, p, q)
    return true
  }
  if @util.is_space(c) {
    let mut q = p + 1
    while q < n && @util.is_space(@util.code_at(src, q)) {
      q += 1
    }
    self.p = q
    return true
  }
  if c == '#' || c == '%' {
    self.p = self.line_break(p)
    return true
  }
  if @util.is_word(c) {
    let mut q = p + 1
    while q < n && @util.is_word(@util.code_at(src, q)) {
      q += 1
    }
    if q - p <= LONGEST_KEYWORD {
      if keywords.get(lower_ascii(@util.slice(src, p, end=q))) is Some(keyword) {
        if keyword == T_STYLE || keyword == T_CLASSDEF || keyword == T_CLASS {
          self.push(S_STYLE)
        }
        self.emit(keyword, p, q)
        return true
      }
    }
    while q < n {
      let d = @util.code_at(src, q)
      if d < 128 && is_stop(d) {
        break
      }
      q += 1
    }
    self.types.push(T_UNQSTRING)
    self.texts.push(@util.trim(@util.slice(src, p, end=q)))
    self.starts.push(p)
    self.p = q
    return true
  }
  match c {
    '{' => self.emit(T_STRUCT_START, p, p + 1)
    '}' => self.emit(T_STRUCT_STOP, p, p + 1)
    ':' =>
      if @util.code_at(src, p + 1) == ':' && @util.code_at(src, p + 2) == ':' {
        self.emit(T_STYLE_SEPARATOR, p, p + 3)
      } else {
        self.emit(T_COLONSEP, p, p + 1)
      }
    '<' => {
      if @util.code_at(src, p + 1) != '-' {
        return false
      }
      self.emit(T_END_ARROW_L, p, p + 2)
    }
    '-' =>
      if @util.code_at(src, p + 1) == '>' {
        self.emit(T_END_ARROW_R, p, p + 2)
      } else {
        self.emit(T_LINE, p, p + 1)
      }
    '"' => {
      self.push(S_STRING)
      self.p = p + 1
    }
    ',' => self.emit(T_COMMA, p, p + 1)
    _ => return false
  }
  true
}

///|
fn Lexer::style(self : Lexer, c : Int32) -> Bool {
  let p = self.p
  if @util.is_word(c) {
    let mut q = p + 1
    while q < self.n && @util.is_word(@util.code_at(self.src, q)) {
      q += 1
    }
    self.emit(T_ALPHA, p, q)
    return true
  }
  match c {
    ':' => self.emit(T_COLON, p, p + 1)
    ';' => self.emit(T_SEMICOLON, p, p + 1)
    '%' => self.emit(T_PERCENT, p, p + 1)
    '-' => self.emit(T_MINUS, p, p + 1)
    '#' => self.emit(T_BRKT, p, p + 1)
    ' ' => self.p = p + 1
    '"' => {
      self.push(S_STRING)
      self.p = p + 1
    }
    '\n' => {
      self.pop()
      self.p = p + 1
    }
    ',' => self.emit(T_COMMA, p, p + 1)
    _ => return false
  }
  true
}

///|
/// Splits a requirement diagram into tokens as Mermaid's lexer does.
/// Its rules are tried in order and the first match wins, so a line that holds a direction
/// statement anywhere is one token.
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
    dir_starts: [[], [], [], []],
    dir_ends: [[], [], [], []],
    dir_seen: [0, 0, 0, 0],
    any_dir: false,
    line_end: -1,
  }
  lexer.find_directions()
  let n = lexer.n
  while lexer.p < n {
    let p = lexer.p
    let c = @util.code_at(src, p)
    let ok = match lexer.state {
      S_INITIAL => lexer.initial(c)
      S_STYLE => lexer.style(c)
      S_STRING => {
        if c == '"' {
          lexer.pop()
          lexer.p = p + 1
        } else {
          let e = @util.index_of(src, "\"", from=p)
          lexer.emit(T_QSTRING, p, if e == -1 { n } else { e })
        }
        true
      }
      S_ACC_TITLE => {
        lexer.pop()
        lexer.emit(T_ACC_TITLE_VALUE, p, lexer.line_break(p))
        true
      }
      S_ACC_DESCR => {
        lexer.pop()
        lexer.emit(T_ACC_DESCR_VALUE, p, lexer.line_break(p))
        true
      }
      _ => {
        if c == '}' {
          lexer.pop()
          lexer.p = p + 1
        } else {
          let e = @util.index_of(src, "}", from=p)
          lexer.emit(
            T_ACC_DESCR_MULTILINE_VALUE,
            p,
            if e == -1 {
              n
            } else {
              e
            },
          )
        }
        true
      }
    }
    if !ok {
      lexer.types.push(T_ERROR)
      lexer.texts.push("")
      lexer.starts.push(lexer.p)
      return { types: lexer.types, texts: lexer.texts, starts: lexer.starts, }
    }
  }
  // At the end of input Jison still tries the rules that can match nothing, once.
  let last = match lexer.state {
    S_INITIAL => T_EOF
    S_STRING => T_QSTRING
    S_ACC_TITLE => T_ACC_TITLE_VALUE
    S_ACC_DESCR => T_ACC_DESCR_VALUE
    S_ACC_DESCR_MULTILINE => T_ACC_DESCR_MULTILINE_VALUE
    _ => -1
  }
  if last != -1 {
    lexer.emit(last, n, n)
  }
  lexer.emit(T_END, n, n)
  { types: lexer.types, texts: lexer.texts, starts: lexer.starts, }
}
