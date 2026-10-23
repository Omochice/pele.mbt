///|
/// The tokens of a source, with the text and start offset of each.
pub(all) struct Tokens {
  types : Array[Tok]
  texts : Array[String]
  starts : Array[Int32]
  /// Set when lexing stopped on the grammar's own error rather than on unrecognized text.
  error : String?
}

///|
const INITIAL : Int32 = 0

///|
const STRUCT : Int32 = 1

///|
const STATE : Int32 = 2

///|
const STATE_STRING : Int32 = 3

///|
const STATE_ID : Int32 = 4

///|
const SCALE : Int32 = 5

///|
const ACC_TITLE : Int32 = 6

///|
const ACC_DESCR : Int32 = 7

///|
const ACC_DESCR_MULTILINE : Int32 = 8

///|
const CLASSDEF : Int32 = 9

///|
const CLASSDEFID : Int32 = 10

///|
const CLASS : Int32 = 11

///|
const CLASS_STYLE : Int32 = 12

///|
const STYLE : Int32 = 13

///|
const STYLEDEF_STYLES : Int32 = 14

///|
const NOTE : Int32 = 15

///|
const NOTE_ID : Int32 = 16

///|
const NOTE_TEXT : Int32 = 17

///|
const FLOATING_NOTE : Int32 = 18

///|
const FLOATING_NOTE_ID : Int32 = 19

///|
/// Finds the next match of a pattern at or after a position, remembering the answer so that asking at each token costs one scan of the text in total.
priv struct Finder {
  /// Whether the pattern matches at a position.
  at : (Int32) -> Bool
  n : Int32
  mut from : Int32
  mut next : Int32
}

///|
fn Finder::new(n : Int32, at : (Int32) -> Bool) -> Finder {
  { at, n, from: 0, next: -2, }
}

///|
fn Finder::find(self : Finder, q : Int32) -> Int32 {
  if self.next == -2 || q < self.from || (self.next != -1 && q > self.next) {
    let mut found = -1
    for i in q..<self.n {
      if (self.at)(i) {
        found = i
        break
      }
    }
    self.next = found
    self.from = q
  }
  self.next
}

///|
/// Case-insensitive match of a lowercase ASCII word, as the grammar's /i flag gives.
fn word(src : String, w : String, q : Int32) -> Bool {
  for i in 0..<w.length() {
    let a = w.unsafe_get(i).to_int()
    let c = @util.code_at(src, q + i)
    if c != a && !(a >= 97 && a <= 122 && c == a - 32) {
      return false
    }
  }
  true
}

///|
/// `<<fork>>`, `<<join>>`, `<<choice>>` or their `[[ ]]` spellings, in any case, starting at `d`.
fn stereotype_at(src : String, d : Int32) -> Bool {
  let open = @util.code_at(src, d)
  let (opener, closer) = if open == 60 {
    ("<<", ">>")
  } else if open == 91 {
    ("[[", "]]")
  } else {
    return false
  }
  if !word(src, opener, d) {
    return false
  }
  for name in ["fork", "join", "choice"] {
    if word(src, name, d + 2) && word(src, closer, d + 2 + name.length()) {
      return true
    }
  }
  false
}

///|
priv struct Lexer {
  src : String
  n : Int32
  types : Array[Tok]
  texts : Array[String]
  starts : Array[Int32]
  stack : Array[Int32]
  mut state : Int32
  mut p : Int32
  mut error : String?
  directions : Finder
  stereotypes : Finder
  line_ends : Finder
  percents : Finder
  braces : Finder
  // The last `direction <dir>` of each kind on the line being lexed, and where its keyword ends.
  mut dir_from : Int32
  mut dir_to : Int32
  dir_at : FixedArray[Int32]
  dir_end : FixedArray[Int32]
  // The same for <<fork>>, <<join>>, <<choice>> and their [[ ]] spellings.
  mut stereo_from : Int32
  mut stereo_to : Int32
  stereo_at : FixedArray[Int32]
}

///|
fn Lexer::code(self : Lexer, i : Int32) -> Int32 {
  @util.code_at(self.src, i)
}

///|
fn Lexer::emit(self : Lexer, kind : Tok, s : Int32, e : Int32) -> Unit {
  self.types.push(kind)
  self.texts.push(@util.slice(self.src, s, end=e))
  self.starts.push(s)
  self.p = e
}

///|
fn Lexer::emit_text(
  self : Lexer,
  kind : Tok,
  text : String,
  s : Int32,
  e : Int32,
) -> Unit {
  self.types.push(kind)
  self.texts.push(text)
  self.starts.push(s)
  self.p = e
}

///|
fn Lexer::push(self : Lexer, s : Int32) -> Unit {
  self.stack.push(self.state)
  self.state = s
}

///|
fn Lexer::pop(self : Lexer) -> Unit {
  if self.stack.pop() is Some(s) {
    self.state = s
  }
}

///|
fn Lexer::word(self : Lexer, w : String, q : Int32) -> Bool {
  word(self.src, w, q)
}

///|
fn Lexer::ws_end(self : Lexer, q : Int32) -> Int32 {
  let mut j = q
  while j < self.n && @util.is_space(self.code(j)) {
    j += 1
  }
  j
}

///|
fn Lexer::word_end(self : Lexer, q : Int32) -> Int32 {
  let mut j = q
  while j < self.n && @util.is_word(self.code(j)) {
    j += 1
  }
  j
}

///|
/// Where the line holding `q` ends, at a line feed only.
fn Lexer::eol(self : Lexer, q : Int32) -> Int32 {
  let k = @util.index_of(self.src, "\n", from=q)
  if k == -1 {
    self.n
  } else {
    k
  }
}

///|
/// Where the line holding `q` ends, at any of the characters JavaScript's `.` does not match.
fn Lexer::line_end(self : Lexer, q : Int32) -> Int32 {
  let k = self.line_ends.find(q)
  if k == -1 {
    self.n
  } else {
    k
  }
}

///|
/// Rules `.*direction\s+TB[^\n]*` and its three siblings: the first kind, in grammar order, found between q and the end of its line.
fn Lexer::direction(self : Lexer, q : Int32) -> Int32 {
  if q < self.dir_from || q > self.dir_to {
    let first = self.directions.find(q)
    let end = if first == -1 { self.n } else { self.line_end(q) }
    self.dir_from = q
    self.dir_to = end
    self.dir_at.fill(-1)
    let mut d = first
    while d != -1 && d < end {
      let w = self.ws_end(d + 9)
      if w != d + 9 {
        let kind = if self.word("tb", w) {
          0
        } else if self.word("bt", w) {
          1
        } else if self.word("rl", w) {
          2
        } else if self.word("lr", w) {
          3
        } else {
          -1
        }
        if kind != -1 {
          self.dir_at[kind] = d
          self.dir_end[kind] = w + 2
        }
      }
      d = self.directions.find(d + 1)
    }
  }
  for kind in 0..<4 {
    if self.dir_at[kind] >= q {
      return kind
    }
  }
  -1
}

///|
fn Lexer::stereotype(self : Lexer, q : Int32) -> Int32 {
  if q < self.stereo_from || q > self.stereo_to {
    let first = self.stereotypes.find(q)
    let end = if first == -1 { self.n } else { self.line_end(q) }
    self.stereo_from = q
    self.stereo_to = end
    self.stereo_at.fill(-1)
    let mut d = first
    while d != -1 && d < end {
      let letter = self.code(d + 2) | 32
      let shape = if self.code(d) == 60 { 0 } else { 3 }
      let name = if letter == 102 { 0 } else if letter == 106 { 1 } else { 2 }
      self.stereo_at[shape + name] = d
      d = self.stereotypes.find(d + 1)
    }
  }
  for kind in 0..<6 {
    if self.stereo_at[kind] >= q {
      return kind
    }
  }
  -1
}

///|
/// The grammar's processId(): an id ends at an inline `%%`, and a text that starts with one is dropped.
fn Lexer::emit_id(self : Lexer, s : Int32, e : Int32) -> Bool {
  let at = self.percents.find(s)
  if at == -1 || at + 2 > e {
    self.emit(Id, s, e)
    return true
  }
  if at == s {
    self.p = e
    return false
  }
  self.emit(Id, s, at)
  true
}

///|
fn Lexer::finish(self : Lexer, kind : Tok) -> Tokens {
  self.types.push(kind)
  self.texts.push("")
  self.starts.push(self.p)
  {
    types: self.types,
    texts: self.texts,
    starts: self.starts,
    error: self.error,
  }
}

///|
/// Splits a state diagram into tokens as Mermaid's Jison lexer does.
pub fn tokenize(src : String) -> Tokens {
  let n = src.length()
  let lx : Lexer = {
    src,
    n,
    types: [],
    texts: [],
    starts: [],
    stack: [],
    state: INITIAL,
    p: 0,
    error: None,
    directions: Finder::new(n, d => word(src, "direction", d)),
    stereotypes: Finder::new(n, d => stereotype_at(src, d)),
    line_ends: Finder::new(n, d => {
      let c = @util.code_at(src, d)
      c == 10 || c == 13 || c == 0x2028 || c == 0x2029
    }),
    percents: Finder::new(n, d => {
      @util.code_at(src, d) == 37 && @util.code_at(src, d + 1) == 37
    }),
    braces: Finder::new(n, d => @util.code_at(src, d) == 123),
    dir_from: -1,
    dir_to: -1,
    dir_at: FixedArray::make(4, -1),
    dir_end: FixedArray::make(4, 0),
    stereo_from: -1,
    stereo_to: -1,
    stereo_at: FixedArray::make(6, -1),
  }
  while true {
    if lx.p >= n {
      // Jison tries the current state's rules once more on the empty remainder.
      match lx.state {
        INITIAL => lx.emit(Nl, n, n)
        ACC_TITLE => lx.emit(AccTitleValue, n, n)
        ACC_DESCR => lx.emit(AccDescrValue, n, n)
        ACC_DESCR_MULTILINE => lx.emit(AccDescrMultilineValue, n, n)
        CLASSDEFID => lx.emit(ClassdefStyleopts, n, n)
        CLASS_STYLE => lx.emit(Styleclass, n, n)
        STYLEDEF_STYLES => lx.emit(StyledefStyleopts, n, n)
        STATE_STRING => lx.emit(StateDescr, n, n)
        FLOATING_NOTE => lx.emit(NoteText, n, n)
        STATE_ID | FLOATING_NOTE_ID => lx.emit(Id, n, n)
        _ => ()
      }
      return lx.finish(End)
    }
    let p = lx.p
    let c = lx.code(p)
    match lx.state {
      INITIAL | STRUCT =>
        match lex_document(lx, p, c) {
          Some(done) => return done
          None => ()
        }
      STATE => {
        if c != 10 && @util.is_space(c) {
          let mut j = p + 1
          while j < n && lx.code(j) != 10 && @util.is_space(lx.code(j)) {
            j += 1
          }
          lx.p = j
          continue
        }
        if c == 35 || (c == 37 && lx.code(p + 1) == 37 && lx.code(p + 2) != 123) {
          lx.p = lx.eol(p)
          continue
        }
        let kind = lx.stereotype(p)
        if kind != -1 {
          let at = lx.stereo_at[kind]
          let choice = kind == 2 || kind == 5
          let token : Tok = if choice {
            Choice
          } else if kind % 3 == 0 {
            Fork
          } else {
            Join
          }
          lx.emit_text(
            token,
            @util.trim(@util.slice(src, p, end=at)),
            p,
            at + (if choice { 10 } else { 8 }),
          )
          lx.pop()
          continue
        }
        if c == 34 {
          lx.p = p + 1
          lx.push(STATE_STRING)
          continue
        }
        let q = if c == 10 { lx.ws_end(p) } else { p }
        if lx.word("as", q) {
          let e = lx.ws_end(q + 2)
          if e > q + 2 {
            lx.emit(As, p, e)
            lx.push(STATE_ID)
            continue
          }
        }
        if c == 10 {
          lx.p = p + 1
          lx.pop()
          continue
        }
        if c == 123 {
          lx.emit(StructStart, p, p + 1)
          lx.pop()
          lx.push(STRUCT)
          continue
        }
        if @util.is_word(c) {
          let first = lx.word_end(p)
          let second = lx.ws_end(first)
          if second > first && @util.is_word(lx.code(second)) {
            let brace = lx.braces.find(second + 1)
            if brace != -1 && brace < lx.line_end(second) {
              let found = @util.trim(@util.slice(src, p, end=brace + 1))
              lx.error = Some(
                "Error: State name must be a single word. Found: \"\{found}\"",
              )
              return lx.finish(Error)
            }
          }
        }
        let mut j = p + 1
        while j < n {
          let d = lx.code(j)
          if d == 123 || @util.is_space(d) {
            break
          }
          j += 1
        }
        lx.emit(CompositState, p, j)
      }
      STATE_STRING => {
        if c == 34 {
          lx.p = p + 1
          lx.pop()
          continue
        }
        let close = @util.index_of(src, "\"", from=p)
        lx.emit(StateDescr, p, if close == -1 { n } else { close })
      }
      STATE_ID => {
        let mut j = p
        while j < n {
          let d = lx.code(j)
          if d == 10 || d == 123 {
            break
          }
          j += 1
        }
        if lx.emit_id(p, j) {
          lx.pop()
        }
      }
      SCALE => {
        if c >= 48 && c <= 57 {
          let mut j = p + 1
          while j < n && lx.code(j) >= 48 && lx.code(j) <= 57 {
            j += 1
          }
          lx.emit(Width, p, j)
          continue
        }
        let q = lx.ws_end(p)
        if q > p && lx.word("width", q) && !@util.is_word(lx.code(q + 5)) {
          lx.p = q + 5
          lx.pop()
          continue
        }
        return lx.finish(Error)
      }
      ACC_TITLE => {
        lx.emit(AccTitleValue, p, lx.eol(p))
        lx.pop()
      }
      ACC_DESCR => {
        lx.emit(AccDescrValue, p, lx.eol(p))
        lx.pop()
      }
      ACC_DESCR_MULTILINE => {
        if c == 125 {
          lx.p = p + 1
          lx.pop()
          continue
        }
        let close = @util.index_of(src, "}", from=p)
        lx.emit(AccDescrMultilineValue, p, if close == -1 { n } else { close })
      }
      CLASSDEF => {
        let is_default = lx.word("default", p) && lx.ws_end(p + 7) > p + 7
        let j = if is_default { p + 7 } else { lx.word_end(p) }
        let e = lx.ws_end(j)
        if j == p || e == j {
          return lx.finish(Error)
        }
        lx.emit(if is_default { DefaultClassdefId } else { ClassdefId }, p, e)
        lx.pop()
        lx.push(CLASSDEFID)
      }
      CLASSDEFID => {
        lx.emit(ClassdefStyleopts, p, lx.eol(p))
        lx.pop()
      }
      CLASS => {
        let mut j = lx.word_end(p)
        if j == p {
          return lx.finish(Error)
        }
        while lx.code(j) == 44 {
          let k = lx.ws_end(j + 1)
          let e = lx.word_end(k)
          if e == k {
            break
          }
          j = e
        }
        lx.emit(ClassentityIds, p, j)
        lx.pop()
        lx.push(CLASS_STYLE)
      }
      CLASS_STYLE => {
        lx.emit(Styleclass, p, lx.eol(p))
        lx.pop()
      }
      STYLE => {
        let mut j = p
        while j < n && (@util.is_word(lx.code(j)) || lx.code(j) == 44) {
          j += 1
        }
        let e = lx.ws_end(j)
        if j == p || e == j {
          return lx.finish(Error)
        }
        lx.emit(StyleIds, p, e)
        lx.pop()
        lx.push(STYLEDEF_STYLES)
      }
      STYLEDEF_STYLES => {
        lx.emit(StyledefStyleopts, p, lx.eol(p))
        lx.pop()
      }
      NOTE => {
        if lx.word("left of", p) && !@util.is_word(lx.code(p + 7)) {
          lx.emit(LeftOf, p, p + 7)
          lx.pop()
          lx.push(NOTE_ID)
          continue
        }
        if lx.word("right of", p) && !@util.is_word(lx.code(p + 8)) {
          lx.emit(RightOf, p, p + 8)
          lx.pop()
          lx.push(NOTE_ID)
          continue
        }
        if c == 34 {
          lx.p = p + 1
          lx.pop()
          lx.push(FLOATING_NOTE)
          continue
        }
        return lx.finish(Error)
      }
      NOTE_ID => {
        let q = lx.ws_end(p)
        let mut j = q
        while j < n {
          let d = lx.code(j)
          if d == 58 || d == 45 || @util.is_space(d) {
            break
          }
          j += 1
        }
        if j == q {
          return lx.finish(Error)
        }
        if lx.emit_id(p, j) {
          lx.pop()
          lx.push(NOTE_TEXT)
        }
      }
      NOTE_TEXT => {
        let q = lx.ws_end(p)
        if lx.code(q) == 58 {
          let mut j = q + 1
          while j < n {
            let d = lx.code(j)
            if d == 58 || d == 10 || d == 59 {
              break
            }
            j += 1
          }
          if j > q + 1 {
            // Mermaid drops two characters here, expecting " :"; with no space before the colon the first character of the note goes too.
            lx.emit_text(
              NoteText,
              @util.trim(@util.slice(src, p + 2, end=j)),
              p,
              j,
            )
            lx.pop()
            continue
          }
        }
        let mut k = @util.index_of(src, "\n", from=p)
        let mut e = -1
        while k != -1 {
          e = lx.ws_end(k)
          if lx.word("end note", e) && !@util.is_word(lx.code(e + 8)) {
            break
          }
          k = @util.index_of(src, "\n", from=e)
        }
        if k == -1 {
          return lx.finish(Error)
        }
        lx.emit_text(NoteText, @util.trim(@util.slice(src, p, end=e)), p, e + 8)
        lx.pop()
      }
      FLOATING_NOTE => {
        let q = lx.ws_end(p)
        if lx.word("as", q) {
          lx.emit(As, p, lx.ws_end(q + 2))
          lx.pop()
          lx.push(FLOATING_NOTE_ID)
          continue
        }
        if c == 34 {
          lx.p = p + 1
          continue
        }
        let close = @util.index_of(src, "\"", from=p)
        lx.emit(NoteText, p, if close == -1 { n } else { close })
      }
      _ =>
        // FLOATING_NOTE_ID
        if lx.emit_id(p, lx.eol(p)) {
          lx.pop()
        }
    }
  }
  panic()
}

///|
/// One step in the root document or inside a composite, which share most of their rules.
/// Returns the tokens when lexing stops here.
fn lex_document(lx : Lexer, p : Int32, c : Int32) -> Tokens? {
  let src = lx.src
  let n = lx.n
  let root = lx.state == INITIAL
  let lc = c | 32
  if root {
    if lc == 99 && lx.word("click", p) && !@util.is_word(lx.code(p + 5)) {
      lx.emit(Click, p, p + 5)
      return None
    }
    if lc == 104 && lx.word("href", p) && !@util.is_word(lx.code(p + 4)) {
      lx.emit(Href, p, p + 4)
      return None
    }
    if c == 34 {
      let close = @util.index_of(src, "\"", from=p + 1)
      if close != -1 {
        lx.emit(Str, p, close + 1)
        return None
      }
    }
    if lc == 100 && lx.word("default", p) && !@util.is_word(lx.code(p + 7)) {
      lx.emit(Default, p, p + 7)
      return None
    }
    let kind = lx.direction(p)
    if kind != -1 {
      lx.emit(direction_token(kind), p, lx.eol(lx.dir_end[kind]))
      return None
    }
    if c == 10 {
      let mut j = p + 1
      while lx.code(j) == 10 {
        j += 1
      }
      lx.emit(Nl, p, j)
      return None
    }
    if @util.is_space(c) {
      lx.p = lx.ws_end(p)
      return None
    }
  } else if c != 10 && @util.is_space(c) {
    let mut j = p + 1
    while j < n && lx.code(j) != 10 && @util.is_space(lx.code(j)) {
      j += 1
    }
    lx.p = j
    return None
  }
  if c == 35 || (c == 37 && lx.code(p + 1) == 37 && lx.code(p + 2) != 123) {
    lx.p = lx.eol(p)
    return None
  }
  if lc == 115 {
    if root && lx.word("scale", p) {
      let e = lx.ws_end(p + 5)
      if e > p + 5 {
        lx.emit(Scale, p, e)
        lx.push(SCALE)
        return None
      }
    }
    if lx.word("style", p) {
      let e = lx.ws_end(p + 5)
      if e > p + 5 {
        lx.emit(Style, p, e)
        lx.push(STYLE)
        return None
      }
    }
    if lx.word("state", p) {
      let e = lx.ws_end(p + 5)
      if e > p + 5 {
        lx.p = e
        lx.push(STATE)
        return None
      }
      if root && lx.word("diagram", p + 5) {
        let from = if lx.word("-v2", p + 12) { p + 15 } else { p + 12 }
        let e = lx.ws_end(from)
        if e > from {
          lx.emit(Sd, p, e)
          return None
        }
      }
    }
  } else if lc == 99 {
    if lx.word("class", p) {
      let def = lx.word("def", p + 5)
      let from = if def { p + 8 } else { p + 5 }
      let e = lx.ws_end(from)
      if e > from {
        lx.emit(if def { ClassDef } else { Class }, p, e)
        lx.push(if def { CLASSDEF } else { CLASS })
        return None
      }
    }
  } else if lc == 97 && root {
    if lx.word("acctitle", p) || lx.word("accdescr", p) {
      let title = (lx.code(p + 3) | 32) == 116
      let q = lx.ws_end(p + 8)
      let d = lx.code(q)
      if d == 58 {
        lx.emit(if title { AccTitle } else { AccDescr }, p, lx.ws_end(q + 1))
        lx.push(if title { ACC_TITLE } else { ACC_DESCR })
        return None
      }
      if d == 123 && !title {
        lx.p = lx.ws_end(q + 1)
        lx.push(ACC_DESCR_MULTILINE)
        return None
      }
    }
  }
  if root {
    if c == 123 {
      lx.emit(StructStart, p, p + 1)
      lx.push(STRUCT)
      return None
    }
  } else {
    let kind = lx.direction(p)
    if kind != -1 {
      lx.emit(direction_token(kind), p, lx.eol(lx.dir_end[kind]))
      return None
    }
    if c == 125 {
      lx.emit(StructStop, p, p + 1)
      lx.pop()
      return None
    }
    if c == 10 {
      lx.p = p + 1
      return None
    }
  }
  if lc == 110 && lx.word("note", p) {
    let e = lx.ws_end(p + 4)
    if e > p + 4 {
      lx.emit(Note, p, e)
      lx.push(NOTE)
      return None
    }
  }
  if root &&
    lc == 104 &&
    lx.word("hide empty description", p) &&
    !@util.is_word(lx.code(p + 22)) {
    lx.emit(HideEmpty, p, p + 22)
    return None
  }
  if c == 91 && lx.code(p + 1) == 42 && lx.code(p + 2) == 93 {
    lx.emit(EdgeState, p, p + 3)
    return None
  }
  let mut j = p
  while j < n {
    let d = lx.code(j)
    if d == 58 || d == 45 || d == 123 || @util.is_space(d) {
      break
    }
    j += 1
  }
  if j > p {
    ignore(lx.emit_id(p, j))
    return None
  }
  if c == 58 {
    j = p + 1
    while j < n {
      let d = lx.code(j)
      if d == 10 || d == 59 {
        break
      }
      if d == 58 {
        let after = lx.code(j + 1)
        if j + 1 >= n || after == 58 || after == 10 || after == 59 {
          break
        }
        j += 1
      }
      j += 1
    }
    if j > p + 1 {
      lx.emit_text(Descr, @util.trim(@util.slice(src, p, end=j)), p, j)
      return None
    }
    if lx.code(p + 1) == 58 && lx.code(p + 2) == 58 {
      lx.emit(StyleSeparator, p, p + 3)
      return None
    }
  } else if c == 45 && lx.code(p + 1) == 45 {
    if lx.code(p + 2) == 62 {
      lx.emit(Arrow, p, p + 3)
      return None
    }
    if !root {
      lx.emit(Concurrent, p, p + 2)
      return None
    }
  }
  if !root {
    return Some(lx.finish(Error))
  }
  lx.emit(Invalid, p, p + 1)
  None
}

///|
/// The direction token for a kind: 0 TB, 1 BT, 2 RL, 3 LR.
fn direction_token(kind : Int32) -> Tok {
  match kind {
    0 => DirectionTb
    1 => DirectionBt
    2 => DirectionRl
    _ => DirectionLr
  }
}
