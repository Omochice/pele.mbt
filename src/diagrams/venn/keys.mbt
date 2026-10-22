///|
fn json_quote(text : String) -> String {
  let out = StringBuilder()
  out.write_char('"')
  let mut i = 0
  while i < text.length() {
    let c = @util.code_at(text, i)
    if c == 34 {
      out.write_string("\\\"")
    } else if c == 92 {
      out.write_string("\\\\")
    } else if c == 8 {
      out.write_string("\\b")
    } else if c == 12 {
      out.write_string("\\f")
    } else if c == 10 {
      out.write_string("\\n")
    } else if c == 13 {
      out.write_string("\\r")
    } else if c == 9 {
      out.write_string("\\t")
    } else if c < 32 || is_lone_surrogate(text, i) {
      out.write_string("\\u" + hex4(c))
    } else {
      @util.write_range(out, text, i, i + 1)
    }
    i += 1
  }
  out.write_char('"')
  out.to_string()
}

///|
fn is_lone_surrogate(text : String, i : Int32) -> Bool {
  let c = @util.code_at(text, i)
  if c >= 0xd800 && c <= 0xdbff {
    let next = @util.code_at(text, i + 1)
    return !(next >= 0xdc00 && next <= 0xdfff)
  }
  if c >= 0xdc00 && c <= 0xdfff {
    let before = @util.code_at(text, i - 1)
    return !(before >= 0xd800 && before <= 0xdbff)
  }
  false
}

///|
fn hex4(c : Int32) -> String {
  let digits = "0123456789abcdef"
  let out = StringBuilder()
  for shift in [12, 8, 4, 0] {
    out.write_char(digits.get_char((c >> shift) & 15).unwrap())
  }
  out.to_string()
}

///|
/// `JSON.stringify(ids)`, which pele uses to key a list of ids.
fn json_key(ids : Array[String]) -> String {
  "[" + ids.map(json_quote).join(",") + "]"
}

///|
/// One key for a list of set ids. Ids may hold any character, so they are not simply joined.
fn key_of(ids : Array[String]) -> String {
  if ids.length() == 1 {
    ids[0]
  } else {
    json_key(ids)
  }
}

///|
/// The key of a list of ids as `JSON.stringify([...ids].sort())` makes it.
fn sorted_key(ids : Array[String]) -> String {
  let sorted = ids.copy()
  sorted.sort()
  json_key(sorted)
}
