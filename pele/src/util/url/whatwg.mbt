// A subset of the WHATWG URL parser: what `new URL(input).toString()` gives for an http or https URL without a base.
// sanitizeUrl hands it only text that starts with such a scheme, so other schemes, bases and opaque hosts are left out.

///|
/// The code points of `text`, with each lone surrogate read as U+FFFD as a USVString conversion does.
fn code_points(text : String) -> Array[Int32] {
  let out = []
  let mut i = 0
  while i < text.length() {
    let (c, next) = @util.code_point_at(text, i)
    out.push(if c >= 0xd800 && c <= 0xdfff { 0xfffd } else { c })
    i = next
  }
  out
}

///|
fn utf8_bytes(cp : Int32) -> Array[Int32] {
  if cp < 0x80 {
    [cp]
  } else if cp < 0x800 {
    [0xc0 | (cp >> 6), 0x80 | (cp & 0x3f)]
  } else if cp < 0x10000 {
    [0xe0 | (cp >> 12), 0x80 | ((cp >> 6) & 0x3f), 0x80 | (cp & 0x3f)]
  } else {
    [
      0xf0 | (cp >> 18),
      0x80 | ((cp >> 12) & 0x3f),
      0x80 | ((cp >> 6) & 0x3f),
      0x80 | (cp & 0x3f),
    ]
  }
}

///|
fn hex_digit(d : Int32) -> Char {
  if d < 10 {
    ('0'.to_int() + d).unsafe_to_char()
  } else {
    ('A'.to_int() + d - 10).unsafe_to_char()
  }
}

///|
fn write_code_point(out : StringBuilder, cp : Int32) -> Unit {
  out.write_char(cp.unsafe_to_char())
}

///|
/// Appends `cp`, percent-encoded as UTF-8 when `encoded(cp)`.
fn write_encoded(
  out : StringBuilder,
  cp : Int32,
  encoded : (Int32) -> Bool,
) -> Unit {
  if !encoded(cp) {
    write_code_point(out, cp)
    return
  }
  for byte in utf8_bytes(cp) {
    out.write_char('%')
    out.write_char(hex_digit(byte >> 4))
    out.write_char(hex_digit(byte & 15))
  }
}

///|
fn in_c0_control_set(cp : Int32) -> Bool {
  cp < 0x20 || cp > 0x7e
}

///|
fn in_fragment_set(cp : Int32) -> Bool {
  in_c0_control_set(cp) ||
  cp == ' ' ||
  cp == '"' ||
  cp == '<' ||
  cp == '>' ||
  cp == '`'
}

///|
fn in_special_query_set(cp : Int32) -> Bool {
  in_c0_control_set(cp) ||
  cp == ' ' ||
  cp == '"' ||
  cp == '#' ||
  cp == '<' ||
  cp == '>' ||
  cp == '\''
}

///|
fn in_path_set(cp : Int32) -> Bool {
  in_c0_control_set(cp) ||
  cp == ' ' ||
  cp == '"' ||
  cp == '#' ||
  cp == '<' ||
  cp == '>' ||
  cp == '?' ||
  cp == '^' ||
  cp == '`' ||
  cp == '{' ||
  cp == '}'
}

///|
fn in_userinfo_set(cp : Int32) -> Bool {
  in_path_set(cp) ||
  cp == '/' ||
  cp == ':' ||
  cp == ';' ||
  cp == '=' ||
  cp == '@' ||
  (cp >= '[' && cp <= '^') ||
  cp == '|'
}

///|
fn is_path_end(cp : Int32) -> Bool {
  cp == '/' || cp == '\\' || cp == '?' || cp == '#'
}

///|
fn ascii_lower_code(cp : Int32) -> Int32 {
  if cp >= 'A' && cp <= 'Z' {
    cp + 32
  } else {
    cp
  }
}

///|
fn is_single_dot(segment : String) -> Bool {
  segment == "." || segment.to_lower() == "%2e"
}

///|
fn is_double_dot(segment : String) -> Bool {
  match segment.to_lower() {
    ".." | ".%2e" | "%2e." | "%2e%2e" => true
    _ => false
  }
}

///|
/// What `new URL(input).toString()` gives for an http or https URL, or `None` where the constructor throws.
fn serialize_http_url(input : String) -> String? {
  let all = code_points(input)
  let mut from = 0
  let mut to = all.length()
  while from < to && all[from] <= 0x20 {
    from += 1
  }
  while to > from && all[to - 1] <= 0x20 {
    to -= 1
  }
  let cps = []
  for i in from..<to {
    let cp = all[i]
    if cp != '\t' && cp != '\n' && cp != '\r' {
      cps.push(cp)
    }
  }
  let n = cps.length()
  let at = (i : Int32) => if i < n { cps[i] } else { -1 }
  guard n > 0 && @util.is_letter(cps[0]) else { return None }
  let mut p = 1
  while p < n &&
        (
          @util.is_letter(cps[p]) ||
          @util.is_digit(cps[p]) ||
          cps[p] == '+' ||
          cps[p] == '-' ||
          cps[p] == '.'
        ) {
    p += 1
  }
  guard at(p) == ':' else { return None }
  let scheme = StringBuilder()
  for i in 0..<p {
    write_code_point(scheme, ascii_lower_code(cps[i]))
  }
  let scheme = scheme.to_string()
  let default_port = match scheme {
    "http" => 80
    "https" => 443
    _ => return None
  }
  p += 1
  while at(p) == '/' || at(p) == '\\' {
    p += 1
  }
  let authority_start = p
  while p < n && !is_path_end(cps[p]) {
    p += 1
  }
  let authority_end = p
  let mut last_at = -1
  for i in authority_start..<authority_end {
    if cps[i] == '@' {
      last_at = i
    }
  }
  let username = StringBuilder()
  let password = StringBuilder()
  let mut host_start = authority_start
  if last_at >= 0 {
    let mut in_password = false
    for i in authority_start..<last_at {
      let cp = cps[i]
      if cp == ':' && !in_password {
        in_password = true
        continue
      }
      write_encoded(
        if in_password {
          password
        } else {
          username
        },
        cp,
        in_userinfo_set,
      )
    }
    host_start = last_at + 1
    if host_start == authority_end {
      return None
    }
  }
  let mut host_end = authority_end
  let mut inside_brackets = false
  for i in host_start..<authority_end {
    let cp = cps[i]
    if cp == '[' {
      inside_brackets = true
    } else if cp == ']' {
      inside_brackets = false
    } else if cp == ':' && !inside_brackets {
      host_end = i
      break
    }
  }
  if host_end == host_start {
    return None
  }
  let host_text = StringBuilder()
  for i in host_start..<host_end {
    write_code_point(host_text, cps[i])
  }
  guard parse_host(host_text.to_string()) is Some(host) else { return None }
  let mut port = ""
  if host_end < authority_end {
    let mut value = 0
    for i in (host_end + 1)..<authority_end {
      guard @util.is_digit(cps[i]) else { return None }
      value = value * 10 + (cps[i] - '0')
      if value > 65535 {
        return None
      }
    }
    if host_end + 1 < authority_end && value != default_port {
      port = value.to_string()
    }
  }
  if at(p) == '/' || at(p) == '\\' {
    p += 1
  }
  let path : Array[String] = []
  let segment = StringBuilder()
  while true {
    let cp = at(p)
    if cp == -1 || is_path_end(cp) {
      let buffer = segment.to_string()
      segment.reset()
      let slash = cp == '/' || cp == '\\'
      if is_double_dot(buffer) {
        ignore(path.pop())
        if !slash {
          path.push("")
        }
      } else if is_single_dot(buffer) {
        if !slash {
          path.push("")
        }
      } else {
        path.push(buffer)
      }
      if !slash {
        break
      }
    } else {
      write_encoded(segment, cp, in_path_set)
    }
    p += 1
  }
  let out = StringBuilder()
  out.write_string(scheme)
  out.write_string("://")
  let username = username.to_string()
  let password = password.to_string()
  if username != "" || password != "" {
    out.write_string(username)
    if password != "" {
      out.write_char(':')
      out.write_string(password)
    }
    out.write_char('@')
  }
  out.write_string(host)
  if port != "" {
    out.write_char(':')
    out.write_string(port)
  }
  for part in path {
    out.write_char('/')
    out.write_string(part)
  }
  if at(p) == '?' {
    out.write_char('?')
    p += 1
    while p < n && cps[p] != '#' {
      write_encoded(out, cps[p], in_special_query_set)
      p += 1
    }
  }
  if at(p) == '#' {
    out.write_char('#')
    p += 1
    while p < n {
      write_encoded(out, cps[p], in_fragment_set)
      p += 1
    }
  }
  Some(out.to_string())
}
