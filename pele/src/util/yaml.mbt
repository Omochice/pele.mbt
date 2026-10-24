// A small YAML reader covering what Mermaid feeds to js-yaml with the JSON schema:
// block and flow collections, quoted and plain scalars, and block scalars.

///|
/// YAML text that the reader rejects, with js-yaml's message.
pub(all) suberror YamlError {
  YamlError(String)
}

///|
/// A quoted scalar or flow collection that runs past the text read so far.
priv suberror Incomplete {
  Incomplete(String)
}

///|
const MAX_DEPTH : Int32 = 64

///|
priv struct Reader {
  lines : Array[String]
  mut i : Int32
}

///|
fn Reader::new(source : String) -> Reader {
  let normalized = if source.contains("\r") {
    normalize_line_breaks(source)
  } else {
    source
  }
  {
    lines: normalized.split("\n").map(line => line.to_owned()).to_array(),
    i: 0,
  }
}

///|
fn Reader::skip_blank(self : Reader) -> Unit {
  while self.i < self.lines.length() {
    let t = trim(self.lines[self.i])
    if t != "" && code_at(t, 0) != '#'.to_int() && t != "---" {
      break
    }
    self.i += 1
  }
}

///|
fn Reader::indent(self : Reader) -> Int32 raise YamlError {
  let line = self.lines[self.i]
  let mut k = 0
  while k < line.length() && code_at(line, k) == ' '.to_int() {
    k += 1
  }
  if code_at(line, k) == '\t'.to_int() {
    raise YamlError("YAML: tabs are not allowed for indentation")
  }
  k
}

///|
fn yaml_blank(c : Int32) -> Bool {
  c == ' '.to_int() ||
  c == '\t'.to_int() ||
  c == '\n'.to_int() ||
  c == '\r'.to_int()
}

///|
fn key_start(c : Int32) -> Bool {
  is_space(c) || "#:,[]{}&*!|>'\"%@`".contains_code_unit(c.to_uint16())
}

///|
/// Splits `key: rest` at the start of a line into the raw key and the offset where the value starts.
fn split_key(line : String) -> (String, Int32)? {
  let first = code_at(line, 0)
  let mut end = 0
  let mut colon = 0
  if first == '"'.to_int() || first == '\''.to_int() {
    let mut i = 1
    while true {
      if i >= line.length() {
        return None
      }
      let c = code_at(line, i)
      if first == '"'.to_int() && c == '\\'.to_int() {
        i += 2
      } else if c == first {
        if first == '"'.to_int() || code_at(line, i + 1) != '\''.to_int() {
          break
        }
        i += 2
      } else {
        i += 1
      }
    }
    end = i + 1
    colon = end
    while yaml_blank(code_at(line, colon)) {
      colon += 1
    }
    if code_at(line, colon) != ':'.to_int() {
      return None
    }
  } else {
    if first == -1 || key_start(first) {
      return None
    }
    if first == '-'.to_int() {
      let next = code_at(line, 1)
      if line.length() < 2 ||
        yaml_blank(next) ||
        next == ':'.to_int() ||
        next == '#'.to_int() {
        return None
      }
    }
    colon = 1
    while colon < line.length() &&
          code_at(line, colon) != ':'.to_int() &&
          code_at(line, colon) != '#'.to_int() {
      colon += 1
    }
    if code_at(line, colon) != ':'.to_int() {
      return None
    }
    end = colon
    while yaml_blank(code_at(line, end - 1)) {
      end -= 1
    }
  }
  let mut length = colon + 1
  if length < line.length() && !yaml_blank(code_at(line, length)) {
    return None
  }
  while yaml_blank(code_at(line, length)) {
    length += 1
  }
  Some((slice(line, 0, end~), length))
}

///|
fn digits_from(s : String, from : Int32, accept : (Int32) -> Bool) -> Int32 {
  let mut i = from
  while accept(code_at(s, i)) {
    i += 1
  }
  i
}

///|
fn sign_length(s : String) -> Int32 {
  let c = code_at(s, 0)
  if c == '-'.to_int() || c == '+'.to_int() {
    1
  } else {
    0
  }
}

///|
fn is_int(s : String) -> Bool {
  let from = sign_length(s)
  if code_at(s, from) == '0'.to_int() {
    return from + 1 == s.length()
  }
  let end = digits_from(s, from, is_digit)
  end > from && end == s.length()
}

///|
fn is_float(s : String) -> Bool {
  let from = sign_length(s)
  let mut i = from
  if is_digit(code_at(s, i)) {
    i = digits_from(s, i, is_digit)
    if code_at(s, i) == '.'.to_int() {
      i = digits_from(s, i + 1, is_digit)
    }
  } else if code_at(s, i) == '.'.to_int() && is_digit(code_at(s, i + 1)) {
    i = digits_from(s, i + 1, is_digit)
  } else {
    return false
  }
  let e = code_at(s, i)
  if e == 'e'.to_int() || e == 'E'.to_int() {
    let mut j = i + 1
    let sign = code_at(s, j)
    if sign == '-'.to_int() || sign == '+'.to_int() {
      j += 1
    }
    let stop = digits_from(s, j, is_digit)
    if stop == j {
      return false
    }
    i = stop
  }
  i == s.length()
}

///|
/// The base of a `0x`, `0o`, or `0b` literal, or 0.
fn radix_of(s : String) -> Int32 {
  let from = sign_length(s)
  if code_at(s, from) != '0'.to_int() {
    return 0
  }
  let marker = code_at(s, from + 1)
  let (base, accept) : (Int32, (Int32) -> Bool) = if marker == 'x'.to_int() {
    (16, is_hex)
  } else if marker == 'o'.to_int() {
    (8, c => c >= '0'.to_int() && c <= '7'.to_int())
  } else if marker == 'b'.to_int() {
    (2, c => c == '0'.to_int() || c == '1'.to_int())
  } else {
    return 0
  }
  let end = digits_from(s, from + 2, accept)
  if end > from + 2 && end == s.length() {
    base
  } else {
    0
  }
}

///|
fn digit_value(c : Int32) -> Int32 {
  if c <= '9'.to_int() {
    c - '0'.to_int()
  } else if c >= 'a'.to_int() {
    c - 'a'.to_int() + 10
  } else {
    c - 'A'.to_int() + 10
  }
}

///|
/// The value of a decimal literal that `is_int` or `is_float` accepted, as `Number()` reads it.
fn decimal_value(s : String) -> Double {
  let negative = code_at(s, 0) == '-'.to_int()
  let mut body = slice(s, sign_length(s))
  if code_at(body, 0) == '.'.to_int() {
    body = "0" + body
  }
  let value = @string.parse_double(body) catch { _ => @double.not_a_number }
  if negative {
    -value
  } else {
    value
  }
}

///|
fn scalar(raw : String) -> Json {
  let s = trim(raw)
  match s {
    "" | "~" | "null" | "Null" | "NULL" => return Json::null()
    "true" | "True" | "TRUE" => return Json::boolean(true)
    "false" | "False" | "FALSE" => return Json::boolean(false)
    _ => ()
  }
  let c = code_at(s, 0)
  if c != '-'.to_int() && c != '+'.to_int() && c != '.'.to_int() && !is_digit(c) {
    return Json::string(s)
  }
  if is_int(s) || is_float(s) {
    return Json::number(decimal_value(s))
  }
  let base = radix_of(s)
  if base > 0 {
    let from = sign_length(s) + 2
    let mut value = 0.0
    for i in from..<s.length() {
      value = value * base.to_double() + digit_value(code_at(s, i)).to_double()
    }
    return Json::number(if c == '-'.to_int() { -value } else { value })
  }
  let unsigned = slice(s, sign_length(s))
  if unsigned is (".inf" | ".Inf" | ".INF") {
    return Json::number(
      if c == '-'.to_int() {
        @double.neg_infinity
      } else {
        @double.infinity
      },
    )
  }
  if s is (".nan" | ".NaN" | ".NAN") {
    return Json::number(@double.not_a_number)
  }
  Json::string(s)
}

///|
fn escape_of(c : Int32) -> String? {
  if c < 0 {
    return None
  }
  match c.unsafe_to_char() {
    '0' => Some("\u{0}")
    'a' => Some("\u{7}")
    'b' => Some("\u{8}")
    't' => Some("\t")
    'n' => Some("\n")
    'v' => Some("\u{b}")
    'f' => Some("\u{c}")
    'r' => Some("\r")
    'e' => Some("\u{1b}")
    ' ' => Some(" ")
    '"' => Some("\"")
    '/' => Some("/")
    '\\' => Some("\\")
    'N' => Some("\u{85}")
    '_' => Some("\u{a0}")
    'L' => Some("\u{2028}")
    'P' => Some("\u{2029}")
    _ => None
  }
}

///|
/// Folds the line breaks of a scalar: blanks around a break go, one break becomes a space, and
/// each further break stays.
fn fold(text : String) -> String {
  if !text.contains("\n") {
    return text
  }
  let lines = text.split("\n").map(line => line.to_owned()).to_array()
  let last = lines.length() - 1
  for i in 0..<=last {
    let line = lines[i]
    let mut from = 0
    let mut to = line.length()
    if i > 0 {
      while from < to && is_blank(code_at(line, from)) {
        from += 1
      }
    }
    if i < last {
      while to > from && is_blank(code_at(line, to - 1)) {
        to -= 1
      }
    }
    lines[i] = slice(line, from, end=to)
  }
  let joined = lines.join("\n")
  let out = StringBuilder()
  let mut i = 0
  while i < joined.length() {
    if code_at(joined, i) == '\n'.to_int() {
      let start = i
      while code_at(joined, i) == '\n'.to_int() {
        i += 1
      }
      let run = i - start
      out.write_string(if run == 1 { " " } else { "\n".repeat(run - 1) })
    } else {
      write_range(out, joined, i, i + 1)
      i += 1
    }
  }
  out.to_string()
}

///|
/// Removes escaped line breaks with the blanks after them.
fn join_escaped_breaks(body : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < body.length() {
    if code_at(body, i) == '\\'.to_int() &&
      code_at(body, i + 1) == '\n'.to_int() {
      i += 2
      while code_at(body, i) == ' '.to_int() ||
            code_at(body, i) == '\t'.to_int() {
        i += 1
      }
    } else {
      write_range(out, body, i, i + 1)
      i += 1
    }
  }
  out.to_string()
}

///|
/// The code point of the hex digits `parseInt` reads at the start of `digits`.
fn hex_code_point(digits : String) -> Int32 raise YamlError {
  let mut value = 0
  let mut read = 0
  while read < digits.length() && is_hex(code_at(digits, read)) {
    value = value * 16 + digit_value(code_at(digits, read))
    read += 1
  }
  if read == 0 {
    raise YamlError("Invalid code point NaN")
  }
  if value > 0x10ffff {
    raise YamlError("Invalid code point \{value}")
  }
  value
}

///|
fn unquote_double(body : String) -> String raise YamlError {
  if !body.contains("\\") {
    return fold(body)
  }
  let s = fold(join_escaped_breaks(body))
  let out = StringBuilder()
  let mut i = 0
  while i < s.length() {
    let c = code_at(s, i)
    if c != '\\'.to_int() {
      write_range(out, s, i, i + 1)
      i += 1
      continue
    }
    i += 1
    let e = code_at(s, i)
    if e == 'x'.to_int() || e == 'u'.to_int() || e == 'U'.to_int() {
      let length = if e == 'x'.to_int() {
        2
      } else if e == 'u'.to_int() {
        4
      } else {
        8
      }
      let point = hex_code_point(slice(s, i + 1, end=i + 1 + length))
      out.write_char(Int32::unsafe_to_char(point))
      i += length + 1
    } else {
      match escape_of(e) {
        Some(text) => out.write_string(text)
        None => raise YamlError("YAML: unknown escape sequence")
      }
      i += 1
    }
  }
  out.to_string()
}

///|
fn skip(s : String, from : Int32, commas : Bool) -> Int32 {
  let mut pos = from
  while pos < s.length() {
    let c = code_at(s, pos)
    if c == ' '.to_int() ||
      c == '\n'.to_int() ||
      c == '\t'.to_int() ||
      c == '\r'.to_int() ||
      (commas && c == ','.to_int()) {
      pos += 1
    } else if c == '#'.to_int() && (pos == 0 || is_space(code_at(s, pos - 1))) {
      let nl = index_of(s, "\n", from=pos)
      pos = if nl == -1 { s.length() } else { nl }
    } else {
      break
    }
  }
  pos
}

///|
/// Entries of a flow collection are separated by exactly one comma, as js-yaml requires.
fn entry_start(c : Int32, separated : Bool) -> Unit raise YamlError {
  if !separated {
    raise YamlError("YAML: missed comma between flow collection entries")
  }
  if c == ','.to_int() {
    raise YamlError("YAML: expected the node content, but found ','")
  }
}

///|
fn flow_stop(c : Int32) -> Bool {
  is_space(c) ||
  c == ','.to_int() ||
  c == '['.to_int() ||
  c == ']'.to_int() ||
  c == '{'.to_int() ||
  c == '}'.to_int()
}

///|
/// Parses a flow value starting at `from`; returns the value and the index after it.
fn flow(
  s : String,
  from : Int32,
  stops : String,
  depth~ : Int32 = 0,
) -> (Json, Int32) raise {
  if depth > MAX_DEPTH {
    raise YamlError("YAML: nesting is too deep")
  }
  let mut pos = skip(s, from, false)
  let ch = code_at(s, pos)
  if ch == '{'.to_int() {
    let out : Map[String, Json] = Map([])
    pos += 1
    let mut separated = true
    while true {
      pos = skip(s, pos, false)
      if pos >= s.length() {
        raise Incomplete(
          "YAML: unexpected end of the stream within a flow collection",
        )
      }
      if code_at(s, pos) == '}'.to_int() {
        return (Json::object(out), pos + 1)
      }
      entry_start(code_at(s, pos), separated)
      let (key, after_key) = flow(s, pos, ":,}", depth=depth + 1)
      pos = skip(s, after_key, false)
      let mut value = Json::null()
      if code_at(s, pos) == ':'.to_int() {
        let (parsed, after) = flow(s, pos + 1, ",}", depth=depth + 1)
        value = parsed
        pos = after
      }
      out[js_string(key)] = value
      pos = skip(s, pos, false)
      separated = code_at(s, pos) == ','.to_int()
      if separated {
        pos += 1
      }
    }
  }
  if ch == '['.to_int() {
    let out : Array[Json] = []
    pos += 1
    let mut separated = true
    while true {
      pos = skip(s, pos, false)
      if pos >= s.length() {
        raise Incomplete(
          "YAML: unexpected end of the stream within a flow collection",
        )
      }
      if code_at(s, pos) == ']'.to_int() {
        return (Json::array(out), pos + 1)
      }
      entry_start(code_at(s, pos), separated)
      let (value, after) = flow(s, pos, ",]", depth=depth + 1)
      out.push(value)
      pos = skip(s, after, false)
      separated = code_at(s, pos) == ','.to_int()
      if separated {
        pos += 1
      }
    }
  }
  if ch == '"'.to_int() {
    let mut end = pos + 1
    while end < s.length() && code_at(s, end) != '"'.to_int() {
      end += if code_at(s, end) == '\\'.to_int() { 2 } else { 1 }
    }
    if end >= s.length() {
      raise Incomplete(
        "YAML: unexpected end of the stream within a double quoted scalar",
      )
    }
    return (Json::string(unquote_double(slice(s, pos + 1, end~))), end + 1)
  }
  if ch == '\''.to_int() {
    let mut end = pos + 1
    while end < s.length() {
      if code_at(s, end) == '\''.to_int() {
        if code_at(s, end + 1) != '\''.to_int() {
          break
        }
        end += 1
      }
      end += 1
    }
    if end >= s.length() {
      raise Incomplete(
        "YAML: unexpected end of the stream within a single quoted scalar",
      )
    }
    let text = fold(slice(s, pos + 1, end~)).replace_all(old="''", new="'")
    return (Json::string(text), end + 1)
  }
  let mut end = pos
  while end < s.length() {
    let c = code_at(s, end)
    if stops.contains_code_unit(c.to_uint16()) &&
      (
        c != ':'.to_int() ||
        end + 1 >= s.length() ||
        flow_stop(code_at(s, end + 1))
      ) {
      break
    }
    if c == '#'.to_int() && end > pos && is_space(code_at(s, end - 1)) {
      let nl = index_of(s, "\n", from=end)
      return (
        scalar(fold(trim(slice(s, pos, end~)))),
        if nl == -1 {
          s.length()
        } else {
          nl
        },
      )
    }
    end += 1
  }
  (scalar(fold(trim(slice(s, pos, end~)))), end)
}

///|
fn strip_comment(s : String) -> String {
  let mut quote = -1
  let mut i = 0
  while i < s.length() {
    let c = code_at(s, i)
    if quote != -1 {
      if c == '\\'.to_int() && quote == '"'.to_int() {
        i += 1
      } else if c == quote {
        quote = -1
      }
    } else if c == '"'.to_int() || c == '\''.to_int() {
      quote = c
    } else if c == '#'.to_int() && (i == 0 || is_blank(code_at(s, i - 1))) {
      return slice(s, 0, end=i)
    }
    i += 1
  }
  s
}

///|
fn leading_space(line : String) -> Int32 {
  line.length() - trim_start(line).length()
}

///|
fn starts_blank(line : String) -> Bool {
  is_blank(code_at(line, 0))
}

///|
fn block_scalar(r : Reader, header : String, parent_indent : Int32) -> String {
  let folded = code_at(header, 0) == '>'.to_int()
  let chomp = if header.contains("-") {
    "-"
  } else if header.contains("+") {
    "+"
  } else {
    ""
  }
  let mut indent = -1
  for i in 0..<header.length() {
    let c = code_at(header, i)
    if c >= '1'.to_int() && c <= '9'.to_int() {
      indent = parent_indent + c - '0'.to_int()
      break
    }
  }
  let out : Array[String] = []
  while r.i < r.lines.length() {
    let line = r.lines[r.i]
    if trim(line) == "" {
      out.push("")
      r.i += 1
      continue
    }
    let k = leading_space(line)
    if indent == -1 {
      if k <= parent_indent {
        break
      }
      indent = k
    }
    if k < indent {
      break
    }
    out.push(slice(line, indent))
    r.i += 1
  }
  let mut trailing = 0
  while out.length() > 0 && out[out.length() - 1] == "" {
    out.pop() |> ignore
    trailing += 1
  }
  let text = if folded {
    let buf = StringBuilder()
    for i, cur in out {
      if i > 0 {
        let prev = out[i - 1]
        if cur == "" {
          buf.write_string("\n")
        } else if prev != "" {
          buf.write_string(
            if starts_blank(prev) || starts_blank(cur) {
              "\n"
            } else {
              " "
            },
          )
        }
      }
      buf.write_string(cur)
    }
    buf.to_string()
  } else {
    out.join("\n")
  }
  if out.length() == 0 {
    return if chomp == "+" { "\n".repeat(trailing) } else { "" }
  }
  match chomp {
    "-" => text
    "+" => text + "\n".repeat(trailing + 1)
    _ => text + "\n"
  }
}

///|
/// Whether `rest` is a block scalar header: `[|>][-+0-9]*\s*(?:#.*)?$`.
fn is_block_header(rest : String) -> Bool {
  let mut i = 1
  while code_at(rest, i) == '-'.to_int() ||
        code_at(rest, i) == '+'.to_int() ||
        is_digit(code_at(rest, i)) {
    i += 1
  }
  while is_space(code_at(rest, i)) {
    i += 1
  }
  if i == rest.length() {
    return true
  }
  if code_at(rest, i) != '#'.to_int() {
    return false
  }
  for k in (i + 1)..<rest.length() {
    if is_line_end(code_at(rest, k)) {
      return false
    }
  }
  true
}

///|
fn count_breaks(text : String, before : Int32) -> Int32 {
  let mut used = 0
  let mut k = index_of(text, "\n")
  while k != -1 && k < before {
    used += 1
    k = index_of(text, "\n", from=k + 1)
  }
  used
}

///|
fn inline_value(r : Reader, rest : String, indent : Int32) -> Json raise {
  let first = code_at(rest, 0)
  if (first == '|'.to_int() || first == '>'.to_int()) && is_block_header(rest) {
    return Json::string(block_scalar(r, rest, indent))
  }
  if first == '{'.to_int() ||
    first == '['.to_int() ||
    first == '"'.to_int() ||
    first == '\''.to_int() {
    // The value may continue on later lines. Read them in growing batches until it closes.
    let start = r.i
    let mut text = rest
    let mut taken = 0
    let mut batch = 1
    while true {
      let attempt : Result[(Json, Int32), String] = Ok(flow(text, 0, "")) catch {
        Incomplete(message) => Err(message)
        error => raise error
      }
      guard attempt is Ok((value, end)) else {
        if start + taken >= r.lines.length() {
          raise YamlError(attempt.unwrap_err())
        }
        let stop = @cmp.minimum(start + taken + batch, r.lines.length())
        let more = r.lines[start + taken:stop]
        text = text + "\n" + more.join("\n")
        taken += more.length()
        batch *= 2
        continue
      }
      let used = count_breaks(text, end)
      let line_end = index_of(text, "\n", from=end)
      let after = slice(
        text,
        end,
        end=if line_end == -1 { text.length() } else { line_end },
      )
      if trim(strip_comment(after)) != "" {
        raise YamlError("YAML: unexpected content after a value")
      }
      r.i = start + used
      return value
    }
  }
  let mut text = trim(strip_comment(rest))
  while r.i < r.lines.length() {
    let line = r.lines[r.i]
    if trim(line) == "" {
      let mut j = r.i
      while j < r.lines.length() && trim(r.lines[j]) == "" {
        j += 1
      }
      if j >= r.lines.length() || leading_space(r.lines[j]) <= indent {
        break
      }
      text = text + "\n".repeat(j - r.i)
      r.i = j
      continue
    }
    if leading_space(line) <= indent {
      break
    }
    let more = trim(strip_comment(line))
    text = text + (if text.has_suffix("\n") { "" } else { " " }) + more
    r.i += 1
  }
  scalar(text)
}

///|
fn is_sequence_entry(line : String) -> Bool {
  line == "-" || line.has_prefix("- ")
}

///|
fn block(r : Reader, min_indent : Int32, depth~ : Int32 = 0) -> Json raise {
  if depth > MAX_DEPTH {
    raise YamlError("YAML: nesting is too deep")
  }
  r.skip_blank()
  if r.i >= r.lines.length() {
    return Json::null()
  }
  let indent = r.indent()
  if indent < min_indent {
    return Json::null()
  }
  let line = slice(r.lines[r.i], indent)
  if is_sequence_entry(line) {
    let out : Array[Json] = []
    while r.i < r.lines.length() {
      r.skip_blank()
      if r.i >= r.lines.length() || r.indent() != indent {
        break
      }
      let cur = slice(r.lines[r.i], indent)
      if !is_sequence_entry(cur) {
        break
      }
      let rest = slice(cur, 1)
      let pad = leading_space(rest) + 1
      let body = trim(strip_comment(rest))
      if body == "" {
        r.i += 1
        out.push(block(r, indent + 1, depth=depth + 1))
      } else if split_key(body) is Some(_) {
        r.lines[r.i] = " ".repeat(indent + pad) + trim_start(rest)
        out.push(block(r, indent + pad, depth=depth + 1))
      } else {
        r.i += 1
        out.push(inline_value(r, trim(rest), indent))
      }
    }
    return Json::array(out)
  }
  if split_key(line) is None {
    r.i += 1
    return inline_value(r, trim(line), indent - 1)
  }
  let out : Map[String, Json] = Map([])
  while r.i < r.lines.length() {
    r.skip_blank()
    if r.i >= r.lines.length() {
      break
    }
    let k = r.indent()
    if k < indent {
      break
    }
    if k > indent {
      raise YamlError("YAML: bad indentation of a mapping entry")
    }
    let cur = slice(r.lines[r.i], indent)
    guard split_key(cur) is Some((raw_key, length)) else {
      raise YamlError("YAML: can not read a block mapping entry")
    }
    let key = js_string(flow(raw_key, 0, "").0)
    let rest = slice(cur, length)
    r.i += 1
    if trim(strip_comment(rest)) == "" {
      r.skip_blank()
      if r.i < r.lines.length() {
        let next = r.indent()
        let next_line = slice(r.lines[r.i], next)
        let seq = is_sequence_entry(next_line)
        out[key] = if next > indent || (seq && next == indent) {
          block(r, if seq { indent } else { indent + 1 }, depth=depth + 1)
        } else {
          Json::null()
        }
      } else {
        out[key] = Json::null()
      }
    } else {
      out[key] = inline_value(r, trim(rest), indent)
    }
  }
  Json::object(out)
}

///|
fn parse_document(source : String) -> Json raise {
  let trimmed = trim(source)
  let first = code_at(trimmed, 0)
  if first == '{'.to_int() || first == '['.to_int() {
    let (value, end) = flow(trimmed, 0, "") catch {
      Incomplete(message) => raise YamlError(message)
      error => raise error
    }
    if skip(trimmed, end, false) == trimmed.length() {
      return value
    }
  }
  let r = Reader::new(source)
  let value = block(r, 0)
  r.skip_blank()
  if r.i < r.lines.length() && trim(r.lines[r.i]) != "..." {
    raise YamlError(
      "YAML: end of the stream or a document separator is expected",
    )
  }
  value
}

///|
/// Reads YAML as Mermaid does with js-yaml's JSON schema.
/// Raises `YamlError` with js-yaml's message for text it rejects.
pub fn parse_yaml(source : String) -> Json raise YamlError {
  parse_document(source) catch {
    YamlError(message) => raise YamlError(message)
    Incomplete(message) => raise YamlError(message)
    error => raise YamlError(error.to_string())
  }
}
