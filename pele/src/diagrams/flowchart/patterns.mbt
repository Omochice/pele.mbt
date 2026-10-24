// The sticky regexes of pele's flowchart lexer, matched by hand.
// Each takes the source and a start offset and returns the end of the match, or -1.

///|
fn code(src : String, i : Int32) -> Int32 {
  @util.code_at(src, i)
}

///|
fn skip_space(src : String, q : Int32) -> Int32 {
  let mut j = q
  while @util.is_space(code(src, j)) {
    j += 1
  }
  j
}

///|
fn is_link_prefix(c : Int32) -> Bool {
  c == 'x' || c == 'o' || c == '<'
}

///|
/// `/word\s*P\s*/y`, as `accTitle\s*:\s*` and its siblings.
pub fn keyword_punct_end(
  src : String,
  q : Int32,
  word : String,
  punct : Int32,
) -> Int32 {
  if !@util.starts_with_at(src, word, q) {
    return -1
  }
  let j = skip_space(src, q + word.length())
  if code(src, j) != punct {
    return -1
  }
  skip_space(src, j + 1)
}

///|
/// `/word\s+/y`, as `call\s+` and `click\s+`.
pub fn keyword_space_end(src : String, q : Int32, word : String) -> Int32 {
  let j = q + word.length()
  if !@util.starts_with_at(src, word, q) || !@util.is_space(code(src, j)) {
    return -1
  }
  skip_space(src, j)
}

///|
/// `/(?:\r?\n)*\s*\n/y`: the run of whitespace at `q` up to its last newline.
pub fn nodir_end(src : String, q : Int32) -> Int32 {
  let w = skip_space(src, q)
  let mut k = w - 1
  while k >= q && code(src, k) != '\n' {
    k -= 1
  }
  if k < q {
    -1
  } else {
    k + 1
  }
}

///|
/// `/\s*(?:LR|RL|TB|BT|TD|BR)\b/y`.
pub fn dir_end(src : String, q : Int32) -> Int32 {
  let j = skip_space(src, q)
  match @util.slice(src, j, end=j + 2) {
    "LR" | "RL" | "TB" | "BT" | "TD" | "BR" =>
      if @util.is_word(code(src, j + 2)) {
        -1
      } else {
        j + 2
      }
    _ => -1
  }
}

///|
/// `/\s*[<>^]/y`.
pub fn dir_symbol_end(src : String, q : Int32) -> Int32 {
  let j = skip_space(src, q)
  let c = code(src, j)
  if c == '<' || c == '>' || c == '^' {
    j + 1
  } else {
    -1
  }
}

///|
/// `/\s*v\b/y`.
pub fn dir_v_end(src : String, q : Int32) -> Int32 {
  let j = skip_space(src, q)
  if code(src, j) == 'v' && !@util.is_word(code(src, j + 1)) {
    j + 1
  } else {
    -1
  }
}

///|
/// `/.*direction\s+XY[^\n]*/y`: the greedy `.*` lets the last `direction` on the line win.
pub fn direction_end(src : String, q : Int32, dir : String) -> Int32 {
  let n = src.length()
  let mut line_end = q
  while line_end < n && !@util.is_line_end(code(src, line_end)) {
    line_end += 1
  }
  let mut k = line_end
  while k >= q {
    if @util.starts_with_at(src, "direction", k) &&
      @util.is_space(code(src, k + 9)) {
      let j = skip_space(src, k + 9)
      if @util.starts_with_at(src, dir, j) {
        let mut e = j + 2
        while e < n && code(src, e) != '\n' {
          e += 1
        }
        return e
      }
    }
    k -= 1
  }
  -1
}

///|
/// `/\s*[xo<]?--+[-xo>]\s*/y` for `-`, and the thick form `/\s*[xo<]?==+[=xo>]\s*/y` for `=`.
fn link_end(src : String, q : Int32, line : Int32) -> Int32 {
  let mut j = skip_space(src, q)
  if is_link_prefix(code(src, j)) {
    j += 1
  }
  let mut m = 0
  while code(src, j + m) == line {
    m += 1
  }
  if m < 2 {
    return -1
  }
  let c = code(src, j + m)
  let e = if c == 'x' || c == 'o' || c == '>' {
    j + m + 1
  } else if m >= 3 {
    j + m
  } else {
    return -1
  }
  skip_space(src, e)
}

///|
fn normal_link_end(src : String, q : Int32) -> Int32 {
  link_end(src, q, '-')
}

///|
fn thick_link_end(src : String, q : Int32) -> Int32 {
  link_end(src, q, '=')
}

///|
/// `/\s*[xo<]?--\s*/y` for `-`, and `/\s*[xo<]?==\s*/y` for `=`.
fn start_link_end(src : String, q : Int32, line : Int32) -> Int32 {
  let mut j = skip_space(src, q)
  if is_link_prefix(code(src, j)) {
    j += 1
  }
  if code(src, j) == line && code(src, j + 1) == line {
    skip_space(src, j + 2)
  } else {
    -1
  }
}

///|
/// `/\s*[xo<]?-?\.+-[xo>]?\s*/y`.
fn dotted_link_end(src : String, q : Int32) -> Int32 {
  let mut j = skip_space(src, q)
  if is_link_prefix(code(src, j)) {
    j += 1
  }
  if code(src, j) == '-' {
    j += 1
  }
  let dots = j
  while code(src, j) == '.' {
    j += 1
  }
  if j == dots || code(src, j) != '-' {
    return -1
  }
  j += 1
  let c = code(src, j)
  if c == 'x' || c == 'o' || c == '>' {
    j += 1
  }
  skip_space(src, j)
}

///|
/// `/\s*[xo<]?-\.\s*/y`.
fn dotted_start_end(src : String, q : Int32) -> Int32 {
  let mut j = skip_space(src, q)
  if is_link_prefix(code(src, j)) {
    j += 1
  }
  if code(src, j) == '-' && code(src, j + 1) == '.' {
    skip_space(src, j + 2)
  } else {
    -1
  }
}

///|
/// `/\s*~~~+\s*/y`.
fn invisible_link_end(src : String, q : Int32) -> Int32 {
  let j = skip_space(src, q)
  let mut m = 0
  while code(src, j + m) == '~' {
    m += 1
  }
  if m < 3 {
    -1
  } else {
    skip_space(src, j + m)
  }
}

///|
/// `/(?:\r?\n)+/y`.
fn newline_end(src : String, q : Int32) -> Int32 {
  let mut j = q
  while true {
    if code(src, j) == '\n' {
      j += 1
    } else if code(src, j) == '\r' && code(src, j + 1) == '\n' {
      j += 2
    } else {
      break
    }
  }
  if j == q {
    -1
  } else {
    j
  }
}

///|
/// `/[^\S\n\r]+/y`: whitespace other than a line feed or carriage return.
fn blank_end(src : String, q : Int32) -> Int32 {
  let mut j = q
  while true {
    let c = code(src, j)
    if !@util.is_space(c) || c == '\n' || c == '\r' {
      break
    }
    j += 1
  }
  if j == q {
    -1
  } else {
    j
  }
}

///|
/// `/\(\s*\)/y`.
pub fn empty_call_end(src : String, q : Int32) -> Int32 {
  if code(src, q) != '(' {
    return -1
  }
  let j = skip_space(src, q + 1)
  if code(src, j) == ')' {
    j + 1
  } else {
    -1
  }
}

///|
/// `text.replace(/\n\s*/g, '<br/>')`.
pub fn break_lines(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    if code(text, i) == '\n' {
      out.write_string("<br/>")
      i = skip_space(text, i + 1)
    } else {
      @util.write_range(out, text, i, i + 1)
      i += 1
    }
  }
  out.to_string()
}
