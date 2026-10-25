///|
/// The UTF-16 code unit at `i`, or -1 outside the string.
/// -1 stands in for the NaN that `charCodeAt` gives past the end, which none of the tests below accept.
pub fn code_at(text : String, i : Int32) -> Int32 {
  if i >= 0 && i < text.length() {
    text.unsafe_get(i).to_int()
  } else {
    -1
  }
}

///|
/// The code point at `i` and where the next one starts, reading a surrogate pair as one code point as the `u` flag does.
/// A surrogate that is not half of a pair is a code point of its own.
pub fn code_point_at(text : String, i : Int32) -> (Int32, Int32) {
  let c = code_at(text, i)
  if c >= 0xd800 && c <= 0xdbff {
    let low = code_at(text, i + 1)
    if low >= 0xdc00 && low <= 0xdfff {
      return (0x10000 + ((c - 0xd800) << 10) + (low - 0xdc00), i + 2)
    }
  }
  (c, i + 1)
}

///|
/// Whitespace as JavaScript's `\s` sees it.
pub fn is_space(c : Int32) -> Bool {
  if c < 128 {
    return c == 32 || (c >= 9 && c <= 13)
  }
  c == 0xa0 ||
  c == 0x1680 ||
  (c >= 0x2000 && c <= 0x200a) ||
  c == 0x2028 ||
  c == 0x2029 ||
  c == 0x202f ||
  c == 0x205f ||
  c == 0x3000 ||
  c == 0xfeff
}

///|
/// A space or a tab.
pub fn is_blank(c : Int32) -> Bool {
  c == 32 || c == 9
}

///|
/// A line terminator: what `.` does not match.
pub fn is_line_end(c : Int32) -> Bool {
  c == 10 || c == 13 || c == 0x2028 || c == 0x2029
}

///|
/// An ASCII digit.
pub fn is_digit(c : Int32) -> Bool {
  c >= 48 && c <= 57
}

///|
/// An ASCII letter.
pub fn is_letter(c : Int32) -> Bool {
  (c >= 65 && c <= 90) || (c >= 97 && c <= 122)
}

///|
/// An ASCII hexadecimal digit.
pub fn is_hex(c : Int32) -> Bool {
  (c >= 48 && c <= 57) || (c >= 65 && c <= 70) || (c >= 97 && c <= 102)
}

///|
/// A character of `\w`.
pub fn is_word(c : Int32) -> Bool {
  (c >= 48 && c <= 57) ||
  (c >= 65 && c <= 90) ||
  (c >= 97 && c <= 122) ||
  c == 95
}
