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
  Id
  Alias
  Line
  Config
  AccTitleState
  AccDescrState
  AccDescrMultiline
}

///|
const ACTOR_START : Int32 = 1

///|
const ACTOR_REST : Int32 = 2

///|
const ID : Int32 = 4

///|
const ID_WIDE : Int32 = 8

///|
const LINE : Int32 = 16

///|
const MENU : Int32 = 32

///|
fn in_set(set : String, c : Int32) -> Bool {
  for i in 0..<set.length() {
    if set.unsafe_get(i).to_int() == c {
      return true
    }
  }
  false
}

///|
/// Character classes of Mermaid's lexer rules, for ASCII.
let char_class : FixedArray[Int32] = {
  let table = FixedArray::make(128, 0)
  for c in 0..<128 {
    let ws = c == 32 || (c >= 9 && c <= 13)
    let mut bits = 0
    if !in_set("/\\+()<->:\n,;", c) {
      bits = bits | ACTOR_START
    }
    if !in_set("+<->:\n,;", c) {
      bits = bits | ACTOR_REST
    }
    if !in_set("<>:\n,;@", c) {
      bits = bits | ID_WIDE | (if ws { 0 } else { ID })
    }
    if !in_set("#\n;", c) {
      bits = bits | LINE
    }
    if !in_set("/\\+()<>:\n,;-", c) && !ws {
      bits = bits | MENU
    }
    table[c] = bits
  }
  table
}

///|
/// Splits a sequence diagram into tokens as Mermaid's Jison lexer does.
/// Text no rule matches ends the stream with an `Error` token.
pub fn tokenize(src : String) -> Tokens {
  let n = src.length()
  let types : Array[Tok] = []
  let texts : Array[String] = []
  let starts : Array[Int32] = []
  let stack : Array[State] = []
  let mut state : State = Initial
  let mut p = 0
  let mut next_nl = -1
  fn code(q : Int32) -> Int32 {
    @util.code_at(src, q)
  }

  fn emit(kind : Tok, s : Int32, e : Int32) -> Unit {
    types.push(kind)
    texts.push(@util.slice(src, s, end=e))
    starts.push(s)
    p = e
  }

  fn emit_text(kind : Tok, s : Int32, e : Int32, text : String) -> Unit {
    types.push(kind)
    texts.push(text)
    starts.push(s)
    p = e
  }

  fn push(next : State) -> Unit {
    stack.push(state)
    state = next
  }

  fn pop() -> Unit {
    if stack.pop() is Some(previous) {
      state = previous
    }
  }

  fn eol(q : Int32) -> Int32 {
    if next_nl < q {
      next_nl = @util.index_of(src, "\n", from=q)
      if next_nl == -1 {
        next_nl = n
      }
    }
    next_nl
  }

  // Past the end, where JavaScript reads NaN, every class but the two that exclude spaces holds.
  fn has(q : Int32, bit : Int32) -> Bool {
    let c = code(q)
    if c >= 0 && c < 128 {
      return (char_class[c] & bit) != 0
    }
    if bit == ID || bit == MENU {
      !@util.is_space(c)
    } else {
      true
    }
  }

  // Matches a lowercase literal without regard to the case of the source.
  fn ci(q : Int32, word : String) -> Bool {
    for k in 0..<word.length() {
      let w = word.unsafe_get(k).to_int()
      let c = code(q + k)
      if w >= 97 && w <= 122 {
        if (c | 32) != w {
          return false
        }
      } else if c != w {
        return false
      }
    }
    true
  }

  fn word(lit : String) -> Bool {
    ci(p, lit) && !@util.is_word(code(p + lit.length()))
  }

  fn skip_ws(from : Int32) -> Int32 {
    let mut q = from
    while q < n && @util.is_space(code(q)) {
      q += 1
    }
    q
  }

  fn skip_same_line() -> Bool {
    let mut q = p
    while q < n {
      let c = code(q)
      if c == 10 || !@util.is_space(c) {
        break
      }
      q += 1
    }
    if q == p {
      return false
    }
    p = q
    true
  }

  fn line_run(from : Int32) -> Int32 {
    let mut q = from
    while q < n && has(q, LINE) {
      q += 1
    }
    q
  }

  fn begin(kind : Tok, len : Int32, next : State) -> Unit {
    emit(kind, p, p + len)
    push(next)
  }

  fn keyword(lit : String, kind : Tok, next : State?) -> Bool {
    if !word(lit) {
      return false
    }
    emit(kind, p, p + lit.length())
    if next is Some(next) {
      push(next)
    }
    true
  }

  // The actor menu keywords count only when spaces and the start of a name follow.
  fn menu(lit : String, kind : Tok) -> Bool {
    if !ci(p, lit) {
      return false
    }
    let mut q = p + lit.length()
    let mut c = code(q)
    if c != 32 && c != 9 {
      return false
    }
    while c == 32 || c == 9 {
      q += 1
      c = code(q)
    }
    if q >= n || !has(q, MENU) {
      return false
    }
    emit(kind, p, p + lit.length())
    true
  }

  fn arrow_ahead(q : Int32) -> Bool {
    let c = code(q)
    let d = code(q + 1)
    if c == 45 {
      if d == 120 || d == 88 || d == 41 || d == 92 || d == 47 || d == 45 {
        return true
      }
      let e = code(q + 2)
      return d == 124 && (e == 92 || e == 47)
    }
    if c == 47 || c == 92 {
      return (d == 124 || d == c) && code(q + 2) == 45
    }
    c == 40 && d == 41
  }

  fn actor() -> Unit {
    let mut q = p + 1
    while q < n && has(q, ACTOR_START) {
      q += 1
    }
    while q < n && !arrow_ahead(q) {
      let mut r = q
      while code(r) == 45 {
        r += 1
      }
      if r >= n || !has(r, ACTOR_REST) {
        break
      }
      r += 1
      while r < n && has(r, ACTOR_REST) {
        r += 1
      }
      q = r
    }
    emit_text(Actor, p, q, @util.trim(@util.slice(src, p, end=q)))
  }

  fn number() -> Bool {
    let mut q = p
    while @util.is_digit(code(q)) {
      q += 1
    }
    let whole = q > p
    if code(q) == 46 && @util.is_digit(code(q + 1)) {
      let r = if @util.is_digit(code(q + 2)) { q + 3 } else { q + 2 }
      let after = code(r)
      if after == 32 || after == 10 {
        emit(Num, p, r)
        return true
      }
    }
    let after = code(q)
    if whole && (after == 32 || after == 10) {
      emit(Num, p, q)
      return true
    }
    false
  }

  fn dash() -> Unit {
    let d = code(p + 1)
    let e = code(p + 2)
    if d == 62 {
      if e == 62 {
        emit(SolidArrow, p, p + 3)
      } else {
        emit(SolidOpenArrow, p, p + 2)
      }
    } else if d == 120 || d == 88 {
      emit(SolidCross, p, p + 2)
    } else if d == 41 {
      emit(SolidPoint, p, p + 2)
    } else if d == 124 && e == 92 {
      emit(SolidArrowTop, p, p + 3)
    } else if d == 124 && e == 47 {
      emit(SolidArrowBottom, p, p + 3)
    } else if d == 92 && e == 92 {
      emit(StickArrowTop, p, p + 3)
    } else if d == 47 && e == 47 {
      emit(StickArrowBottom, p, p + 3)
    } else if d == 45 {
      let f = code(p + 3)
      if e == 62 {
        if f == 62 {
          emit(DottedArrow, p, p + 4)
        } else {
          emit(DottedOpenArrow, p, p + 3)
        }
      } else if e == 120 || e == 88 {
        emit(DottedCross, p, p + 3)
      } else if e == 41 {
        emit(DottedPoint, p, p + 3)
      } else if e == 124 && f == 92 {
        emit(SolidArrowTopDotted, p, p + 4)
      } else if e == 124 && f == 47 {
        emit(SolidArrowBottomDotted, p, p + 4)
      } else if e == 92 && f == 92 {
        emit(StickArrowTopDotted, p, p + 4)
      } else if e == 47 && f == 47 {
        emit(StickArrowBottomDotted, p, p + 4)
      } else {
        emit(Minus, p, p + 1)
      }
    } else {
      emit(Minus, p, p + 1)
    }
  }

  fn reverse(c : Int32) -> Bool {
    let d = code(p + 1)
    if (d != 124 && d != c) || code(p + 2) != 45 {
      return false
    }
    let dotted = code(p + 3) == 45
    let top = c == 47
    let kind : Tok = match (d == 124, dotted, top) {
      (true, true, true) => SolidArrowTopReverseDotted
      (true, true, false) => SolidArrowBottomReverseDotted
      (true, false, true) => SolidArrowTopReverse
      (true, false, false) => SolidArrowBottomReverse
      (false, true, true) => StickArrowTopReverseDotted
      (false, true, false) => StickArrowBottomReverseDotted
      (false, false, true) => StickArrowTopReverse
      (false, false, false) => StickArrowBottomReverse
    }
    emit(kind, p, p + (if dotted { 4 } else { 3 }))
    true
  }

  fn title() -> Bool {
    if !ci(p, "title") {
      return false
    }
    let mut q = p + 5
    let legacy = code(q) == 58
    if legacy {
      q += 1
    }
    if !@util.is_space(code(q)) || q + 1 >= n || !has(q + 1, LINE) {
      return false
    }
    emit(if legacy { LegacyTitle } else { Title }, p, line_run(q + 1))
    true
  }

  fn acc() -> Bool {
    let descr = ci(p, "accdescr")
    if !descr && !ci(p, "acctitle") {
      return false
    }
    let q = skip_ws(p + 8)
    let c = code(q)
    if c == 58 {
      emit(if descr { AccDescr } else { AccTitle }, p, skip_ws(q + 1))
      push(if descr { AccDescrState } else { AccTitleState })
      return true
    }
    if descr && c == 123 {
      p = skip_ws(q + 1)
      push(AccDescrMultiline)
      return true
    }
    false
  }

  fn keywords(c : Int32) -> Bool {
    match c | 32 {
      97 =>
        keyword("actor", ParticipantActor, Some(Id)) ||
        keyword("alt", Alt, Some(Line)) ||
        keyword("and", And, Some(Line)) ||
        keyword("activate", Activate, Some(Id)) ||
        acc() ||
        keyword("autonumber", Autonumber, None)
      98 =>
        keyword("box", Box, Some(Line)) || keyword("break", Break, Some(Line))
      99 =>
        keyword("create", Create, None) ||
        keyword("critical", Critical, Some(Line))
      100 =>
        keyword("destroy", Destroy, Some(Id)) ||
        menu("details", Details) ||
        keyword("deactivate", Deactivate, Some(Id))
      101 => keyword("else", Else, Some(Line)) || keyword("end", EndKw, None)
      108 =>
        keyword("loop", Loop, Some(Line)) ||
        keyword("left of", LeftOf, None) ||
        menu("links", Links) ||
        menu("link", Link)
      110 => keyword("note", Note, None)
      111 =>
        keyword("opt", Opt, Some(Line)) ||
        keyword("option", Option, Some(Line)) ||
        keyword("over", Over, None) ||
        keyword("off", Off, None)
      112 =>
        keyword("participant", Participant, Some(Id)) ||
        keyword("par", Par, Some(Line)) ||
        keyword("par_over", ParOver, Some(Line)) ||
        menu("properties", Properties)
      114 =>
        keyword("rect", Rect, Some(Line)) || keyword("right of", RightOf, None)
      115 => keyword("sequencediagram", Sd, None)
      116 => title()
      _ => false
    }
  }

  fn initial() -> Unit {
    let c = code(p)
    if c == 10 {
      let mut q = p + 1
      while code(q) == 10 {
        q += 1
      }
      emit(Newline, p, q)
      return
    }
    if @util.is_space(c) {
      p = skip_ws(p + 1)
      return
    }
    if c == 35 || (c == 37 && code(p + 1) != 123) {
      p = eol(p)
      return
    }
    if c != 125 && code(p + 1) == 37 && code(p + 2) == 37 {
      p = eol(p)
      return
    }
    if (@util.is_digit(c) || c == 46) && number() {
      return
    }
    if c < 128 && (c | 32) >= 97 && (c | 32) <= 122 && keywords(c) {
      return
    }
    if c == 44 {
      emit(Comma, p, p + 1)
    } else if c == 59 {
      emit(Newline, p, p + 1)
    } else if has(p, ACTOR_START) {
      actor()
    } else if c == 45 {
      dash()
    } else if c == 60 && @util.starts_with_at(src, "<<->>", p) {
      emit(BidirectionalSolidArrow, p, p + 5)
    } else if c == 60 && @util.starts_with_at(src, "<<-->>", p) {
      emit(BidirectionalDottedArrow, p, p + 6)
    } else if (c == 47 || c == 92) && reverse(c) {
      return
    } else if c == 58 {
      emit(Txt, p, line_run(p + 1))
    } else if c == 43 {
      emit(Plus, p, p + 1)
    } else if c == 40 && code(p + 1) == 41 {
      emit(Central, p, p + 2)
    } else {
      emit(Invalid, p, p + 1)
    }
  }

  // A participant name, up to an alias, a config object, or the end of the statement.
  fn id() -> Bool {
    if skip_same_line() {
      return true
    }
    let c = code(p)
    if c == 35 {
      p = eol(p)
      return true
    }
    if c == 64 && code(p + 1) == 123 {
      begin(ConfigStart, 2, Config)
      return true
    }
    let mut a = p
    while a < n && has(a, ID) {
      a += 1
    }
    if a > p {
      let w = skip_ws(a)
      if code(w) == 64 && code(w + 1) == 123 {
        emit(Actor, p, a)
        return true
      }
      if w > a && ci(w, "as") && @util.is_space(code(w + 2)) {
        emit(Actor, p, a)
        push(Alias)
        return true
      }
    }
    let mut b = a
    while b < n && has(b, ID_WIDE) {
      b += 1
    }
    if b > p {
      let end = code(b)
      // Before any other delimiter the name must be followed by a comment, so it ends at the last one.
      let mut cut = b
      if b < n && end != 10 && end != 59 {
        cut -= 1
        while cut > p && code(cut) != 35 {
          cut -= 1
        }
      }
      if cut > p {
        emit_text(Actor, p, cut, @util.trim(@util.slice(src, p, end=cut)))
        pop()
        return true
      }
    }
    if code(b) == 60 {
      emit(Invalid, p, eol(p))
      pop()
      return true
    }
    if c != 10 {
      let e = eol(p)
      emit_text(Invalid, p, e, @util.trim(@util.slice(src, p, end=e)))
      pop()
      return true
    }
    false
  }

  fn step() -> Bool {
    match state {
      Initial => {
        initial()
        true
      }
      Id => id()
      Alias => {
        if skip_same_line() {
          return true
        }
        if code(p) == 35 {
          p = eol(p)
          return true
        }
        pop()
        pop()
        if word("as") {
          begin(As, 2, Line)
        } else {
          emit(Newline, p, p)
        }
        true
      }
      Line => {
        if skip_same_line() {
          return true
        }
        if code(p) == 35 {
          p = eol(p)
          return true
        }
        emit(RestOfLine, p, line_run(p))
        pop()
        true
      }
      Config => {
        if code(p) != 125 {
          let mut q = @util.index_of(src, "}", from=p)
          if q == -1 {
            q = n
          }
          emit(ConfigContent, p, q)
        } else {
          let w = skip_ws(p + 1)
          let aliased = w > p + 1 && ci(w, "as") && @util.is_space(code(w + 2))
          emit(ConfigEnd, p, p + 1)
          pop()
          if aliased {
            push(Alias)
          } else {
            pop()
          }
        }
        true
      }
      AccTitleState => {
        emit(AccTitleValue, p, eol(p))
        pop()
        true
      }
      AccDescrState => {
        emit(AccDescrValue, p, eol(p))
        pop()
        true
      }
      AccDescrMultiline => {
        if code(p) == 125 {
          p += 1
          pop()
        } else {
          let mut q = @util.index_of(src, "}", from=p)
          if q == -1 {
            q = n
          }
          emit(AccDescrMultilineValue, p, q)
        }
        true
      }
    }
  }

  while p < n {
    if !step() {
      types.push(Error)
      texts.push("")
      starts.push(p)
      return { types, texts, starts, }
    }
  }

  // Mermaid's lexer tries its rules once more on the empty remainder before reporting the end.
  match state {
    Initial | Alias => emit(Newline, n, n)
    Line => emit(RestOfLine, n, n)
    AccTitleState => emit(AccTitleValue, n, n)
    AccDescrState => emit(AccDescrValue, n, n)
    AccDescrMultiline => emit(AccDescrMultilineValue, n, n)
    _ => ()
  }
  types.push(End)
  texts.push("")
  starts.push(n)
  { types, texts, starts, }
}
