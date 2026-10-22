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
  t == SUBGRAPH ||
  t == SUBGRAPH_END ||
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
  t == NEWLINE || t == SEMI || t == EOF
}

///|
let text_tokens : String = "'UNICODE_TEXT', 'TEXT', 'TAGSTART'"

///|
let statement_start : String = "'SEMI', 'NEWLINE', 'SPACE', 'EOF', 'subgraph', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'STYLE', 'LINKSTYLE', 'CLASSDEF', 'CLASS', 'CLICK', 'NODE_STRING'"

///|
let directions : Array[String] = ["TB", "BT", "RL", "LR", "TD"]

///|
/// An open subgraph: its header, and the list and collect flag of its parent.
priv struct Frame {
  id : FlowText?
  title : FlowText?
  title_is_id : Bool
  mut list : Array[DocItem]
  mut collect : Bool
}

///|
priv struct Parser {
  src : String
  tokens : Tokens
  db : FlowDb
  mut i : Int32
  mut pending_data : String?
}

///|
/// The type of the token at `i`, or -1 past the end, which no table holds.
fn Parser::kind_at(self : Parser, i : Int32) -> Int32 {
  if i < self.tokens.types.length() {
    self.tokens.types[i]
  } else {
    -1
  }
}

///|
fn Parser::kind(self : Parser) -> Int32 {
  self.kind_at(self.i)
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
  let at = self.tokens.starts[@cmp.minimum(
      self.i,
      self.tokens.starts.length() - 1,
    )]
  if t == ERROR {
    raise @errors.syntax_error("flowchart", self.src, at, "", lexical=true)
  }
  let name = if t >= 0 { token_names[t] } else { "undefined" }
  raise @errors.syntax_error(
    "flowchart",
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
    self.fail("'SEMI', 'NEWLINE', 'EOF'")
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
fn Parser::text(self : Parser) -> FlowText raise @errors.PeleError {
  let t = self.kind()
  let kind : LabelType = if t == STR {
    Str
  } else if t == MD_STR {
    Markdown
  } else if is_text_token(t) {
    Text
  } else {
    self.fail("\{text_tokens}, 'TAGEND', 'STR', 'MD_STR'")
  }
  let out = StringBuilder()
  out.write_string(self.take())
  while is_text_token(self.kind()) {
    out.write_string(self.take())
  }
  { text: out.to_string(), kind, }
}

///|
fn Parser::closed(self : Parser, kind : Int32) -> Unit raise @errors.PeleError {
  ignore(self.expect(kind, also=text_tokens))
}

///|
fn Parser::edge_text(self : Parser) -> FlowText raise @errors.PeleError {
  let t = self.kind()
  let is_edge_text = (t : Int32) => t == EDGE_TEXT || t == UNICODE_TEXT
  let kind : LabelType = if t == STR {
    Str
  } else if t == MD_STR {
    Markdown
  } else if is_edge_text(t) {
    Text
  } else {
    self.fail("'EDGE_TEXT', 'STR', 'MD_STR'")
  }
  let out = StringBuilder()
  out.write_string(self.take())
  while is_edge_text(self.kind()) {
    out.write_string(self.take())
  }
  { text: out.to_string(), kind, }
}

///|
fn Parser::text_no_tags(self : Parser) -> FlowText raise @errors.PeleError {
  let t = self.kind()
  let kind : LabelType = if t == STR {
    Text
  } else if t == MD_STR {
    Markdown
  } else if is_no_tags_token(t) {
    Text
  } else {
    self.fail("'NODE_STRING', 'STR', 'MD_STR'")
  }
  let out = StringBuilder()
  out.write_string(self.take())
  while is_no_tags_token(self.kind()) {
    out.write_string(self.take())
  }
  { text: out.to_string(), kind, }
}

///|
fn Parser::shape_data(self : Parser) -> String {
  let out = StringBuilder()
  out.write_string(self.take())
  while self.kind() == SHAPE_DATA {
    out.write_string(self.take())
  }
  out.to_string()
}

///|
/// A bracketed label closed by `closer`, added as a node of the shape.
fn Parser::shaped(
  self : Parser,
  id : String,
  closer : Int32,
  shape : String,
) -> Unit raise @errors.PeleError {
  let label = self.text()
  self.closed(closer)
  self.db.add_vertex(id, text=label, kind=shape)
}

///|
fn Parser::vertex(self : Parser) -> String raise @errors.PeleError {
  let id = self.id_string()
  let db = self.db
  match self.kind() {
    SQS => {
      self.i += 1
      self.shaped(id, SQE, "square")
    }
    DOUBLECIRCLESTART => {
      self.i += 1
      self.shaped(id, DOUBLECIRCLEEND, "doublecircle")
    }
    PS => {
      self.i += 1
      if self.kind() == PS {
        self.i += 1
        let label = self.text()
        self.closed(PE)
        ignore(self.expect(PE))
        db.add_vertex(id, text=label, kind="circle")
      } else {
        self.shaped(id, PE, "round")
      }
    }
    ELLIPSE_START => {
      self.i += 1
      self.shaped(id, ELLIPSE_END, "ellipse")
    }
    STADIUMSTART => {
      self.i += 1
      self.shaped(id, STADIUMEND, "stadium")
    }
    SUBROUTINESTART => {
      self.i += 1
      self.shaped(id, SUBROUTINEEND, "subroutine")
    }
    VERTEX_WITH_PROPS_START => {
      self.i += 1
      let field = self.expect(NODE_STRING)
      ignore(self.expect(COLON))
      let value = self.expect(NODE_STRING)
      ignore(self.expect(PIPE))
      let label = self.text()
      self.closed(SQE)
      db.add_vertex(id, text=label, kind="rect", props=Map([(field, value)]))
    }
    CYLINDERSTART => {
      self.i += 1
      self.shaped(id, CYLINDEREND, "cylinder")
    }
    DIAMOND_START => {
      self.i += 1
      if self.kind() == DIAMOND_START {
        self.i += 1
        let label = self.text()
        self.closed(DIAMOND_STOP)
        ignore(self.expect(DIAMOND_STOP))
        db.add_vertex(id, text=label, kind="hexagon")
      } else {
        self.shaped(id, DIAMOND_STOP, "diamond")
      }
    }
    TAGEND => {
      self.i += 1
      self.shaped(id, SQE, "odd")
    }
    TRAPSTART => {
      self.i += 1
      let label = self.text()
      if self.kind() == INVTRAPEND {
        self.i += 1
        db.add_vertex(id, text=label, kind="lean_right")
      } else {
        self.closed(TRAPEND)
        db.add_vertex(id, text=label, kind="trapezoid")
      }
    }
    INVTRAPSTART => {
      self.i += 1
      let label = self.text()
      if self.kind() == TRAPEND {
        self.i += 1
        db.add_vertex(id, text=label, kind="lean_left")
      } else {
        self.closed(INVTRAPEND)
        db.add_vertex(id, text=label, kind="inv_trapezoid")
      }
    }
    _ => db.add_vertex(id)
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
/// One node or an `&` group of them. Node data after the last one is left in `pending_data`.
fn Parser::node(self : Parser) -> Array[String] raise @errors.PeleError {
  let ids = [self.styled_vertex()]
  self.pending_data = None
  while true {
    let data = if self.kind() == SHAPE_DATA {
      Some(self.shape_data())
    } else {
      None
    }
    if self.kind() != SPACE {
      self.pending_data = data
      return ids
    }
    self.skip_spaces()
    if self.kind() != AMP {
      if data is Some(_) {
        self.fail("'AMP'")
      }
      return ids
    }
    self.i += 1
    if self.kind() != SPACE {
      self.fail("'SPACE'")
    }
    self.skip_spaces()
    let next = self.styled_vertex()
    if data is Some(metadata) {
      self.db.add_vertex(ids[ids.length() - 1], metadata~)
    }
    ids.push(next)
  }
  ids
}

///|
fn Parser::link(self : Parser) -> LinkInfo raise @errors.PeleError {
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
fn Parser::apply_pending(
  self : Parser,
  ids : Array[String],
) -> Unit raise @errors.PeleError {
  if self.pending_data is Some(metadata) {
    self.db.add_vertex(ids[ids.length() - 1], metadata~)
  }
}

///|
fn Parser::vertex_statement(
  self : Parser,
  collect : Bool,
) -> Array[String] raise @errors.PeleError {
  let mut stmt = self.node()
  self.apply_pending(stmt)
  let mut nodes = stmt
  while true {
    let t = self.kind()
    if t != LINK && t != START_LINK && t != LINK_ID {
      return nodes
    }
    let info = self.link()
    let next = self.node()
    self.apply_pending(next)
    self.db.add_link(stmt, next, Some(info))
    if collect {
      nodes = next + nodes
    }
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
fn Parser::subgraph_header(self : Parser) -> Frame raise @errors.PeleError {
  self.i += 1
  if is_separator_token(self.kind()) {
    self.i += 1
    return {
      id: None,
      title: None,
      title_is_id: false,
      list: [],
      collect: false,
    }
  }
  ignore(self.expect(SPACE, also="'SEMI', 'NEWLINE', 'EOF'"))
  let id = self.text_no_tags()
  let mut title = id
  let mut title_is_id = true
  if self.kind() == SQS {
    self.i += 1
    title = self.text()
    title_is_id = false
    self.closed(SQE)
  }
  if !is_separator_token(self.kind()) {
    self.fail("'SEMI', 'NEWLINE', 'EOF', 'SQS'")
  }
  self.i += 1
  { id: Some(id), title: Some(title), title_is_id, list: [], collect: false, }
}

///|
fn Parser::statement(
  self : Parser,
  collect : Bool,
) -> DocItem raise @errors.PeleError {
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
      let nodes = self.vertex_statement(collect)
      self.separator()
      Ids(nodes)
    }
  }
}

///|
/// Subgraphs nest without recursion: each open one keeps the list and collect flag of its parent.
fn Parser::document(self : Parser) -> Unit raise @errors.PeleError {
  let open : Array[Frame] = []
  let mut list : Array[DocItem] = []
  let mut collect = false
  while true {
    let t = self.kind()
    if t == END_OF_INPUT {
      break
    }
    if t == SUBGRAPH_END {
      guard open.pop() is Some(frame) else { break }
      self.i += 1
      let id = self.db.add_subgraph(
        frame.id,
        list,
        frame.title,
        title_is_id=frame.title_is_id,
      )
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
    } else if t == SUBGRAPH {
      let frame = self.subgraph_header()
      frame.list = list
      frame.collect = collect
      open.push(frame)
      list = []
      collect = true
    } else {
      let item = self.statement(collect)
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
/// `source.replace(/}\s*\n/g, '}\n')`: Mermaid trims whitespace between a closing brace and the end of its line before parsing.
fn trim_brace_lines(source : String) -> String {
  let out = StringBuilder()
  let n = source.length()
  let mut i = 0
  while i < n {
    if @util.code_at(source, i) == '}' {
      let w = skip_space(source, i + 1)
      let mut k = w - 1
      while k > i && @util.code_at(source, k) != '\n' {
        k -= 1
      }
      if k > i {
        out.write_string("}\n")
        i = k + 1
        continue
      }
    }
    @util.write_range(out, source, i, i + 1)
    i += 1
  }
  out.to_string()
}

///|
/// Parses flowchart text into `db`, raising a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_flowchart(
  source : String,
  db : FlowDb,
) -> Unit raise @errors.PeleError {
  let src = if source.contains("}") { trim_brace_lines(source) } else { source }
  let parser : Parser = {
    src,
    tokens: tokenize(src),
    db,
    i: 0,
    pending_data: None,
  }
  while parser.kind() == SPACE || parser.kind() == NEWLINE {
    parser.i += 1
  }
  ignore(parser.expect(GRAPH, also="'SPACE', 'NEWLINE'"))
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
    } else if t != SEMI && t != NEWLINE {
      parser.fail("'SEMI', 'NEWLINE', 'SPACE'")
    }
    parser.i += 1
    db.set_direction(dir)
  }
  parser.document()
  if parser.kind() != END_OF_INPUT {
    parser.fail(statement_start)
  }
}
