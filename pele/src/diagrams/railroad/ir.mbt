// `railroad-beta`: Mermaid's own notation, one constructor call per node.

///|
const IR_NONTERMINAL : Int32 = 1

///|
const IR_ZERO_OR_MORE : Int32 = 2

///|
const IR_ONE_OR_MORE : Int32 = 3

///|
const IR_SEQUENCE : Int32 = 4

///|
const IR_OPTIONAL : Int32 = 5

///|
const IR_TERMINAL : Int32 = 6

///|
const IR_SPECIAL : Int32 = 7

///|
const IR_CHOICE : Int32 = 8

///|
const IR_EQUALS : Int32 = 9

///|
const IR_SEMICOLON : Int32 = 10

///|
const IR_OPEN : Int32 = 11

///|
const IR_COMMA : Int32 = 12

///|
const IR_CLOSE : Int32 = 13

///|
const IR_TITLE : Int32 = 14

///|
const IR_ID : Int32 = 17

///|
const IR_STRING : Int32 = 18

///|
let ir_tokens : Array[@common.TokenType] = [
  @common.keyword("railroad-beta"),
  word("nonterminal"),
  word("zeroOrMore"),
  word("oneOrMore"),
  word("sequence"),
  word("optional"),
  word("terminal"),
  word("special"),
  word("choice"),
  @common.literal("=", "="),
  @common.literal(";", ";"),
  @common.literal("(", "("),
  @common.literal(",", ","),
  @common.literal(")", ")"),
  title(continues_identifier),
  acc_title,
  acc_descr,
  identifier("RR_ID"),
  quoted("RR_STRING"),
  ..hidden_tokens("RR"),
  block_comment("RR_BLOCK_COMMENT"),
]

///|
/// A constructor call that is still waiting for its closing parenthesis.
priv struct Open {
  kind : Int32
  items : Array[RailroadNode]
}

///|
fn argument(r : @common.TokenReader) -> String raise @errors.PeleError {
  r.i += 1
  r.expect(IR_OPEN) |> ignore
  let value = unescape(r.expect(IR_STRING))
  r.expect(IR_CLOSE) |> ignore
  value
}

///|
fn close_call(call : Open) -> RailroadNode {
  let kid = call.items[0]
  match call.kind {
    IR_SEQUENCE => sequence(call.items)
    IR_CHOICE => choice(call.items)
    IR_OPTIONAL => Optional(kid)
    IR_ONE_OR_MORE => repetition(kid, 1)
    _ => repetition(kid, 0)
  }
}

///|
/// Reads one expression with an explicit stack, so that nesting depth is bounded by memory, not by the stack.
fn expression(r : @common.TokenReader) -> RailroadNode raise @errors.PeleError {
  let open : Array[Open] = []
  while true {
    let kind = r.kind()
    let mut value = if kind == IR_TERMINAL {
      Terminal(argument(r))
    } else if kind == IR_NONTERMINAL {
      NonTerminal(argument(r))
    } else if kind == IR_SPECIAL {
      Special(argument(r))
    } else if kind == IR_SEQUENCE ||
      kind == IR_CHOICE ||
      kind == IR_OPTIONAL ||
      kind == IR_ONE_OR_MORE ||
      kind == IR_ZERO_OR_MORE {
      r.i += 1
      r.expect(IR_OPEN) |> ignore
      open.push({ kind, items: [], })
      continue
    } else {
      r.fail("an expression")
    }
    while true {
      guard open.last() is Some(parent) else { return value }
      parent.items.push(value)
      let list = parent.kind == IR_SEQUENCE || parent.kind == IR_CHOICE
      if list && r.accept(IR_COMMA) {
        break
      }
      r.expect(IR_CLOSE) |> ignore
      open.pop() |> ignore
      value = close_call(parent)
    }
  }
  abort("unreachable")
}

///|
fn parse_ir(src : String) -> Grammar raise @errors.PeleError {
  parse_grammar(src, ir_tokens, IR_TITLE, unescape, r => {
    let name = r.expect(IR_ID)
    r.expect(IR_EQUALS) |> ignore
    let definition = expression(r)
    r.expect(IR_SEMICOLON) |> ignore
    { name, definition, }
  })
}
