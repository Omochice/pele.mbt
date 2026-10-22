///|
/// A keyword that is also an identifier.
/// Langium gives such a keyword the identifier as a longer alternative, so the keyword is a token only where the identifier would not go on.
fn word(text : String) -> @common.TokenType {
  @common.pattern(
    text,
    (src, p) => {
      if !@util.starts_with_at(src, text, p) {
        return @common.NO_MATCH
      }
      let end = p + text.length()
      if @util.is_word(@util.code_at(src, end)) {
        @common.NO_MATCH
      } else {
        end
      }
    },
    first=@util.slice(text, 0, end=1),
  )
}

///|
/// `[_a-zA-Z][\w_]*`
let em_id : @common.TokenType = @common.pattern(
  "EM_ID",
  (src, p) => {
    let c = @util.code_at(src, p)
    if !(@util.is_letter(c) || c == '_'.to_int()) {
      return @common.NO_MATCH
    }
    let mut end = p + 1
    while @util.is_word(@util.code_at(src, end)) {
      end += 1
    }
    end
  },
  first="_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
)

///|
/// `\d{1,3}`
let em_fid : @common.TokenType = @common.pattern(
  "EM_FID",
  (src, p) => {
    let mut end = p
    while end < p + 3 && @util.is_digit(@util.code_at(src, end)) {
      end += 1
    }
    if end > p {
      end
    } else {
      @common.NO_MATCH
    }
  },
  first="0123456789",
)

///|
/// `\{(.*)\}|"(.*)"|'(.*)'`: up to the last closing character on the line.
let em_data_inline : @common.TokenType = @common.pattern(
  "EM_DATA_INLINE",
  (src, p) => {
    let open = @util.code_at(src, p)
    let close = if open == '{'.to_int() {
      '}'.to_int()
    } else if open == '"'.to_int() || open == '\''.to_int() {
      open
    } else {
      return @common.NO_MATCH
    }
    let mut last = -1
    let mut i = p + 1
    while i < src.length() {
      let c = @util.code_at(src, i)
      if @util.is_line_end(c) {
        break
      }
      if c == close {
        last = i
      }
      i += 1
    }
    if last == -1 {
      @common.NO_MATCH
    } else {
      last + 1
    }
  },
  first="{\"'",
)

///|
/// The end of `(?:\r?\n|(?!\S))` at `at`, or -1.
fn line_break_or_space(src : String, at : Int32) -> Int32 {
  let c = @util.code_at(src, at)
  if c == '\r'.to_int() && @util.code_at(src, at + 1) == '\n'.to_int() {
    at + 2
  } else if c == '\n'.to_int() {
    at + 1
  } else if c == -1 || @util.is_space(c) {
    at
  } else {
    -1
  }
}

///|
/// `\{[\t ]*\r?\n(?:[\S\s]*?\r?\n)?\}(?:\r?\n|(?!\S))`
/// Without a closer there is none further on either, so the type is not tried again.
/// pele tries the pattern at every opening brace and does not remember that.
let em_data_block : @common.TokenType = @common.pattern(
  "EM_DATA_BLOCK",
  (src, p) => {
    if @util.code_at(src, p) != '{'.to_int() {
      return @common.NO_MATCH
    }
    let mut a = p + 1
    while @util.is_blank(@util.code_at(src, a)) {
      a += 1
    }
    if @util.code_at(src, a) == '\r'.to_int() {
      a += 1
    }
    if @util.code_at(src, a) != '\n'.to_int() {
      return @common.NO_MATCH
    }
    a += 1
    // The optional group is tried first, so the closing brace is the first one after a line break that ends the block.
    let mut nl = @util.index_of(src, "\n}", from=a)
    while nl != -1 {
      let end = line_break_or_space(src, nl + 2)
      if end != -1 {
        return end
      }
      nl = @util.index_of(src, "\n}", from=nl + 1)
    }
    if @util.code_at(src, a) == '}'.to_int() {
      let end = line_break_or_space(src, a + 1)
      if end != -1 {
        return end
      }
    }
    @common.NO_CLOSER
  },
  first="{",
)

///|
/// `\s+`, skipped.
let em_ws : @common.TokenType = @common.pattern(
  "EM_WS",
  (src, p) => {
    let mut end = p
    while @util.is_space(@util.code_at(src, end)) {
      end += 1
    }
    if end > p {
      end
    } else {
      @common.NO_MATCH
    }
  },
  hidden=true,
)

///|
/// `\/\*[\s\S]*?\*\/`, skipped.
/// Without a closer there is none further on either, so the type is not tried again.
let em_ml_comment : @common.TokenType = @common.pattern(
  "EM_ML_COMMENT",
  (src, p) => {
    if !@util.starts_with_at(src, "/*", p) {
      return @common.NO_MATCH
    }
    let close = @util.index_of(src, "*/", from=p + 2)
    if close == -1 {
      @common.NO_CLOSER
    } else {
      close + 2
    }
  },
  first="/",
  hidden=true,
)

///|
/// `\/\/[^\n\r]*`, skipped.
let em_sl_comment : @common.TokenType = @common.pattern(
  "EM_SL_COMMENT",
  (src, p) => {
    if !@util.starts_with_at(src, "//", p) {
      return @common.NO_MATCH
    }
    let mut end = p + 2
    while end < src.length() {
      let c = @util.code_at(src, end)
      if c == '\n'.to_int() || c == '\r'.to_int() {
        break
      }
      end += 1
    }
    end
  },
  first="/",
  hidden=true,
)

///|
/// The token types in the order Chevrotain tries them: the first to match wins.
let tokens : Array[@common.TokenType] = [
  @common.keyword("eventmodeling"),
  word("resetframe"),
  word("readmodel"),
  word("processor"),
  word("timeframe"),
  word("command"),
  word("entity"),
  word("event"),
  word("jsobj"),
  word("figma"),
  word("given"),
  word("json"),
  word("salt"),
  word("html"),
  word("text"),
  word("data"),
  word("note"),
  word("when"),
  word("then"),
  word("rmo"),
  word("cmd"),
  word("evt"),
  word("pcr"),
  word("uri"),
  @common.literal("->>", "->>"),
  word("gwt"),
  word("ui"),
  word("md"),
  word("tf"),
  @common.literal("[[", "[["),
  @common.literal("]]", "]]"),
  word("rf"),
  @common.literal("`", "`"),
  @common.literal(".", "."),
  em_id,
  em_fid,
  em_data_inline,
  em_data_block,
  { ..@common.acc_descr, name: "EM_ACC_DESCR", },
  { ..@common.acc_title, name: "EM_ACC_TITLE", },
  { ..@common.title, name: "EM_TITLE", },
  em_ws,
  { ..@common.yaml, name: "EM_YAML", },
  { ..@common.directive, name: "EM_DIRECTIVE", },
  { ..@common.single_line_comment, name: "EM_SINGLE_LINE_COMMENT", },
  em_ml_comment,
  em_sl_comment,
]

///|
fn token_index(name : String) -> Int32 {
  for i, type_ in tokens {
    if type_.name == name {
      return i
    }
  }
  abort("no token type named \{name}")
}

///|
fn token_kinds(names : Array[String]) -> Array[Int32] {
  names.map(token_index)
}

///|
let t_keyword : Int32 = 0

///|
let t_arrow : Int32 = token_index("->>")

///|
let t_open : Int32 = token_index("[[")

///|
let t_close : Int32 = token_index("]]")

///|
let t_tick : Int32 = token_index("`")

///|
let t_dot : Int32 = token_index(".")

///|
let t_id : Int32 = token_index("EM_ID")

///|
let t_frame_id : Int32 = token_index("EM_FID")

///|
let t_inline : Int32 = token_index("EM_DATA_INLINE")

///|
let t_block : Int32 = token_index("EM_DATA_BLOCK")

///|
let t_acc_descr : Int32 = token_index("EM_ACC_DESCR")

///|
let t_acc_title : Int32 = token_index("EM_ACC_TITLE")

///|
let t_title : Int32 = token_index("EM_TITLE")

///|
let t_entity : Int32 = token_index("entity")

///|
let t_data : Int32 = token_index("data")

///|
let t_note : Int32 = token_index("note")

///|
let t_gwt : Int32 = token_index("gwt")

///|
let t_given : Int32 = token_index("given")

///|
let t_when : Int32 = token_index("when")

///|
let t_then : Int32 = token_index("then")

///|
let time_frame : Array[Int32] = token_kinds(["tf", "timeframe"])

///|
let reset_frame : Array[Int32] = token_kinds(["rf", "resetframe"])

///|
let entity_type : Array[Int32] = token_kinds([
  "rmo", "readmodel", "ui", "cmd", "command", "evt", "event", "pcr", "processor",
])

///|
let data_types : Array[Int32] = token_kinds([
  "json", "jsobj", "figma", "salt", "uri", "md", "html", "text",
])
