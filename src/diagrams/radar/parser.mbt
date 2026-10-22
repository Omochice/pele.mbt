///|
/// An axis as written in the source.
pub(all) struct AxisAst {
  name : String
  label : String?
}

///|
/// A value of a curve.
/// `axis` is the name of the axis it belongs to, for a named entry.
pub(all) struct EntryAst {
  axis : String?
  value : Double
}

///|
pub(all) struct CurveAst {
  name : String
  label : String?
  entries : Array[EntryAst]
}

///|
pub(all) enum OptionValue {
  Flag(Bool)
  Number(Double)
  Name(String)
}

///|
/// An option as written in the source; `name` is the keyword that introduced it.
pub(all) struct OptionAst {
  name : String
  value : OptionValue
}

///|
/// The statements of a radar chart, as Mermaid's grammar reads them.
pub(all) struct RadarAst {
  title : String?
  acc_title : String?
  acc_descr : String?
  axes : Array[AxisAst]
  curves : Array[CurveAst]
  options : Array[OptionAst]
}

///|
fn digits(src : String, from : Int32) -> Int32 {
  let mut i = from
  while @util.is_digit(@util.code_at(src, i)) {
    i += 1
  }
  i
}

///|
/// Answers as the NUMBER pattern `(?:[0-9]+\.[0-9]+(?!\.))|(?:0|[1-9][0-9]*(?!\.))` does.
/// The pattern reads a whole run of digits from every position in the run, which is quadratic
/// for a long run of zeros, so the run is remembered.
fn number_scanner() -> @common.Scanner {
  let mut run_from = 0
  let mut run_end = 0
  (src, at) => {
    if at < run_from || at >= run_end {
      run_from = at
      run_end = digits(src, at)
    }
    let whole = run_end
    if whole == at {
      return @common.NO_MATCH
    }
    let dot = @util.code_at(src, whole) == '.'.to_int()
    if dot {
      let fraction = digits(src, whole + 1)
      let length = fraction - whole - 1
      if length > 0 && @util.code_at(src, fraction) != '.'.to_int() {
        return fraction
      }
      if length > 1 {
        return fraction - 1
      }
    }
    if @util.code_at(src, at) == '0'.to_int() {
      return at + 1
    }
    if !dot {
      return whole
    }
    if whole - 1 > at {
      whole - 1
    } else {
      @common.NO_MATCH
    }
  }
}

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
/// Chevrotain's LONGER_ALT: where a name matches more text than the word does, the name wins.
/// Giving way here lets the name type, which comes later in the order, take the token.
fn unless_longer_name(scan : @common.Scanner) -> @common.Scanner {
  (src, p) => {
    let end = scan(src, p)
    if end > p && id_end(src, p) > end {
      @common.NO_MATCH
    } else {
      end
    }
  }
}

///|
/// Does what `acc_descr` does, without reading to the end of the text again for each `accDescr {`
/// when no `}` follows it.
/// In the other grammars an unclosed `accDescr {` ends the lexing; here `accDescr` is also a name and `{` a token.
fn acc_descr_scanner() -> @common.Scanner {
  let base = (@common.acc_descr.scanner)()
  let mut last_brace = -2
  (src, p) => {
    let mut at = p
    while @util.is_blank(@util.code_at(src, at)) {
      at += 1
    }
    if @util.starts_with_at(src, "accDescr", at) {
      at += "accDescr".length()
      while @util.is_space(@util.code_at(src, at)) {
        at += 1
      }
      if @util.code_at(src, at) == '{'.to_int() {
        if last_brace == -2 {
          last_brace = @util.last_index_of(src, "}")
        }
        if at + 1 > last_brace {
          return @common.NO_MATCH
        }
      }
    }
    base(src, p)
  }
}

///|
const ID_FIRST : String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"

///|
const RADAR_COLON : Int32 = 0

///|
const RADAR : Int32 = 1

///|
const SHOW_LEGEND : Int32 = 2

///|
const GRATICULE : Int32 = 3

///|
const CURVE : Int32 = 4

///|
const TICKS : Int32 = 5

///|
const AXIS : Int32 = 6

///|
const MAX : Int32 = 7

///|
const MIN : Int32 = 8

///|
const COLON : Int32 = 9

///|
const COMMA : Int32 = 10

///|
const OPEN : Int32 = 11

///|
const CLOSE : Int32 = 12

///|
const OPEN_BRACE : Int32 = 13

///|
const CLOSE_BRACE : Int32 = 14

///|
const GRATICULE_VALUE : Int32 = 15

///|
const BOOLEAN : Int32 = 16

///|
const ACC_DESCR : Int32 = 17

///|
const ACC_TITLE : Int32 = 18

///|
const TITLE : Int32 = 19

///|
const NUMBER : Int32 = 20

///|
const STRING : Int32 = 21

///|
const ID : Int32 = 22

///|
const NEWLINE : Int32 = 23

///|
fn word(text : String) -> @common.TokenType {
  @common.pattern(
    text,
    unless_longer_name((src, p) => {
      if @util.starts_with_at(src, text, p) {
        p + text.length()
      } else {
        @common.NO_MATCH
      }
    }),
    first=@util.slice(text, 0, end=1),
  )
}

///|
fn one_of(
  name : String,
  choices : Array[String],
  first : String,
) -> @common.TokenType {
  @common.pattern(
    name,
    (src, p) => {
      for choice in choices {
        if @util.starts_with_at(src, choice, p) {
          return p + choice.length()
        }
      }
      @common.NO_MATCH
    },
    first~,
  )
}

///|
/// Mermaid's radar lexer, whose token order the constants above index.
let radar_tokens : Array[@common.TokenType] = [
  @common.literal("radar-beta:", "radar-beta:"),
  {
    ..@common.keyword("radar-beta"),
    scanner: () => unless_longer_name((@common.keyword("radar-beta").scanner)()),
  },
  word("showLegend"),
  word("graticule"),
  word("curve"),
  word("ticks"),
  word("axis"),
  word("max"),
  word("min"),
  @common.literal(":", ":"),
  @common.literal(",", ","),
  @common.literal("[", "["),
  @common.literal("]", "]"),
  @common.literal("{", "{"),
  @common.literal("}", "}"),
  one_of("GRATICULE", ["circle", "polygon"], "cp"),
  one_of("BOOLEAN", ["true", "false"], "tf"),
  { ..@common.acc_descr, scanner: acc_descr_scanner, },
  @common.acc_title,
  @common.title,
  {
    name: "NUMBER",
    scanner: number_scanner,
    first: Some("0123456789"),
    hidden: false,
  },
  @common.string,
  @common.pattern("ID", id_end, first=ID_FIRST),
  @common.newline,
  @common.whitespace,
  @common.yaml,
  @common.directive,
  @common.single_line_comment,
]

///|
/// The value of a NUMBER token, as `Number()` reads it.
/// A NUMBER is always well formed, so a failure to parse is an overflow, which `Number()` reads as infinity.
fn number_value(text : String) -> Double {
  @string.parse_double(text) catch {
    _ => @double.infinity
  }
}

///|
fn newlines(r : @common.TokenReader) -> Unit {
  while r.kind() == NEWLINE {
    r.i += 1
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
  newlines(r)
}

///|
fn label(r : @common.TokenReader) -> String? raise @errors.PeleError {
  if !r.accept(OPEN) {
    return None
  }
  let text = @common.string_value(r.expect(STRING))
  r.expect(CLOSE) |> ignore
  Some(text)
}

///|
fn entry(
  r : @common.TokenReader,
  detailed : Bool,
) -> EntryAst raise @errors.PeleError {
  if !detailed {
    return { axis: None, value: number_value(r.expect(NUMBER)), }
  }
  let axis = r.expect(ID)
  r.accept(COLON) |> ignore
  { axis: Some(axis), value: number_value(r.expect(NUMBER)), }
}

///|
fn curve(r : @common.TokenReader) -> CurveAst raise @errors.PeleError {
  let name = r.expect(ID)
  let text = label(r)
  r.expect(OPEN_BRACE) |> ignore
  newlines(r)
  if r.kind() != NUMBER && r.kind() != ID {
    r.fail("a number or an axis name")
  }
  let detailed = r.kind() == ID
  let entries = [entry(r, detailed)]
  while r.accept(COMMA) {
    newlines(r)
    entries.push(entry(r, detailed))
  }
  newlines(r)
  r.expect(CLOSE_BRACE) |> ignore
  { name, label: text, entries, }
}

///|
fn axis(r : @common.TokenReader) -> AxisAst raise @errors.PeleError {
  let name = r.expect(ID)
  { name, label: label(r), }
}

///|
fn is_option(r : @common.TokenReader) -> Bool {
  r.kind() is (SHOW_LEGEND | TICKS | MAX | MIN | GRATICULE)
}

///|
fn read_option(r : @common.TokenReader) -> OptionAst raise @errors.PeleError {
  let kind = r.kind()
  let name = r.take()
  let value = if kind == SHOW_LEGEND {
    Flag(r.expect(BOOLEAN) == "true")
  } else if kind == GRATICULE {
    Name(r.expect(GRATICULE_VALUE))
  } else {
    Number(number_value(r.expect(NUMBER)))
  }
  { name, value, }
}

///|
/// Reads a radar chart. Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_radar(source : String) -> RadarAst raise @errors.PeleError {
  let r = @common.TokenReader::new(
    @common.tokenize(source, radar_tokens, "radar"),
    radar_tokens,
    "radar",
  )
  let mut title = None
  let mut acc_title = None
  let mut acc_descr = None
  let axes = []
  let curves = []
  let options = []
  newlines(r)
  if !r.accept(RADAR_COLON) {
    r.expect(RADAR) |> ignore
    r.accept(COLON) |> ignore
  }
  newlines(r)
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
      AXIS => {
        r.i += 1
        axes.push(axis(r))
        while r.accept(COMMA) {
          axes.push(axis(r))
        }
      }
      CURVE => {
        r.i += 1
        curves.push(curve(r))
        while r.accept(COMMA) {
          curves.push(curve(r))
        }
      }
      _ => {
        if !is_option(r) {
          r.fail("an axis, a curve, an option, a title, or a line break")
        }
        options.push(read_option(r))
        while r.accept(COMMA) {
          if !is_option(r) {
            r.fail("an option")
          }
          options.push(read_option(r))
        }
      }
    }
  }
  { title, acc_title, acc_descr, axes, curves, options, }
}
