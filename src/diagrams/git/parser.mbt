///|
/// The type a commit is written with.
pub(all) enum CommitTypeName {
  Normal
  Reverse
  Highlight
}

///|
/// A commit statement as written.
pub(all) struct CommitAst {
  id : String?
  message : String?
  tags : Array[String]
  commit_type : CommitTypeName?
}

///|
/// A branch statement as written.
pub(all) struct BranchAst {
  name : String
  order : Double?
}

///|
/// A merge statement as written.
pub(all) struct MergeAst {
  branch : String
  id : String?
  tags : Array[String]
  commit_type : CommitTypeName?
}

///|
/// A checkout statement as written, whether spelled checkout or switch.
pub(all) struct CheckoutAst {
  branch : String
}

///|
/// A cherry-pick statement as written.
pub(all) struct CherryPickingAst {
  id : String?
  tags : Array[String]
  parent : String?
}

///|
/// A statement of a git graph.
pub(all) enum StatementAst {
  Commit(CommitAst)
  Branch(BranchAst)
  Merge(MergeAst)
  Checkout(CheckoutAst)
  CherryPicking(CherryPickingAst)
}

///|
/// The direction a graph is drawn in.
pub(all) enum GitDirection {
  LR
  TB
  BT
}

///|
/// The statements of a git graph, as Mermaid's grammar reads them.
pub(all) struct GitGraphAst {
  dir : GitDirection?
  title : String?
  acc_title : String?
  acc_descr : String?
  statements : Array[StatementAst]
}

///|
const CHERRY_PICK : Int32 = 0

///|
const GIT_GRAPH_COLON : Int32 = 1

///|
const HIGHLIGHT : Int32 = 2

///|
const GIT_GRAPH : Int32 = 3

///|
const CHECKOUT : Int32 = 4

///|
const REVERSE : Int32 = 5

///|
const PARENT : Int32 = 6

///|
const COMMIT : Int32 = 7

///|
const NORMAL : Int32 = 8

///|
const BRANCH : Int32 = 9

///|
const ORDER : Int32 = 10

///|
const SWITCH : Int32 = 11

///|
const TYPE : Int32 = 12

///|
const MERGE : Int32 = 13

///|
const MSG : Int32 = 14

///|
const TAG : Int32 = 15

///|
const ID : Int32 = 16

///|
const LR_TOKEN : Int32 = 17

///|
const TB_TOKEN : Int32 = 18

///|
const BT_TOKEN : Int32 = 19

///|
const COLON : Int32 = 20

///|
const ACC_DESCR : Int32 = 21

///|
const ACC_TITLE : Int32 = 22

///|
const TITLE : Int32 = 23

///|
const INT : Int32 = 24

///|
const STRING : Int32 = 25

///|
const NEWLINE : Int32 = 26

///|
const REFERENCE : Int32 = 31

///|
const WORD_FIRST : String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"

///|
/// Answers as the REFERENCE pattern `\w([-\./\w]*[-\w])?` does, including its backtracking over trailing dots and slashes.
fn reference_end(src : String, at : Int32) -> Int32 {
  if !@util.is_word(@util.code_at(src, at)) {
    return @common.NO_MATCH
  }
  let mut end = at + 1
  let mut i = at + 1
  while true {
    let c = @util.code_at(src, i)
    if @util.is_word(c) || c == '-'.to_int() {
      i += 1
      end = i
    } else if c == '.'.to_int() || c == '/'.to_int() {
      i += 1
    } else {
      break
    }
  }
  end
}

///|
/// Answers as the INT pattern `0|[1-9][0-9]*(?!\.)` does, which gives up its last digit rather than end before a dot.
fn int_end(src : String, at : Int32) -> Int32 {
  let first = @util.code_at(src, at)
  if first == '0'.to_int() {
    return at + 1
  }
  if !@util.is_digit(first) {
    return @common.NO_MATCH
  }
  let mut whole = at + 1
  while @util.is_digit(@util.code_at(src, whole)) {
    whole += 1
  }
  if @util.code_at(src, whole) != '.'.to_int() {
    whole
  } else if whole - 1 > at {
    whole - 1
  } else {
    @common.NO_MATCH
  }
}

///|
/// Chevrotain's LONGER_ALT: where a name matches more text than the word does, the name wins.
/// Giving way here lets the name type, which comes last in the order, take the token.
fn unless_longer_name(scan : @common.Scanner) -> @common.Scanner {
  (src, p) => {
    let end = scan(src, p)
    if end > p && reference_end(src, p) > end {
      @common.NO_MATCH
    } else {
      end
    }
  }
}

///|
/// Unlike the other grammars' lexers, this one has no `{` token, so an `accDescr {` with no closing brace ends the lexing.
/// Reading to the end of the text once is enough to know that no later one can close either.
fn acc_descr_scanner() -> @common.Scanner {
  let base = (@common.acc_descr.scanner)()
  (src, p) => {
    let end = base(src, p)
    if end != @common.NO_MATCH {
      return end
    }
    let mut at = p
    while @util.is_blank(@util.code_at(src, at)) {
      at += 1
    }
    if !@util.starts_with_at(src, "accDescr", at) {
      return @common.NO_MATCH
    }
    at += "accDescr".length()
    while @util.is_space(@util.code_at(src, at)) {
      at += 1
    }
    if @util.code_at(src, at) == '{'.to_int() {
      @common.NO_CLOSER
    } else {
      @common.NO_MATCH
    }
  }
}

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
/// Mermaid's gitGraph lexer, whose token order the constants above index.
let git_tokens : Array[@common.TokenType] = [
  word("cherry-pick"),
  @common.literal("gitGraph:", "gitGraph:"),
  word("HIGHLIGHT"),
  {
    ..@common.keyword("gitGraph"),
    scanner: () => unless_longer_name((@common.keyword("gitGraph").scanner)()),
  },
  word("checkout"),
  word("REVERSE"),
  @common.literal("parent:", "parent:"),
  word("commit"),
  word("NORMAL"),
  word("branch"),
  @common.literal("order:", "order:"),
  word("switch"),
  @common.literal("type:", "type:"),
  word("merge"),
  @common.literal("msg:", "msg:"),
  @common.literal("tag:", "tag:"),
  @common.literal("id:", "id:"),
  word("LR"),
  word("TB"),
  word("BT"),
  @common.literal(":", ":"),
  { ..@common.acc_descr, scanner: acc_descr_scanner, },
  @common.acc_title,
  @common.title,
  @common.pattern("INT", int_end, first="0123456789"),
  @common.string,
  @common.newline,
  @common.whitespace,
  @common.yaml,
  @common.directive,
  @common.single_line_comment,
  @common.pattern("REFERENCE", reference_end, first=WORD_FIRST),
]

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
fn name(r : @common.TokenReader) -> String raise @errors.PeleError {
  if r.kind() == REFERENCE {
    return r.take()
  }
  if r.kind() == STRING {
    return @common.string_value(r.take())
  }
  r.fail("a branch name")
}

///|
fn string(r : @common.TokenReader) -> String raise @errors.PeleError {
  @common.string_value(r.expect(STRING))
}

///|
fn commit_type(
  r : @common.TokenReader,
) -> CommitTypeName raise @errors.PeleError {
  match r.kind() {
    NORMAL => {
      r.i += 1
      Normal
    }
    REVERSE => {
      r.i += 1
      Reverse
    }
    HIGHLIGHT => {
      r.i += 1
      Highlight
    }
    _ => r.fail("NORMAL, REVERSE, or HIGHLIGHT")
  }
}

///|
priv struct Clauses {
  mut id : String?
  mut message : String?
  tags : Array[String]
  mut commit_type : CommitTypeName?
  mut parent : String?
}

///|
/// Reads the clauses a statement allows, in any order.
/// For a commit a bare string stands for its message.
fn clauses(
  r : @common.TokenReader,
  id~ : Bool = false,
  tag~ : Bool = false,
  kind~ : Bool = false,
  message~ : Bool = false,
  parent~ : Bool = false,
) -> Clauses raise @errors.PeleError {
  let found : Clauses = {
    id: None,
    message: None,
    tags: [],
    commit_type: None,
    parent: None,
  }
  while true {
    if id && r.accept(ID) {
      found.id = Some(string(r))
    } else if tag && r.accept(TAG) {
      found.tags.push(string(r))
    } else if kind && r.accept(TYPE) {
      found.commit_type = Some(commit_type(r))
    } else if message && (r.accept(MSG) || r.kind() == STRING) {
      found.message = Some(string(r))
    } else if parent && r.accept(PARENT) {
      found.parent = Some(string(r))
    } else {
      break
    }
  }
  found
}

///|
fn direction_of(kind : Int32) -> GitDirection? {
  match kind {
    LR_TOKEN => Some(LR)
    TB_TOKEN => Some(TB)
    BT_TOKEN => Some(BT)
    _ => None
  }
}

///|
/// Reads a git graph. Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_git(source : String) -> GitGraphAst raise @errors.PeleError {
  let r = @common.TokenReader::new(
    @common.tokenize(source, git_tokens, "gitGraph"),
    git_tokens,
    "gitGraph",
  )
  let mut dir = None
  let mut title = None
  let mut acc_title = None
  let mut acc_descr = None
  let statements = []
  newlines(r)
  if !r.accept(GIT_GRAPH_COLON) {
    r.expect(GIT_GRAPH) |> ignore
    let direction = direction_of(r.kind())
    if direction is Some(_) && r.tokens.kinds[r.i + 1] == COLON {
      dir = direction
      r.i += 2
    } else {
      r.accept(COLON) |> ignore
    }
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
      COMMIT => {
        r.i += 1
        let c = clauses(r, id=true, tag=true, kind=true, message=true)
        end_of_line(r)
        statements.push(
          Commit({
            id: c.id,
            message: c.message,
            tags: c.tags,
            commit_type: c.commit_type,
          }),
        )
      }
      BRANCH => {
        r.i += 1
        let branch = name(r)
        let order = if r.accept(ORDER) {
          Some(@util.parse_float(r.expect(INT)))
        } else {
          None
        }
        end_of_line(r)
        statements.push(Branch({ name: branch, order, }))
      }
      MERGE => {
        r.i += 1
        let branch = name(r)
        let c = clauses(r, id=true, tag=true, kind=true)
        end_of_line(r)
        statements.push(
          Merge({ branch, id: c.id, tags: c.tags, commit_type: c.commit_type, }),
        )
      }
      CHECKOUT | SWITCH => {
        r.i += 1
        let branch = name(r)
        end_of_line(r)
        statements.push(Checkout({ branch, }))
      }
      CHERRY_PICK => {
        r.i += 1
        let c = clauses(r, id=true, tag=true, parent=true)
        end_of_line(r)
        statements.push(
          CherryPicking({ id: c.id, tags: c.tags, parent: c.parent, }),
        )
      }
      _ => r.fail("a statement, a title, or a line break")
    }
  }
  { dir, title, acc_title, acc_descr, statements, }
}
