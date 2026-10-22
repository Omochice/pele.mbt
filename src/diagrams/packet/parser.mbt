///|
/// A field as written in the source.
/// Numbers are doubles because `Number()` reads digit runs of any length, and a long one becomes infinity.
pub(all) struct PacketBlockAst {
  start : Double?
  end : Double?
  bits : Double?
  label : String
}

///|
/// The statements of a packet diagram, as Mermaid's grammar reads them.
pub(all) struct PacketAst {
  title : String?
  acc_title : String?
  acc_descr : String?
  blocks : Array[PacketBlockAst]
}

///|
const PACKET_BETA : Int32 = 0

///|
const PACKET : Int32 = 1

///|
const DASH : Int32 = 2

///|
const PLUS : Int32 = 3

///|
const COLON : Int32 = 4

///|
const ACC_DESCR : Int32 = 5

///|
const ACC_TITLE : Int32 = 6

///|
const TITLE : Int32 = 7

///|
const INT : Int32 = 8

///|
const STRING : Int32 = 9

///|
const NEWLINE : Int32 = 10

///|
/// Answers as INT's pattern `0|[1-9][0-9]*(?!\.)` does.
/// The lookahead belongs to the second alternative only, so a zero ends its number even before a dot.
/// A digit run before a dot gives back its last digit.
fn int_scanner(src : String, p : Int32) -> Int32 {
  let first = @util.code_at(src, p)
  if first == '0'.to_int() {
    return p + 1
  }
  if !@util.is_digit(first) {
    return @common.NO_MATCH
  }
  let mut end = p + 1
  while @util.is_digit(@util.code_at(src, end)) {
    end += 1
  }
  if @util.code_at(src, end) != '.'.to_int() {
    return end
  }
  if end - 1 > p {
    end - 1
  } else {
    @common.NO_MATCH
  }
}

///|
/// A dash, unless the same text starts front matter, which Langium lets win over it.
/// Chevrotain's `longer_alt` does this by trying the front matter type at the same place.
fn dash() -> @common.Scanner {
  let front_matter = (@common.yaml.scanner)()
  let mut closerless = false
  (src, p) => {
    if @util.code_at(src, p) != '-'.to_int() {
      return @common.NO_MATCH
    }
    if !closerless {
      let end = front_matter(src, p)
      if end == @common.NO_CLOSER {
        closerless = true
      } else if end > p + 1 {
        return @common.NO_MATCH
      }
    }
    p + 1
  }
}

///|
/// Mermaid's packet lexer, whose token order the constants above index.
let packet_tokens : Array[@common.TokenType] = [
  @common.literal("packet-beta", "packet-beta"),
  @common.keyword("packet"),
  { name: "-", scanner: dash, first: Some("-"), hidden: false, },
  @common.literal("+", "+"),
  @common.literal(":", ":"),
  @common.acc_descr,
  @common.acc_title,
  @common.title,
  @common.pattern("INT", int_scanner, first="0123456789"),
  @common.string,
  @common.newline,
  @common.whitespace,
  @common.yaml,
  @common.directive,
  @common.single_line_comment,
]

///|
fn end_of_line(r : @common.TokenReader) -> Unit raise @errors.PeleError {
  if r.kind() == -1 {
    return
  }
  if r.kind() != NEWLINE {
    r.fail("a line break or the end of input")
  }
  while r.kind() == NEWLINE {
    r.i += 1
  }
}

///|
/// Reads a packet diagram. Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_packet(source : String) -> PacketAst raise @errors.PeleError {
  let r = @common.TokenReader::new(
    @common.tokenize(source, packet_tokens, "packet"),
    packet_tokens,
    "packet",
  )
  let mut title = None
  let mut acc_title = None
  let mut acc_descr = None
  let blocks = []
  while r.kind() == NEWLINE {
    r.i += 1
  }
  if !r.accept(PACKET_BETA) {
    r.expect(PACKET) |> ignore
  }
  while r.kind() != -1 {
    match r.kind() {
      NEWLINE => r.i += 1
      ACC_DESCR => {
        acc_descr = Some(@common.acc_descr_value(r.take()))
        end_of_line(r)
      }
      ACC_TITLE => {
        acc_title = Some(@common.acc_title_value(r.take()))
        end_of_line(r)
      }
      TITLE => {
        title = Some(@common.title_value(r.take()))
        end_of_line(r)
      }
      INT | PLUS => {
        let mut start = None
        let mut end = None
        let mut bits = None
        if r.accept(PLUS) {
          bits = Some(@util.to_number(r.expect(INT)))
        } else {
          start = Some(@util.to_number(r.take()))
          if r.accept(DASH) {
            end = Some(@util.to_number(r.expect(INT)))
          }
        }
        r.expect(COLON) |> ignore
        let label = @common.string_value(r.expect(STRING))
        blocks.push({ start, end, bits, label, })
        end_of_line(r)
      }
      _ => r.fail("a field, a title, or a line break")
    }
  }
  { title, acc_title, acc_descr, blocks, }
}
