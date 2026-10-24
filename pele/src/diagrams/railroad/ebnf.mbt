// `railroad-ebnf-beta`: EBNF in the W3C and ISO 14977 styles.

///|
const EBNF_DEFINES : Int32 = 1

///|
const EBNF_EQUALS : Int32 = 2

///|
const EBNF_SEMICOLON : Int32 = 3

///|
const EBNF_BAR : Int32 = 4

///|
const EBNF_COMMA : Int32 = 5

///|
const EBNF_GROUP : Int32 = 6

///|
const EBNF_OPTION : Int32 = 8

///|
const EBNF_REPEAT : Int32 = 10

///|
const EBNF_QUESTION : Int32 = 12

///|
const EBNF_STAR : Int32 = 13

///|
const EBNF_PLUS : Int32 = 14

///|
const EBNF_MINUS : Int32 = 15

///|
const EBNF_TITLE : Int32 = 16

///|
const EBNF_ID : Int32 = 19

///|
const EBNF_STRING : Int32 = 20

///|
const EBNF_SPECIAL : Int32 = 21

///|
/// A question mark, text with something other than blanks in it and no `?` or `;`, and a question mark.
/// Mermaid's pattern looks ahead with two nested runs, which rescans; this reads the text once.
fn special_sequence(src : String, at : Int32) -> Int32 {
  if @util.code_at(src, at) != '?'.to_int() {
    return @common.NO_MATCH
  }
  let mut solid = false
  for i = at + 1; i < src.length(); i = i + 1 {
    let c = @util.code_at(src, i)
    if c == '?'.to_int() {
      return if solid { i + 1 } else { @common.NO_MATCH }
    }
    if c == ';'.to_int() {
      return @common.NO_MATCH
    }
    solid = solid || !@util.is_space(c)
  }
  @common.NO_MATCH
}

///|
/// A question mark that does not start a special sequence.
let question : @common.TokenType = @common.pattern(
  "?",
  (src, p) => {
    if @util.code_at(src, p) != '?'.to_int() ||
      special_sequence(src, p) != @common.NO_MATCH {
      @common.NO_MATCH
    } else {
      p + 1
    }
  },
  first="?",
)

///|
let special_token : @common.TokenType = @common.pattern(
  "EBNF_SPECIAL_SEQUENCE",
  special_sequence,
  first="?",
)

///|
/// An opening parenthesis that does not start an ISO comment.
/// When the text holds no `*)` at all, no later comment closes either, so that is not searched for again.
let open_group : @common.TokenType = {
  name: "(",
  scanner: () => {
    let mut unclosed = false
    (src, p) => {
      if @util.code_at(src, p) != '('.to_int() {
        return @common.NO_MATCH
      }
      if @util.code_at(src, p + 1) == '*'.to_int() && !unclosed {
        if @util.index_of(src, "*)", from=p + 2) != -1 {
          return @common.NO_MATCH
        }
        unclosed = true
      }
      p + 1
    }
  },
  first: Some("("),
  hidden: false,
}

///|
/// A dash that does not start front matter.
let minus : @common.TokenType = {
  name: "-",
  scanner: () => {
    let front_matter = (@common.yaml.scanner)()
    let mut unclosed = false
    (src, p) => {
      if @util.code_at(src, p) != '-'.to_int() {
        return @common.NO_MATCH
      }
      if !unclosed {
        let end = front_matter(src, p)
        if end > p {
          return @common.NO_MATCH
        }
        unclosed = end == @common.NO_CLOSER
      }
      p + 1
    }
  },
  first: Some("-"),
  hidden: false,
}

///|
let ebnf_tokens : Array[@common.TokenType] = [
  @common.keyword("railroad-ebnf-beta"),
  @common.literal("::=", "::="),
  @common.literal("=", "="),
  @common.literal(";", ";"),
  @common.literal("|", "|"),
  @common.literal(",", ","),
  open_group,
  @common.literal(")", ")"),
  @common.literal("[", "["),
  @common.literal("]", "]"),
  @common.literal("{", "{"),
  @common.literal("}", "}"),
  question,
  @common.literal("*", "*"),
  @common.literal("+", "+"),
  minus,
  title,
  acc_title,
  acc_descr,
  identifier("EBNF_ID"),
  quoted("EBNF_STRING"),
  special_token,
  ..hidden_tokens("EBNF"),
  block_comment("EBNF_BLOCK_COMMENT"),
  delimited_comment("EBNF_ISO_COMMENT", "(*", "*)"),
]

///|
/// One open bracket, or the rule itself at the bottom of the stack.
priv struct EbnfFrame {
  alternatives : Array[RailroadNode]
  mut elements : Array[RailroadNode]
  /// The opening token of the bracket, or -1 for the rule.
  open : Int32
  close : Int32
  /// Whether the bracket is the right side of an exception.
  except : Bool
}

///|
fn EbnfFrame::finish(self : EbnfFrame) -> RailroadNode {
  self.alternatives.push(sequence(self.elements))
  let inside = choice(self.alternatives)
  match self.open {
    EBNF_OPTION => Optional(inside)
    EBNF_REPEAT => repetition(inside, 0)
    _ => inside
  }
}

///|
fn starts_primary(kind : Int32) -> Bool {
  kind == EBNF_STRING ||
  kind == EBNF_ID ||
  kind == EBNF_SPECIAL ||
  kind == EBNF_GROUP ||
  kind == EBNF_OPTION ||
  kind == EBNF_REPEAT
}

///|
/// Reads a rule's definition with an explicit stack of open brackets, so that nesting depth is bounded by memory, not by the stack.
/// Each postfix operator applies at once to everything before it in its term, and an exception
/// joins the term as it stands.
fn ebnf_definition(
  r : @common.TokenReader,
) -> RailroadNode raise @errors.PeleError {
  let stack : Array[EbnfFrame] = []
  let mut top : EbnfFrame = {
    alternatives: [],
    elements: [],
    open: -1,
    close: -2,
    except: false,
  }
  let mut except = false
  while true {
    let kind = r.kind()
    let mut primary = if kind == EBNF_STRING {
      Terminal(unescape(r.take()))
    } else if kind == EBNF_ID {
      NonTerminal(r.take())
    } else if kind == EBNF_SPECIAL {
      Special(@util.trim(@util.slice(r.take(), 1, end=-1)))
    } else if kind == EBNF_GROUP || kind == EBNF_OPTION || kind == EBNF_REPEAT {
      r.i += 1
      stack.push(top)
      top = {
        alternatives: [],
        elements: [],
        open: kind,
        close: kind + 1,
        except,
      }
      except = false
      continue
    } else {
      r.fail("a terminal, a name, or an opening bracket")
    }
    while true {
      if except {
        let last = top.elements.length() - 1
        top.elements[last] = Sequence([
          top.elements[last],
          Terminal("-"),
          primary,
        ])
        except = false
      } else {
        top.elements.push(primary)
      }
      let last = top.elements.length() - 1
      while true {
        let k = r.kind()
        if k == EBNF_QUESTION {
          top.elements[last] = Optional(top.elements[last])
        } else if k == EBNF_STAR {
          top.elements[last] = repetition(top.elements[last], 0)
        } else if k == EBNF_PLUS {
          top.elements[last] = repetition(top.elements[last], 1)
        } else {
          break
        }
        r.i += 1
      }
      let k = r.kind()
      if k == top.close {
        r.i += 1
        primary = top.finish()
        except = top.except
        top = stack.pop().unwrap()
        continue
      }
      if k == EBNF_MINUS {
        r.i += 1
        except = true
      } else if k == EBNF_COMMA {
        r.i += 1
      } else if k == EBNF_BAR {
        r.i += 1
        top.alternatives.push(sequence(top.elements))
        top.elements = []
      } else if !starts_primary(k) {
        if stack.is_empty() {
          return top.finish()
        }
        r.fail("token of type '\{ebnf_tokens[top.close].name}'")
      }
      break
    }
  }
  abort("unreachable")
}

///|
fn parse_ebnf(src : String) -> Grammar raise @errors.PeleError {
  parse_grammar(src, ebnf_tokens, EBNF_TITLE, unescape, r => {
    let name = r.expect(EBNF_ID)
    if !r.accept(EBNF_EQUALS) {
      r.expect(EBNF_DEFINES) |> ignore
    }
    let definition = ebnf_definition(r)
    r.expect(EBNF_SEMICOLON) |> ignore
    { name, definition, }
  })
}
