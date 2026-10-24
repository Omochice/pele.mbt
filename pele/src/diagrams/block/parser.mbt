///|
const STATEMENT_START : String = "'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style'"

///|
/// A block as one side of a statement names it: its id, and the label, brackets and arrow directions it may give.
priv struct NodeInfo {
  id : String
  label : String
  type_str : String?
  directions : Array[String]
}

///|
/// The statements of an open composite's parent, and the statement that opened it, if any.
priv struct Opened {
  list : Array[Statement]
  header : Statement?
}

///|
priv struct Parser {
  src : String
  tokens : Tokens
  db : BlockDb
  mut i : Int32
}

///|
fn Parser::kind(self : Parser) -> Tok {
  self.tokens.types[self.i]
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
  let kind = self.kind()
  let start = self.tokens.starts[self.i]
  if kind is Error {
    raise @errors.syntax_error("block", self.src, start, "", lexical=true)
  }
  raise @errors.syntax_error(
    "block",
    self.src,
    start,
    "Expecting \{expected}, got '\{kind.name()}'",
  )
}

///|
fn Parser::expect(self : Parser, kind : Tok) -> String raise @errors.PeleError {
  if !self.is_at(kind) {
    self.fail("'\{kind.name()}'")
  }
  self.take()
}

///|
fn Parser::is_at(self : Parser, kind : Tok) -> Bool {
  self.kind().name() == kind.name()
}

///|
fn Parser::node(self : Parser) -> NodeInfo raise @errors.PeleError {
  let id = self.expect(NodeId)
  if self.is_at(NodeDStart) {
    let open = self.take()
    let label = self.expect(Str)
    return {
      id,
      label,
      type_str: Some(open + self.expect(NodeDEnd)),
      directions: [],
    }
  }
  if self.is_at(BlockArrowStart) {
    let open = self.take()
    let label = self.expect(Str)
    let directions = [self.expect(Dir)]
    while self.is_at(Dir) {
      directions.push(self.take())
    }
    return {
      id,
      label,
      type_str: Some(open + self.expect(BlockArrowEnd)),
      directions,
    }
  }
  { id, label: "", type_str: None, directions: [], }
}

///|
fn Parser::node_statement(self : Parser) -> Statement raise @errors.PeleError {
  let first = self.node()
  let size = if self.is_at(Size) { @util.parse_float(self.take()) } else { 1 }
  let mut from = Block::new(
    first.id,
    type_str_to_type(first.type_str),
    label=first.label,
    directions=first.directions,
    width_in_columns=size,
  )
  let mut chain : Array[Block]? = None
  while self.is_at(Link) || self.is_at(StartLink) {
    let mut label = ""
    let starts_label = self.is_at(StartLink)
    self.i += 1
    if starts_label {
      self.expect(LinkLabel) |> ignore
      label = self.expect(Str)
      self.expect(Link) |> ignore
    }
    let link = self.tokens.texts[self.i - 1]
    let to = self.node()
    // Mermaid keeps only the last link of `A --> B --> C` and loses its start.
    // Here every link counts.
    let list = match chain {
      Some(list) => list
      None => {
        let list = [
          Block::new(
            from.id,
            from.kind,
            label=from.label,
            directions=from.directions,
          ),
        ]
        chain = Some(list)
        list
      }
    }
    from = Block::new(
      to.id,
      type_str_to_type(to.type_str),
      label=to.label,
      directions=to.directions,
    )
    let previous = list[list.length() - 1].id
    list.push(
      Block::new(
        previous + "-" + to.id,
        "edge",
        start=previous,
        end=to.id,
        label~,
        thickness=edge_str_to_thickness(link),
        pattern=edge_str_to_pattern(link),
        directions=to.directions,
        arrow_type_end=edge_str_to_edge_data(link),
        arrow_type_start=edge_str_to_edge_start_data(link),
      ),
    )
    list.push(from)
  }
  match chain {
    Some(list) => Chain(list)
    None => One(from)
  }
}

///|
/// The blocks of a closed document, with its statements of several blocks laid out in order.
fn flatten(list : Array[Statement]) -> Array[Block] {
  let blocks = []
  for statement in list {
    match statement {
      One(block) => blocks.push(block)
      Chain(chain) => blocks.append(chain)
    }
  }
  blocks
}

///|
/// The composite that an `end` closes, from the statement that opened it.
fn composite(
  header : Statement?,
  id : String,
  children : Array[Block],
) -> Block {
  match header {
    None => Block::new(id, "composite", children~)
    // The grammar spreads a link statement into the composite, which leaves it no id of its own.
    Some(Chain(_)) => Block::new("", "composite", children~)
    Some(One(block)) => { ..block, kind: "composite", children, }
  }
}

///|
/// Reads a block diagram into `db`, as Mermaid's grammar does.
/// Composites nest without recursion: each open one keeps the statement list of its parent.
/// Raises a syntax error where the grammar rejects the source.
pub fn parse_block(src : String, db : BlockDb) -> Unit raise @errors.PeleError {
  let p : Parser = { src, tokens: tokenize(src), db, i: 0, }
  p.expect(Key) |> ignore
  let open : Array[Opened] = []
  let mut list : Array[Statement] = []
  while true {
    match p.kind() {
      NodeId => list.push(p.node_statement())
      Columns => {
        let columns = @util.parse_float(p.take())
        list.push(One(Block::new("", "column-setting", columns~)))
      }
      SpaceBlock => {
        let width = @util.parse_float(p.take())
        list.push(One(Block::new(p.db.generate_id(), "space", width~)))
      }
      Key => {
        p.i += 1
        open.push({ list, header: None, })
        list = []
      }
      IdBlock => {
        p.i += 1
        if !p.is_at(NodeId) {
          p.fail("'NODE_ID'")
        }
        open.push({ list, header: Some(p.node_statement()), })
        list = []
      }
      EndKw => {
        guard open.pop() is Some(frame) && list.length() > 0 else {
          p.fail(STATEMENT_START)
        }
        p.i += 1
        let id = p.db.generate_id()
        let children = flatten(list)
        list = frame.list
        list.push(One(composite(frame.header, id, children)))
      }
      ClassDef => {
        p.i += 1
        let id = @util.trim(p.expect(ClassDefId))
        let css = @util.trim(p.expect(ClassDefStyleOpts))
        list.push(One(Block::new(id, "classDef", css~)))
      }
      Class => {
        p.i += 1
        let id = @util.trim(p.expect(ClassEntityIds))
        let style_class = @util.trim(p.expect(StyleClass))
        list.push(One(Block::new(id, "applyClass", style_class~)))
      }
      Style => {
        p.i += 1
        let id = @util.trim(p.expect(StyleEntityIds))
        let styles_str = @util.trim(p.expect(StyleDefinitionData))
        list.push(One(Block::new(id, "applyStyles", styles_str~)))
      }
      Eof => {
        if open.length() > 0 {
          p.fail(STATEMENT_START + ", 'end'")
        }
        if list.length() == 0 {
          p.fail(STATEMENT_START)
        }
        p.db.set_hierarchy(list)
        return
      }
      _ =>
        p.fail(
          if list.length() == 0 {
            STATEMENT_START
          } else if open.length() > 0 {
            STATEMENT_START + ", 'end'"
          } else {
            STATEMENT_START + ", 'EOF'"
          },
        )
    }
  }
}
