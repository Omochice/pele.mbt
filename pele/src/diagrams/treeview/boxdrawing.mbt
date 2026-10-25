///|
/// The text of a tree view with box-drawing prefixes turned into indentation.
pub(all) struct BoxDrawing {
  text : String
  /// Output line number to original line number, both from 1.
  /// Empty when the text is unchanged.
  line_map : Map[Int32, Int32]
  /// Per output line, where an index of the rewritten line comes from in the original one.
  columns : Map[Int32, (Int32) -> Int32]
}

///|
/// `[─━│┃└┗├┣]`
fn is_box_char(c : Int32) -> Bool {
  c == 0x2500 ||
  c == 0x2501 ||
  c == 0x2502 ||
  c == 0x2503 ||
  c == 0x2514 ||
  c == 0x2517 ||
  c == 0x251c ||
  c == 0x2523
}

///|
/// `[└┗├┣]`
fn is_branch_char(c : Int32) -> Bool {
  c == 0x2514 || c == 0x2517 || c == 0x251c || c == 0x2523
}

///|
/// `[─━]`
fn is_dash_char(c : Int32) -> Bool {
  c == 0x2500 || c == 0x2501
}

///|
fn has_char(text : String, accepts : (Int32) -> Bool) -> Bool {
  first_char(text, accepts) != -1
}

///|
fn first_char(text : String, accepts : (Int32) -> Bool) -> Int32 {
  for i in 0..<text.length() {
    if accepts(@util.code_at(text, i)) {
      return i
    }
  }
  -1
}

///|
/// Whether `text` is not empty and every code unit passes `test`.
fn all_chars(text : String, accepts : (Int32) -> Bool) -> Bool {
  text.length() > 0 && first_char(text, c => !accepts(c)) == -1
}

///|
fn split_lines(text : String) -> Array[String] {
  let lines = []
  let mut from = 0
  let mut at = @util.index_of(text, "\n")
  while at != -1 {
    lines.push(@util.slice(text, from, end=at))
    from = at + 1
    at = @util.index_of(text, "\n", from~)
  }
  lines.push(@util.slice(text, from))
  lines
}

///|
fn expand_tabs(line : String) -> String {
  line.replace_all(old="\t", new="    ")
}

///|
/// `^\s*%%`
fn is_comment_line(line : String) -> Bool {
  let mut i = 0
  while @util.is_space(@util.code_at(line, i)) {
    i += 1
  }
  @util.starts_with_at(line, "%%", i)
}

///|
/// `^\s*(title[\t ]|accTitle[\t ]*:|accDescr[\t ]*[:{])`
fn is_metadata_line(line : String) -> Bool {
  let mut i = 0
  while @util.is_space(@util.code_at(line, i)) {
    i += 1
  }
  if @util.starts_with_at(line, "title", i) {
    return @util.is_blank(@util.code_at(line, i + 5))
  }
  let after_blanks = (from : Int32) => {
    let mut j = from
    while @util.is_blank(@util.code_at(line, j)) {
      j += 1
    }
    @util.code_at(line, j)
  }
  if @util.starts_with_at(line, "accTitle", i) {
    return after_blanks(i + 8) == ':'.to_int()
  }
  if @util.starts_with_at(line, "accDescr", i) {
    let c = after_blanks(i + 8)
    return c == ':'.to_int() || c == '{'.to_int()
  }
  false
}

///|
/// Whether any of `lines` has a box-drawing character.
pub fn is_box_drawing_format(lines : Array[String]) -> Bool {
  lines.iter().any(line => has_char(line, is_box_char))
}

///|
/// The column of the first branch character that is not in the first column, which is how wide one level of the tree is.
fn infer_segment_width(content_lines : Array[String]) -> Int32 {
  for line in content_lines {
    let at = first_char(line, is_branch_char)
    if at > 0 {
      return at
    }
  }
  4
}

///|
/// Rewrites the line numbers in an error message through `line_map`.
/// A number that is not in the map stays.
pub fn remap_error_lines(
  message : String,
  line_map : Map[Int32, Int32],
) -> String {
  let out = StringBuilder()
  let n = message.length()
  let mut i = 0
  let mut copied = 0
  while i < n {
    let c = @util.code_at(message, i)
    let at_word = (c == 'l'.to_int() || c == 'L'.to_int()) &&
      (i == 0 || !@util.is_word(@util.code_at(message, i - 1))) &&
      @util.starts_with_at(message.to_lower(), "line", i)
    if !at_word {
      i += 1
      continue
    }
    let mut j = i + 4
    if !@util.is_space(@util.code_at(message, j)) {
      i += 1
      continue
    }
    while @util.is_space(@util.code_at(message, j)) {
      j += 1
    }
    let digits = j
    while @util.is_digit(@util.code_at(message, j)) {
      j += 1
    }
    if j == digits || @util.is_word(@util.code_at(message, j)) {
      i += 1
      continue
    }
    let number = @util.slice(message, digits, end=j)
    let original = if number.length() < 10 {
      line_map.get(@util.parse_float(number).to_int())
    } else {
      None
    }
    if original is Some(line) && line != 0 {
      @util.write_range(out, message, copied, i)
      out.write_string("line \{line}")
      copied = j
    }
    i = j
  }
  @util.write_range(out, message, copied, n)
  out.to_string()
}

///|
/// Where line `line`, from 1, starts in `text`.
pub fn line_start(text : String, line : Int32) -> Int32 {
  let mut at = 0
  for _ in 1..<line {
    at = @util.index_of(text, "\n", from=at) + 1
  }
  at
}

///|
/// Where index `at` of `line` with its tabs expanded to four spaces is in `line` itself.
fn before_tabs(line : String, at : Int32) -> Int32 {
  let mut i = 0
  let mut n = 0
  while i < line.length() && n < at {
    n += if @util.code_at(line, i) == '\t'.to_int() { 4 } else { 1 }
    i += 1
  }
  i
}

///|
/// Raises an error at line `index`, from 0, of `input`, numbered as the source was written.
fn fail(
  input : String,
  index : Int32,
  message : String,
) -> Unit raise @errors.PeleError {
  let (line, _, _) = @errors.locate(input, line_start(input, index + 1))
  raise @errors.pele_error(
    "Line \{line}: \{message}",
    code=Syntax,
    kind="treeView",
    line~,
  )
}

///|
/// Turns the `├──`, `└──`, `│` prefixes `tree` prints, and their heavy variants, into the indentation the grammar reads.
/// Text that is not a tree view in box-drawing format is returned as it is.
/// Raises a syntax `PeleError` naming the line of the original text for an empty node or for indentation without box-drawing characters.
pub fn preprocess_box_drawing(
  input : String,
) -> BoxDrawing raise @errors.PeleError {
  let line_map : Map[Int32, Int32] = Map([])
  let columns : Map[Int32, (Int32) -> Int32] = Map([])
  let unchanged = { text: input, line_map, columns, }
  if !has_char(input, is_box_char) {
    return unchanged
  }
  let lines = split_lines(input)
  let mut keyword_index = -1
  for i, line in lines {
    if @util.trim(line) == "treeView-beta" {
      keyword_index = i
      break
    }
  }
  if keyword_index == -1 {
    return unchanged
  }
  let passes = (line : String) => {
    @util.trim(line) == "" || is_comment_line(line) || is_metadata_line(line)
  }
  let is_decoration = (line : String) => {
    all_chars(line, c => @util.is_space(c) || c == 0x2502 || c == 0x2503)
  }
  let content_lines = []
  for i in (keyword_index + 1)..<lines.length() {
    let line = lines[i]
    if passes(line) || is_decoration(line) {
      continue
    }
    content_lines.push(expand_tabs(line))
  }
  if !is_box_drawing_format(content_lines) {
    return unchanged
  }
  let segment_width = infer_segment_width(content_lines)
  let out = []
  let keep = (text : String, index : Int32, column : ((Int32) -> Int32)?) => {
    out.push(text)
    line_map[out.length()] = index + 1
    if column is Some(column) {
      columns[out.length()] = column
    }
  }
  for i in 0..<=keyword_index {
    keep(lines[i], i, None)
  }
  for i in (keyword_index + 1)..<lines.length() {
    let line = lines[i]
    if passes(line) {
      keep(line, i, None)
      continue
    }
    if is_decoration(line) {
      continue
    }
    let normalized = expand_tabs(line)
    let branch = first_char(normalized, is_branch_char)
    if branch != -1 {
      let depth = (branch.to_double() / segment_width.to_double())
        .round()
        .to_int() +
        1
      let mut pos = branch + 1
      while pos < normalized.length() &&
            is_dash_char(@util.code_at(normalized, pos)) {
        pos += 1
      }
      while pos < normalized.length() &&
            @util.code_at(normalized, pos) == ' '.to_int() {
        pos += 1
      }
      let content = @util.trim_end(@util.slice(normalized, pos))
      if content == "" {
        fail(
          input, i, "Empty node — expected a filename or directory name after the box-drawing prefix",
        )
      }
      let indent = "    ".repeat(depth)
      keep(
        indent + content,
        i,
        Some(at => {
          before_tabs(
            line,
            pos + (if at > indent.length() { at - indent.length() } else { 0 }),
          )
        }),
      )
    } else if all_chars(normalized, c => is_box_char(c) || @util.is_space(c)) {
      continue
    } else if has_char(normalized, is_box_char) {
      // A name that happens to contain a box character, such as "Section ─ A.txt", is a root item.
      keep(line, i, None)
    } else if @util.is_space(@util.code_at(normalized, 0)) {
      fail(
        input, i, "Unexpected indentation without box-drawing characters. In box-drawing format, use ├── or └── prefixes for indented nodes.",
      )
    } else {
      keep(line, i, None)
    }
  }
  { text: out.join("\n"), line_map, columns, }
}
