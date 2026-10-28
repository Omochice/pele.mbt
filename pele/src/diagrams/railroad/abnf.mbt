// `railroad-abnf-beta`: ABNF as in RFC 5234, with each rule closed by a semicolon.

///|
const ABNF_EQUALS : Int32 = 1

///|
const ABNF_SEMICOLON : Int32 = 2

///|
const ABNF_SLASH : Int32 = 3

///|
const ABNF_GROUP : Int32 = 4

///|
const ABNF_OPTION : Int32 = 6

///|
const ABNF_TITLE : Int32 = 8

///|
const ABNF_NAME : Int32 = 11

///|
const ABNF_STRING : Int32 = 12

///|
const ABNF_NUMBER : Int32 = 13

///|
const ABNF_REPEAT : Int32 = 14

///|
const ABNF_EXACT : Int32 = 15

///|
/// `[A-Za-z][A-Za-z0-9-]*`
let abnf_name : @common.TokenType = @common.pattern(
  "ABNF_RULENAME",
  (src, p) => {
    if !@util.is_letter(@util.code_at(src, p)) {
      return @common.NO_MATCH
    }
    let mut i = p + 1
    while @util.is_letter(@util.code_at(src, i)) ||
          @util.is_digit(@util.code_at(src, i)) ||
          @util.code_at(src, i) == '-'.to_int() {
      i += 1
    }
    i
  },
  first=letters,
)

///|
/// A semicolon closes a rule only at the end of its line; with anything after it, it starts a comment.
let closing_semicolon : @common.TokenType = @common.pattern(
  ";",
  (src, p) => {
    if @util.code_at(src, p) != ';'.to_int() {
      return @common.NO_MATCH
    }
    let next = @util.code_at(src, p + 1)
    if next == -1 || next == '\n'.to_int() || next == '\r'.to_int() {
      p + 1
    } else {
      @common.NO_MATCH
    }
  },
  first=";",
)

///|
let abnf_comment : @common.TokenType = @common.pattern(
  "ABNF_COMMENT",
  (src, p) => {
    if @util.code_at(src, p) != ';'.to_int() {
      return @common.NO_MATCH
    }
    let mut i = p + 1
    while i < src.length() &&
          @util.code_at(src, i) != '\n'.to_int() &&
          @util.code_at(src, i) != '\r'.to_int() {
      i += 1
    }
    i
  },
  first=";",
  hidden=true,
)

///|
/// `"[^"]*"`
let abnf_string : @common.TokenType = @common.pattern(
  "ABNF_STRING",
  (src, p) => {
    if @util.code_at(src, p) != '"'.to_int() {
      return @common.NO_MATCH
    }
    let close = @util.index_of(src, "\"", from=p + 1)
    if close == -1 {
      @common.NO_MATCH
    } else {
      close + 1
    }
  },
  first="\"",
)

///|
fn hex_run(src : String, from : Int32) -> Int32 {
  let mut i = from
  while @util.is_hex(@util.code_at(src, i)) {
    i += 1
  }
  i
}

///|
/// `%[xXdDbB][0-9A-Fa-f]+(?:-[0-9A-Fa-f]+|\.[0-9A-Fa-f]+)*`
let abnf_numval : @common.TokenType = {
  name: "ABNF_NUMVAL",
  scanner: () => {
    (src, p, _) => {
      if @util.code_at(src, p) != '%'.to_int() {
        return @common.NO_MATCH
      }
      let base = @util.code_at(src, p + 1)
      if !"xXdDbB".contains_code_unit(base.to_uint16()) {
        return @common.NO_MATCH
      }
      let mut end = hex_run(src, p + 2)
      if end == p + 2 {
        return @common.NO_MATCH
      }
      while true {
        let c = @util.code_at(src, end)
        if c != '-'.to_int() && c != '.'.to_int() {
          break
        }
        let next = hex_run(src, end + 1)
        if next == end + 1 {
          break
        }
        end = next
      }
      end
    }
  },
  first: Some("%"),
  hidden: false,
}

///|
fn digit_run(src : String, from : Int32) -> Int32 {
  let mut i = from
  while @util.is_digit(@util.code_at(src, i)) {
    i += 1
  }
  i
}

///|
/// `[0-9]*\*[0-9]*`
let abnf_repeat : @common.TokenType = @common.pattern(
  "ABNF_REPEAT",
  (src, p) => {
    let star = digit_run(src, p)
    if @util.code_at(src, star) != '*'.to_int() {
      return @common.NO_MATCH
    }
    digit_run(src, star + 1)
  },
  first="0123456789*",
)

///|
/// `[0-9]+`
let abnf_exact : @common.TokenType = @common.pattern(
  "ABNF_EXACT_REPEAT",
  (src, p) => {
    let end = digit_run(src, p)
    if end > p {
      end
    } else {
      @common.NO_MATCH
    }
  },
  first="0123456789",
)

///|
let abnf_tokens : Array[@common.TokenType] = [
  @common.keyword("railroad-abnf-beta"),
  @common.literal("=", "="),
  closing_semicolon,
  @common.literal("/", "/"),
  @common.literal("(", "("),
  @common.literal(")", ")"),
  @common.literal("[", "["),
  @common.literal("]", "]"),
  title,
  acc_title,
  acc_descr,
  abnf_name,
  abnf_string,
  abnf_numval,
  abnf_repeat,
  abnf_exact,
  ..hidden_tokens("ABNF"),
  abnf_comment,
]

///|
/// The value of the leading digits of `text` from `from`, as `parseInt` reads them.
fn leading_integer(text : String, from : Int32) -> Double {
  let digits = @util.slice(text, from, end=digit_run(text, from))
  @string.parse_double(digits) catch {
    _ => @double.infinity
  }
}

///|
/// An element with the repeat written before it: `n`, `n*m`, `n*`, `*m`, or `*`.
fn repeated(repeat : String?, node : RailroadNode) -> RailroadNode {
  guard repeat is Some(repeat) else { return node }
  let star = @util.index_of(repeat, "*")
  let exact = star == -1
  let min = if star > 0 || exact { leading_integer(repeat, 0) } else { 0.0 }
  let max = if exact {
    min
  } else if star < repeat.length() - 1 {
    leading_integer(repeat, star + 1)
  } else {
    @double.infinity
  }
  if min == 0 && max == 1 {
    Optional(node)
  } else {
    repetition(node, min, max~)
  }
}

///|
/// One open bracket, or the rule itself at the bottom of the stack.
priv struct AbnfFrame {
  alternatives : Array[RailroadNode]
  mut elements : Array[RailroadNode]
  /// The opening token of the bracket, or -1 for the rule.
  open : Int32
  close : Int32
  /// The repeat written before the bracket.
  repeat : String?
}

///|
fn AbnfFrame::finish(self : AbnfFrame) -> RailroadNode {
  self.alternatives.push(sequence(self.elements))
  let inside = choice(self.alternatives)
  if self.open == ABNF_OPTION {
    Optional(inside)
  } else {
    inside
  }
}

///|
fn starts_element(kind : Int32) -> Bool {
  kind == ABNF_STRING ||
  kind == ABNF_NUMBER ||
  kind == ABNF_NAME ||
  kind == ABNF_GROUP ||
  kind == ABNF_OPTION ||
  kind == ABNF_REPEAT ||
  kind == ABNF_EXACT
}

///|
/// Reads a rule's definition with an explicit stack of open brackets, so that nesting depth is bounded by memory, not by the stack.
fn abnf_alternation(
  r : @common.TokenReader,
) -> RailroadNode raise @errors.PeleError {
  let stack : Array[AbnfFrame] = []
  let mut top : AbnfFrame = {
    alternatives: [],
    elements: [],
    open: -1,
    close: -2,
    repeat: None,
  }
  while true {
    let mut repeat = if r.kind() == ABNF_REPEAT || r.kind() == ABNF_EXACT {
      Some(r.take())
    } else {
      None
    }
    let kind = r.kind()
    let mut primary = if kind == ABNF_STRING {
      Terminal(@util.slice(r.take(), 1, end=-1))
    } else if kind == ABNF_NUMBER {
      Terminal(r.take())
    } else if kind == ABNF_NAME {
      NonTerminal(r.take())
    } else if kind == ABNF_GROUP || kind == ABNF_OPTION {
      r.i += 1
      stack.push(top)
      top = {
        alternatives: [],
        elements: [],
        open: kind,
        close: kind + 1,
        repeat,
      }
      continue
    } else {
      r.fail("a string, a number, a name, or an opening bracket")
    }
    while true {
      top.elements.push(repeated(repeat, primary))
      let k = r.kind()
      if k == top.close {
        r.i += 1
        primary = top.finish()
        repeat = top.repeat
        top = stack.pop().unwrap()
        continue
      }
      if k == ABNF_SLASH {
        r.i += 1
        top.alternatives.push(sequence(top.elements))
        top.elements = []
      } else if !starts_element(k) {
        if stack.is_empty() {
          return top.finish()
        }
        r.fail("token of type '\{abnf_tokens[top.close].name}'")
      }
      break
    }
  }
  abort("unreachable")
}

///|
fn parse_abnf(src : String) -> Grammar raise @errors.PeleError {
  parse_grammar(
    src,
    abnf_tokens,
    ABNF_TITLE,
    text => @util.slice(text, 1, end=-1),
    r => {
      let name = r.expect(ABNF_NAME)
      r.expect(ABNF_EQUALS) |> ignore
      let definition = abnf_alternation(r)
      r.expect(ABNF_SEMICOLON) |> ignore
      { name, definition, }
    },
  )
}
