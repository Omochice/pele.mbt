///|
/// The tokens of a C4 source: token `i` is `types[i]`, over `src[starts[i]:ends[i]]`.
pub(all) struct C4Tokens {
  types : Array[Int32]
  starts : Array[Int32]
  ends : Array[Int32]
}

///|
/// The name Jison's error messages give a token type.
pub fn token_name(type_ : Int32) -> String {
  token_names[type_]
}

///|
const S_INITIAL : Int32 = 0

///|
const S_STRUCT : Int32 = 1

///|
const S_ATTRIBUTE : Int32 = 2

///|
const S_STRING : Int32 = 3

///|
const S_STRING_KV : Int32 = 4

///|
const S_STRING_KV_KEY : Int32 = 5

///|
const S_STRING_KV_VALUE : Int32 = 6

///|
const S_ACC : Int32 = 7

///|
const S_ACC_DESCR_MULTILINE : Int32 = 8

///|
let direction_words : Array[String] = ["TB", "BT", "RL", "LR"]

///|
/// Where `/.*direction\s+<word>[^\n]*/y` matching at `p` ends, or -1 when it does not match.
/// The greedy `.*` settles on the last `direction` that starts before `line_end`.
fn direction_end(
  src : String,
  p : Int32,
  line_end : Int32,
  word : String,
) -> Int32 {
  let n = src.length()
  for s = line_end - 9; s >= p; s = s - 1 {
    guard @util.starts_with_at(src, "direction", s) else { continue }
    let mut q = s + 9
    guard @util.is_space(@util.code_at(src, q)) else { continue }
    while @util.is_space(@util.code_at(src, q)) {
      q += 1
    }
    guard @util.starts_with_at(src, word, q) else { continue }
    let mut end = q + 2
    while end < n && @util.code_at(src, end) != 10 {
      end += 1
    }
    return end
  }
  -1
}

///|
/// Splits a C4 source into tokens as the lexer Jison compiles from c4Diagram.jison does:
/// its rule order, its start conditions, and what it returns once the input runs out in each of them.
pub fn tokenize(src : String) -> C4Tokens {
  let n = src.length()
  let types = []
  let starts = []
  let ends = []
  let mut state = S_INITIAL
  let mut acc_value = ACC_TITLE_VALUE
  let mut p = 0
  let mut done = false
  // Where the next `direction` is; -2 until the first search.
  // pele searches lazily so that a source with many statements is not searched once for each.
  let mut dir_next = -2
  let mut line_end = -1
  let mut dir_failed = 0
  fn emit(type_ : Int32, s : Int32, e : Int32) {
    types.push(type_)
    starts.push(s)
    ends.push(e)
    p = e
  }

  fn skip_ws(from : Int32) -> Int32 {
    let mut q = from
    while q < n && @util.is_space(@util.code_at(src, q)) {
      q += 1
    }
    q
  }

  fn up_to(ch : String, from : Int32) -> Int32 {
    let q = @util.index_of(src, ch, from~)
    if q == -1 {
      n
    } else {
      q
    }
  }

  // `word\s[^#\n;]+`
  fn statement(word : String, type_ : Int32) -> Bool {
    let mut q = p + word.length()
    if !@util.starts_with_at(src, word, p) ||
      !@util.is_space(@util.code_at(src, q)) {
      return false
    }
    q += 1
    let from = q
    while q < n {
      let c = @util.code_at(src, q)
      if c == 35 || c == 10 || c == 59 {
        break
      }
      q += 1
    }
    if q == from {
      return false
    }
    emit(type_, p, q)
    true
  }

  while true {
    // Jison notes the end of input one call before it reports it, so a rule that matches nothing gets one last turn.
    if done {
      emit(END, n, n)
      break
    }
    if p >= n {
      done = true
    }
    let c = @util.code_at(src, p)
    if state == S_INITIAL {
      if p >= n {
        emit(EOF, n, n)
        continue
      }
      if dir_next != -1 && p >= dir_failed {
        if dir_next < p {
          dir_next = @util.index_of(src, "direction", from=p)
        }
        if dir_next != -1 {
          if line_end < p {
            line_end = p
            while line_end < n &&
                  !@util.is_line_end(@util.code_at(src, line_end)) {
              line_end += 1
            }
          }
          if dir_next < line_end {
            let mut matched = false
            for i in 0..<4 {
              let end = direction_end(src, p, line_end, direction_words[i])
              if end >= 0 {
                emit(DIRECTION_TB + i, p, end)
                matched = true
                break
              }
            }
            if matched {
              continue
            }
            // No direction statement starts anywhere in the rest of this line either.
            dir_failed = line_end
          }
        }
      }
      if c == 116 && statement("title", TITLE) {
        continue
      }
      if c == 97 {
        if statement("accDescription", ACC_DESCRIPTION) {
          continue
        }
        let title = @util.starts_with_at(src, "accTitle", p)
        if title || @util.starts_with_at(src, "accDescr", p) {
          let q = skip_ws(p + 8)
          let d = @util.code_at(src, q)
          if d == 58 {
            emit(if title { ACC_TITLE } else { ACC_DESCR }, p, skip_ws(q + 1))
            acc_value = if title { ACC_TITLE_VALUE } else { ACC_DESCR_VALUE }
            state = S_ACC
            continue
          }
          if d == 123 && !title {
            p = skip_ws(q + 1)
            state = S_ACC_DESCR_MULTILINE
            continue
          }
        }
      }
      if c == 37 && @util.code_at(src, p + 1) == 37 {
        // A comment takes the line breaks after it, so no NEWLINE follows.
        let mut q = up_to("\n", p + 2)
        while q < n &&
              (@util.code_at(src, q) == 10 || @util.code_at(src, q) == 13) {
          q += 1
        }
        p = q
        continue
      }
      if @util.is_space(c) {
        let mut q = p
        let mut last = -1
        while q < n {
          let d = @util.code_at(src, q)
          if !@util.is_space(d) {
            break
          }
          if d == 10 {
            last = q
          }
          q += 1
        }
        if last != -1 {
          emit(NEWLINE, p, last + 1)
        } else {
          p = q
        }
        continue
      }
      if c == 123 {
        emit(LBRACE, p, p + 1)
        continue
      }
      if c == 125 {
        emit(RBRACE, p, p + 1)
        continue
      }
      if @util.is_word(c) {
        let mut q = p + 1
        while q < n && @util.is_word(@util.code_at(src, q)) {
          q += 1
        }
        if q - p <= 19 &&
          keywords.get(@util.slice(src, p, end=q)) is Some(type_) {
          if type_ > C4_DEPLOYMENT {
            state = S_STRUCT
          }
          emit(type_, p, q)
          continue
        }
      }
      emit(ERROR, p, p)
      break
    }
    if state == S_STRUCT {
      if p >= n {
        emit(EOF_IN_STRUCT, n, n)
      } else if c == 40 {
        let mut q = p + 1
        while @util.code_at(src, q) == 32 {
          q += 1
        }
        if @util.code_at(src, q) == 44 {
          emit(ATTRIBUTE_EMPTY, p, q + 1)
        } else {
          p += 1
        }
        state = S_ATTRIBUTE
      } else if c == 41 {
        p += 1
        state = S_INITIAL
      } else {
        emit(ERROR, p, p)
        break
      }
      continue
    }
    if state == S_ATTRIBUTE {
      if p >= n {
        continue
      }
      if c == 41 {
        p += 1
        state = S_INITIAL
      } else if c == 44 {
        if @util.code_at(src, p + 1) == 44 {
          emit(ATTRIBUTE_EMPTY, p, p + 2)
        } else {
          p += 1
        }
      } else {
        let mut q = p
        while @util.code_at(src, q) == 32 {
          q += 1
        }
        let d = @util.code_at(src, q)
        if d == 34 {
          if @util.code_at(src, q + 1) == 34 {
            emit(ATTRIBUTE_EMPTY, p, q + 2)
          } else {
            p = q + 1
            state = S_STRING
          }
        } else if d == 36 {
          p = q + 1
          state = S_STRING_KV
        } else {
          // An unquoted value runs to the next comma, through closing parentheses and line breaks.
          emit(STR, p, up_to(",", p))
        }
      }
      continue
    }
    if state == S_STRING {
      if c == 34 {
        p += 1
        state = S_ATTRIBUTE
      } else {
        emit(STR, p, up_to("\"", p))
      }
      continue
    }
    if state == S_STRING_KV {
      emit(STR_KEY, p, up_to("=", p))
      state = S_STRING_KV_KEY
      continue
    }
    if state == S_STRING_KV_KEY {
      if p >= n {
        continue
      }
      let mut q = p + 1
      if c == 61 {
        while @util.code_at(src, q) == 32 {
          q += 1
        }
      }
      if c != 61 || @util.code_at(src, q) != 34 {
        emit(ERROR, p, p)
        break
      }
      p = q + 1
      state = S_STRING_KV_VALUE
      continue
    }
    if state == S_STRING_KV_VALUE {
      if p >= n {
        continue
      }
      if c == 34 {
        p += 1
        state = S_ATTRIBUTE
      } else {
        emit(STR_VALUE, p, up_to("\"", p))
      }
      continue
    }
    if state == S_ACC {
      emit(acc_value, p, up_to("\n", p))
      state = S_INITIAL
      continue
    }
    if c == 125 {
      p += 1
      state = S_INITIAL
    } else {
      emit(ACC_DESCR_MULTILINE_VALUE, p, up_to("}", p))
    }
  }
  { types, starts, ends, }
}
