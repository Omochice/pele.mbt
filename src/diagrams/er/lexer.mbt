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
  Block
  BlockBq
  AccTitleState
  AccDescrState
  AccDescrMultiline
  StyleState
}

///|
const TEXT : Int32 = 1

///|
const STYLE_TEXT : Int32 = 2

///|
const ATTR_START : Int32 = 4

///|
const ATTR_REST : Int32 = 8

///|
/// The classes of an ASCII character, as the character sets of Mermaid's rules allow it.
fn char_class(c : Int32) -> Int32 {
  if c < 0 || c >= 128 {
    return 0
  }
  let mut kind = 0
  if @util.is_word(c) {
    kind = kind | TEXT | STYLE_TEXT | ATTR_REST
    if !@util.is_digit(c) {
      kind = kind | ATTR_START
    }
  }
  match c {
    45 => kind | TEXT | STYLE_TEXT | ATTR_REST
    42 => kind | TEXT | STYLE_TEXT | ATTR_REST | ATTR_START
    46 => kind | TEXT | ATTR_REST
    91 | 93 | 40 | 41 | 44 => kind | ATTR_REST
    _ => kind
  }
}

///|
/// Mermaid's attribute pattern is case-insensitive, which lets the micro sign into its À-￿ range.
fn is_attr(c : Int32, kind : Int32) -> Bool {
  if c < 128 {
    (char_class(c) & kind) != 0
  } else {
    c >= 0xc0 || c == 0xb5
  }
}

///|
fn is_text(c : Int32, kind : Int32) -> Bool {
  c >= 128 || (char_class(c) & kind) != 0
}

///|
/// Whether `word`, in lower case, is at `p`, ignoring the case of its letters.
fn keyword_at(src : String, p : Int32, word : String) -> Bool {
  for i in 0..<word.length() {
    let k = word.unsafe_get(i).to_int()
    let c = @util.code_at(src, p + i)
    if c != k && (k < 97 || k > 122 || (c | 32) != k) {
      return false
    }
  }
  true
}

///|
/// The end of `/<word>\s*<sep>\s*/iy` at `p`, or -1.
fn marker_end(src : String, p : Int32, word : String, sep : Int32) -> Int32 {
  if !keyword_at(src, p, word) {
    return -1
  }
  let mut q = p + word.length()
  while @util.is_space(@util.code_at(src, q)) {
    q += 1
  }
  if @util.code_at(src, q) != sep {
    return -1
  }
  q += 1
  while @util.is_space(@util.code_at(src, q)) {
    q += 1
  }
  q
}

///|
/// The first line terminator at or after `q`, or the end of the text.
fn next_line_end(src : String, q : Int32) -> Int32 {
  let mut i = q
  while i < src.length() && !@util.is_line_end(src.unsafe_get(i).to_int()) {
    i += 1
  }
  i
}

///|
/// The end of `/.*direction\s+<dir>[^\n]*/iy` at `p`, or -1.
/// The greedy `.*` makes the last `direction` on the line that is followed by the direction win.
fn direction_end(src : String, p : Int32, dir : String) -> Int32 {
  for k = next_line_end(src, p); k >= p; k = k - 1 {
    if !keyword_at(src, k, "direction") {
      continue
    }
    let mut q = k + 9
    if !@util.is_space(@util.code_at(src, q)) {
      continue
    }
    while @util.is_space(@util.code_at(src, q)) {
      q += 1
    }
    if !keyword_at(src, q, dir) {
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
/// The first `direction`, in any case, at or after `q`, or -1.
fn find_direction_word(src : String, q : Int32) -> Int32 {
  for i = q; i <= src.length() - 9; i = i + 1 {
    if keyword_at(src, i, "direction") {
      return i
    }
  }
  -1
}

///|
fn index_of_code(src : String, code : Int32, from : Int32) -> Int32 {
  for i = from; i < src.length(); i = i + 1 {
    if src.unsafe_get(i).to_int() == code {
      return i
    }
  }
  -1
}

///|
let direction_tokens : Array[(Tok, String)] = [
  (DirectionTb, "tb"),
  (DirectionBt, "bt"),
  (DirectionRl, "rl"),
  (DirectionLr, "lr"),
]

///|
/// Splits an ER diagram into tokens as Mermaid's Jison lexer does.
/// A character no style rule allows ends the stream with an `Error` token.
pub fn tokenize(src : String) -> Tokens {
  let n = src.length()
  let types : Array[Tok] = []
  let texts : Array[String] = []
  let starts : Array[Int32] = []
  let mut state = Initial
  let mut p = 0
  let mut dir_next = -2
  let mut dir_failed = 0
  let mut line_end = -1
  let mut tilde_next = -2
  let mut tilde_line = -1
  let mut tilde_last = -1
  let mut ws_next = -1
  let code = (q : Int32) => @util.code_at(src, q)
  let emit = (kind : Tok, s : Int32, e : Int32) => {
    types.push(kind)
    texts.push(@util.slice(src, s, end=e))
    starts.push(s)
    p = e
  }
  let kwb = (word : String) => {
    keyword_at(src, p, word) && !@util.is_word(code(p + word.length()))
  }
  let lower = (q : Int32) => {
    let c = code(q)
    if c >= 65 && c <= 90 {
      c + 32
    } else {
      c
    }
  }
  let digits = (q : Int32) => {
    let mut i = q
    while @util.is_digit(code(i)) {
      i += 1
    }
    i
  }
  // A direction statement swallows its whole line, from wherever the lexer stands on it.
  let direction = () => {
    if dir_next == -1 {
      return false
    }
    if dir_next < p {
      dir_next = find_direction_word(src, p)
      if dir_next == -1 {
        return false
      }
    }
    if p < dir_failed {
      return false
    }
    if line_end < p {
      line_end = next_line_end(src, p)
    }
    if dir_next >= line_end {
      return false
    }
    for entry in direction_tokens {
      let (kind, dir) = entry
      let e = direction_end(src, p, dir)
      if e >= 0 {
        emit(kind, p, e)
        return true
      }
    }
    dir_failed = line_end
    false
  }
  let quoted = () => {
    let e = index_of_code(src, 34, p + 1)
    if e == -1 {
      emit(Char, p, p + 1)
      return
    }
    let mut name = e > p + 1
    for q = p + 1; name && q < e; q = q + 1 {
      if code(q) is (37 | 92 | 13 | 10 | 11 | 8) {
        name = false
      }
    }
    emit(if name { EntityName } else { Word }, p, e + 1)
  }
  let number = (c : Int32) => {
    let d = code(p + 1)
    if d == 43 && (c == 49 || c == 48) {
      emit(if c == 49 { OneOrMore } else { ZeroOrMore }, p, p + 2)
      return
    }
    let q = digits(p + 1)
    if code(q) == 46 && @util.is_digit(code(q + 1)) {
      emit(DecimalNum, p, digits(q + 2))
      return
    }
    if c == 49 {
      if @util.is_space(d) {
        let mut r = p + 2
        while @util.is_space(code(r)) {
          r += 1
        }
        let f = code(r)
        if @util.is_word(f) || f == 34 || f == 39 {
          emit(OnlyOne, p, p + 1)
          return
        }
      } else if d == 45 || d == 46 {
        let f = code(p + 2)
        if f == 45 || f == 46 {
          emit(OnlyOne, p, p + 1)
          return
        }
      }
      if !@util.is_word(d) {
        emit(EntityOne, p, p + 1)
        return
      }
    }
    emit(Num, p, q)
  }
  let keyword = (lc : Int32) => {
    let d = code(p + 1)
    match lc {
      101 =>
        if kwb("erdiagram") {
          emit(ErDiagram, p, p + 9)
        } else if kwb("end") {
          let mut e = p + 3
          while @util.is_space(code(e)) {
            e += 1
          }
          emit(EndKw, p, e)
        } else {
          return false
        }
      115 =>
        if kwb("style") {
          state = StyleState
          emit(Style, p, p + 5)
        } else if kwb("subgraph") {
          emit(Subgraph, p, p + 8)
        } else {
          return false
        }
      99 =>
        if kwb("classdef") {
          state = StyleState
          emit(ClassDef, p, p + 8)
        } else if kwb("class") {
          emit(Class, p, p + 5)
        } else {
          return false
        }
      111 =>
        if kwb("one or zero") {
          emit(ZeroOrOne, p, p + 11)
        } else if kwb("one or more") || kwb("one or many") {
          emit(OneOrMore, p, p + 11)
        } else if kwb("one") {
          emit(OnlyOne, p, p + 3)
        } else if kwb("only one") {
          emit(OnlyOne, p, p + 8)
        } else if d == 124 {
          emit(ZeroOrOne, p, p + 2)
        } else if d == 123 {
          emit(ZeroOrMore, p, p + 2)
        } else if kwb("optionally to") {
          emit(NonIdentifying, p, p + 13)
        } else {
          return false
        }
      122 =>
        if kwb("zero or one") {
          emit(ZeroOrOne, p, p + 11)
        } else if kwb("zero or more") || kwb("zero or many") {
          emit(ZeroOrMore, p, p + 12)
        } else {
          return false
        }
      109 =>
        if keyword_at(src, p, "many(0)") {
          emit(ZeroOrMore, p, p + 7)
        } else if keyword_at(src, p, "many(1)") {
          emit(OneOrMore, p, p + 7)
        } else if kwb("many") {
          emit(ZeroOrMore, p, p + 4)
        } else {
          return false
        }
      116 => {
        if !kwb("to") {
          return false
        }
        emit(Identifying, p, p + 2)
      }
      117 => {
        if d != 46 && d != 45 && d != 124 {
          return false
        }
        emit(MdParent, p, p + 1)
      }
      124 =>
        if lower(p + 1) == 111 && !@util.is_word(code(p + 2)) {
          emit(ZeroOrOne, p, p + 2)
        } else if d == 124 {
          emit(OnlyOne, p, p + 2)
        } else if d == 123 {
          emit(OneOrMore, p, p + 2)
        } else {
          return false
        }
      125 =>
        if lower(p + 1) == 111 && !@util.is_word(code(p + 2)) {
          emit(ZeroOrMore, p, p + 2)
        } else if d == 124 {
          emit(OneOrMore, p, p + 2)
        } else {
          return false
        }
      46 => {
        if d != 46 && d != 45 {
          return false
        }
        emit(NonIdentifying, p, p + 2)
      }
      45 =>
        if d == 45 {
          emit(Identifying, p, p + 2)
        } else if d == 46 {
          emit(NonIdentifying, p, p + 2)
        } else {
          return false
        }
      _ => return false
    }
    true
  }
  let initial = (c : Int32) => {
    if (c == 97 || c == 65) && keyword_at(src, p, "acc") {
      let title = marker_end(src, p, "acctitle", 58)
      if title >= 0 {
        state = AccTitleState
        emit(AccTitle, p, title)
        return
      }
      let descr = marker_end(src, p, "accdescr", 58)
      if descr >= 0 {
        state = AccDescrState
        emit(AccDescr, p, descr)
        return
      }
      let multiline = marker_end(src, p, "accdescr", 123)
      if multiline >= 0 {
        state = AccDescrMultiline
        p = multiline
        return
      }
    }
    if direction() {
      return
    }
    match c {
      32 | 9 | 13 => {
        let mut e = p + 1
        while code(e) is (32 | 9 | 13) {
          e += 1
        }
        p = e
        return
      }
      10 => {
        let mut e = p + 1
        while code(e) == 10 {
          e += 1
        }
        emit(Newline, p, e)
        return
      }
      34 => {
        quoted()
        return
      }
      123 => {
        state = Block
        emit(BlockStart, p, p + 1)
        return
      }
      35 => {
        emit(Brkt, p, p + 1)
        return
      }
      44 => {
        emit(Comma, p, p + 1)
        return
      }
      58 => {
        if code(p + 1) == 58 && code(p + 2) == 58 {
          emit(StyleSeparator, p, p + 3)
        } else {
          emit(Colon, p, p + 1)
        }
        return
      }
      91 => {
        emit(Sqs, p, p + 1)
        return
      }
      93 => {
        emit(Sqe, p, p + 1)
        return
      }
      _ => ()
    }
    if @util.is_digit(c) {
      number(c)
      return
    }
    if keyword(if c >= 65 && c <= 90 { c + 32 } else { c }) {
      return
    }
    if is_text(c, TEXT) {
      let mut e = p + 1
      while is_text(code(e), TEXT) {
        e += 1
      }
      emit(UnicodeText, p, e)
      return
    }
    emit(Char, p, p + 1)
  }
  // Mermaid's generic type rule: a run of non-space characters holding a `~`, through the last `~` on the line.
  let generic = () => {
    if tilde_next == -1 {
      return false
    }
    if tilde_next < p {
      tilde_next = index_of_code(src, 126, p)
      if tilde_next == -1 {
        return false
      }
    }
    if ws_next < p {
      let mut q = p
      while q < n && !@util.is_space(code(q)) {
        q += 1
      }
      ws_next = q
    }
    if tilde_next >= ws_next {
      return false
    }
    if tilde_line < p {
      tilde_line = next_line_end(src, p)
      tilde_last = @util.last_index_of(src, "~", from=tilde_line - 1)
    }
    if tilde_last <= tilde_next {
      return false
    }
    let mut e = tilde_last + 1
    while e < n && !@util.is_space(code(e)) {
      e += 1
    }
    emit(AttributeWord, p, e)
    true
  }
  let block = (c : Int32) => {
    if @util.is_space(c) {
      p += 1
      while @util.is_space(code(p)) {
        p += 1
      }
      return
    }
    let lc = c | 32
    if (lc == 112 || lc == 102 || lc == 117) &&
      (code(p + 1) | 32) == 107 &&
      !@util.is_word(code(p + 2)) {
      emit(AttributeKey, p, p + 2)
      return
    }
    if generic() {
      return
    }
    if is_attr(c, ATTR_START) {
      let mut e = p + 1
      while e < n && is_attr(code(e), ATTR_REST) {
        e += 1
      }
      emit(AttributeWord, p, e)
      return
    }
    if c == 96 {
      state = BlockBq
      p += 1
      return
    }
    if c == 34 {
      let e = index_of_code(src, 34, p + 1)
      if e != -1 {
        emit(Comment, p, e + 1)
        return
      }
    } else if c == 125 {
      state = Initial
      emit(BlockStop, p, p + 1)
      return
    }
    emit(Char, p, p + 1)
  }
  while p < n {
    let c = code(p)
    match state {
      Initial => initial(c)
      Block => block(c)
      BlockBq =>
        if c == 96 {
          state = Block
          p += 1
        } else {
          let e = index_of_code(src, 96, p)
          emit(AttributeWord, p, if e == -1 { n } else { e })
        }
      AccTitleState | AccDescrState => {
        let e = index_of_code(src, 10, p)
        let kind = if state is AccTitleState {
          AccTitleValue
        } else {
          AccDescrValue
        }
        emit(kind, p, if e == -1 { n } else { e })
        state = Initial
      }
      AccDescrMultiline =>
        if c == 125 {
          state = Initial
          p += 1
        } else {
          let e = index_of_code(src, 125, p)
          emit(AccDescrMultilineValue, p, if e == -1 { n } else { e })
        }
      StyleState =>
        if c == 10 {
          let mut e = p + 1
          while code(e) == 10 {
            e += 1
          }
          state = Initial
          emit(Newline, p, e)
        } else if @util.is_space(c) {
          p += 1
          while @util.is_space(code(p)) {
            p += 1
          }
        } else if c == 58 {
          emit(Colon, p, p + 1)
        } else if c == 44 {
          emit(Comma, p, p + 1)
        } else if c == 35 {
          emit(Brkt, p, p + 1)
        } else if c == 59 {
          emit(Semi, p, p + 1)
        } else if is_text(c, STYLE_TEXT) {
          let mut e = p + 1
          while is_text(code(e), STYLE_TEXT) {
            e += 1
          }
          emit(StyleText, p, e)
        } else {
          types.push(Error)
          texts.push("")
          starts.push(p)
          return { types, texts, starts, }
        }
    }
  }
  // At the end of input Jison's INITIAL state yields EOF, the title and description states yield an empty value, and the block and style states yield nothing.
  let last : Tok? = match state {
    Initial => Some(Eof)
    AccTitleState => Some(AccTitleValue)
    AccDescrState => Some(AccDescrValue)
    AccDescrMultiline => Some(AccDescrMultilineValue)
    _ => None
  }
  if last is Some(kind) {
    types.push(kind)
    texts.push("")
    starts.push(n)
  }
  types.push(End)
  texts.push("")
  starts.push(n)
  { types, texts, starts, }
}
