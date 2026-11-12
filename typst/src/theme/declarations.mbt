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
  let pieces : Array[StringView] = []
  let mut changed = false
  let mut run_start = -1
  let mut start = 0
  while true {
    let end = declaration_end(css, start)
    let decision = decide(start, end)
    if decision is Keep {
      if run_start < 0 {
        run_start = start
      }
    } else {
      changed = true
      if run_start >= 0 {
        pieces.push(css.unsafe_view(start=run_start, end=start - 1))
        run_start = -1
      }
      if decision is Replace(text) {
        pieces.push(text.unsafe_view(start=0, end=text.length()))
      }
    }
    if end >= css.length() {
      break
    }
    start = end + 1
  }
  if !changed {
    return css
  }
  if run_start >= 0 {
    pieces.push(css.unsafe_view(start=run_start, end=css.length()))
  }
  // Not a `StringBuilder` of the final size, because its `to_string` copies the buffer.
  // A style near the port's hold limit would then be held three times over, as the style, the buffer and the copy.
  // A lone piece is joined as its two halves, because `join` copies a lone piece through a buffer of bytes, which holds it three times over as well.
  if pieces is [piece] {
    let half = piece.length() / 2
    return [
      piece.unsafe_view(start=0, end=half),
      piece.unsafe_view(start=half, end=piece.length()),
    ].join("")
  }
  pieces.join(";")
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
