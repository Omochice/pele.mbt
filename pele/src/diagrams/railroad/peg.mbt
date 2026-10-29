// `railroad-peg-beta`: parsing expression grammars.

///|
const PEG_ARROW : Int32 = 1

///|
const PEG_SEMICOLON : Int32 = 2

///|
const PEG_SLASH : Int32 = 3

///|
const PEG_AND : Int32 = 4

///|
const PEG_NOT : Int32 = 5

///|
const PEG_QUESTION : Int32 = 6

///|
const PEG_STAR : Int32 = 7

///|
const PEG_PLUS : Int32 = 8

///|
const PEG_GROUP : Int32 = 9

///|
const PEG_GROUP_END : Int32 = 10

///|
const PEG_DOT : Int32 = 11

///|
const PEG_TITLE : Int32 = 12

///|
const PEG_ID : Int32 = 15

///|
const PEG_STRING : Int32 = 16

///|
let peg_tokens : Array[@common.TokenType] = [
  @common.keyword("railroad-peg-beta"),
  @common.literal("<-", "<-"),
  @common.literal(";", ";"),
  @common.literal("/", "/"),
  @common.literal("&", "&"),
  @common.literal("!", "!"),
  @common.literal("?", "?"),
  @common.literal("*", "*"),
  @common.literal("+", "+"),
  @common.literal("(", "("),
  @common.literal(")", ")"),
  @common.literal(".", "."),
  title(continues_identifier),
  acc_title,
  acc_descr,
  identifier("PEG_ID"),
  quoted("PEG_STRING"),
  ..hidden_tokens("PEG"),
  @common.pattern(
    "PEG_LINE_COMMENT",
    (src, p) => {
      if @util.code_at(src, p) != '#'.to_int() {
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
    first="#",
    hidden=true,
  ),
]

///|
/// One open group, or the rule itself at the bottom of the stack.
priv struct PegFrame {
  alternatives : Array[RailroadNode]
  mut elements : Array[RailroadNode]
  /// The predicate written before the group.
  operator : String?
}

///|
fn PegFrame::finish(self : PegFrame) -> RailroadNode {
  self.alternatives.push(sequence(self.elements))
  choice(self.alternatives)
}

///|
/// What a predicate shows of the expression it looks ahead for.
fn label(node : RailroadNode) -> String {
  match node {
    Terminal(value) => "\"\{value}\""
    NonTerminal(name) => name
    Special(text) => text
    _ => "(...)"
  }
}

///|
/// Reads a rule's definition with an explicit stack of open groups, so that nesting depth is bounded by memory, not by the stack.
fn peg_definition(
  r : @common.TokenReader,
) -> RailroadNode raise @errors.PeleError {
  let stack : Array[PegFrame] = []
  let mut top : PegFrame = { alternatives: [], elements: [], operator: None, }
  while true {
    let mut operator = if r.kind() == PEG_AND || r.kind() == PEG_NOT {
      Some(r.take())
    } else {
      None
    }
    let kind = r.kind()
    let mut primary = if kind == PEG_STRING {
      Terminal(unescape(r.take()))
    } else if kind == PEG_ID {
      NonTerminal(r.take())
    } else if kind == PEG_DOT {
      Special(r.take())
    } else if kind == PEG_GROUP {
      r.i += 1
      stack.push(top)
      top = { alternatives: [], elements: [], operator, }
      continue
    } else {
      r.fail("a literal, a name, a dot, or an opening parenthesis")
    }
    while true {
      let suffixed = if r.accept(PEG_QUESTION) {
        Optional(primary)
      } else if r.accept(PEG_STAR) {
        repetition(primary, 0)
      } else if r.accept(PEG_PLUS) {
        repetition(primary, 1)
      } else {
        primary
      }
      top.elements.push(
        match operator {
          Some(predicate) => Special(predicate + label(suffixed))
          None => suffixed
        },
      )
      let k = r.kind()
      if k == PEG_GROUP_END && !stack.is_empty() {
        r.i += 1
        primary = top.finish()
        operator = top.operator
        top = stack.pop().unwrap()
        continue
      }
      if k == PEG_SLASH {
        r.i += 1
        top.alternatives.push(sequence(top.elements))
        top.elements = []
      } else if k != PEG_AND &&
        k != PEG_NOT &&
        k != PEG_STRING &&
        k != PEG_ID &&
        k != PEG_DOT &&
        k != PEG_GROUP {
        if stack.is_empty() {
          return top.finish()
        }
        r.fail("token of type ')'")
      }
      break
    }
  }
  abort("unreachable")
}

///|
fn parse_peg(src : String) -> Grammar raise @errors.PeleError {
  parse_grammar(src, peg_tokens, PEG_TITLE, unescape, r => {
    let name = r.expect(PEG_ID)
    r.expect(PEG_ARROW) |> ignore
    let definition = peg_definition(r)
    r.expect(PEG_SEMICOLON) |> ignore
    { name, definition, }
  })
}
