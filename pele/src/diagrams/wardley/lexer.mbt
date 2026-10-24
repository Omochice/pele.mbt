///|
const LBRACKET : Int32 = 0

///|
const COMMA : Int32 = 1

///|
const RBRACKET : Int32 = 2

///|
const AT : Int32 = 3

///|
const SLASH : Int32 = 4

///|
const LPAREN : Int32 = 5

///|
const RPAREN : Int32 = 6

///|
const MINUS : Int32 = 7

///|
const LBRACE : Int32 = 8

///|
const RBRACE : Int32 = 9

///|
const NUMBER : Int32 = 10

///|
const ARROW : Int32 = 11

///|
const LINK_PORT : Int32 = 12

///|
const LINK_ARROW : Int32 = 13

///|
const LINK_LABEL : Int32 = 14

///|
const STRATEGY : Int32 = 15

///|
const WARDLEY : Int32 = 16

///|
const SIZE : Int32 = 17

///|
const EVOLUTION : Int32 = 18

///|
const ANCHOR : Int32 = 19

///|
const COMPONENT : Int32 = 20

///|
const LABEL : Int32 = 21

///|
const INERTIA : Int32 = 22

///|
const EVOLVE : Int32 = 23

///|
const PIPELINE : Int32 = 24

///|
const NOTE : Int32 = 25

///|
const ANNOTATIONS : Int32 = 26

///|
const ANNOTATION : Int32 = 27

///|
const ACCELERATOR : Int32 = 28

///|
const DEACCELERATOR : Int32 = 29

///|
const NAME : Int32 = 30

///|
const ACC_DESCR : Int32 = 32

///|
const ACC_TITLE : Int32 = 33

///|
const TITLE : Int32 = 34

///|
const INT : Int32 = 35

///|
const STRING : Int32 = 36

///|
const ID : Int32 = 37

///|
const NEWLINE : Int32 = 38

///|
fn digits_end(src : String, from : Int32) -> Int32 {
  let mut i = from
  while @util.is_digit(@util.code_at(src, i)) {
    i += 1
  }
  i
}

///|
/// `[0-9]+\.[0-9]+`.
/// The pattern reads a whole run of digits before it finds there is no fraction, and would do so
/// again from every digit of a long run, so the end of the run is remembered.
fn number_scanner() -> @common.Scanner {
  let mut from = 0
  let mut end = 0
  (src, p) => {
    if p < from || p >= end {
      from = p
      end = digits_end(src, p)
    }
    if end == p || @util.code_at(src, end) != '.'.to_int() {
      return @common.NO_MATCH
    }
    let stop = digits_end(src, end + 1)
    if stop > end + 1 {
      stop
    } else {
      @common.NO_MATCH
    }
  }
}

///|
/// `->`
fn arrow_end(src : String, p : Int32) -> Int32 {
  if @util.starts_with_at(src, "->", p) {
    p + 2
  } else {
    @common.NO_MATCH
  }
}

///|
/// `-->|-\.->|>|\+'[^']*'<>|\+'[^']*'<|\+'[^']*'>`
fn link_arrow_end(src : String, p : Int32) -> Int32 {
  for arrow in ["-->", "-.->", ">"] {
    if @util.starts_with_at(src, arrow, p) {
      return p + arrow.length()
    }
  }
  if !@util.starts_with_at(src, "+'", p) {
    return @common.NO_MATCH
  }
  let close = @util.index_of(src, "'", from=p + 2)
  if close == -1 {
    return @common.NO_MATCH
  }
  for tail in ["'<>", "'<", "'>"] {
    if @util.starts_with_at(src, tail, close) {
      return close + tail.length()
    }
  }
  @common.NO_MATCH
}

///|
/// A hyphen, unless an arrow or front matter reads more text from the same place.
/// pele makes those its longer alternatives; giving way here lets them, which come later in the
/// order with nothing between that matches a hyphen, take the token.
fn dash() -> @common.Scanner {
  let front_matter = (@common.yaml.scanner)()
  let mut closerless = false
  (src, p) => {
    if @util.code_at(src, p) != '-'.to_int() {
      return @common.NO_MATCH
    }
    if arrow_end(src, p) > p + 1 || link_arrow_end(src, p) > p + 1 {
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
fn is_ascii_letter(c : Int32) -> Bool {
  (c >= 'A'.to_int() && c <= 'Z'.to_int()) ||
  (c >= 'a'.to_int() && c <= 'z'.to_int())
}

///|
/// The end of `(?:[A-Za-z0-9_()&]|-(?!>))*` from `from`.
fn name_part_end(src : String, from : Int32) -> Int32 {
  let mut i = from
  while true {
    let c = @util.code_at(src, i)
    if @util.is_word(c) ||
      c == '('.to_int() ||
      c == ')'.to_int() ||
      c == '&'.to_int() {
      i += 1
    } else if c == '-'.to_int() && @util.code_at(src, i + 1) != '>'.to_int() {
      i += 1
    } else {
      break
    }
  }
  i
}

///|
/// `(?!title\s|accTitle|accDescr)[A-Za-z](?:[A-Za-z0-9_()&]|-(?!>))*(?:[ \t]+[A-Za-z(](?:[A-Za-z0-9_()&]|-(?!>))*)*`
/// Of V8's backtracking stack, the match takes three slots, two for each character after a word's first and five for each further word.
/// Giving up on a last word at blanks that start none takes two more, and on a character at an arrow one more.
fn name_end(src : String, p : Int32) -> Int32 raise @errors.PeleError {
  if !is_ascii_letter(@util.code_at(src, p)) {
    return @common.NO_MATCH
  }
  if (
      @util.starts_with_at(src, "title", p) &&
      @util.is_space(@util.code_at(src, p + 5))
    ) ||
    @util.starts_with_at(src, "accTitle", p) ||
    @util.starts_with_at(src, "accDescr", p) {
    return @common.NO_MATCH
  }
  let mut end = name_part_end(src, p + 1)
  let mut slots = 3L + 2L * (end - p - 1).to_int64()
  while true {
    let mut word = end
    while @util.is_blank(@util.code_at(src, word)) {
      word += 1
    }
    if word == end {
      if @util.code_at(src, end) == '-'.to_int() {
        slots += 1
      }
      break
    }
    let c = @util.code_at(src, word)
    if !(is_ascii_letter(c) || c == '('.to_int()) {
      slots += 2
      break
    }
    let next = name_part_end(src, word + 1)
    slots += 5L + 2L * (next - word - 1).to_int64()
    end = next
  }
  if @util.backtrack_stack_overflows(slots) {
    raise @errors.nested_too_deeply()
  }
  end
}

///|
/// `0|[1-9][0-9]*(?!\.)`: a run of digits followed by a dot gives back its last digit.
fn int_end(src : String, p : Int32) -> Int32 {
  let c = @util.code_at(src, p)
  if c == '0'.to_int() {
    return p + 1
  }
  if c < '1'.to_int() || c > '9'.to_int() {
    return @common.NO_MATCH
  }
  let end = digits_end(src, p + 1)
  if @util.code_at(src, end) != '.'.to_int() {
    end
  } else if end - 1 > p {
    end - 1
  } else {
    @common.NO_MATCH
  }
}

///|
/// `[\w]([-\w]*\w)?`
fn id_end(src : String, p : Int32) -> Int32 {
  if !@util.is_word(@util.code_at(src, p)) {
    return @common.NO_MATCH
  }
  let mut end = p + 1
  let mut i = p + 1
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
const LETTERS : String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

///|
/// Mermaid's Wardley lexer, in its matching order, which the constants above index.
pub let wardley_tokens : Array[@common.TokenType] = [
  @common.literal("[", "["),
  @common.literal(",", ","),
  @common.literal("]", "]"),
  @common.literal("@", "@"),
  @common.literal("/", "/"),
  @common.literal("(", "("),
  @common.literal(")", ")"),
  { name: "-", scanner: dash, first: Some("-"), hidden: false, },
  @common.literal("{", "{"),
  @common.literal("}", "}"),
  {
    name: "WARDLEY_NUMBER",
    scanner: number_scanner,
    first: Some("0123456789"),
    hidden: false,
  },
  @common.pattern("ARROW", arrow_end, first="-"),
  one_of("LINK_PORT", ["+<>", "+>", "+<"], "+"),
  @common.pattern("LINK_ARROW", link_arrow_end, first="->+"),
  @common.pattern(
    "LINK_LABEL",
    (src, p) => {
      if @util.code_at(src, p) != ';'.to_int() {
        return @common.NO_MATCH
      }
      let mut i = p + 1
      while i < src.length() {
        let c = @util.code_at(src, i)
        if c == '\n'.to_int() || c == '\r'.to_int() {
          break
        }
        i += 1
      }
      if i > p + 1 {
        i
      } else {
        @common.NO_MATCH
      }
    },
    first=";",
  ),
  one_of("STRATEGY", ["build", "buy", "outsource", "market"], "bom"),
  @common.literal("KW_WARDLEY", "wardley-beta"),
  @common.literal("KW_SIZE", "size"),
  @common.literal("KW_EVOLUTION", "evolution"),
  @common.literal("KW_ANCHOR", "anchor"),
  @common.literal("KW_COMPONENT", "component"),
  @common.literal("KW_LABEL", "label"),
  @common.literal("KW_INERTIA", "inertia"),
  @common.literal("KW_EVOLVE", "evolve"),
  @common.literal("KW_PIPELINE", "pipeline"),
  @common.literal("KW_NOTE", "note"),
  @common.literal("KW_ANNOTATIONS", "annotations"),
  @common.literal("KW_ANNOTATION", "annotation"),
  @common.literal("KW_ACCELERATOR", "accelerator"),
  @common.literal("KW_DEACCELERATOR", "deaccelerator"),
  {
    name: "NAME_WITH_SPACES",
    scanner: () => name_end,
    first: Some(LETTERS),
    hidden: false,
  },
  { ..@common.whitespace, name: "WS", },
  @common.resumable_acc_descr,
  @common.acc_title,
  @common.title,
  @common.pattern("INT", int_end, first="0123456789"),
  @common.string,
  @common.pattern("ID", id_end, first="_0123456789" + LETTERS),
  @common.newline,
  @common.whitespace,
  @common.yaml,
  @common.directive,
  @common.single_line_comment,
]
