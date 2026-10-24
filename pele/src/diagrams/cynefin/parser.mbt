///|
/// A domain block as written: the domain's name and the labels of its items.
pub(all) struct DomainBlockAst {
  domain : String
  items : Array[String]
}

///|
pub(all) struct TransitionAst {
  from : String
  to : String
  label : String?
}

///|
/// The statements of a cynefin diagram, as Mermaid's grammar reads them.
pub(all) struct CynefinAst {
  title : String?
  acc_title : String?
  acc_descr : String?
  domains : Array[DomainBlockAst]
  transitions : Array[TransitionAst]
}

///|
const KEYWORD_COLON : Int32 = 0

///|
const KEYWORD : Int32 = 1

///|
const ARROW : Int32 = 2

///|
const COLON : Int32 = 3

///|
const DOMAIN : Int32 = 4

///|
const ACC_DESCR : Int32 = 5

///|
const ACC_TITLE : Int32 = 6

///|
const TITLE : Int32 = 7

///|
const STRING : Int32 = 8

///|
const NEWLINE : Int32 = 9

///|
/// Answers as `/complex|complicated|clear|chaotic|confusion/y` does, so a longer word is cut after its first domain name.
fn scan_domain(src : String, p : Int32) -> Int32 {
  for name in ["complex", "complicated", "clear", "chaotic", "confusion"] {
    if @util.starts_with_at(src, name, p) {
      return p + name.length()
    }
  }
  @common.NO_MATCH
}

///|
/// Mermaid's cynefin lexer, whose token order the constants above index.
let cynefin_tokens : Array[@common.TokenType] = [
  @common.literal("cynefin-beta:", "cynefin-beta:"),
  @common.keyword("cynefin-beta"),
  @common.literal("-->", "-->"),
  @common.literal(":", ":"),
  @common.pattern("DOMAIN_NAME", scan_domain, first="c"),
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
fn skip_lines(r : @common.TokenReader) -> Unit {
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
  skip_lines(r)
}

///|
/// Reads a cynefin diagram. Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_cynefin(source : String) -> CynefinAst raise @errors.PeleError {
  let r = @common.TokenReader::new(
    @common.tokenize(source, cynefin_tokens, "cynefin"),
    cynefin_tokens,
    "cynefin",
  )
  let mut title = None
  let mut acc_title = None
  let mut acc_descr = None
  let domains = []
  let transitions = []
  skip_lines(r)
  if r.kind() != KEYWORD && r.kind() != KEYWORD_COLON {
    r.fail("'cynefin-beta'")
  }
  r.i += 1
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
      DOMAIN => {
        let name = r.take()
        if r.accept(ARROW) {
          let to = r.expect(DOMAIN)
          let label = if r.accept(COLON) {
            Some(@common.string_value(r.expect(STRING)))
          } else {
            None
          }
          end_of_line(r)
          transitions.push({ from: name, to, label, })
          continue
        }
        let items = []
        skip_lines(r)
        while r.kind() == STRING {
          items.push(@common.string_value(r.take()))
          skip_lines(r)
        }
        domains.push({ domain: name, items, })
      }
      _ => r.fail("a domain, a transition, a title, or a line break")
    }
  }
  { title, acc_title, acc_descr, domains, transitions, }
}
