///|
fn is_id_token(t : Int32) -> Bool {
  t == NUM ||
  t == NODE_STRING ||
  t == DOWN ||
  t == MINUS ||
  t == DEFAULT ||
  t == COMMA ||
  t == COLON ||
  t == AMP ||
  t == BRKT ||
  t == MULT ||
  t == UNICODE_TEXT
}

///|
fn is_alphanum_token(t : Int32) -> Bool {
  t == NUM ||
  t == UNICODE_TEXT ||
  t == NODE_STRING ||
  t == DIR ||
  t == DOWN ||
  t == MINUS ||
  t == COMMA ||
  t == COLON ||
  t == AMP ||
  t == BRKT ||
  t == MULT
}

///|
fn is_no_tags_token(t : Int32) -> Bool {
  t == NUM ||
  t == NODE_STRING ||
  t == SPACE ||
  t == MINUS ||
  t == AMP ||
  t == UNICODE_TEXT ||
  t == COLON ||
  t == MULT ||
  t == BRKT ||
  t == STYLE ||
  t == LINKSTYLE ||
  t == CLASSDEF ||
  t == CLASS ||
  t == CLICK ||
  t == GRAPH ||
  t == DIR ||
  t == FLOW ||
  t == CONNECTOR ||
  t == GLOBAL ||
  t == END ||
  t == DOWN ||
  t == UP ||
  t == START_LINK
}

///|
fn is_style_token(t : Int32) -> Bool {
  t == NUM ||
  t == NODE_STRING ||
  t == COLON ||
  t == SPACE ||
  t == BRKT ||
  t == STYLE
}

///|
fn is_text_token(t : Int32) -> Bool {
  t == TEXT || t == TAGSTART || t == TAGEND || t == UNICODE_TEXT
}

///|
fn is_separator_token(t : Int32) -> Bool {
  t == NEWLINE || t == SEMI || t == EOF || t == COMMENT
}

///|
let text_tokens : String = "'UNICODE_TEXT', 'TEXT', 'TAGSTART'"

///|
let separators : String = "'COMMENT', 'SEMI', 'NEWLINE', 'EOF'"

///|
let statement_start : String = "'COMMENT', 'SEMI', 'NEWLINE', 'SPACE', 'EOF', 'flow', 'global', 'connector', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'STYLE', 'LINKSTYLE', 'CLASSDEF', 'CLASS', 'CLICK', 'NODE_STRING'"

///|
let directions : Array[String] = ["TB", "BT", "RL", "LR", "TD"]

///|
/// An open `flow` or `global` block: its header, and the list and collect flag of its parent.
priv struct Frame {
  global : Bool
  id : @flowchart.FlowText?
  title : @flowchart.FlowText?
  mut list : Array[@flowchart.DocItem]
  mut collect : Bool
}

///|
priv struct Parser {
  src : String
  tokens : Tokens
  db : AgentflowDb
  mut i : Int32
}

///|
fn Parser::kind(self : Parser) -> Int32 {
  if self.i < self.tokens.types.length() {
    self.tokens.types[self.i]
  } else {
    -1
  }
}

///|
fn Parser::take(self : Parser) -> String {
  let text = self.tokens.texts[self.i]
  self.i += 1
  text
}

///|
fn[T] Parser::fail(
  self : Parser,
  expected : String,
) -> T raise @errors.PeleError {
  let t = self.kind()
  let last = self.tokens.starts.length() - 1
  let at = self.tokens.starts[if self.i < last { self.i } else { last }]
  if t == ERROR {
    raise @errors.syntax_error("agentflow", self.src, at, "", lexical=true)
  }
  let name = if t >= 0 { token_names[t] } else { "undefined" }
  raise @errors.syntax_error(
    "agentflow",
    self.src,
    at,
    "Expecting \{expected}, got '\{name}'",
  )
}

///|
fn Parser::expect(
  self : Parser,
  kind : Int32,
  also~ : String = "",
) -> String raise @errors.PeleError {
  if self.kind() != kind {
    let more = if also == "" { "" } else { ", " + also }
    self.fail("'\{token_names[kind]}'\{more}")
  }
  self.take()
}

///|
fn Parser::separator(self : Parser) -> Unit raise @errors.PeleError {
  if !is_separator_token(self.kind()) {
    self.fail(separators)
  }
  self.i += 1
}

///|
fn Parser::run_of(
  self : Parser,
  belongs : (Int32) -> Bool,
  expected : String,
) -> String raise @errors.PeleError {
  if !belongs(self.kind()) {
    self.fail(expected)
  }
  let out = StringBuilder()
  out.write_string(self.take())
  while belongs(self.kind()) {
    out.write_string(self.take())
  }
  out.to_string()
}

///|
fn Parser::id_string(self : Parser) -> String raise @errors.PeleError {
  self.run_of(is_id_token, "'NODE_STRING'")
}

///|
fn Parser::alpha_num(self : Parser) -> String raise @errors.PeleError {
  self.run_of(is_alphanum_token, "'NODE_STRING'")
}

///|
fn Parser::label_of(
  self : Parser,
  kind : @flowchart.LabelType,
  belongs : (Int32) -> Bool,
) -> @flowchart.FlowText {
  let out = StringBuilder()
  out.write_string(self.take())
  while belongs(self.kind()) {
    out.write_string(self.take())
  }
  { text: out.to_string(), kind, }
}

///|
fn Parser::text(self : Parser) -> @flowchart.FlowText raise @errors.PeleError {
  let t = self.kind()
  let kind : @flowchart.LabelType = if t == STR {
    Str
  } else if t == MD_STR {
    Markdown
  } else if is_text_token(t) {
    Text
  } else {
    self.fail("\{text_tokens}, 'TAGEND', 'STR', 'MD_STR'")
  }
  self.label_of(kind, is_text_token)
}

///|
fn Parser::closed(self : Parser, kind : Int32) -> Unit raise @errors.PeleError {
  ignore(self.expect(kind, also=text_tokens))
}

///|
fn is_edge_text_token(t : Int32) -> Bool {
  t == EDGE_TEXT || t == UNICODE_TEXT
}

///|
fn Parser::edge_text(
  self : Parser,
) -> @flowchart.FlowText raise @errors.PeleError {
  let t = self.kind()
  let kind : @flowchart.LabelType = if t == STR {
    Str
  } else if t == MD_STR {
    Markdown
  } else if is_edge_text_token(t) {
    Text
  } else {
    self.fail("'EDGE_TEXT', 'STR', 'MD_STR'")
  }
  self.label_of(kind, is_edge_text_token)
}

///|
fn Parser::text_no_tags(
  self : Parser,
) -> @flowchart.FlowText raise @errors.PeleError {
  let t = self.kind()
  let kind : @flowchart.LabelType = if t == STR {
    Text
  } else if t == MD_STR {
    Markdown
  } else if is_no_tags_token(t) {
    Text
  } else {
    self.fail("'NODE_STRING', 'STR', 'MD_STR'")
  }
  self.label_of(kind, is_no_tags_token)
}

///|
/// Skips a metadata block, reporting whether there was one.
fn Parser::skip_shape_data(self : Parser) -> Bool {
  if self.kind() != SHAPE_DATA {
    return false
  }
  while self.kind() == SHAPE_DATA {
    self.i += 1
  }
  true
}

///|
/// A bracketed label closed by `closer`, with its shape.
fn Parser::shaped(
  self : Parser,
  closer : Int32,
  shape : String,
) -> (@flowchart.FlowText, String) raise @errors.PeleError {
  let label = self.text()
  self.closed(closer)
  (label, shape)
}

///|
fn Parser::vertex(self : Parser) -> String raise @errors.PeleError {
  let id = self.id_string()
  let mut props = None
  let shaped = match self.kind() {
    SQS => {
      self.i += 1
      Some(self.shaped(SQE, "square"))
    }
    DOUBLECIRCLESTART => {
      self.i += 1
      Some(self.shaped(DOUBLECIRCLEEND, "doublecircle"))
    }
    PS => {
      self.i += 1
      if self.kind() == PS {
        self.i += 1
        let label = self.text()
        self.closed(PE)
        ignore(self.expect(PE))
        Some((label, "circle"))
      } else {
        Some(self.shaped(PE, "round"))
      }
    }
    ELLIPSE_START => {
      self.i += 1
      Some(self.shaped(ELLIPSE_END, "ellipse"))
    }
    STADIUMSTART => {
      self.i += 1
      Some(self.shaped(STADIUMEND, "stadium"))
    }
    SUBROUTINESTART => {
      self.i += 1
      Some(self.shaped(SUBROUTINEEND, "subroutine"))
    }
    VERTEX_WITH_PROPS_START => {
      self.i += 1
      let field = self.expect(NODE_STRING)
      ignore(self.expect(COLON))
      let value = self.expect(NODE_STRING)
      ignore(self.expect(PIPE))
      props = Some(Map([(field, value)]))
      Some(self.shaped(SQE, "rect"))
    }
    CYLINDERSTART => {
      self.i += 1
      Some(self.shaped(CYLINDEREND, "cylinder"))
    }
    DIAMOND_START => {
      self.i += 1
      if self.kind() == DIAMOND_START {
        self.i += 1
        let label = self.text()
        self.closed(DIAMOND_STOP)
        ignore(self.expect(DIAMOND_STOP))
        Some((label, "hexagon"))
      } else {
        Some(self.shaped(DIAMOND_STOP, "diamond"))
      }
    }
    TAGEND => {
      self.i += 1
      Some(self.shaped(SQE, "odd"))
    }
    TRAPSTART => {
      self.i += 1
      let label = self.text()
      if self.kind() == INVTRAPEND {
        self.i += 1
        Some((label, "lean_right"))
      } else {
        self.closed(TRAPEND)
        Some((label, "trapezoid"))
      }
    }
    INVTRAPSTART => {
      self.i += 1
      let label = self.text()
      if self.kind() == TRAPEND {
        self.i += 1
        Some((label, "lean_left"))
      } else {
        self.closed(INVTRAPEND)
        Some((label, "inv_trapezoid"))
      }
    }
    _ => None
  }
  match shaped {
    Some((label, shape)) =>
      self.db.add_vertex(id, text=label, kind=shape, props?)
    None => self.db.add_vertex(id)
  }
  id
}

///|
fn Parser::styled_vertex(self : Parser) -> String raise @errors.PeleError {
  let id = self.vertex()
  if self.kind() == STYLE_SEPARATOR {
    self.i += 1
    self.db.set_class(id, self.id_string())
  }
  id
}

///|
fn Parser::skip_spaces(self : Parser) -> Unit {
  while self.kind() == SPACE {
    self.i += 1
  }
}

///|
/// One node or an `&` group of them.
fn Parser::node(self : Parser) -> Array[String] raise @errors.PeleError {
  let ids = [self.styled_vertex()]
  while true {
    let data = self.skip_shape_data()
    if self.kind() != SPACE {
      return ids
    }
    self.skip_spaces()
    if self.kind() != AMP {
      if data {
        self.fail("'AMP'")
      }
      return ids
    }
    self.i += 1
    if self.kind() != SPACE {
      self.fail("'SPACE'")
    }
    self.skip_spaces()
    ids.push(self.styled_vertex())
  }
  ids
}

///|
fn Parser::link(self : Parser) -> @flowchart.LinkInfo raise @errors.PeleError {
  let id = if self.kind() == LINK_ID { Some(self.take()) } else { None }
  if self.kind() == LINK {
    let info = self.db.destruct_link(self.take())
    if id is Some(_) {
      info.id = id
    }
    if self.kind() == PIPE {
      self.i += 1
      info.text = Some(self.text())
      self.closed(PIPE)
      if self.kind() == SPACE {
        self.i += 1
      }
    }
    return info
  }
  if self.kind() == START_LINK {
    let start = self.take()
    let label = self.edge_text()
    let end = self.expect(LINK, also="'EDGE_TEXT'")
    let info = self.db.destruct_link(end, start~)
    info.text = Some(label)
    if id is Some(_) {
      info.id = id
    }
    return info
  }
  self.fail("'LINK', 'START_LINK'")
}

///|
fn Parser::vertex_statement(
  self : Parser,
) -> Array[String] raise @errors.PeleError {
  let mut stmt = self.node()
  let mut nodes = stmt
  while true {
    let t = self.kind()
    if t != LINK && t != START_LINK && t != LINK_ID {
      return nodes
    }
    let info = self.link()
    let next = self.node()
    self.db.add_link(stmt, next, Some(info))
    nodes = next + nodes
    stmt = next
  }
  nodes
}

///|
fn Parser::style(self : Parser) -> String raise @errors.PeleError {
  self.run_of(is_style_token, "'NODE_STRING', 'NUM', 'COLON', 'BRKT'")
}

///|
fn Parser::styles_opt(self : Parser) -> Array[String] raise @errors.PeleError {
  let out = [self.style()]
  while self.kind() == COMMA {
    self.i += 1
    out.push(self.style())
  }
  out
}

///|
fn Parser::link_style_statement(self : Parser) -> Unit raise @errors.PeleError {
  self.i += 1
  ignore(self.expect(SPACE))
  let positions = if self.kind() == DEFAULT {
    [self.take()]
  } else {
    let positions = [self.expect(NUM, also="'DEFAULT'")]
    while self.kind() == COMMA {
      self.i += 1
      positions.push(self.expect(NUM))
    }
    positions
  }
  ignore(self.expect(SPACE))
  if self.kind() != INTERPOLATE {
    self.db.update_link(positions, self.styles_opt())
    return
  }
  self.i += 1
  ignore(self.expect(SPACE))
  let interpolate = self.alpha_num()
  if self.kind() == SPACE {
    self.i += 1
    let styles = self.styles_opt()
    self.db.update_link_interpolate(positions, interpolate)
    self.db.update_link(positions, styles)
  } else {
    self.db.update_link_interpolate(positions, interpolate)
  }
}

///|
fn Parser::link_tail(
  self : Parser,
  id : String,
  url : String,
) -> Unit raise @errors.PeleError {
  if self.kind() != SPACE {
    self.db.set_link(id, url)
    return
  }
  self.i += 1
  if self.kind() == LINK_TARGET {
    self.db.set_link(id, url, target=self.take())
    return
  }
  let tooltip = self.expect(STR, also="'LINK_TARGET'")
  if self.kind() == SPACE {
    self.i += 1
    self.db.set_link(id, url, target=self.expect(LINK_TARGET))
  } else {
    self.db.set_link(id, url)
  }
  self.db.set_tooltip(id, Some(tooltip))
}

///|
fn Parser::click_statement(self : Parser) -> Unit raise @errors.PeleError {
  let id = self.take()
  let db = self.db
  match self.kind() {
    CALLBACKNAME => {
      self.i += 1
      if self.kind() == CALLBACKARGS {
        self.i += 1
      }
      let mut tooltip = None
      if self.kind() == SPACE {
        self.i += 1
        tooltip = Some(self.expect(STR))
      }
      db.set_click_event(id)
      db.set_tooltip(id, tooltip)
    }
    HREF => {
      self.i += 1
      let url = self.expect(STR)
      self.link_tail(id, url)
    }
    STR => {
      let url = self.take()
      self.link_tail(id, url)
    }
    _ => {
      ignore(self.alpha_num())
      if self.kind() == SPACE {
        self.i += 1
        let tooltip = self.expect(STR)
        db.set_click_event(id)
        db.set_tooltip(id, Some(tooltip))
      } else {
        db.set_click_event(id)
      }
    }
  }
}

///|
/// Reads `flow` or `connector` up to the separator: an id, an optional bracketed title, optional metadata.
fn Parser::header(self : Parser) -> Frame raise @errors.PeleError {
  ignore(self.expect(SPACE, also=separators))
  let id = self.text_no_tags()
  let mut title : @flowchart.FlowText = { text: "", kind: Text, }
  if self.kind() == SQS {
    self.i += 1
    title = self.text()
    self.closed(SQE)
  }
  ignore(self.skip_shape_data())
  if !is_separator_token(self.kind()) {
    self.fail("\{separators}, 'SHAPE_DATA'")
  }
  { global: false, id: Some(id), title: Some(title), list: [], collect: false, }
}

///|
fn Parser::statement(
  self : Parser,
) -> @flowchart.DocItem raise @errors.PeleError {
  let db = self.db
  let t = self.kind()
  match t {
    STYLE => {
      self.i += 1
      ignore(self.expect(SPACE))
      let id = self.id_string()
      ignore(self.expect(SPACE))
      db.add_vertex(id, style=self.styles_opt())
      self.separator()
      Ids([])
    }
    LINKSTYLE => {
      self.link_style_statement()
      self.separator()
      Ids([])
    }
    CLASSDEF => {
      self.i += 1
      ignore(self.expect(SPACE))
      let id = self.id_string()
      ignore(self.expect(SPACE))
      db.add_class(id, self.styles_opt())
      self.separator()
      Ids([])
    }
    CLASS => {
      self.i += 1
      ignore(self.expect(SPACE))
      let ids = self.id_string()
      ignore(self.expect(SPACE))
      db.set_class(ids, self.id_string())
      self.separator()
      Ids([])
    }
    CLICK => {
      self.click_statement()
      self.separator()
      Ids([])
    }
    CONNECTOR => {
      self.i += 1
      let frame = self.header()
      self.i += 1
      Id(db.add_connector(frame.id, title?=frame.title))
    }
    DIRECTION_TB | DIRECTION_BT | DIRECTION_RL | DIRECTION_LR | DIRECTION_TD => {
      self.i += 1
      Direction(directions[t - DIRECTION_TB])
    }
    ACC_TITLE => {
      self.i += 1
      let value = @util.trim(self.expect(ACC_TITLE_VALUE))
      db.set_acc_title(value)
      Id(value)
    }
    ACC_DESCR => {
      self.i += 1
      let value = @util.trim(self.expect(ACC_DESCR_VALUE))
      db.set_acc_description(value)
      Id(value)
    }
    ACC_DESCR_MULTILINE_VALUE => {
      let value = @util.trim(self.take())
      db.set_acc_description(value)
      Id(value)
    }
    _ => {
      if !is_id_token(t) {
        self.fail(statement_start)
      }
      let nodes = self.vertex_statement()
      self.separator()
      Ids(nodes)
    }
  }
}

///|
/// Blocks nest without recursion: each open one keeps the list and collect flag of its parent.
fn Parser::document(self : Parser) -> Unit raise @errors.PeleError {
  let open : Array[Frame] = []
  let mut list : Array[@flowchart.DocItem] = []
  let mut collect = false
  while true {
    let t = self.kind()
    if t == END_OF_INPUT {
      break
    }
    if t == END {
      guard open.pop() is Some(frame) else { break }
      self.i += 1
      if frame.global {
        self.db.add_global(list)
        list = frame.list
        collect = frame.collect
        continue
      }
      let id = self.db.add_subgraph(frame.id, list, frame.title)
      list = frame.list
      collect = frame.collect
      if collect {
        list.push(Id(id))
      }
    } else if t == SEMI || t == NEWLINE || t == SPACE || t == EOF {
      if collect {
        list.push(Id(self.tokens.texts[self.i]))
      }
      self.i += 1
    } else if t == COMMENT {
      self.i += 1
    } else if t == FLOW || t == GLOBAL {
      self.i += 1
      let frame = if t == GLOBAL || is_separator_token(self.kind()) {
        let bare : Frame = {
          global: t == GLOBAL,
          id: None,
          title: None,
          list,
          collect,
        }
        self.separator()
        bare
      } else {
        let frame = self.header()
        frame.list = list
        frame.collect = collect
        self.i += 1
        frame
      }
      open.push(frame)
      list = []
      collect = true
    } else {
      let item = self.statement()
      let empty = item is Ids(ids) && ids.is_empty()
      if collect && !empty {
        list.push(item)
      }
    }
  }
  if open.length() > 0 {
    self.fail("'end'")
  }
}

///|
/// `source.replace(/}[^\S\n]*\n/g, '}\n')`: Mermaid trims spaces and tabs between a closing brace and the end of its line before parsing.
fn trim_brace_lines(source : String) -> String {
  let out = StringBuilder()
  let n = source.length()
  let mut i = 0
  while i < n {
    if @util.code_at(source, i) == '}' {
      let mut j = i + 1
      while @util.is_space(@util.code_at(source, j)) &&
            @util.code_at(source, j) != '\n' {
        j += 1
      }
      if @util.code_at(source, j) == '\n' {
        out.write_string("}\n")
        i = j + 1
        continue
      }
    }
    @util.write_range(out, source, i, i + 1)
    i += 1
  }
  out.to_string()
}

///|
/// Reads an agentflow into `db`, raising a syntax `PeleError` with Mermaid's message on invalid text.
/// `raw` reads the text as it is, as Mermaid's generated parser does without the wrapper that trims spaces after a closing brace.
pub fn parse_agentflow(
  source : String,
  db : AgentflowDb,
  raw~ : Bool = false,
) -> Unit raise @errors.PeleError {
  let src = if !raw && source.contains("}") {
    trim_brace_lines(source)
  } else {
    source
  }
  let parser : Parser = { src, tokens: tokenize(src), db, i: 0, }
  while parser.kind() == SPACE ||
        parser.kind() == NEWLINE ||
        parser.kind() == COMMENT {
    parser.i += 1
  }
  ignore(parser.expect(GRAPH, also="'SPACE', 'NEWLINE', 'COMMENT'"))
  if parser.kind() == NODIR {
    parser.i += 1
    db.set_direction("TB")
  } else {
    let dir = parser.expect(DIR, also="'NODIR'")
    let t = parser.kind()
    if t == SPACE {
      parser.skip_spaces()
      if parser.kind() != NEWLINE {
        parser.fail("'NEWLINE', 'SPACE'")
      }
    } else if t != SEMI && t != NEWLINE && t != COMMENT {
      parser.fail("'COMMENT', 'SEMI', 'NEWLINE', 'SPACE'")
    }
    parser.i += 1
    db.set_direction(dir)
  }
  parser.document()
  if parser.kind() != END_OF_INPUT {
    parser.fail(statement_start)
  }
}
