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
  Quoted
  Backticked
  Generic
  CallbackNameState
  CallbackArgsState
  AccTitleState
  AccDescrState
  AccDescrMultiline
  Cls
  ClassBody
  NamespaceState
  NamespaceBody
}

///|
/// The token each state gives at the end of input, before the parser sees the end itself.
fn at_end(state : State) -> Tok {
  match state {
    Initial | Backticked | Cls | NamespaceState => Eof
    Quoted => Str
    Generic => GenericType
    CallbackNameState => CallbackName
    CallbackArgsState => CallbackArgs
    AccTitleState => AccTitleValue
    AccDescrState => AccDescrValue
    AccDescrMultiline => AccDescrMultilineValue
    ClassBody | NamespaceBody => EofInStruct
  }
}

///|
let direction_tokens : Array[(Tok, String)] = [
  (DirectionTb, "TB"),
  (DirectionBt, "BT"),
  (DirectionRl, "RL"),
  (DirectionLr, "LR"),
]

///|
/// The end of `/.*direction\s+<dir>[^\n]*/y` at `p`, where the line from `p` ends at `line_end`, or -1.
/// The greedy `.*` makes the last `direction` on the line that is followed by the direction win.
fn direction_end(
  src : String,
  p : Int32,
  line_end : Int32,
  dir : String,
) -> Int32 {
  for k = line_end - 9; k >= p; k = k - 1 {
    if !@util.starts_with_at(src, "direction", k) {
      continue
    }
    let mut q = k + 9
    if !@util.is_space(@util.code_at(src, q)) {
      continue
    }
    while @util.is_space(@util.code_at(src, q)) {
      q += 1
    }
    if !@util.starts_with_at(src, dir, q) {
      continue
    }
    q += 2
    while q < src.length() && src.unsafe_get(q).to_int() != 10 {
      q += 1
    }
    return q
  }
  -1
}

///|
/// Splits a class diagram into tokens as Mermaid's Jison lexer does.
/// A character no rule allows ends the stream with an `Error` token.
pub fn tokenize(src : String) -> Tokens {
  let n = src.length()
  let types : Array[Tok] = []
  let texts : Array[String] = []
  let starts : Array[Int32] = []
  let stack : Array[State] = []
  let mut state = Initial
  let mut p = 0
  let mut dir_next = @util.index_of(src, "direction")
  let mut line_end = -1
  let mut dir_failed = 0
  let code = (q : Int32) => @util.code_at(src, q)
  let emit = (kind : Tok, s : Int32, e : Int32) => {
    types.push(kind)
    texts.push(@util.slice(src, s, end=e))
    starts.push(s)
    p = e
    true
  }
  let push = (next : State) => {
    stack.push(state)
    state = next
  }
  let pop = () => if stack.pop() is Some(previous) { state = previous }
  let kw = (word : String) => {
    @util.starts_with_at(src, word, p) &&
    !@util.is_word(code(p + word.length()))
  }
  let skip_ws = (from : Int32) => {
    let mut q = from
    while q < n && @util.is_space(code(q)) {
      q += 1
    }
    q
  }
  let until = (ch : String) => {
    let e = @util.index_of(src, ch, from=p)
    if e == -1 {
      n
    } else {
      e
    }
  }

  // A run of whitespace is a NEWLINE up to its last line feed; the rest is skipped.
  let space = (leaves : Bool) => {
    let mut q = p
    let mut k = -1
    while q < n && @util.is_space(code(q)) {
      if code(q) == 10 {
        k = q
      }
      q += 1
    }
    if k < 0 {
      p = q
      return
    }
    if leaves {
      pop()
    }
    ignore(emit(Newline, p, k + 1))
  }

  // The keywords that every state recognizes, even inside generics and backtick names.
  let keyword = (c : Int32) => {
    match c {
      99 =>
        if kw("cssClass") {
          return emit(CssClass, p, p + 8)
        } else if kw("callback") {
          return emit(Callback, p, p + 8)
        } else if kw("click") {
          return emit(Click, p, p + 5)
        }
      108 => if kw("link") { return emit(Link, p, p + 4) }
      110 =>
        if kw("note for") {
          return emit(NoteFor, p, p + 8)
        } else if kw("note") {
          return emit(Note, p, p + 4)
        }
      60 => if code(p + 1) == 60 { return emit(AnnotationStart, p, p + 2) }
      62 => if code(p + 1) == 62 { return emit(AnnotationEnd, p, p + 2) }
      104 => if kw("href") { return emit(Href, p, p + 4) }
      _ => ()
    }
    false
  }
  let common = (c : Int32) => {
    if keyword(c) {
      return true
    }
    let d = code(p + 1)
    match c {
      34 => {
        push(Quoted)
        p += 1
        return true
      }
      126 => {
        push(Generic)
        p += 1
        return true
      }
      96 => {
        push(Backticked)
        p += 1
        return true
      }
      95 =>
        if kw("_self") {
          return emit(LinkTarget, p, p + 5)
        } else if kw("_blank") {
          return emit(LinkTarget, p, p + 6)
        } else if kw("_parent") {
          return emit(LinkTarget, p, p + 7)
        } else if kw("_top") {
          return emit(LinkTarget, p, p + 4)
        }
      60 =>
        return if d == 124 {
          emit(Extension, p, p + 2)
        } else {
          emit(Dependency, p, p + 1)
        }
      124 => return d == 62 && emit(Extension, p, p + 2)
      62 => return emit(Dependency, p, p + 1)
      42 => return emit(Composition, p, p + 1)
      111 => if !@util.is_word(d) { return emit(Aggregation, p, p + 1) }
      40 => return d == 41 && emit(Lollipop, p, p + 2)
      45 =>
        return if d == 45 {
          emit(Line, p, p + 2)
        } else {
          emit(Minus, p, p + 1)
        }
      46 =>
        return if d == 46 {
          emit(DottedLine, p, p + 2)
        } else {
          emit(Dot, p, p + 1)
        }
      58 => {
        let mut q = p + 1
        while q < n {
          let ch = code(q)
          if ch == 58 || ch == 10 || ch == 59 {
            break
          }
          q += 1
        }
        if q > p + 1 {
          return emit(Label, p, q)
        }
        return d == 58 && code(p + 2) == 58 && emit(StyleSeparator, p, p + 3)
      }
      43 => return emit(Plus, p, p + 1)
      37 => return emit(Pct, p, p + 1)
      61 => return emit(Equals, p, p + 1)
      91 => return emit(Sqs, p, p + 1)
      93 => return emit(Sqe, p, p + 1)
      33 | 35 | 36 | 38 | 39 | 44 | 63 | 92 | 47 =>
        return emit(Punctuation, p, p + 1)
      _ => ()
    }
    if @util.is_word(c) {
      let mut q = p + 1
      while @util.is_word(code(q)) {
        q += 1
      }
      return emit(Alpha, p, q)
    }
    @util.is_unicode_letter(c) && emit(UnicodeText, p, p + 1)
  }
  let direction = () => {
    if dir_next == -1 || p < dir_failed {
      return false
    }
    if dir_next < p {
      dir_next = @util.index_of(src, "direction", from=p)
    }
    if dir_next == -1 {
      return false
    }
    if line_end < p {
      let mut e = p
      while e < n && !@util.is_line_end(code(e)) {
        e += 1
      }
      line_end = e
    }
    if dir_next >= line_end {
      return false
    }
    for entry in direction_tokens {
      let (kind, dir) = entry
      let e = direction_end(src, p, line_end, dir)
      if e >= 0 {
        return emit(kind, p, e)
      }
    }
    // No direction statement starts anywhere in the rest of this line either.
    dir_failed = line_end
    false
  }
  let initial = (c : Int32) => {
    if direction() {
      return true
    }
    if @util.is_space(c) {
      space(false)
      return true
    }
    match c {
      37 =>
        if code(p + 1) == 37 {
          let mut e = until("\n")
          while e < n && (code(e) == 10 || code(e) == 13) {
            e += 1
          }
          p = e
          return true
        }
      97 => {
        let title = @util.starts_with_at(src, "accTitle", p)
        if title || @util.starts_with_at(src, "accDescr", p) {
          let q = skip_ws(p + 8)
          let d = code(q)
          if d == 58 {
            ignore(
              emit(if title { AccTitle } else { AccDescr }, p, skip_ws(q + 1)),
            )
            push(if title { AccTitleState } else { AccDescrState })
            return true
          }
          if d == 123 && !title {
            p = skip_ws(q + 1)
            push(AccDescrMultiline)
            return true
          }
        }
      }
      99 =>
        if kw("classDiagram-v2") {
          return emit(ClassDiagram, p, p + 15)
        } else if kw("classDiagram") {
          return emit(ClassDiagram, p, p + 12)
        } else if @util.starts_with_at(src, "call", p) &&
          @util.is_space(code(p + 4)) {
          p = skip_ws(p + 4)
          push(CallbackNameState)
          return true
        } else if kw("classDef") {
          return emit(ClassDef, p, p + 8)
        } else if kw("class") {
          push(Cls)
          return emit(Class, p, p + 5)
        }
      91 =>
        if @util.starts_with_at(src, "*]", p + 1) {
          return emit(EdgeState, p, p + 3)
        }
      115 => if kw("style") { return emit(Style, p, p + 5) }
      110 =>
        if kw("namespace") {
          push(NamespaceState)
          return emit(Namespace, p, p + 9)
        }
      44 => return emit(Comma, p, p + 1)
      35 => return emit(Brkt, p, p + 1)
      _ => ()
    }
    common(c) || (c == 58 && emit(Colon, p, p + 1))
  }
  while true {
    if p >= n {
      types.push(at_end(state))
      texts.push("")
      starts.push(n)
      break
    }
    let c = code(p)
    let mut ok = true
    match state {
      Initial => ok = initial(c)
      Cls =>
        if @util.is_space(c) {
          space(true)
        } else if c == 125 {
          pop()
          pop()
          ignore(emit(StructStop, p, p + 1))
        } else if c == 123 {
          push(ClassBody)
          ignore(emit(StructStart, p, p + 1))
        } else {
          ok = common(c)
        }
      ClassBody =>
        if c == 34 {
          push(Quoted)
          p += 1
        } else if c == 125 {
          pop()
          ignore(emit(StructStop, p, p + 1))
        } else if c == 91 && @util.starts_with_at(src, "*]", p + 1) {
          ignore(emit(EdgeState, p, p + 3))
        } else if c == 123 {
          ignore(emit(OpenInStruct, p, p + 1))
        } else if c == 10 {
          p += 1
        } else {
          let mut q = p + 1
          while q < n {
            let ch = code(q)
            if ch == 123 || ch == 125 || ch == 10 {
              break
            }
            q += 1
          }
          ignore(emit(Member, p, q))
        }
      NamespaceState =>
        if @util.is_space(c) {
          space(true)
        } else if c == 123 {
          push(NamespaceBody)
          ignore(emit(StructStart, p, p + 1))
        } else if c == 125 {
          // The brace is read again in the state the namespace was opened from.
          pop()
        } else if c == 110 && kw("namespace") {
          push(NamespaceState)
          ignore(emit(Namespace, p, p + 9))
        } else {
          ok = common(c)
        }
      NamespaceBody =>
        if @util.is_space(c) {
          space(false)
        } else if c == 125 {
          pop()
          ignore(emit(StructStop, p, p + 1))
        } else if c == 110 && kw("namespace") {
          push(NamespaceState)
          ignore(emit(Namespace, p, p + 9))
        } else if c == 91 && @util.starts_with_at(src, "*]", p + 1) {
          ignore(emit(EdgeState, p, p + 3))
        } else if c == 99 && kw("class") {
          push(Cls)
          ignore(emit(Class, p, p + 5))
        } else {
          ok = common(c)
        }
      Quoted =>
        if c == 34 {
          pop()
          p += 1
        } else {
          ignore(emit(Str, p, until("\"")))
        }
      Generic =>
        if c == 34 {
          push(Quoted)
          p += 1
        } else if keyword(c) {
          ()
        } else if c == 126 {
          pop()
          p += 1
        } else {
          ignore(emit(GenericType, p, until("~")))
        }
      Backticked =>
        if c == 34 {
          push(Quoted)
          p += 1
        } else if keyword(c) {
          ()
        } else if c == 126 {
          push(Generic)
          p += 1
        } else if c == 96 {
          pop()
          p += 1
        } else {
          ignore(emit(BquoteStr, p, until("`")))
        }
      CallbackNameState =>
        if c == 40 {
          let q = skip_ws(p + 1)
          pop()
          if code(q) == 41 {
            p = q + 1
          } else {
            push(CallbackArgsState)
            p += 1
          }
        } else {
          ignore(emit(CallbackName, p, until("(")))
        }
      CallbackArgsState =>
        if c == 41 {
          pop()
          p += 1
        } else {
          ignore(emit(CallbackArgs, p, until(")")))
        }
      AccTitleState | AccDescrState => {
        ignore(
          emit(
            if state is AccTitleState {
              AccTitleValue
            } else {
              AccDescrValue
            },
            p,
            until("\n"),
          ),
        )
        pop()
      }
      AccDescrMultiline =>
        if c == 125 {
          pop()
          p += 1
        } else {
          ignore(emit(AccDescrMultilineValue, p, until("}")))
        }
    }
    if !ok {
      types.push(Error)
      texts.push("")
      starts.push(p)
      return { types, texts, starts, }
    }
  }
  types.push(End)
  texts.push("")
  starts.push(n)
  { types, texts, starts, }
}
