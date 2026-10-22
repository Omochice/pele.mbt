///|
/// A tree entry as written: its indentation and name with the annotations after it.
pub(all) struct TreeNodeAst {
  /// `None` for an entry with no leading blanks.
  indent : Int32?
  name : String
  class_annotation : String?
  icon_annotation : String?
  desc_annotation : String?
}

///|
/// The statements of a tree view, as Mermaid's grammar reads them.
pub(all) struct TreeViewAst {
  title : String?
  acc_title : String?
  acc_descr : String?
  nodes : Array[TreeNodeAst]
}

///|
const KEYWORD : Int32 = 0

///|
const ACC_DESCR : Int32 = 1

///|
const ACC_TITLE : Int32 = 2

///|
const TITLE : Int32 = 3

///|
const CLASS_ANNOTATION : Int32 = 4

///|
const ICON_ANNOTATION : Int32 = 5

///|
const DESC_ANNOTATION : Int32 = 6

///|
const INDENTATION : Int32 = 7

///|
const QUOTED_NAME : Int32 = 8

///|
const BARE_NAME : Int32 = 12

///|
fn skip_blanks(src : String, from : Int32) -> Int32 {
  let mut i = from
  while @util.is_blank(@util.code_at(src, i)) {
    i += 1
  }
  i
}

///|
fn line_end_at(src : String, from : Int32, until_lf_only : Bool) -> Int32 {
  let mut i = from
  while i < src.length() {
    let c = @util.code_at(src, i)
    if c == '\n'.to_int() || (!until_lf_only && c == '\r'.to_int()) {
      break
    }
    i += 1
  }
  i
}

///|
/// Whether `:::` with a class name, `icon(`, or `##` starts at `at`, after the blanks a name may not end with.
fn annotation_at(src : String, at : Int32) -> Bool {
  if @util.starts_with_at(src, "##", at) ||
    @util.starts_with_at(src, "icon(", at) {
    return true
  }
  if !@util.starts_with_at(src, ":::", at) {
    return false
  }
  let c = @util.code_at(src, skip_blanks(src, at + 3))
  (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95
}

///|
/// Answers as `(?!:::|icon\(|##)[^ \t\n\r"'](?:(?![ \t]+:::[ \t]*[A-Za-z_]|[ \t]+icon\(|[ \t]+##)[^\n\r])*` does.
/// The pattern looks ahead from every blank for an annotation, which would rescan a long run of blanks, so this looks once per run.
fn match_bare_name(src : String, at : Int32) -> Int32 {
  let first = @util.code_at(src, at)
  if @util.is_blank(first) ||
    first == '\n'.to_int() ||
    first == '\r'.to_int() ||
    first == '"'.to_int() ||
    first == '\''.to_int() {
    return @common.NO_MATCH
  }
  if @util.starts_with_at(src, ":::", at) ||
    @util.starts_with_at(src, "icon(", at) ||
    @util.starts_with_at(src, "##", at) {
    return @common.NO_MATCH
  }
  let n = src.length()
  let mut i = at + 1
  while i < n {
    let c = @util.code_at(src, i)
    if c == '\n'.to_int() || c == '\r'.to_int() {
      break
    }
    if @util.is_blank(c) {
      let j = skip_blanks(src, i + 1)
      if annotation_at(src, j) {
        break
      }
      i = j
    } else {
      i += 1
    }
  }
  i
}

///|
/// The keyword loses to a bare name that reads further, as Chevrotain's longer alternative does.
/// No type between the two can match where the keyword does, so declining is the same as choosing the bare name.
fn keyword_token() -> @common.TokenType {
  let keyword = @common.keyword("treeView-beta")
  {
    ..keyword,
    scanner: () => {
      let scan = (keyword.scanner)()
      (src, p) => {
        let end = scan(src, p)
        if end > p && match_bare_name(src, p) > end {
          @common.NO_MATCH
        } else {
          end
        }
      }
    },
  }
}

///|
/// `[ \t]+:::[ \t]*[A-Za-z_][\w-]*`
fn scan_class_annotation(src : String, p : Int32) -> Int32 {
  let colons = skip_blanks(src, p)
  if colons == p || !@util.starts_with_at(src, ":::", colons) {
    return @common.NO_MATCH
  }
  let name = skip_blanks(src, colons + 3)
  let c = @util.code_at(src, name)
  if !(@util.is_letter(c) || c == '_'.to_int()) {
    return @common.NO_MATCH
  }
  word_or_hyphen_end(src, name + 1)
}

///|
fn word_or_hyphen_end(src : String, from : Int32) -> Int32 {
  let mut i = from
  while @util.is_word(@util.code_at(src, i)) ||
        @util.code_at(src, i) == '-'.to_int() {
    i += 1
  }
  i
}

///|
/// `[ \t]+icon\([\w-]*(?::[\w-]+)?\)`
fn scan_icon_annotation(src : String, p : Int32) -> Int32 {
  let word = skip_blanks(src, p)
  if word == p || !@util.starts_with_at(src, "icon(", word) {
    return @common.NO_MATCH
  }
  let mut i = word_or_hyphen_end(src, word + 5)
  if @util.code_at(src, i) == ':'.to_int() {
    let rest = word_or_hyphen_end(src, i + 1)
    if rest == i + 1 {
      return @common.NO_MATCH
    }
    i = rest
  }
  if @util.code_at(src, i) == ')'.to_int() {
    i + 1
  } else {
    @common.NO_MATCH
  }
}

///|
/// `[ \t]+##[^\n\r]*`
fn scan_desc_annotation(src : String, p : Int32) -> Int32 {
  let marker = skip_blanks(src, p)
  if marker == p || !@util.starts_with_at(src, "##", marker) {
    return @common.NO_MATCH
  }
  line_end_at(src, marker + 2, false)
}

///|
/// `[ \t]+`
fn scan_blanks(src : String, p : Int32) -> Int32 {
  let end = skip_blanks(src, p)
  if end == p {
    @common.NO_MATCH
  } else {
    end
  }
}

///|
/// `"[^"]*"|'[^']*'`
fn scan_quoted_name(src : String, p : Int32) -> Int32 {
  let quote = @util.code_at(src, p)
  if quote != '"'.to_int() && quote != '\''.to_int() {
    return @common.NO_MATCH
  }
  let close = @util.index_of(
    src,
    quote.unsafe_to_char().to_string(),
    from=p + 1,
  )
  if close == -1 {
    @common.NO_MATCH
  } else {
    close + 1
  }
}

///|
/// `%%[^\n]*`
fn scan_comment(src : String, p : Int32) -> Int32 {
  if @util.starts_with_at(src, "%%", p) {
    line_end_at(src, p + 2, true)
  } else {
    @common.NO_MATCH
  }
}

///|
/// `\r?\n`
fn scan_newline(src : String, p : Int32) -> Int32 {
  let c = @util.code_at(src, p)
  if c == '\n'.to_int() {
    p + 1
  } else if c == '\r'.to_int() && @util.code_at(src, p + 1) == '\n'.to_int() {
    p + 2
  } else {
    @common.NO_MATCH
  }
}

///|
let treeview_tokens : Array[@common.TokenType] = [
  keyword_token(),
  @common.acc_descr,
  @common.acc_title,
  @common.title,
  @common.pattern("CLASS_ANNOTATION", scan_class_annotation, first="\t "),
  @common.pattern("ICON_ANNOTATION", scan_icon_annotation, first="\t "),
  @common.pattern("DESC_ANNOTATION", scan_desc_annotation, first="\t "),
  @common.pattern("INDENTATION", scan_blanks, first="\t "),
  @common.pattern("QUOTED_NAME", scan_quoted_name, first="\"'"),
  @common.pattern("WS", scan_blanks, first="\t ", hidden=true),
  @common.pattern("ML_COMMENT", scan_comment, first="%", hidden=true),
  @common.pattern("NL", scan_newline, first="\r\n", hidden=true),
  @common.pattern("BARE_NAME", match_bare_name),
]

///|
fn trim_blanks_end(text : String) -> String {
  let mut end = text.length()
  while end > 0 && @util.is_blank(@util.code_at(text, end - 1)) {
    end -= 1
  }
  @util.slice(text, 0, end~)
}

///|
/// Mermaid's `input.trim().substring(count).trim()` for a class or description annotation.
fn annotation_value(text : String, marker : Int32) -> String {
  @util.trim(@util.slice(@util.trim(text), marker))
}

///|
fn icon_value(text : String) -> String {
  let trimmed = @util.trim(text)
  @util.slice(trimmed, 5, end=trimmed.length() - 1)
}

///|
/// Reads the text of a tree view, which starts with the `treeView-beta` keyword.
/// Raises a syntax `PeleError` where the text does not follow the grammar.
pub fn parse_treeview(source : String) -> TreeViewAst raise @errors.PeleError {
  let r = @common.TokenReader::new(
    @common.tokenize(source, treeview_tokens, "treeView"),
    treeview_tokens,
    "treeView",
  )
  let mut title = None
  let mut acc_title = None
  let mut acc_descr = None
  let nodes = []
  r.expect(KEYWORD) |> ignore
  while true {
    match r.kind() {
      ACC_DESCR => acc_descr = Some(@common.acc_descr_value(r.take()))
      ACC_TITLE => acc_title = Some(@common.acc_title_value(r.take()))
      TITLE => title = Some(@common.title_value(r.take()))
      _ => break
    }
  }
  while r.kind() != -1 {
    let indent = if r.kind() == INDENTATION {
      Some(r.take().length())
    } else {
      None
    }
    let name = match r.kind() {
      QUOTED_NAME => {
        let text = r.take()
        @util.slice(text, 1, end=text.length() - 1)
      }
      BARE_NAME => trim_blanks_end(r.take())
      _ => r.fail("a name")
    }
    let mut class_annotation = None
    let mut icon_annotation = None
    let mut desc_annotation = None
    while true {
      match r.kind() {
        CLASS_ANNOTATION =>
          class_annotation = Some(annotation_value(r.take(), 3))
        ICON_ANNOTATION => icon_annotation = Some(icon_value(r.take()))
        DESC_ANNOTATION => desc_annotation = Some(annotation_value(r.take(), 2))
        _ => break
      }
    }
    nodes.push({
      indent,
      name,
      class_annotation,
      icon_annotation,
      desc_annotation,
    })
  }
  { title, acc_title, acc_descr, nodes, }
}
