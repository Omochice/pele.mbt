///|
/// What becomes of one declaration of a `style` attribute as it is rewritten.
priv enum Kept {
  Keep
  Drop
  Replace(String)
}

///|
/// Where the declaration of `css` starting at `start` ends: at the next `;`, or at the end.
fn declaration_end(css : String, start : Int32) -> Int32 {
  let end = @util.index_of(css, ";", from=start)
  if end < 0 {
    css.length()
  } else {
    end
  }
}

///|
/// `css` with each declaration between its `;`s kept, dropped or replaced as `decide` says of
/// its range, and what is kept joined by `;`, as splitting at `;` and joining what is kept would.
/// `decide` is asked once for each declaration, in order.
/// The result is built at its final size and only when something changes, because a style of
/// tens of millions of escaped `&` has as many declarations, each ended by its entity's `;`, and
/// splitting it would hold each of them as a string of its own.
fn rebuild(css : String, decide : (Int32, Int32) -> Kept) -> String {
  let changes : Array[(Int32, Kept)] = []
  let mut length = 0
  let mut kept = 0
  let mut start = 0
  while true {
    let end = declaration_end(css, start)
    match decide(start, end) {
      Keep => {
        length += end - start
        kept += 1
      }
      Drop => changes.push((start, Drop))
      Replace(text) => {
        length += text.length()
        kept += 1
        changes.push((start, Replace(text)))
      }
    }
    if end >= css.length() {
      break
    }
    start = end + 1
  }
  if changes.is_empty() {
    return css
  }
  if kept > 1 {
    length += kept - 1
  }
  let out = StringBuilder(size_hint=length * 2)
  let mut next = 0
  let mut first = true
  start = 0
  while true {
    let end = declaration_end(css, start)
    let decision = if next < changes.length() && changes[next].0 == start {
      next += 1
      changes[next - 1].1
    } else {
      Keep
    }
    match decision {
      Drop => ()
      Keep => {
        if !first {
          out.write_char(';')
        }
        first = false
        @util.write_range(out, css, start, end)
      }
      Replace(text) => {
        if !first {
          out.write_char(';')
        }
        first = false
        out.write_string(text)
      }
    }
    if end >= css.length() {
      break
    }
    start = end + 1
  }
  out.to_string()
}

///|
/// Where the text of `css` from `start` to `end` starts once CSS whitespace is trimmed from it.
fn trimmed_start(css : String, start : Int32, end : Int32) -> Int32 {
  let mut i = start
  while i < end && is_css_space(@util.code_at(css, i)) {
    i += 1
  }
  i
}

///|
/// Whether the declaration of `css` from `start` to `end`, trimmed, names a custom property.
fn is_custom_property(css : String, start : Int32, end : Int32) -> Bool {
  let i = trimmed_start(css, start, end)
  i + 2 <= end &&
  @util.code_at(css, i) == '-' &&
  @util.code_at(css, i + 1) == '-'
}

///|
/// Where `word`, in lowercase ASCII, next occurs in `text` from `from` with ASCII case ignored, as
/// it would be found in the text lowercased, or -1.
fn index_ignoring_case(text : String, word : String, from : Int32) -> Int32 {
  let last = text.length() - word.length()
  for at = from; at <= last; at = at + 1 {
    let mut matched = true
    for k in 0..<word.length() {
      let c = @util.code_at(text, at + k)
      let lower = if c >= 'A' && c <= 'Z' { c + 32 } else { c }
      if lower != word.unsafe_get(k).to_int() {
        matched = false
        break
      }
    }
    if matched {
      return at
    }
  }
  -1
}

///|
/// Where the first `:` of the declaration of `css` from `start` to `end` is when what comes
/// before it, trimmed, is `rx` or `ry`.
fn radius_colon(css : String, start : Int32, end : Int32) -> Int32? {
  let i = trimmed_start(css, start, end)
  guard i + 2 <= end &&
    @util.code_at(css, i) == 'r' &&
    @util.code_at(css, i + 1) is ('x' | 'y') else {
    return None
  }
  let colon = trimmed_start(css, i + 2, end)
  if colon < end && @util.code_at(css, colon) == ':' {
    Some(colon)
  } else {
    None
  }
}
