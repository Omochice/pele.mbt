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
fn name_end(src : String, p : Int32) -> Int32 {
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
  while true {
    let mut word = end
    while @util.is_blank(@util.code_at(src, word)) {
      word += 1
    }
    let c = @util.code_at(src, word)
    if word == end || !(is_ascii_letter(c) || c == '('.to_int()) {
      break
    }
    end = name_part_end(src, word + 1)
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
/// Mermaid's Wardley lexer, in its matching order.
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
  @common.pattern("NAME_WITH_SPACES", name_end, first=LETTERS),
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
