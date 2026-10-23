///|
/// Diagram text with front matter, directives, and comment lines taken out.
pub(all) struct Preprocessed {
  text : String
  title : String?
  config : @types.Config
  /// The text before its comment lines are removed.
  with_comments : String
  /// The number of front matter lines before `with_comments`.
  line_offset : Int32
}

///|
fn is_record(value : Json?) -> Map[String, Json]? {
  match value {
    Some(Object(record)) => Some(record)
    _ => None
  }
}

///|
fn is_unsafe_key(key : String) -> Bool {
  key is ("__proto__" | "constructor" | "prototype")
}

///|
/// Objects still to merge wait on a stack of their own, so nesting is limited by memory and not by the call stack.
/// Merging them later rather than at once gives the same config, because no two of them share an object.
fn merge(target : @types.Config, source : @types.Config) -> @types.Config {
  let pending = [(target, source)]
  while pending.pop() is Some((into, from)) {
    for key, value in from {
      if is_unsafe_key(key) {
        continue
      }
      match (value, is_record(into.get(key))) {
        (Object(incoming), Some(current)) => pending.push((current, incoming))
        (Object(incoming), None) => {
          let copy = Map([])
          into[key] = Json::object(copy)
          pending.push((copy, incoming))
        }
        _ => into[key] = value
      }
    }
  }
  target
}

///|
/// Removes `%%` comment lines, keeping directives, and leading whitespace.
pub fn cleanup_comments(text : String) -> String {
  let cleaned = if text.contains("%%") {
    remove_comment_lines(text)
  } else {
    text
  }
  @util.trim_start(cleaned)
}

///|
/// Does what `text.replace(/^\s*%%(?!{)[^\n]+\n?/gm, '')` does.
fn remove_comment_lines(text : String) -> String {
  let out = StringBuilder()
  let mut last = 0
  let mut p = 0
  while p < text.length() {
    if p > 0 && !@util.is_line_end(@util.code_at(text, p - 1)) {
      p += 1
      continue
    }
    let mut q = p
    while @util.is_space(@util.code_at(text, q)) {
      q += 1
    }
    let after = @util.code_at(text, q + 2)
    if @util.starts_with_at(text, "%%", q) &&
      after != -1 &&
      after != '{'.to_int() &&
      after != '\n'.to_int() {
      let mut end = q + 2
      while end < text.length() && @util.code_at(text, end) != '\n'.to_int() {
        end += 1
      }
      if end < text.length() {
        end += 1
      }
      @util.write_range(out, text, last, p)
      last = end
      p = end
    } else {
      // Every line start up to `q` reaches the same `q` through `\s*`, so none of them match.
      p = if q > p { q } else { p + 1 }
    }
  }
  @util.write_range(out, text, last, text.length())
  out.to_string()
}

///|
/// Does what Mermaid's `<(\w+)([^>]*)>` replacement does: attribute values in double quotes
/// get single quotes.
fn quote_attributes(text : String) -> String {
  let out = StringBuilder()
  let mut last = 0
  let mut i = @util.index_of(text, "<")
  while i != -1 {
    let mut name_end = i + 1
    while @util.is_word(@util.code_at(text, name_end)) {
      name_end += 1
    }
    let close = if name_end > i + 1 {
      @util.index_of(text, ">", from=name_end)
    } else {
      -1
    }
    if close == -1 {
      i = @util.index_of(text, "<", from=i + 1)
      continue
    }
    @util.write_range(out, text, last, name_end)
    let mut k = name_end
    while k < close {
      if @util.starts_with_at(text, "=\"", k) {
        let quote = @util.index_of(text, "\"", from=k + 2)
        if quote != -1 && quote < close {
          out.write_string("='")
          @util.write_range(out, text, k + 2, quote)
          out.write_string("'")
          k = quote + 1
          continue
        }
      }
      @util.write_range(out, text, k, k + 1)
      k += 1
    }
    last = close
    i = @util.index_of(text, "<", from=close + 1)
  }
  @util.write_range(out, text, last, text.length())
  out.to_string()
}

///|
priv struct FrontMatter {
  indent : String
  body : String
  length : Int32
}

///|
fn is_line_break(c : Int32) -> Bool {
  c == '\n'.to_int() || c == '\r'.to_int()
}

///|
/// The end of the line a closing fence at `i` ends, or -1 when `i` holds no closing fence.
fn closing_end(text : String, fence : String, i : Int32) -> Int32 {
  if !is_line_break(@util.code_at(text, i)) ||
    !@util.starts_with_at(text, fence, i + 1) {
    return -1
  }
  let mut last = -1
  let mut j = i + 1 + fence.length()
  while j < text.length() && @util.is_space(@util.code_at(text, j)) {
    if is_line_break(@util.code_at(text, j)) {
      last = j
    }
    j += 1
  }
  last
}

///|
/// Finds a `---` fenced YAML block at the start of the text the way Mermaid's front matter regex does.
fn match_front_matter(text : String) -> FrontMatter? {
  let mut cursor = 0
  while cursor < text.length() &&
        @util.is_space(@util.code_at(text, cursor)) &&
        !is_line_break(@util.code_at(text, cursor)) {
    cursor += 1
  }
  let indent = @util.slice(text, 0, end=cursor)
  if !@util.starts_with_at(text, "---", cursor) {
    return None
  }
  let opening_ends : Array[Int32] = []
  let mut i = cursor + 3
  while i < text.length() && @util.is_space(@util.code_at(text, i)) {
    if is_line_break(@util.code_at(text, i)) {
      opening_ends.push(i)
    }
    i += 1
  }
  if opening_ends.is_empty() {
    return None
  }
  let fence = indent + "---"
  let needle = "\n" + fence
  let mut last_fence = -1
  let mut at = @util.last_index_of(text, needle)
  while at > opening_ends[0] {
    if closing_end(text, fence, at) != -1 {
      last_fence = at
      break
    }
    at = @util.last_index_of(text, needle, from=at - 1)
  }
  if last_fence == -1 {
    return None
  }
  let mut opening_end = opening_ends[0]
  for candidate in opening_ends {
    if candidate < last_fence {
      opening_end = candidate
    }
  }
  let body_start = opening_end + 1
  let first_at = if body_start > 0 { body_start - 1 } else { 0 }
  let mut k = @util.index_of(text, needle, from=first_at)
  while k != -1 && k <= last_fence {
    if k >= body_start {
      let end = closing_end(text, fence, k)
      if end != -1 {
        return Some({
          indent,
          body: @util.slice(text, body_start, end=k),
          length: end + 1,
        })
      }
    }
    k = @util.index_of(text, needle, from=k + 1)
  }
  None
}

///|
/// Removes the fence indentation from each line of a front matter body.
fn dedent_body(front : FrontMatter) -> String {
  if front.indent == "" {
    return front.body
  }
  front.body
  .split("\n")
  .map(line => {
    let line = line.to_owned()
    if line.has_prefix(front.indent) {
      @util.slice(line, front.indent.length())
    } else {
      line
    }
  })
  .to_array()
  .join("\n")
}

///|
/// The parts of a `%%{...}%%` directive at `at`, as `RE_DIRECTIVE` captures them, or `None`.
fn match_directive(text : String, at : Int32) -> (Int32, String, String?)? {
  let mut i = at + 3
  while @util.is_space(@util.code_at(text, i)) {
    i += 1
  }
  let word_start = i
  while @util.is_word(@util.code_at(text, i)) {
    i += 1
  }
  if i == word_start {
    return None
  }
  let kind = @util.slice(text, word_start, end=i)
  let mut j = i
  while @util.is_space(@util.code_at(text, j)) {
    j += 1
  }
  if @util.code_at(text, j) == ':'.to_int() {
    i = j + 1
  }
  while @util.is_space(@util.code_at(text, i)) {
    i += 1
  }
  let mut args = None
  if @util.is_word(@util.code_at(text, i)) {
    while @util.is_word(@util.code_at(text, i)) {
      i += 1
    }
  } else {
    let start = i
    while i < text.length() {
      let c = @util.code_at(text, i)
      if @util.starts_with_at(text, "}%%", i) {
        break
      }
      if !@util.is_line_end(c) {
        i += 1
      } else if c == '\n'.to_int() {
        i += 1
      } else if c == '\r'.to_int() &&
        @util.code_at(text, i + 1) == '\n'.to_int() {
        i += 2
      } else {
        break
      }
    }
    args = Some(@util.slice(text, start, end=i))
  }
  while @util.is_space(@util.code_at(text, i)) {
    i += 1
  }
  if @util.starts_with_at(text, "}%%", i) {
    i += 3
  }
  Some((i, kind, args))
}

///|
/// Applies `%%{init: ...}%%` and `%%{wrap}%%` directives to the config and removes them.
fn directives(text : String, config : @types.Config) -> String {
  if !text.contains("%%{") {
    return text
  }
  let normalized = @util.trim(text).replace_all(old="'", new="\"")
  let mut at = @util.index_of(normalized, "%%{")
  while at != -1 {
    match match_directive(normalized, at) {
      Some((end, kind, args)) => {
        if kind == "wrap" {
          config["wrap"] = Json::boolean(true)
        } else if (kind == "init" || kind == "initialize") &&
          args is Some(body) &&
          body != "" {
          // Mermaid ignores an init directive whose body is not valid JSON.
          let parsed = Some(@util.parse_json(@util.trim(body))) catch {
            _ => None
          }
          if parsed is Some(Object(record)) {
            merge(config, record) |> ignore
          }
        }
        at = @util.index_of(normalized, "%%{", from=end)
      }
      None => at = @util.index_of(normalized, "%%{", from=at + 1)
    }
  }
  let out = StringBuilder()
  let mut last = 0
  let mut found = @util.index_of(text, "%%{")
  while found != -1 {
    match match_directive(text, found) {
      Some((end, _, _)) => {
        @util.write_range(out, text, last, found)
        last = end
        found = @util.index_of(text, "%%{", from=end)
      }
      None => found = @util.index_of(text, "%%{", from=found + 1)
    }
  }
  @util.write_range(out, text, last, text.length())
  out.to_string()
}

///|
/// Reads front matter and directives into a config, as Mermaid does before parsing.
/// Raises a syntax `PeleError` when the front matter is not valid YAML.
pub fn preprocess(source : String) -> Preprocessed raise @errors.PeleError {
  let mut text = if source.contains("\r") {
    @util.normalize_line_breaks(source)
  } else {
    source
  }
  // A tag needs a closing bracket, so nothing after the last one can match.
  let last_close = if text.contains("<") {
    @util.last_index_of(text, ">")
  } else {
    -1
  }
  if last_close > 0 {
    text = quote_attributes(@util.slice(text, 0, end=last_close + 1)) +
      @util.slice(text, last_close + 1)
  }
  let config : @types.Config = Map([])
  let mut title = None
  let mut line_offset = 0
  let front = if text.contains("---") { match_front_matter(text) } else { None }
  if front is Some(front) {
    let parsed = @util.parse_yaml(dedent_body(front)) catch {
      @util.YamlError(message) =>
        raise @errors.pele_error(
          "Front matter is not valid YAML. \{message}",
          code=Syntax,
        )
    }
    if parsed is Object(record) {
      if record.get("title") is Some(value) && @util.js_truthy(value) {
        title = Some(@util.js_string(value))
      }
      if is_record(record.get("config")) is Some(incoming) {
        merge(config, incoming) |> ignore
      }
      if record.get("displayMode") is Some(mode) && @util.js_truthy(mode) {
        let gantt = match is_record(config.get("gantt")) {
          Some(gantt) => gantt
          None => {
            let gantt = Map([])
            config["gantt"] = Json::object(gantt)
            gantt
          }
        }
        gantt["displayMode"] = Json::string(@util.js_string(mode))
      }
    }
    let mut i = @util.index_of(text, "\n")
    while i != -1 && i < front.length {
      line_offset += 1
      i = @util.index_of(text, "\n", from=i + 1)
    }
    text = @util.slice(text, front.length)
  }
  text = directives(text, config)
  {
    text: cleanup_comments(text),
    title,
    config,
    with_comments: text,
    line_offset,
  }
}

///|
/// Does what Mermaid's `text.replace(/keyword.*:\S*#.*;/g, drop the last character)` does:
/// on a line where the keyword is followed by a colon, a color-like `#`, and later a semicolon,
/// the last semicolon goes.
fn drop_color_semicolons(text : String, keyword : String) -> String {
  let mut from = @util.index_of(text, keyword)
  if from == -1 {
    return text
  }
  let out = StringBuilder()
  let mut last = 0
  while from != -1 {
    let mut line_end = from
    while line_end < text.length() &&
          !@util.is_line_end(@util.code_at(text, line_end)) {
      line_end += 1
    }
    let mut after_colon = false
    let mut hash = -1
    for j in (from + keyword.length())..<line_end {
      let c = @util.code_at(text, j)
      if c == ':'.to_int() {
        after_colon = true
      } else if c == '#'.to_int() {
        if after_colon {
          hash = j
          break
        }
      } else if @util.is_space(c) {
        after_colon = false
      }
    }
    if hash != -1 {
      let semi = @util.last_index_of(text, ";", from=line_end - 1)
      if semi > hash {
        @util.write_range(out, text, last, semi)
        last = semi + 1
      }
    }
    from = if line_end >= text.length() {
      -1
    } else {
      @util.index_of(text, keyword, from=line_end + 1)
    }
  }
  if last == 0 {
    return text
  }
  @util.write_range(out, text, last, text.length())
  out.to_string()
}

///|
/// Hides `#name;` entity codes behind Mermaid's placeholder characters, so `#` and `;` survive parsing.
pub fn encode_entities(text : String) -> String {
  if !text.contains("#") {
    return text
  }
  let source = drop_color_semicolons(
    drop_color_semicolons(text, "style"),
    "classDef",
  )
  let out = StringBuilder()
  let mut last = 0
  let mut i = @util.index_of(source, "#")
  while i != -1 {
    let mut end = i + 1
    while @util.is_word(@util.code_at(source, end)) {
      end += 1
    }
    if end > i + 1 && @util.code_at(source, end) == ';'.to_int() {
      let inner = @util.slice(source, i + 1, end~)
      let numeric = inner.iter().all(c => c >= '0' && c <= '9')
      @util.write_range(out, source, last, i)
      out.write_string(
        if numeric {
          "\u{fb02}\u{b0}\u{b0}"
        } else {
          "\u{fb02}\u{b0}"
        },
      )
      out.write_string(inner)
      out.write_string("\u{b6}\u{df}")
      last = end + 1
      i = @util.index_of(source, "#", from=end + 1)
    } else {
      i = @util.index_of(source, "#", from=i + 1)
    }
  }
  @util.write_range(out, source, last, source.length())
  out.to_string()
}
