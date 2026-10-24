// The indented outline grammar that Mermaid's mindmap and kanban diagrams share.
// Kanban adds `@{ ... }` metadata after a node and keeps `@` out of node ids.

///|
/// A token type of the outline grammar.
pub(all) enum OutlineToken {
  End
  Invalid
  Spaceline
  Nl
  Eof
  Keyword
  Spacelist
  Icon
  Class
  NodeDstart
  NodeId
  NodeDescr
  NodeDend
  ShapeData
}

///|
/// The token's name as the generated parser prints it in an error, which for the end of input is its number.
pub fn OutlineToken::name(self : OutlineToken, kanban : Bool) -> String {
  match self {
    End => "1"
    Invalid => "INVALID"
    Spaceline => "SPACELINE"
    Nl => "NL"
    Eof => "EOF"
    Keyword => if kanban { "KANBAN" } else { "MINDMAP" }
    Spacelist => "SPACELIST"
    Icon => "ICON"
    Class => "CLASS"
    NodeDstart => "NODE_DSTART"
    NodeId => "NODE_ID"
    NodeDescr => "NODE_DESCR"
    NodeDend => "NODE_DEND"
    ShapeData => "SHAPE_DATA"
  }
}

///|
/// An outline's tokens as parallel arrays: the type of each, its text, and where it starts.
pub(all) struct OutlineTokens {
  types : Array[OutlineToken]
  texts : Array[String]
  starts : Array[Int32]
}

///|
/// The lexer's start conditions.
priv enum State {
  Initial
  InClass
  InIcon
  Node
  Nstr
  Nstr2
  Data
  DataStr
}

///|
/// The end of `\s+` at `from`, or -1.
fn space_run_end(src : String, from : Int32) -> Int32 {
  let mut e = from
  while @util.is_space(@util.code_at(src, e)) {
    e += 1
  }
  if e > from {
    e
  } else {
    -1
  }
}

///|
/// The end of `.+` at `from`, or -1.
fn line_run_end(src : String, from : Int32) -> Int32 {
  let mut e = from
  while e < src.length() && !@util.is_line_end(@util.code_at(src, e)) {
    e += 1
  }
  if e > from {
    e
  } else {
    -1
  }
}

///|
/// The end of `[^excluded]+` at `from`, or -1.
fn run_end(src : String, from : Int32, excluded : String) -> Int32 {
  let mut e = from
  while e < src.length() && !excluded.contains_code_unit(src.unsafe_get(e)) {
    e += 1
  }
  if e > from {
    e
  } else {
    -1
  }
}

///|
/// Replaces each line break and the whitespace after it with `<br/>`, as `replace(/\n\s*/g, '<br/>')`.
fn breaks_to_br(text : String) -> String {
  if !text.contains("\n") {
    return text
  }
  let out = StringBuilder()
  let mut last = 0
  let mut i = 0
  while i < text.length() {
    if text.unsafe_get(i) == '\n' {
      @util.write_range(out, text, last, i)
      out.write_string("<br/>")
      i += 1
      while @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
      last = i
    } else {
      i += 1
    }
  }
  @util.write_range(out, text, last, text.length())
  out.to_string()
}

///|
/// Splits a mindmap, or with `kanban` a kanban, into tokens as Mermaid's lexer does.
/// Text the lexer cannot read ends the list with an `Invalid` token where it stops.
pub fn tokenize_outline(src : String, kanban : Bool) -> OutlineTokens {
  let n = src.length()
  let types = []
  let texts = []
  let starts = []
  let keyword = if kanban { "kanban" } else { "mindmap" }
  let id_excluded = if kanban { "([\n){}@" } else { "([\n){}" }
  let mut state = Initial
  let mut p = 0
  let mut next_break = -1
  let put = (kind : OutlineToken, text : String, end : Int32) => {
    types.push(kind)
    texts.push(text)
    starts.push(p)
    p = end
  }
  let emit = (kind : OutlineToken, end : Int32, next : State) => {
    put(kind, @util.slice(src, p, end~), end)
    state = next
  }
  let up_to = (ch : String) => {
    let e = @util.index_of(src, ch, from=p)
    if e == -1 {
      n
    } else {
      e
    }
  }
  while p < n {
    let c = @util.code_at(src, p)
    let d = @util.code_at(src, p + 1)
    match state {
      Initial => {
        let spaces = if c <= 32 || c >= 160 {
          space_run_end(src, p)
        } else {
          -1
        }
        let w = if spaces == -1 { p } else { spaces }
        if kanban && c == '@' && d == '{' {
          put(ShapeData, "", p + 2)
          state = Data
        } else if @util.code_at(src, w) == '%' &&
          @util.code_at(src, w + 1) == '%' {
          emit(Spaceline, line_run_end(src, w), Initial)
        } else if w > p {
          if next_break < p {
            next_break = up_to("\n")
          }
          if next_break >= w {
            emit(Spacelist, w, Initial)
          } else {
            let e = @util.last_index_of(src, "\n", from=w - 1)
            if e > p {
              emit(Spaceline, e + 1, Initial)
            } else {
              emit(Nl, p + 1, Initial)
            }
          }
        } else if word_at(src, p, keyword) &&
          !@util.is_word(@util.code_at(src, p + keyword.length())) {
          emit(Keyword, p + keyword.length(), Initial)
        } else if c == ':' && d == ':' && @util.code_at(src, p + 2) == ':' {
          p += 3
          state = InClass
        } else if c == ':' &&
          d == ':' &&
          word_at(src, p + 2, "icon") &&
          @util.code_at(src, p + 6) == '(' {
          p += 7
          state = InIcon
        } else if (c == '-' && d == ')') ||
          (c == '(' && (d == '-' || d == '(')) ||
          ((c == ')' || c == '{') && d == c) {
          emit(NodeDstart, p + 2, Node)
        } else if c == ')' || c == '(' || c == '[' {
          emit(NodeDstart, p + 1, Node)
        } else {
          let e = run_end(src, p, id_excluded)
          if e == -1 {
            break
          }
          emit(NodeId, e, Initial)
        }
      }
      Node =>
        if c == '"' {
          state = if d == '`' { Nstr2 } else { Nstr }
          p += if d == '`' { 2 } else { 1 }
        } else if c == ')' || c == '(' {
          let two = d == c || (c == '(' && d == '-')
          emit(NodeDend, if two { p + 2 } else { p + 1 }, Initial)
        } else if c == ']' {
          emit(NodeDend, p + 1, Initial)
        } else if (c == '}' && d == '}') || (c == '-' && d == ')') {
          emit(NodeDend, p + 2, Initial)
        } else if c == '}' {
          // A lone closing brace takes the rest of its line as text.
          emit(NodeDescr, line_run_end(src, p), Node)
        } else {
          emit(NodeDescr, run_end(src, p, ")](}"), Node)
        }
      Nstr =>
        if c == '"' {
          p += 1
          state = Node
        } else {
          emit(NodeDescr, up_to("\""), Nstr)
        }
      Nstr2 =>
        if c == '`' && d == '"' {
          p += 2
          state = Node
        } else {
          let e = run_end(src, p, "`\"")
          if e == -1 {
            break
          }
          emit(NodeDescr, e, Nstr2)
        }
      InClass => {
        let e = line_run_end(src, p)
        if e != -1 {
          emit(Class, e, Initial)
        } else if c == '\n' {
          p += 1
          state = Initial
        } else {
          break
        }
      }
      InIcon =>
        if c == ')' {
          p += 1
          state = Initial
        } else {
          emit(Icon, up_to(")"), InIcon)
        }
      Data =>
        if c == '"' {
          emit(ShapeData, p + 1, DataStr)
        } else if c == '}' {
          p += 1
          state = Initial
        } else {
          // Jison's `[^}^"]` keeps `^` out of the class as well, so a caret ends the lexing.
          let e = run_end(src, p, "}^\"")
          if e == -1 {
            break
          }
          emit(ShapeData, e, Data)
        }
      DataStr =>
        if c == '"' {
          emit(ShapeData, p + 1, Data)
        } else {
          let e = up_to("\"")
          put(ShapeData, breaks_to_br(@util.slice(src, p, end=e)), e)
        }
    }
  }
  if p < n {
    put(Invalid, "", p)
  } else {
    if state is Initial {
      put(Eof, "", n)
    }
    put(End, "", n)
  }
  { types, texts, starts, }
}

///|
/// A node drawn without a shape.
pub const NODE_TYPE_DEFAULT : Int32 = 0

///|
/// Mermaid's alias of the default node type.
pub const NODE_TYPE_NO_BORDER : Int32 = 0

///|
/// A node written `(text)`.
pub const NODE_TYPE_ROUNDED_RECT : Int32 = 1

///|
/// A node written `[text]`.
pub const NODE_TYPE_RECT : Int32 = 2

///|
/// A node written `((text))`.
pub const NODE_TYPE_CIRCLE : Int32 = 3

///|
/// A node written `)text(`.
pub const NODE_TYPE_CLOUD : Int32 = 4

///|
/// A node written `))text((`.
pub const NODE_TYPE_BANG : Int32 = 5

///|
/// A node written `{{text}}`.
pub const NODE_TYPE_HEXAGON : Int32 = 6

///|
/// The node type of a node written between `start` and `end`.
/// Any opening delimiter pairs with any closing one, as in Mermaid.
pub fn outline_node_type(start : String, end : String) -> Int32 {
  match start {
    "[" => NODE_TYPE_RECT
    "(" => if end == ")" { NODE_TYPE_ROUNDED_RECT } else { NODE_TYPE_CLOUD }
    "((" => NODE_TYPE_CIRCLE
    ")" => NODE_TYPE_CLOUD
    "))" => NODE_TYPE_BANG
    "{{" => NODE_TYPE_HEXAGON
    _ => NODE_TYPE_DEFAULT
  }
}

///|
/// What an `::icon()` or `:::class` line adds to the node before it.
pub(all) enum Decoration {
  Icon(String)
  Class(String)
}

///|
/// The model an outline is parsed into, called as the grammar's actions call Mermaid's database.
pub(open) trait OutlineDb {
  /// Adds a node indented by `level`, with the metadata written after it, if any.
  fn add_node(
    Self,
    level : Int32,
    id : String,
    descr : String,
    node_type : Int32,
    shape_data : String?,
  ) -> Unit raise @errors.PeleError
  /// Decorates the node added last.
  fn decorate_node(Self, Decoration) -> Unit
}

///|
fn is_stop(kind : OutlineToken) -> Bool {
  kind is (Spaceline | Nl | Eof)
}

///|
/// Whether a token can start a statement after the first.
fn starts_statement(kind : OutlineToken) -> Bool {
  kind is (Spaceline | Spacelist | Icon | Class | NodeDstart | NodeId)
}

///|
const STOP : String = "'SPACELINE', 'NL', 'EOF'"

///|
/// Parses a mindmap, or with `kanban` a kanban, into `db`, making the calls the grammar's actions make in the same order.
/// Raises the syntax error the generated parser would, in the same state.
pub fn[Db : OutlineDb] parse_outline(
  src : String,
  db : Db,
  kanban : Bool,
) -> Unit raise @errors.PeleError {
  let diagram = if kanban { "kanban" } else { "mindmap" }
  let { types, texts, starts, } = tokenize_outline(src, kanban)
  let data = if kanban { ", 'SHAPE_DATA'" } else { "" }
  // The token list always ends in End or Invalid, neither of which the parser moves past.
  let kind = (i : Int32) => types[i]
  let mut i = 0
  let fail = (expected : String) => {
    let t = types[i]
    if t is Invalid {
      @errors.syntax_error(diagram, src, starts[i], "", lexical=true)
    } else {
      @errors.syntax_error(
        diagram,
        src,
        starts[i],
        "Expecting \{expected}, got '\{t.name(kanban)}'",
      )
    }
  }
  let keyword = "'\{Keyword.name(kanban)}'"
  if kind(i) is Spaceline {
    i += 1
    while kind(i) is (Spaceline | Nl) {
      i += 1
    }
    if !(kind(i) is Keyword) {
      raise fail("'SPACELINE', 'NL', \{keyword}")
    }
  } else if !(kind(i) is Keyword) {
    raise fail("'SPACELINE', \{keyword}")
  }
  i += 1
  let mut first = "'SPACELINE', 'NL', 'SPACELIST', 'ICON', 'CLASS', 'NODE_DSTART', 'NODE_ID'"
  if kind(i) is Nl {
    i += 1
    first = "'SPACELINE', 'SPACELIST', 'ICON', 'CLASS', 'NODE_DSTART', 'NODE_ID'"
  }
  while true {
    let mut t = kind(i)
    let mut level = 0
    let indented = t is Spacelist
    if indented {
      level = texts[i].length()
      i += 1
      t = kind(i)
    }
    if t is (NodeId | NodeDstart) {
      let mut id = None
      let mut descr = ""
      let mut node_type = 0
      if t is NodeId {
        id = Some(texts[i])
        i += 1
      }
      if kind(i) is NodeDstart {
        let start = texts[i]
        i += 1
        if !(kind(i) is NodeDescr) {
          raise fail("'NODE_DESCR'")
        }
        descr = texts[i]
        i += 1
        if !(kind(i) is NodeDend) {
          raise fail("'NODE_DEND'")
        }
        let end = texts[i]
        i += 1
        if !is_stop(kind(i)) && !(kind(i) is ShapeData) {
          raise fail(STOP + data)
        }
        node_type = outline_node_type(start, end)
      } else {
        if !is_stop(kind(i)) && !(kind(i) is ShapeData) {
          raise fail(STOP + ", 'NODE_DSTART'" + data)
        }
        descr = id.unwrap()
      }
      let id = id.unwrap_or(descr)
      if kind(i) is ShapeData {
        let shape_data = StringBuilder()
        while kind(i) is ShapeData {
          shape_data.write_string(texts[i])
          i += 1
        }
        if !is_stop(kind(i)) {
          raise fail(STOP + data)
        }
        db.add_node(level, id, descr, node_type, Some(shape_data.to_string()))
      } else {
        db.add_node(level, id, descr, node_type, None)
      }
    } else if t is (Icon | Class) {
      let text = texts[i]
      i += 1
      if !is_stop(kind(i)) {
        raise fail(STOP)
      }
      db.decorate_node(
        if t is Icon {
          Decoration::Icon(text)
        } else {
          Decoration::Class(text)
        },
      )
    } else if indented {
      if !is_stop(t) {
        raise fail(STOP + ", 'ICON', 'CLASS', 'NODE_DSTART', 'NODE_ID'")
      }
    } else if t is Spaceline {
      i += 1
      if !is_stop(kind(i)) {
        raise fail(STOP)
      }
    } else {
      raise fail(first)
    }
    i += 1
    while kind(i) is (Nl | Eof) {
      i += 1
    }
    if kind(i) is End {
      return
    }
    if !starts_statement(kind(i)) {
      raise fail(
        STOP + ", 'SPACELIST', 'ICON', 'CLASS', 'NODE_DSTART', 'NODE_ID'",
      )
    }
  }
}
