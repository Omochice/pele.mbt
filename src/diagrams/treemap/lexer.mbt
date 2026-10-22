///|
const ACC_DESCR : Int32 = 0

///|
const ACC_TITLE : Int32 = 1

///|
const TITLE : Int32 = 2

///|
const KEYWORD : Int32 = 3

///|
const CLASS_DEF : Int32 = 4

///|
const STYLE_SEPARATOR : Int32 = 5

///|
const SEPARATOR : Int32 = 6

///|
const COMMA : Int32 = 7

///|
const INDENTATION : Int32 = 8

///|
const NUMBER : Int32 = 13

///|
const STRING : Int32 = 14

///|
const ID : Int32 = 12

///|
fn is_name_start(c : Int32) -> Bool {
  (c >= 'a'.to_int() && c <= 'z'.to_int()) ||
  (c >= 'A'.to_int() && c <= 'Z'.to_int()) ||
  c == '_'.to_int()
}

///|
fn is_name_char(c : Int32) -> Bool {
  is_name_start(c) || @util.is_digit(c)
}

///|
/// Where the pieces of a `classDef` statement lie.
priv struct ClassDefSpan {
  end : Int32
  name_start : Int32
  name_end : Int32
  /// The declarations are absent when `style_start` is -1.
  style_start : Int32
  style_end : Int32
}

///|
/// Reads `classDef\s+([a-zA-Z_][a-zA-Z0-9_]+)(?:\s+([^;\r\n]*))?;?` at `p`.
/// The whitespace of the optional group may run over line breaks, so a name at the end of a line
/// takes the line break with it and a declaration may begin on a later line.
fn scan_class_def(src : String, p : Int32) -> ClassDefSpan? {
  if !@util.starts_with_at(src, "classDef", p) {
    return None
  }
  let mut i = p + "classDef".length()
  let name_start = skip_space(src, i)
  if name_start == i || !is_name_start(@util.code_at(src, name_start)) {
    return None
  }
  i = name_start + 1
  if !is_name_char(@util.code_at(src, i)) {
    return None
  }
  while is_name_char(@util.code_at(src, i)) {
    i += 1
  }
  let name_end = i
  let mut style_start = -1
  let mut style_end = -1
  let declarations = skip_space(src, i)
  if declarations > i {
    style_start = declarations
    i = declarations
    while i < src.length() {
      let c = @util.code_at(src, i)
      if c == ';'.to_int() || c == '\r'.to_int() || c == '\n'.to_int() {
        break
      }
      i += 1
    }
    style_end = i
  }
  if @util.code_at(src, i) == ';'.to_int() {
    i += 1
  }
  Some({ end: i, name_start, name_end, style_start, style_end, })
}

///|
fn skip_space(src : String, from : Int32) -> Int32 {
  let mut i = from
  while @util.is_space(@util.code_at(src, i)) {
    i += 1
  }
  i
}

///|
fn scan_name(src : String, p : Int32) -> Int32 {
  if !is_name_start(@util.code_at(src, p)) {
    return @common.NO_MATCH
  }
  let mut i = p + 1
  while is_name_char(@util.code_at(src, i)) {
    i += 1
  }
  i
}

///|
fn scan_number(src : String, p : Int32) -> Int32 {
  let mut i = p
  while true {
    let c = @util.code_at(src, i)
    if @util.is_digit(c) ||
      c == '_'.to_int() ||
      c == '.'.to_int() ||
      c == ','.to_int() {
      i += 1
    } else {
      break
    }
  }
  if i > p {
    i
  } else {
    @common.NO_MATCH
  }
}

///|
/// `"[^"]*"|'[^']*'`, which has no escapes, unlike the string of other diagrams.
fn scan_string(src : String, p : Int32) -> Int32 {
  let quote = @util.code_at(src, p)
  if quote != '"'.to_int() && quote != '\''.to_int() {
    return @common.NO_MATCH
  }
  let close = @util.index_of(
    src,
    if quote == '"'.to_int() {
      "\""
    } else {
      "'"
    },
    from=p + 1,
  )
  if close == -1 {
    @common.NO_MATCH
  } else {
    close + 1
  }
}

///|
/// Mermaid's treemap lexer, whose token order the constants above index.
/// Every run of spaces and tabs is an INDENTATION token because that type comes before WS, so rows
/// are told apart by their tokens alone and a row's indentation is the whitespace before it.
let treemap_tokens : Array[@common.TokenType] = [
  @common.acc_descr,
  @common.acc_title,
  @common.title,
  @common.pattern(
    "TREEMAP_KEYWORD",
    (src, p) => {
      if @util.starts_with_at(src, "treemap-beta", p) {
        p + "treemap-beta".length()
      } else if @util.starts_with_at(src, "treemap", p) {
        p + "treemap".length()
      } else {
        @common.NO_MATCH
      }
    },
    first="t",
  ),
  @common.pattern(
    "CLASS_DEF",
    (src, p) => {
      match scan_class_def(src, p) {
        Some(span) => span.end
        None => @common.NO_MATCH
      }
    },
    first="c",
  ),
  @common.literal(":::", ":::") |> with_name("STYLE_SEPARATOR"),
  @common.literal(":", ":") |> with_name("SEPARATOR"),
  @common.literal(",", ",") |> with_name("COMMA"),
  { ..@common.whitespace, name: "INDENTATION", hidden: false, },
  { ..@common.whitespace, name: "WS", },
  @common.pattern(
    "ML_COMMENT",
    (src, p) => {
      if !@util.starts_with_at(src, "%%", p) {
        return @common.NO_MATCH
      }
      let mut i = p + 2
      while i < src.length() && @util.code_at(src, i) != '\n'.to_int() {
        i += 1
      }
      i
    },
    first="%",
    hidden=true,
  ),
  { ..@common.newline, name: "NL", hidden: true, },
  @common.pattern(
    "ID2",
    scan_name,
    first="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_",
  ),
  @common.pattern("NUMBER2", scan_number, first="0123456789_.,"),
  @common.pattern("STRING2", scan_string, first="\"'"),
]

///|
fn with_name(type_ : @common.TokenType, name : String) -> @common.TokenType {
  { ..type_, name, }
}
