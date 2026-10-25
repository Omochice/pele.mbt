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
  /// Token index of the keyword.
  at : Int32
  id : @flowchart.FlowText?
  title : @flowchart.FlowText?
  data : String?
  data_from : Int32
  data_to : Int32
  mut list : Array[@flowchart.DocItem]
  mut collect : Bool
}

///|
priv struct Parser {
  src : String
  /// The text before the spaces after closing braces were trimmed, in which errors are reported.
  source : String
  tokens : Tokens
  db : AgentflowDb
  mut i : Int32
  mut pending_data : String?
  mut data_from : Int32
  mut data_to : Int32
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
  let at = if self.src == self.source {
    at
  } else {
    let edits = []
    trim_brace_lines(self.source, edits~) |> ignore
    @errors.input_offset([edits], at)
  }
  if t == ERROR {
    raise @errors.syntax_error("agentflow", self.source, at, "", lexical=true)
  }
  let name = if t >= 0 { token_names[t] } else { "undefined" }
  raise @errors.syntax_error(
    "agentflow",
    self.source,
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
  // Joined at its final size, because a run holding a token of hundreds of millions of
  // characters would need a doubling builder's block past what wasm allocates.
  let parts = [self.take()]
  while belongs(self.kind()) {
    parts.push(self.take())
  }
  if parts.length() == 1 {
    parts[0]
  } else {
    parts.join("")
  }
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
fn Parser::shape_data(self : Parser) -> String {
  self.data_from = self.i
  let out = StringBuilder()
  out.write_string(self.take())
  while self.kind() == SHAPE_DATA {
    out.write_string(self.take())
  }
  self.data_to = self.i - 1
  out.to_string()
}

///|
/// The span from the start of token `a` to the end of token `b`.
fn Parser::span(self : Parser, a : Int32, b : Int32) -> Loc {
  let tokens = self.tokens
  {
    first_line: tokens.first_lines[a],
    first_column: tokens.first_columns[a],
    last_line: tokens.last_lines[b],
    last_column: tokens.last_columns[b],
  }
}

///|
/// Gives the node the metadata block that follows it.
fn Parser::attach(
  self : Parser,
  id : String,
  data : String,
  from : Int32,
  to : Int32,
) -> Unit raise @errors.PeleError {
  let loc = self.span(from, to)
  self.db.add_vertex(id, metadata=data, metadata_loc=loc)
  self.db.extend_vertex_mapping(id, loc)
}

///|
/// Gives a flow or a connector the metadata block of its header.
fn Parser::attach_data(
  self : Parser,
  id : String,
  frame : Frame,
) -> Unit raise @errors.PeleError {
  guard frame.data is Some(data) else { return }
  self.db.add_vertex(
    id,
    metadata=data,
    metadata_loc=self.span(frame.data_from, frame.data_to),
  )
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
  let from = self.i
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
  self.db.add_vertex_mapping(
    id,
    shaped.map(s => s.1),
    self.span(from, self.i - 1),
  )
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
/// The metadata block after the last one is left in `pending_data`.
fn Parser::node(self : Parser) -> Array[String] raise @errors.PeleError {
  let ids = [self.styled_vertex()]
  self.pending_data = None
  while true {
    let data = if self.kind() == SHAPE_DATA {
      Some(self.shape_data())
    } else {
      None
    }
    let from = self.data_from
    let to = self.data_to
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
    if data is Some(data) {
      self.attach(ids[ids.length() - 1], data, from, to)
    }
    ids.push(next)
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
fn Parser::apply_pending(
  self : Parser,
  ids : Array[String],
) -> Unit raise @errors.PeleError {
  if self.pending_data is Some(data) {
    self.attach(ids[ids.length() - 1], data, self.data_from, self.data_to)
  }
}

///|
fn Parser::vertex_statement(
  self : Parser,
) -> Array[String] raise @errors.PeleError {
  let from = self.i
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
    self.db.add_edge_mapping(next, self.span(from, self.i - 1))
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
fn Parser::header(self : Parser, at : Int32) -> Frame raise @errors.PeleError {
  ignore(self.expect(SPACE, also=separators))
  let id = self.text_no_tags()
  let mut title : @flowchart.FlowText = { text: "", kind: Text, }
  if self.kind() == SQS {
    self.i += 1
    title = self.text()
    self.closed(SQE)
  }
  let data = if self.kind() == SHAPE_DATA {
    Some(self.shape_data())
  } else {
    None
  }
  if !is_separator_token(self.kind()) {
    self.fail("\{separators}, 'SHAPE_DATA'")
  }
  {
    global: false,
    at,
    id: Some(id),
    title: Some(title),
    data,
    data_from: self.data_from,
    data_to: self.data_to,
    list: [],
    collect: false,
  }
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
      let at = self.i
      self.i += 1
      let frame = self.header(at)
      let sep = self.i
      self.i += 1
      let id = db.add_connector(frame.id, title?=frame.title)
      self.attach_data(id, frame)
      db.add_connector_mapping(
        frame.id,
        self.span(frame.at, frame.at),
        self.span(sep, sep),
      )
      Id(id)
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
      let at = self.i
      self.i += 1
      if frame.global {
        self.db.add_global(list)
        list = frame.list
        collect = frame.collect
        continue
      }
      let id = self.db.add_subgraph(frame.id, list, frame.title)
      self.attach_data(id, frame)
      self.db.add_subgraph_mapping(
        frame.id,
        self.span(frame.at, frame.at),
        self.span(at, at),
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
    } else if t == COMMENT {
      self.i += 1
    } else if t == FLOW || t == GLOBAL {
      let at = self.i
      self.i += 1
      let frame = if t == GLOBAL || is_separator_token(self.kind()) {
        let bare : Frame = {
          global: t == GLOBAL,
          at,
          id: None,
          title: None,
          data: None,
          data_from: 0,
          data_to: 0,
          list,
          collect,
        }
        self.separator()
        bare
      } else {
        let frame = self.header(at)
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
fn trim_brace_lines(source : String, edits? : Array[@errors.Edit]) -> String {
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
        if edits is Some(edits) {
          edits.push((i, j + 1, 2))
        }
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
  let parser : Parser = {
    src,
    source,
    tokens: tokenize(src),
    db,
    i: 0,
    pending_data: None,
    data_from: 0,
    data_to: 0,
  }
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
