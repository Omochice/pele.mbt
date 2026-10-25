///|
/// A gantt chart's tokens, with the text and start offset of each.
pub(all) struct Tokens {
  types : Array[Tok]
  texts : Array[String]
  starts : Array[Int32]
}

///|
priv enum State {
  Initial
  InAccTitle
  InAccDescr
  InAccDescrMultiline
  InHref
  InCallbackName
  InCallbackArgs
  InClick
}

///|
fn ascii_lower(c : Int32) -> Int32 {
  if c >= 65 && c <= 90 {
    c + 32
  } else {
    c
  }
}

///|
/// Whether `word` is at `p`, ignoring the case of ASCII letters as a JavaScript `i` regular expression does.
fn caseless_at(src : String, p : Int32, word : String) -> Bool {
  if p + word.length() > src.length() {
    return false
  }
  for i in 0..<word.length() {
    if ascii_lower(@util.code_at(src, p + i)) !=
      ascii_lower(word.unsafe_get(i).to_int()) {
      return false
    }
  }
  true
}

///|
fn is_word(c : Int32) -> Bool {
  (c >= 48 && c <= 57) ||
  (c >= 65 && c <= 90) ||
  (c >= 97 && c <= 122) ||
  c == 95
}

///|
/// The end of `word\b` at `p`, or -1.
fn bare_keyword(src : String, p : Int32, word : String) -> Int32 {
  let e = p + word.length()
  if caseless_at(src, p, word) && !is_word(@util.code_at(src, e)) {
    e
  } else {
    -1
  }
}

///|
/// The end of `word\s[^\n...]+` at `p`, where the value also stops at `#` and `;` when asked to, or -1.
fn valued_keyword(
  src : String,
  p : Int32,
  word : String,
  hash : Bool,
  semicolon : Bool,
) -> Int32 {
  if !caseless_at(src, p, word) {
    return -1
  }
  let space = p + word.length()
  if !@util.is_space(@util.code_at(src, space)) {
    return -1
  }
  let mut e = space + 1
  while e < src.length() {
    let c = @util.code_at(src, e)
    if c == 10 || (hash && c == 35) || (semicolon && c == 59) {
      break
    }
    e += 1
  }
  if e > space + 1 {
    e
  } else {
    -1
  }
}

///|
fn skip_spaces(src : String, from : Int32) -> Int32 {
  let mut e = from
  while @util.is_space(@util.code_at(src, e)) {
    e += 1
  }
  e
}

///|
/// The end of `word\s*` followed by `mark` and `\s*` at `p`, or -1.
fn marked_keyword(
  src : String,
  p : Int32,
  word : String,
  mark : Int32,
) -> Int32 {
  if !caseless_at(src, p, word) {
    return -1
  }
  let e = skip_spaces(src, p + word.length())
  if @util.code_at(src, e) != mark {
    return -1
  }
  skip_spaces(src, e + 1)
}

///|
/// The end of `word\s+` at `p`, or -1.
fn spaced_keyword(src : String, p : Int32, word : String) -> Int32 {
  if !caseless_at(src, p, word) {
    return -1
  }
  let start = p + word.length()
  let e = skip_spaces(src, start)
  if e > start {
    e
  } else {
    -1
  }
}

///|
let day_names : Array[String] = [
  "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
]

///|
/// The day and the end of `keyword\s+(day)\b` at `p`, trying the days in order.
fn day_keyword(
  src : String,
  p : Int32,
  keyword : String,
  days : Array[String],
) -> (Int32, Int32)? {
  let start = spaced_keyword(src, p, keyword)
  if start < 0 {
    return None
  }
  for i, day in days {
    let e = bare_keyword(src, start, day)
    if e >= 0 {
      return Some((i, e))
    }
  }
  None
}

///|
let weekday_tokens : Array[Tok] = [
  WeekdayMonday,
  WeekdayTuesday,
  WeekdayWednesday,
  WeekdayThursday,
  WeekdayFriday,
  WeekdaySaturday,
  WeekdaySunday,
]

///|
/// Splits a gantt chart into tokens as Mermaid's Jison lexer does.
pub fn tokenize(src : String) -> Tokens {
  let n = src.length()
  let types : Array[Tok] = []
  let texts : Array[String] = []
  let starts : Array[Int32] = []
  let mut state = Initial
  let mut p = 0
  let emit = (kind : Tok, s : Int32, e : Int32) => {
    types.push(kind)
    texts.push(@util.slice(src, s, end=e))
    starts.push(s)
    p = e
  }
  let until = (ch : String, from : Int32) => {
    let e = @util.index_of(src, ch, from~)
    if e == -1 {
      n
    } else {
      e
    }
  }
  // Statements that start with a keyword, tried in the grammar's rule order.
  let keyword = (c : Int32) => {
    let lower = c | 32
    if lower == 97 {
      let e = marked_keyword(src, p, "accTitle", 58)
      if e >= 0 {
        state = InAccTitle
        emit(AccTitle, p, e)
        return true
      }
      let e = marked_keyword(src, p, "accDescr", 58)
      if e >= 0 {
        state = InAccDescr
        emit(AccDescr, p, e)
        return true
      }
      let e = marked_keyword(src, p, "accDescr", 123)
      if e >= 0 {
        state = InAccDescrMultiline
        p = e
        return true
      }
    } else if lower == 104 {
      let e = spaced_keyword(src, p, "href")
      if e >= 0 && @util.code_at(src, e) == 34 {
        state = InHref
        p = e + 1
        return true
      }
    } else if lower == 99 {
      let e = spaced_keyword(src, p, "call")
      if e >= 0 {
        state = InCallbackName
        p = e
        return true
      }
      let e = spaced_keyword(src, p, "click")
      if e >= 0 {
        state = InClick
        p = e
        return true
      }
    } else if lower == 119 {
      if day_keyword(src, p, "weekday", day_names) is Some((day, e)) {
        emit(weekday_tokens[day], p, e)
        return true
      }
      if day_keyword(src, p, "weekend", ["friday", "saturday"])
        is Some((day, e)) {
        emit(if day == 0 { WeekendFriday } else { WeekendSaturday }, p, e)
        return true
      }
    }
    let found = match lower {
      97 => {
        let e = valued_keyword(src, p, "axisFormat", true, true)
        if e >= 0 {
          Some((AxisFormat, e))
        } else {
          let e = valued_keyword(src, p, "accDescription", true, true)
          if e >= 0 {
            Some((AccDescription, e))
          } else {
            None
          }
        }
      }
      103 => {
        let e = bare_keyword(src, p, "gantt")
        if e >= 0 {
          Some((Gantt, e))
        } else {
          None
        }
      }
      100 => {
        let e = valued_keyword(src, p, "dateFormat", true, true)
        if e >= 0 {
          Some((DateFormat, e))
        } else {
          None
        }
      }
      105 => {
        let e = bare_keyword(src, p, "inclusiveEndDates")
        if e >= 0 {
          Some((InclusiveEndDates, e))
        } else {
          let e = valued_keyword(src, p, "includes", true, true)
          if e >= 0 {
            Some((Includes, e))
          } else {
            None
          }
        }
      }
      116 => {
        let e = bare_keyword(src, p, "topAxis")
        if e >= 0 {
          Some((TopAxis, e))
        } else {
          let e = valued_keyword(src, p, "tickInterval", true, true)
          if e >= 0 {
            Some((TickInterval, e))
          } else {
            let e = valued_keyword(src, p, "todayMarker", false, true)
            if e >= 0 {
              Some((TodayMarker, e))
            } else {
              let e = valued_keyword(src, p, "title", false, false)
              if e >= 0 {
                Some((Title, e))
              } else {
                None
              }
            }
          }
        }
      }
      101 => {
        let e = valued_keyword(src, p, "excludes", true, true)
        if e >= 0 {
          Some((Excludes, e))
        } else {
          None
        }
      }
      115 => {
        let e = valued_keyword(src, p, "section", false, false)
        if e >= 0 {
          Some((Section, e))
        } else {
          None
        }
      }
      _ => None
    }
    match found {
      Some((kind, e)) => {
        emit(kind, p, e)
        true
      }
      None => false
    }
  }
  while true {
    if p >= n {
      let kind : Tok = match state {
        InAccTitle => AccTitleValue
        InAccDescr => AccDescrValue
        InAccDescrMultiline => AccDescrMultilineValue
        InHref => Href
        InCallbackName => CallbackName
        InCallbackArgs => CallbackArgs
        InClick => Click
        Initial => Eof
      }
      emit(kind, n, n)
      break
    }
    let c = @util.code_at(src, p)
    match state {
      Initial => {
        let d = @util.code_at(src, p + 1)
        if c == 37 {
          if d != 37 {
            let mut e = until("\n", p + 1)
            while @util.code_at(src, e) == 10 {
              e += 1
            }
            p = e
          } else if @util.code_at(src, p + 2) == 123 {
            // The grammar enters a lexer state it never defines, so nothing can follow.
            emit(OpenDirective, p, p + 3)
            emit(Error, p, p)
            return { types, texts, starts, }
          } else {
            p = until("\n", p + 2)
          }
        } else if c == 10 {
          let mut e = p + 1
          while @util.code_at(src, e) == 10 {
            e += 1
          }
          emit(Nl, p, e)
        } else if @util.is_space(c) {
          p = skip_spaces(src, p + 1)
        } else if keyword(c) {
          ()
        } else if c >= 48 && c <= 57 && is_date(src, p) {
          emit(Date, p, p + 10)
        } else if c != 58 {
          let mut e = p + 1
          while e < n {
            let ch = @util.code_at(src, e)
            if ch == 58 || ch == 10 {
              break
            }
            e += 1
          }
          emit(TaskTxt, p, e)
        } else {
          let mut e = p + 1
          while e < n {
            let ch = @util.code_at(src, e)
            if ch == 35 || ch == 10 || ch == 59 {
              break
            }
            e += 1
          }
          emit(if e > p + 1 { TaskData } else { Colon }, p, e)
        }
      }
      InAccTitle | InAccDescr => {
        let kind : Tok = if state is InAccTitle {
          AccTitleValue
        } else {
          AccDescrValue
        }
        state = Initial
        emit(kind, p, until("\n", p))
      }
      InAccDescrMultiline =>
        if c == 125 {
          state = Initial
          p += 1
        } else {
          emit(AccDescrMultilineValue, p, until("}", p))
        }
      InHref =>
        if c == 34 {
          state = Initial
          p += 1
        } else {
          emit(Href, p, until("\"", p))
        }
      InCallbackName =>
        if c == 40 {
          let e = skip_spaces(src, p + 1)
          if @util.code_at(src, e) == 41 {
            state = Initial
            p = e + 1
          } else {
            state = InCallbackArgs
            p += 1
          }
        } else {
          emit(CallbackName, p, until("(", p))
        }
      InCallbackArgs =>
        if c == 41 {
          state = Initial
          p += 1
        } else {
          emit(CallbackArgs, p, until(")", p))
        }
      InClick =>
        if @util.is_space(c) {
          state = Initial
          p += 1
        } else {
          let mut e = p + 1
          while e < n && !@util.is_space(@util.code_at(src, e)) {
            e += 1
          }
          emit(Click, p, e)
        }
    }
  }
  types.push(End)
  texts.push("")
  starts.push(n)
  { types, texts, starts, }
}

///|
/// Whether `\d\d\d\d-\d\d-\d\d\b` matches at `p`.
fn is_date(src : String, p : Int32) -> Bool {
  for i in 0..<10 {
    let c = @util.code_at(src, p + i)
    let ok = if i == 4 || i == 7 { c == 45 } else { c >= 48 && c <= 57 }
    if !ok {
      return false
    }
  }
  !is_word(@util.code_at(src, p + 10))
}
