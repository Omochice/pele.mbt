///|
let blank : String = "about:blank"

///|
/// Whether the character at `i` is in `[\u0000-\u001F\u007F-\u009F -‍﻿\uD800-\uDFFF\uFFFE\uFFFF]/u`,
/// which sanitize-url strips, and how many code units it takes.
/// The class reads code points, so only a surrogate that is not half of a pair is in it.
fn ctrl_at(text : String, i : Int32) -> (Bool, Int32) {
  let (c, next) = @util.code_point_at(text, i)
  let ctrl = c <= 0x1f ||
    (c >= 0x7f && c <= 0x9f) ||
    (c >= 0x2000 && c <= 0x200d) ||
    (c >= 0xd800 && c <= 0xdfff) ||
    c == 0xfeff ||
    c == 0xfffe ||
    c == 0xffff
  (ctrl, next - i)
}

///|
fn without_ctrl(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    let (ctrl, width) = ctrl_at(text, i)
    if !ctrl {
      @util.write_range(out, text, i, i + width)
    }
    i += width
  }
  out.to_string()
}

///|
fn has_ctrl(text : String) -> Bool {
  let mut i = 0
  while i < text.length() {
    let (ctrl, width) = ctrl_at(text, i)
    if ctrl {
      return true
    }
    i += width
  }
  false
}

///|
/// The end of `&#(\w+)(^\w|;)?` at `at`, or -1; the `^\w` branch can never match past the start.
fn entity_end(text : String, at : Int32) -> Int32 {
  if !@util.starts_with_at(text, "&#", at) {
    return -1
  }
  let mut e = at + 2
  while @util.is_word(@util.code_at(text, e)) {
    e += 1
  }
  if e == at + 2 {
    return -1
  }
  if @util.code_at(text, e) == ';'.to_int() {
    e + 1
  } else {
    e
  }
}

///|
/// `String.fromCharCode(word)`: the number wrapped to 16 bits, with NaN and infinities as 0.
fn char_code(word : String) -> Int32 {
  let n = @util.to_number(word)
  if n.is_nan() || n.is_inf() {
    return 0
  }
  let wrapped = n.trunc() % 65536.0
  (if wrapped < 0.0 { wrapped + 65536.0 } else { wrapped }).to_int()
}

///|
fn replace_entities(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    let e = entity_end(text, i)
    if e < 0 {
      @util.write_range(out, text, i, i + 1)
      i += 1
      continue
    }
    let mut w = i + 2
    while @util.is_word(@util.code_at(text, w)) {
      w += 1
    }
    out.write_char(char_code(@util.slice(text, i + 2, end=w)).unsafe_to_char())
    i = e
  }
  out.to_string()
}

///|
fn has_entity(text : String) -> Bool {
  for i in 0..<text.length() {
    if entity_end(text, i) >= 0 {
      return true
    }
  }
  false
}

///|
/// The end of `&(newline|tab);` with any letter case at `at`, or -1.
fn ctrl_entity_end(text : String, at : Int32) -> Int32 {
  if @util.code_at(text, at) != '&'.to_int() {
    return -1
  }
  for name in ["newline;", "tab;"] {
    let candidate = @util.slice(text, at + 1, end=at + 1 + name.length())
    if candidate.to_lower() == name {
      return at + 1 + name.length()
    }
  }
  -1
}

///|
/// The end of `(\\|%5[cC])((%(6[eE]|72|74))|[nrt])` at `at`, or -1.
fn ws_escape_end(text : String, at : Int32) -> Int32 {
  let c = @util.code_at(text, at)
  let mut e = if c == '\\'.to_int() {
    at + 1
  } else if c == '%'.to_int() &&
    @util.code_at(text, at + 1) == '5'.to_int() &&
    (
      @util.code_at(text, at + 2) == 'c'.to_int() ||
      @util.code_at(text, at + 2) == 'C'.to_int()
    ) {
    at + 3
  } else {
    return -1
  }
  let d = @util.code_at(text, e)
  if d == '%'.to_int() {
    let x = @util.code_at(text, e + 1)
    let y = @util.code_at(text, e + 2)
    if (x == '6'.to_int() && (y == 'e'.to_int() || y == 'E'.to_int())) ||
      (x == '7'.to_int() && (y == '2'.to_int() || y == '4'.to_int())) {
      return e + 3
    }
    return -1
  }
  if d == 'n'.to_int() || d == 'r'.to_int() || d == 't'.to_int() {
    e += 1
    return e
  }
  -1
}

///|
/// Removes every match that `end_at` finds, scanning left to right as a global replace does.
fn remove_matches(text : String, end_at : (String, Int32) -> Int32) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    let e = end_at(text, i)
    if e < 0 {
      @util.write_range(out, text, i, i + 1)
      i += 1
    } else {
      i = e
    }
  }
  out.to_string()
}

///|
fn has_match(text : String, end_at : (String, Int32) -> Int32) -> Bool {
  for i in 0..<text.length() {
    if end_at(text, i) >= 0 {
      return true
    }
  }
  false
}

///|
fn decode_or_keep(uri : String) -> String {
  match decode_uri_component(uri) {
    Some(decoded) => decoded
    None => uri
  }
}

///|
/// The first match of `/^.+(:|&colon;)/gim`: from the start of the first line holding a colon to its last colon, `.` stopping at line terminators.
fn scheme_match(text : String) -> String? {
  let n = text.length()
  let mut start = 0
  while start < n {
    let mut end = start
    while end < n && !@util.is_line_end(@util.code_at(text, end)) {
      end += 1
    }
    let mut k = end - 1
    while k > start {
      if @util.code_at(text, k) == ':'.to_int() {
        return Some(@util.slice(text, start, end=k + 1))
      }
      if @util.slice(text, k, end=k + 7).to_lower() == "&colon;" {
        return Some(@util.slice(text, start, end=k + 7))
      }
      k -= 1
    }
    start = end + 1
  }
  None
}

///|
/// `toLowerCase` as far as the protocol checks can tell: two capitals outside ASCII lower to ASCII letters.
fn protocol_lower(text : String) -> String {
  let out = StringBuilder()
  for i in 0..<text.length() {
    let c = @util.code_at(text, i)
    if c >= 'A'.to_int() && c <= 'Z'.to_int() {
      out.write_char((c + 32).unsafe_to_char())
    } else if c == 0x130 {
      out.write_string("i\u{307}")
    } else if c == 0x212a {
      out.write_char('k')
    } else {
      @util.write_range(out, text, i, i + 1)
    }
  }
  out.to_string()
}

///|
/// Whether `/^([^\w]*)(javascript|data|vbscript)/im` matches the protocol.
fn is_invalid_protocol(protocol : String) -> Bool {
  let mut i = 0
  while i < protocol.length() && !@util.is_word(@util.code_at(protocol, i)) {
    i += 1
  }
  let rest = @util.slice(protocol, i).to_lower()
  rest.has_prefix("javascript") ||
  rest.has_prefix("data") ||
  rest.has_prefix("vbscript")
}

///|
/// `url` without the control characters, entity codes and escapes that could hide a scheme, and
/// with `percent`, without percent escapes too, or `None` for a URL wrapped too many times to be
/// a real one.
fn unwrap(url : String, percent~ : Bool) -> String? {
  let mut out = if percent {
    decode_or_keep(@util.trim(url))
  } else {
    @util.trim(url)
  }
  let mut rounds = 0
  while true {
    rounds += 1
    if rounds > 32 {
      return None
    }
    out = without_ctrl(out)
    out = replace_entities(out)
    out = remove_matches(out, ctrl_entity_end)
    out = without_ctrl(out)
    out = remove_matches(out, ws_escape_end)
    out = @util.trim(out)
    if percent {
      out = decode_or_keep(out)
    }
    let more = has_ctrl(out) ||
      has_entity(out) ||
      has_match(out, ctrl_entity_end) ||
      has_match(out, ws_escape_end)
    if !more {
      break
    }
  }
  Some(out)
}

///|
/// The click target with what @braintree/sanitize-url, which Mermaid applies to links, refuses
/// turned into `about:blank`, such as a script or data URL.
/// Unlike it, keeps percent escapes, so `file=A%26B` still names the note `A&B`.
pub fn sanitize_url(url : String) -> String {
  if url == "" {
    return blank
  }
  guard unwrap(url, percent=true) is Some(decoded) &&
    decoded != "" &&
    unwrap(url, percent=false) is Some(kept) &&
    kept != "" else {
    return blank
  }
  let first = @util.code_at(decoded, 0)
  if first == '.'.to_int() || first == '/'.to_int() {
    return kept
  }
  guard scheme_match(@util.trim_start(decoded)) is Some(scheme) else {
    return kept
  }
  let protocol = @util.trim(protocol_lower(scheme))
  if is_invalid_protocol(protocol) {
    return blank
  }
  let normalized = @util.trim_start(kept).replace_all(old="\\", new="/")
  if protocol == "mailto:" || protocol.contains("://") {
    return normalized
  }
  if protocol == "http:" || protocol == "https:" {
    return serialize_http_url(normalized).unwrap_or(blank)
  }
  normalized
}
