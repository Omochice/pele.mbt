///|
/// A slice as written in the source.
pub(all) struct PieSection {
  label : String
  value : Double
}

///|
/// The statements of a pie chart, as Mermaid's grammar reads them.
pub(all) struct PieAst {
  show_data : Bool
  title : String?
  acc_title : String?
  acc_descr : String?
  sections : Array[PieSection]
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
/// Answers as NUMBER_PIE's pattern `(?:-?[0-9]+\.[0-9]+(?!\.))|(?:-?(0|[1-9][0-9]*)(?!\.))` does.
/// The pattern reads a whole run of digits before it finds there is no fraction, and would do so
/// again from every digit of a long run of zeros, so the run is remembered.
fn number_scanner() -> @common.Scanner {
  let mut from = 0
  let mut end = 0
  let mut fraction = -1
  (src, p, _) => {
    let at = if @util.code_at(src, p) == '-'.to_int() { p + 1 } else { p }
    if at < from || at >= end {
      from = at
      end = digits(src, at)
      fraction = -1
      if end > at && @util.code_at(src, end) == '.'.to_int() {
        let stop = digits(src, end + 1)
        let length = stop - end - 1
        if length > 0 && @util.code_at(src, stop) != '.'.to_int() {
          fraction = stop
        } else if length > 1 {
          fraction = stop - 1
        }
      }
    }
    if end == at {
      return @common.NO_MATCH
    }
    if fraction >= 0 {
      return fraction
    }
    if @util.code_at(src, at) == '0'.to_int() {
      return if @util.code_at(src, at + 1) == '.'.to_int() {
        @common.NO_MATCH
      } else {
        at + 1
      }
    }
    if @util.code_at(src, end) != '.'.to_int() {
      return end
    }
    if end - 1 > at {
      end - 1
    } else {
      @common.NO_MATCH
    }
  }
}

///|
const SHOW_DATA : Int32 = 0

///|
const PIE : Int32 = 1

///|
const COLON : Int32 = 2

///|
const NUMBER : Int32 = 3

///|
const ACC_DESCR : Int32 = 4

///|
const ACC_TITLE : Int32 = 5

///|
const TITLE : Int32 = 6

///|
const STRING : Int32 = 7

///|
const NEWLINE : Int32 = 8

///|
/// Mermaid's pie lexer, whose token order the constants above index.
let pie_tokens : Array[@common.TokenType] = [
  @common.keyword("showData"),
  @common.keyword("pie"),
  @common.literal(":", ":"),
  {
    name: "NUMBER_PIE",
    scanner: number_scanner,
    first: Some("-0123456789"),
    hidden: false,
  },
  @common.acc_descr,
  @common.acc_title,
  @common.title,
  @common.string,
  @common.newline,
  @common.whitespace,
  @common.yaml,
  @common.directive,
  @common.single_line_comment,
]

///|
/// The value of a NUMBER_PIE token, as `Number()` reads it.
fn number_value(text : String) -> Double {
  let negative = @util.code_at(text, 0) == '-'.to_int()
  let digits = if negative { @util.slice(text, 1) } else { text }
  let value = @string.parse_double(digits) catch { _ => @double.not_a_number }
  if negative {
    -value
  } else {
    value
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
/// Reads a pie chart. Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_pie(source : String) -> PieAst raise @errors.PeleError {
  let r = @common.TokenReader::new(
    @common.tokenize(source, pie_tokens, "pie"),
    pie_tokens,
    "pie",
  )
  let mut title = None
  let mut acc_title = None
  let mut acc_descr = None
  let sections = []
  while r.kind() == NEWLINE {
    r.i += 1
  }
  r.expect(PIE) |> ignore
  let show_data = r.accept(SHOW_DATA)
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
      STRING => {
        let label = @common.string_value(r.take())
        r.expect(COLON) |> ignore
        let value = number_value(r.expect(NUMBER))
        sections.push({ label, value, })
        end_of_line(r)
      }
      _ => r.fail("a section, a title, or a line break")
    }
  }
  { show_data, title, acc_title, acc_descr, sections, }
}
