///|
/// The statements of an info diagram, as Mermaid's grammar reads them.
pub(all) struct InfoAst {
  title : String?
  acc_title : String?
  acc_descr : String?
}

///|
const SHOW_INFO : Int32 = 0

///|
const INFO : Int32 = 1

///|
const ACC_DESCR : Int32 = 2

///|
const ACC_TITLE : Int32 = 3

///|
const TITLE : Int32 = 4

///|
const NEWLINE : Int32 = 5

///|
/// Mermaid's info lexer, whose token order the constants above index.
let info_tokens : Array[@common.TokenType] = [
  @common.keyword("showInfo"),
  @common.keyword("info"),
  @common.acc_descr,
  @common.acc_title,
  @common.title,
  @common.newline,
  @common.whitespace,
  @common.yaml,
  @common.directive,
  @common.single_line_comment,
]

///|
fn skip_newlines(r : @common.TokenReader) -> Unit {
  while r.kind() == NEWLINE {
    r.i += 1
  }
}

///|
/// Reads an info diagram. Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_info(source : String) -> InfoAst raise @errors.PeleError {
  let r = @common.TokenReader::new(
    @common.tokenize(source, info_tokens, "info"),
    info_tokens,
    "info",
  )
  let mut title = None
  let mut acc_title = None
  let mut acc_descr = None
  skip_newlines(r)
  r.expect(INFO) |> ignore
  skip_newlines(r)
  if r.accept(SHOW_INFO) {
    skip_newlines(r)
  }
  while r.kind() != -1 {
    match r.kind() {
      ACC_DESCR => acc_descr = Some(@common.acc_descr_value(r.take()))
      ACC_TITLE => acc_title = Some(@common.acc_title_value(r.take()))
      TITLE => title = Some(@common.title_value(r.take()))
      _ => r.fail("a title or the end of input")
    }
    if r.kind() == -1 {
      break
    }
    if r.kind() != NEWLINE {
      r.fail("a line break or the end of input")
    }
    skip_newlines(r)
  }
  { title, acc_title, acc_descr, }
}
