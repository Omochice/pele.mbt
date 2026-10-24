///|
/// The code units from `start` to `end`, clamped to the string as JavaScript's `slice` does.
pub fn slice(text : String, start : Int32, end? : Int32) -> String {
  let length = text.length()
  let clamp = (i : Int32) => {
    if i < 0 {
      @cmp.maximum(length + i, 0)
    } else {
      @cmp.minimum(i, length)
    }
  }
  let from = clamp(start)
  let to = match end {
    Some(end) => clamp(end)
    None => length
  }
  if from >= to {
    ""
  } else if to - from <= 2 && short_ascii(text, from, to) is Some(short) {
    short
  } else {
    text.unsafe_substring(start=from, end=to)
  }
}

///|
/// The strings of one and of two ASCII code units, each made the first time it is sliced.
let short_ascii_strings : FixedArray[String?] = FixedArray::make(
  128 + 128 * 128,
  None,
)

///|
/// The shared string of the one or two code units from `from` to `to`, when they are ASCII.
/// A lexer slices a token's text for each of tens of millions of one-character tokens, and a
/// string of its own for each would hold several times the source.
fn short_ascii(text : String, from : Int32, to : Int32) -> String? {
  let first = text.unsafe_get(from).to_int()
  guard first < 128 else { return None }
  let index = if to - from == 1 {
    first
  } else {
    let second = text.unsafe_get(from + 1).to_int()
    guard second < 128 else { return None }
    128 + first * 128 + second
  }
  if short_ascii_strings[index] is Some(short) {
    return Some(short)
  }
  let short = text.unsafe_substring(start=from, end=to)
  short_ascii_strings[index] = Some(short)
  Some(short)
}

///|
/// The first index of `needle` at or after `from`, or -1, as `indexOf`.
pub fn index_of(text : String, needle : String, from~ : Int32 = 0) -> Int32 {
  let start = @cmp.maximum(from, 0)
  if start > text.length() {
    return if needle.length() == 0 { text.length() } else { -1 }
  }
  match text.view(start_offset=start).find(needle) {
    Some(at) => start + at
    None => -1
  }
}

///|
/// The last index of `needle` at or before `from`, or -1, as `lastIndexOf`.
pub fn last_index_of(text : String, needle : String, from? : Int32) -> Int32 {
  let limit = match from {
    Some(from) => @cmp.minimum(@cmp.maximum(from, 0), text.length())
    None => text.length()
  }
  let end = @cmp.minimum(limit + needle.length(), text.length())
  match text.view(end_offset=end).rev_find(needle) {
    Some(at) => at
    None => -1
  }
}

///|
/// Whether `text` holds `prefix` at `at`, as `startsWith`.
pub fn starts_with_at(text : String, prefix : String, at : Int32) -> Bool {
  if at < 0 || at + prefix.length() > text.length() {
    return false
  }
  for i in 0..<prefix.length() {
    if text.unsafe_get(at + i).to_int() != prefix.unsafe_get(i).to_int() {
      return false
    }
  }
  true
}

///|
/// The text without leading whitespace, as `trimStart`.
pub fn trim_start(text : String) -> String {
  let mut from = 0
  while from < text.length() && is_space(text.unsafe_get(from).to_int()) {
    from += 1
  }
  slice(text, from)
}

///|
/// The text without trailing whitespace, as `trimEnd`.
pub fn trim_end(text : String) -> String {
  let mut to = text.length()
  while to > 0 && is_space(text.unsafe_get(to - 1).to_int()) {
    to -= 1
  }
  slice(text, 0, end=to)
}

///|
/// The text without surrounding whitespace, as `trim`.
pub fn trim(text : String) -> String {
  trim_start(trim_end(text))
}

///|
/// Turns `\r\n` and lone `\r` into `\n`.
pub fn normalize_line_breaks(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    let c = code_at(text, i)
    if c == '\r'.to_int() {
      out.write_char('\n')
      if code_at(text, i + 1) == '\n'.to_int() {
        i += 1
      }
    } else {
      write_range(out, text, i, i + 1)
    }
    i += 1
  }
  out.to_string()
}

///|
/// Appends the code units of `text` from `from` to `to`.
pub fn write_range(
  out : StringBuilder,
  text : String,
  from : Int32,
  to : Int32,
) -> Unit {
  if from < to {
    out.write_view(text.view(start_offset=from, end_offset=to))
  }
}
