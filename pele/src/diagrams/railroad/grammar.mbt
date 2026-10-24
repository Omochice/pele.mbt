// What the four railroad grammars share: the title and accessibility tokens (which, unlike
// the ones in Mermaid's common grammar, do not take leading blanks), the hidden tokens, the
// statements before the first rule, and string values.
// pele gives a token type a list of longer alternatives; here a type that would lose to such an
// alternative does not match, so that the alternative's own type, which follows it, is the one chosen.

///|
let letters : String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

///|
fn is_blank_at(src : String, at : Int32) -> Bool {
  @util.is_blank(@util.code_at(src, at))
}

///|
/// A type from `common` that matches the same text but does not take blanks before it.
fn without_leading_blanks(
  base : @common.TokenType,
  first : String,
) -> @common.TokenType {
  {
    name: base.name,
    scanner: () => {
      let scan = (base.scanner)()
      (src, p) => {
        if is_blank_at(src, p) {
          @common.NO_MATCH
        } else {
          scan(src, p)
        }
      }
    },
    first: Some(first),
    hidden: false,
  }
}

///|
let title : @common.TokenType = without_leading_blanks(@common.title, "t")

///|
let acc_title : @common.TokenType = without_leading_blanks(
  @common.acc_title, "a",
)

///|
/// `accDescr(?:[\t ]*:([^\n\r]*?(?=%%)|[^\n\r]*)|\s*{([^}]*)})`.
/// The braced form scans to the next closing brace.
/// Once none is found, none exists further on either, so later braced descriptions fail without scanning again.
let acc_descr : @common.TokenType = {
  name: "ACC_DESCR",
  scanner: () => {
    let mut unclosed = 0x7fffffff
    (src, at) => {
      if !@util.starts_with_at(src, "accDescr", at) {
        return @common.NO_MATCH
      }
      let n = src.length()
      let mut i = at + 8
      while i < n && is_blank_at(src, i) {
        i += 1
      }
      if @util.code_at(src, i) == ':'.to_int() {
        i += 1
        while i < n {
          let c = @util.code_at(src, i)
          if c == '\n'.to_int() ||
            c == '\r'.to_int() ||
            (c == '%'.to_int() && @util.code_at(src, i + 1) == '%'.to_int()) {
            break
          }
          i += 1
        }
        return i
      }
      while i < n && @util.is_space(@util.code_at(src, i)) {
        i += 1
      }
      if @util.code_at(src, i) != '{'.to_int() || i >= unclosed {
        return @common.NO_MATCH
      }
      let close = @util.index_of(src, "}", from=i + 1)
      if close == -1 {
        unclosed = i
        @common.NO_MATCH
      } else {
        close + 1
      }
    }
  },
  first: Some("a"),
  hidden: false,
}

///|
/// `[A-Z_a-z][\w-]*`
fn identifier(name : String) -> @common.TokenType {
  @common.pattern(
    name,
    (src, p) => {
      let c = @util.code_at(src, p)
      if !(@util.is_letter(c) || c == '_'.to_int()) {
        return @common.NO_MATCH
      }
      let mut i = p + 1
      while @util.is_word(@util.code_at(src, i)) ||
            @util.code_at(src, i) == '-'.to_int() {
        i += 1
      }
      i
    },
    first=letters + "_",
  )
}

///|
/// A fixed word that a longer name starting with it is not.
fn word(name : String) -> @common.TokenType {
  @common.pattern(
    name,
    (src, p) => {
      if !@util.starts_with_at(src, name, p) {
        return @common.NO_MATCH
      }
      let end = p + name.length()
      let next = @util.code_at(src, end)
      if @util.is_word(next) || next == '-'.to_int() {
        @common.NO_MATCH
      } else {
        end
      }
    },
    first=@util.slice(name, 0, end=1),
  )
}

///|
fn quoted(name : String) -> @common.TokenType {
  { ..@common.string, name, }
}

///|
/// Whitespace, front matter, directive, and `%%` comment, in the order every railroad grammar lists them.
fn hidden_tokens(prefix : String) -> Array[@common.TokenType] {
  [
    @common.pattern(
      prefix + "_WHITESPACE",
      (src, p) => {
        let mut i = p
        while i < src.length() &&
              (
                is_blank_at(src, i) ||
                @util.code_at(src, i) == '\r'.to_int() ||
                @util.code_at(src, i) == '\n'.to_int()
              ) {
          i += 1
        }
        if i > p {
          i
        } else {
          @common.NO_MATCH
        }
      },
      first="\t \r\n",
      hidden=true,
    ),
    { ..@common.yaml, name: prefix + "_YAML", },
    { ..@common.directive, name: prefix + "_DIRECTIVE", },
    { ..@common.single_line_comment, name: prefix + "_SINGLE_LINE_COMMENT", },
  ]
}

///|
/// A comment between an opener and a closer, which stays unmatched when no closer follows.
fn delimited_comment(
  name : String,
  open : String,
  close : String,
) -> @common.TokenType {
  @common.pattern(
    name,
    (src, p) => {
      if !@util.starts_with_at(src, open, p) {
        return @common.NO_MATCH
      }
      let end = @util.index_of(src, close, from=p + 2)
      if end == -1 {
        @common.NO_CLOSER
      } else {
        end + 2
      }
    },
    first=@util.slice(open, 0, end=1),
    hidden=true,
  )
}

///|
fn block_comment(name : String) -> @common.TokenType {
  delimited_comment(name, "/*", "*/")
}

///|
/// Mermaid's railroad value converters know three escapes; any other escaped character stands for itself.
fn unescape(text : String) -> String {
  if @util.index_of(text, "\\") == -1 {
    return @util.slice(text, 1, end=-1)
  }
  let end = text.length() - 1
  let out = StringBuilder()
  let mut i = 1
  while i < end {
    let c = @util.code_at(text, i)
    if c == '\\'.to_int() && i + 1 < end {
      i += 1
      let escaped = @util.code_at(text, i)
      if escaped == 'n'.to_int() {
        out.write_char('\n')
      } else if escaped == 'r'.to_int() {
        out.write_char('\r')
      } else if escaped == 't'.to_int() {
        out.write_char('\t')
      } else {
        @util.write_range(out, text, i, i + 1)
      }
    } else {
      @util.write_range(out, text, i, i + 1)
    }
    i += 1
  }
  out.to_string()
}

///|
/// The statements of a grammar as written: its titles and its rules.
priv struct Grammar {
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
  rules : Array[RailroadRule]
}

///|
/// Parses the keyword, then any titles and accessibility statements, then rules to the end of the text.
/// Every table starts with its keyword and has the title, accTitle, and accDescr tokens in a row from `meta`.
fn parse_grammar(
  src : String,
  types : ArrayView[@common.TokenType],
  meta : Int32,
  unquote : (String) -> String,
  rule : (@common.TokenReader) -> RailroadRule raise @errors.PeleError,
) -> Grammar raise @errors.PeleError {
  let r = @common.TokenReader::new(
    @common.tokenize(src, types, "railroad"),
    types,
    "railroad",
  )
  let ast : Grammar = {
    title: None,
    acc_title: None,
    acc_descr: None,
    rules: [],
  }
  r.expect(0) |> ignore
  while true {
    let kind = r.kind()
    if kind == meta {
      let text = @common.title_value(r.take())
      let quote = @util.code_at(text, 0)
      ast.title = Some(
        if (quote == '"'.to_int() || quote == '\''.to_int()) &&
          @util.code_at(text, text.length() - 1) == quote {
          unquote(text)
        } else {
          text
        },
      )
    } else if kind == meta + 1 {
      ast.acc_title = Some(@common.acc_title_value(r.take()))
    } else if kind == meta + 2 {
      ast.acc_descr = Some(@common.acc_descr_value(r.take()))
    } else {
      break
    }
  }
  while r.kind() != -1 {
    ast.rules.push(rule(r))
  }
  ast
}

///|
/// A sequence or a choice of one is that one, in every notation.
fn sequence(elements : Array[RailroadNode]) -> RailroadNode {
  if elements.length() == 1 {
    elements[0]
  } else {
    Sequence(elements)
  }
}

///|
fn choice(alternatives : Array[RailroadNode]) -> RailroadNode {
  if alternatives.length() == 1 {
    alternatives[0]
  } else {
    Choice(alternatives)
  }
}

///|
fn repetition(
  element : RailroadNode,
  min : Double,
  max~ : Double = @double.infinity,
) -> RailroadNode {
  Repetition(element~, min~, max~)
}
