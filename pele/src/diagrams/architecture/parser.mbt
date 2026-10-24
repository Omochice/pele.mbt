///|
/// The side of a service or junction an edge leaves from or arrives at.
pub(all) enum Side {
  L
  R
  T
  B
}

///|
/// The letter that names the side in the source.
pub fn Side::name(self : Side) -> String {
  match self {
    L => "L"
    R => "R"
    T => "T"
    B => "B"
  }
}

///|
/// A group as written; `parent` is the group named after `in`.
pub(all) struct GroupAst {
  id : String
  icon : String?
  title : String?
  parent : String?
}

///|
/// A service as written; it carries an icon or an icon text, not both.
pub(all) struct ServiceAst {
  id : String
  icon : String?
  icon_text : String?
  title : String?
  parent : String?
}

///|
pub(all) struct JunctionAst {
  id : String
  parent : String?
}

///|
/// An edge as written: `into` is an arrowhead at that end, and `group` a `{group}` modifier.
pub(all) struct EdgeAst {
  lhs_id : String
  lhs_group : Bool
  lhs_dir : Side
  lhs_into : Bool
  title : String?
  rhs_into : Bool
  rhs_dir : Side
  rhs_id : String
  rhs_group : Bool
}

///|
/// An `align` statement; `direction` is `row` or `column`.
pub(all) struct AlignmentAst {
  direction : String
  members : Array[String]
}

///|
/// The statements of an architecture diagram, as Mermaid's grammar reads them, by kind.
pub(all) struct ArchitectureAst {
  title : String?
  acc_title : String?
  acc_descr : String?
  groups : Array[GroupAst]
  services : Array[ServiceAst]
  junctions : Array[JunctionAst]
  edges : Array[EdgeAst]
  alignments : Array[AlignmentAst]
}

///|
const HEADER : Int32 = 0

///|
const JUNCTION : Int32 = 1

///|
const SERVICE : Int32 = 2

///|
const COLUMN : Int32 = 3

///|
const GROUP : Int32 = 4

///|
const ALIGN : Int32 = 5

///|
const ROW : Int32 = 6

///|
const DASHES : Int32 = 7

///|
const IN : Int32 = 8

///|
const COLON : Int32 = 9

///|
const DASH : Int32 = 10

///|
const DIRECTION : Int32 = 11

///|
const ARROW_GROUP : Int32 = 12

///|
const INTO : Int32 = 13

///|
const ACC_DESCR : Int32 = 14

///|
const ACC_TITLE : Int32 = 15

///|
const TITLE : Int32 = 16

///|
const STRING : Int32 = 17

///|
const ID : Int32 = 18

///|
const NEWLINE : Int32 = 19

///|
const ICON : Int32 = 24

///|
const LABEL : Int32 = 25

///|
const ID_FIRST : String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"

///|
/// Answers as the ID pattern `[\w]([-\w]*\w)?` does, including its backtracking over trailing dashes.
fn id_end(src : String, at : Int32) -> Int32 {
  if !@util.is_word(@util.code_at(src, at)) {
    return @common.NO_MATCH
  }
  let mut end = at + 1
  let mut i = at + 1
  while true {
    let c = @util.code_at(src, i)
    if @util.is_word(c) {
      i += 1
      end = i
    } else if c == '-'.to_int() {
      i += 1
    } else {
      break
    }
  }
  end
}

///|
/// A fixed word with Chevrotain's LONGER_ALT of an id: where an id matches more text, the id wins.
/// Every type between the two in the order fails where the word matches, so declining here is
/// the same as choosing the id.
fn word(text : String) -> @common.TokenType {
  @common.pattern(
    text,
    (src, p) => {
      if !@util.starts_with_at(src, text, p) {
        return @common.NO_MATCH
      }
      let end = p + text.length()
      if id_end(src, p) > end {
        @common.NO_MATCH
      } else {
        end
      }
    },
    first=@util.slice(text, 0, end=1),
  )
}

///|
/// A run of dashes, unless front matter starting at the same place reads further, which
/// Langium lets win over it as Chevrotain's LONGER_ALT does.
fn dashes(text : String) -> @common.TokenType {
  {
    name: text,
    scanner: () => {
      let front_matter = (@common.yaml.scanner)()
      let mut closerless = false
      (src, p) => {
        if !@util.starts_with_at(src, text, p) {
          return @common.NO_MATCH
        }
        let end = p + text.length()
        if !closerless {
          let fence = front_matter(src, p)
          if fence == @common.NO_CLOSER {
            closerless = true
          } else if fence > end {
            return @common.NO_MATCH
          }
        }
        end
      }
    },
    first: Some("-"),
    hidden: false,
  }
}

///|
/// `\([\w-:]+\)`
fn scan_icon(src : String, p : Int32) -> Int32 {
  if @util.code_at(src, p) != '('.to_int() {
    return @common.NO_MATCH
  }
  let mut i = p + 1
  while true {
    let c = @util.code_at(src, i)
    if @util.is_word(c) || c == '-'.to_int() || c == ':'.to_int() {
      i += 1
    } else {
      break
    }
  }
  if i > p + 1 && @util.code_at(src, i) == ')'.to_int() {
    i + 1
  } else {
    @common.NO_MATCH
  }
}

///|
/// `\[(?:"([^"\\]|\\.)*"|'([^'\\]|\\.)*'|[^\[\]\r\n]+)\]`
/// Neither quoted repetition can give back a character that would let the closing quote come sooner.
fn scan_label(src : String, p : Int32) -> Int32 raise @errors.PeleError {
  if @util.code_at(src, p) != '['.to_int() {
    return @common.NO_MATCH
  }
  let open = @util.code_at(src, p + 1)
  if open == '"'.to_int() || open == '\''.to_int() {
    let (close, steps) = @common.quoted_span(src, p + 1)
    let closed = close != -1 && @util.code_at(src, close) == ']'.to_int()
    @common.check_quoted_steps(steps, untried_alternative=closed)
    if closed {
      return close + 1
    }
  }
  let mut i = p + 1
  while true {
    let c = @util.code_at(src, i)
    if c == -1 ||
      c == '['.to_int() ||
      c == ']'.to_int() ||
      c == '\r'.to_int() ||
      c == '\n'.to_int() {
      break
    }
    i += 1
  }
  if i > p + 1 && @util.code_at(src, i) == ']'.to_int() {
    i + 1
  } else {
    @common.NO_MATCH
  }
}

///|
fn one_char(name : String, chars : String) -> @common.TokenType {
  @common.pattern(
    name,
    (src, p) => {
      let c = @util.code_at(src, p)
      if c >= 0 && c < 128 && chars.contains_code_unit(c.to_uint16()) {
        p + 1
      } else {
        @common.NO_MATCH
      }
    },
    first=chars,
  )
}

///|
/// Mermaid's architecture lexer, whose token order the constants above index.
/// The direction letters come before identifiers and have no longer alternative, so Mermaid
/// reads an id that starts with L, R, T or B as a direction followed by the rest.
let architecture_tokens : Array[@common.TokenType] = [
  word("architecture-beta"),
  word("junction"),
  word("service"),
  word("column"),
  word("group"),
  word("align"),
  word("row"),
  dashes("--"),
  word("in"),
  @common.literal(":", ":"),
  dashes("-"),
  one_char("ARROW_DIRECTION", "LRTB"),
  @common.literal("ARROW_GROUP", "{group}"),
  one_char("ARROW_INTO", "<>"),
  @common.acc_descr,
  @common.acc_title,
  @common.title,
  @common.string,
  @common.pattern("ID", id_end, first=ID_FIRST),
  @common.newline,
  @common.whitespace,
  @common.yaml,
  @common.directive,
  @common.single_line_comment,
  @common.pattern("ARCH_ICON", scan_icon, first="("),
  {
    name: "ARCH_TITLE",
    scanner: () => scan_label,
    first: Some("["),
    hidden: false,
  },
]

///|
/// Replaces every `from` in `text` with `to`, left to right.
fn replace_all(text : String, from : String, to : String) -> String {
  let out = StringBuilder()
  let mut last = 0
  let mut at = @util.index_of(text, from)
  while at != -1 {
    @util.write_range(out, text, last, at)
    out.write_string(to)
    last = at + from.length()
    at = @util.index_of(text, from, from=last)
  }
  @util.write_range(out, text, last, text.length())
  out.to_string()
}

///|
/// Mermaid's ArchitectureValueConverter for ARCH_TITLE.
fn label_value(text : String) -> String {
  let mut result = @util.trim(@util.slice(text, 1, end=text.length() - 1))
  let n = result.length()
  let first = @util.code_at(result, 0)
  let last = @util.code_at(result, n - 1)
  if (first == '"'.to_int() || first == '\''.to_int()) && last == first {
    let inner = @util.slice(result, 1, end=@cmp.maximum(1, n - 1))
    result = replace_all(replace_all(inner, "\\\"", "\""), "\\'", "'")
  }
  @util.trim(result)
}

///|
fn side(text : String) -> Side {
  match text {
    "L" => L
    "R" => R
    "T" => T
    _ => B
  }
}

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
fn parent(r : @common.TokenReader) -> String? raise @errors.PeleError {
  if r.accept(IN) {
    Some(r.expect(ID))
  } else {
    None
  }
}

///|
fn icon(r : @common.TokenReader) -> String? {
  if r.kind() == ICON {
    let text = r.take()
    Some(@util.slice(text, 1, end=text.length() - 1))
  } else {
    None
  }
}

///|
fn title(r : @common.TokenReader) -> String? {
  if r.kind() == LABEL {
    Some(label_value(r.take()))
  } else {
    None
  }
}

///|
fn edge(r : @common.TokenReader) -> EdgeAst raise @errors.PeleError {
  let lhs_id = r.take()
  let lhs_group = r.accept(ARROW_GROUP)
  r.expect(COLON) |> ignore
  let lhs_dir = side(r.expect(DIRECTION))
  let lhs_into = r.accept(INTO)
  let mut title = None
  if !r.accept(DASHES) {
    if r.kind() != DASH {
      r.fail("'--' or '-'")
    }
    r.i += 1
    title = Some(label_value(r.expect(LABEL)))
    r.expect(DASH) |> ignore
  }
  let rhs_into = r.accept(INTO)
  let rhs_dir = side(r.expect(DIRECTION))
  r.expect(COLON) |> ignore
  let rhs_id = r.expect(ID)
  let rhs_group = r.accept(ARROW_GROUP)
  {
    lhs_id,
    lhs_group,
    lhs_dir,
    lhs_into,
    title,
    rhs_into,
    rhs_dir,
    rhs_id,
    rhs_group,
  }
}

///|
/// Reads an architecture diagram, which starts with `architecture-beta`.
/// Raises a syntax `PeleError` with Mermaid's message where the text does not follow the grammar.
pub fn parse_architecture(
  source : String,
) -> ArchitectureAst raise @errors.PeleError {
  let r = @common.TokenReader::new(
    @common.tokenize(source, architecture_tokens, "architecture"),
    architecture_tokens,
    "architecture",
  )
  let mut diagram_title = None
  let mut acc_title = None
  let mut acc_descr = None
  let groups : Array[GroupAst] = []
  let services : Array[ServiceAst] = []
  let junctions : Array[JunctionAst] = []
  let edges : Array[EdgeAst] = []
  let alignments : Array[AlignmentAst] = []
  while r.kind() == NEWLINE {
    r.i += 1
  }
  r.expect(HEADER) |> ignore
  while r.kind() != -1 {
    match r.kind() {
      NEWLINE => {
        r.i += 1
        continue
      }
      ACC_DESCR => acc_descr = Some(@common.acc_descr_value(r.take()))
      ACC_TITLE => acc_title = Some(@common.acc_title_value(r.take()))
      TITLE => diagram_title = Some(@common.title_value(r.take()))
      GROUP => {
        r.i += 1
        let id = r.expect(ID)
        let icon = icon(r)
        let title = title(r)
        groups.push({ id, icon, title, parent: parent(r), })
      }
      SERVICE => {
        r.i += 1
        let id = r.expect(ID)
        let (icon, icon_text) = if r.kind() == STRING {
          (None, Some(@common.string_value(r.take())))
        } else {
          (icon(r), None)
        }
        let title = title(r)
        services.push({ id, icon, icon_text, title, parent: parent(r), })
      }
      JUNCTION => {
        r.i += 1
        let id = r.expect(ID)
        junctions.push({ id, parent: parent(r), })
      }
      ID => edges.push(edge(r))
      ALIGN => {
        r.i += 1
        if r.kind() != ROW && r.kind() != COLUMN {
          r.fail("'row' or 'column'")
        }
        let direction = r.take()
        let members = [r.expect(ID), r.expect(ID)]
        while r.kind() == ID {
          members.push(r.take())
        }
        alignments.push({ direction, members, })
      }
      _ =>
        r.fail(
          "a group, a service, a junction, an edge, an alignment, a title, or a line break",
        )
    }
    end_of_line(r)
  }
  {
    title: diagram_title,
    acc_title,
    acc_descr,
    groups,
    services,
    junctions,
    edges,
    alignments,
  }
}
