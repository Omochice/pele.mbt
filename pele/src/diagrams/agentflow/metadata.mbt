///|
/// Whether a JavaScript object would list the key among its integer keys, ahead of the others.
fn is_index_key(key : String) -> Bool {
  let n = key.length()
  if n == 0 || n > 10 {
    return false
  }
  if n > 1 && @util.code_at(key, 0) == '0' {
    return false
  }
  let mut value = 0.0
  for i in 0..<n {
    let c = @util.code_at(key, i)
    if c < '0' || c > '9' {
      return false
    }
    value = value * 10 + (c - '0').to_double()
  }
  value <= 4294967294.0
}

///|
/// The keys in the order a JavaScript object lists them: integer keys ascending, then the rest as they were added.
fn js_keys(fields : Map[String, Json]) -> Array[String] {
  let indexes = []
  let others = []
  for key, _ in fields {
    if is_index_key(key) {
      indexes.push(key)
    } else {
      others.push(key)
    }
  }
  indexes.sort_by((a, b) => {
    if a.length() != b.length() {
      a.length().compare(b.length())
    } else {
      a.compare(b)
    }
  })
  indexes + others
}

///|
fn empty_copy(value : Json) -> Json {
  match value {
    Array(_) => Json::array([])
    Object(_) => Json::object(Map([]))
    _ => value
  }
}

///|
/// A copy without `__proto__`, `constructor` and `prototype` keys at any level, so that a consumer merging metadata into its own objects cannot be made to pollute a prototype.
/// Objects list their keys as JavaScript would, and the walk keeps its own stack, as nesting depth is up to the author.
fn strip_prototype_keys(root : Json) -> Json {
  let out = empty_copy(root)
  let pending = [(root, out)]
  while pending.pop() is Some((from, to)) {
    match (from, to) {
      (Array(items), Array(copies)) =>
        for entry in items {
          let next = empty_copy(entry)
          copies.push(next)
          if entry is (Array(_) | Object(_)) {
            pending.push((entry, next))
          }
        }
      (Object(fields), Object(copies)) =>
        for key in js_keys(fields) {
          if key == "__proto__" || key == "constructor" || key == "prototype" {
            continue
          }
          let entry = fields[key]
          let next = empty_copy(entry)
          copies[key] = next
          if entry is (Array(_) | Object(_)) {
            pending.push((entry, next))
          }
        }
      _ => ()
    }
  }
  out
}

///|
/// Adds what a metadata block holds to an element's metadata.
/// Mermaid spreads the parsed YAML whatever it is, so a list adds its indexes as keys and a string its characters.
fn merge_metadata(into : Map[String, Json]?, doc : Json) -> Map[String, Json] {
  let merged : Map[String, Json] = Map([])
  if into is Some(fields) {
    for key, value in fields {
      merged[key] = value
    }
  }
  match doc {
    Object(fields) =>
      for key in js_keys(fields) {
        merged[key] = fields[key]
      }
    Array(items) =>
      for i, item in items {
        merged[i.to_string()] = item
      }
    String(text) =>
      for i in 0..<text.length() {
        merged[i.to_string()] = Json::string(@util.slice(text, i, end=i + 1))
      }
    _ => ()
  }
  let ordered : Map[String, Json] = Map([])
  for key in js_keys(merged) {
    ordered[key] = merged[key]
  }
  ordered
}

///|
/// `/:\s*[>|][\d+-]*\s*$/`: whether the code of a line opens a block scalar.
fn opens_block_scalar(code : String) -> Bool {
  let n = code.length()
  for k in 0..<n {
    if @util.code_at(code, k) != ':' {
      continue
    }
    let mut j = k + 1
    while @util.is_space(@util.code_at(code, j)) {
      j += 1
    }
    let c = @util.code_at(code, j)
    if c != '>' && c != '|' {
      continue
    }
    j += 1
    while true {
      let d = @util.code_at(code, j)
      if !(@util.is_digit(d) || d == '+' || d == '-') {
        break
      }
      j += 1
    }
    while @util.is_space(@util.code_at(code, j)) {
      j += 1
    }
    if j == n {
      return true
    }
  }
  false
}

///|
/// `code.replace(/,([\t ]*)$/, '$1')`.
fn without_trailing_comma(code : String) -> String {
  let mut k = code.length()
  while k > 0 &&
        (
          @util.code_at(code, k - 1) == ' ' ||
          @util.code_at(code, k - 1) == '\t'
        ) {
    k -= 1
  }
  if k > 0 && @util.code_at(code, k - 1) == ',' {
    @util.slice(code, 0, end=k - 1) + @util.slice(code, k)
  } else {
    code
  }
}

///|
/// Removes the comma that ends a line of a multi-line metadata body, which block YAML does not allow.
/// Commas inside quoted scalars, flow collections and block scalars are content and stay.
fn strip_line_trailing_commas(body : String) -> String {
  let mut in_single = false
  let mut in_double = false
  let mut flow_depth = 0
  let mut block_scalar_indent : Int32? = None
  let out = []
  for piece in body.split("\n") {
    let line = piece.to_owned()
    let indent = line.length() - @util.trim_start(line).length()
    if block_scalar_indent is Some(scalar_indent) {
      if @util.trim(line) == "" || indent > scalar_indent {
        out.push(line)
        continue
      }
      block_scalar_indent = None
    }
    let mut comment_start = -1
    let mut i = 0
    while i < line.length() {
      let ch = @util.code_at(line, i)
      if in_double {
        if ch == '\\' {
          i += 1
        } else if ch == '"' {
          in_double = false
        }
      } else if in_single {
        if ch == '\'' {
          in_single = false
        }
      } else if ch == '"' {
        in_double = true
      } else if ch == '\'' {
        in_single = true
      } else if ch == '#' &&
        (
          i == 0 ||
          @util.code_at(line, i - 1) == ' ' ||
          @util.code_at(line, i - 1) == '\t'
        ) {
        comment_start = i
        break
      } else if ch == '[' || ch == '{' {
        flow_depth += 1
      } else if ch == ']' || ch == '}' {
        flow_depth = if flow_depth > 1 { flow_depth - 1 } else { 0 }
      }
      i += 1
    }
    if in_single || in_double || flow_depth > 0 {
      out.push(line)
      continue
    }
    let code = if comment_start >= 0 {
      @util.slice(line, 0, end=comment_start)
    } else {
      line
    }
    let comment = if comment_start >= 0 {
      @util.slice(line, comment_start)
    } else {
      ""
    }
    if opens_block_scalar(code) {
      block_scalar_indent = Some(indent)
      out.push(line)
      continue
    }
    out.push(without_trailing_comma(code) + comment)
  }
  out.join("\n")
}
