///|
const NAME : String = "'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE'"

///|
const CARDS : String = "'ZERO_OR_ONE', 'ZERO_OR_MORE', 'ONE_OR_MORE', 'ONLY_ONE', 'MD_PARENT'"

///|
/// What may start a line, as Mermaid's grammar lists it; `title` is a token the lexer never yields.
const LINE : String = "'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', " +
  NAME

///|
fn cardinality(kind : Tok) -> Cardinality? {
  match kind {
    ZeroOrOne => Some(ZeroOrOne)
    ZeroOrMore => Some(ZeroOrMore)
    OneOrMore => Some(OneOrMore)
    OnlyOne => Some(OnlyOne)
    MdParent => Some(MdParent)
    _ => None
  }
}

///|
fn is_name(kind : Tok) -> Bool {
  kind is (UnicodeText | EntityName | Num | DecimalNum | EntityOne)
}

///|
fn is_style_component(kind : Tok) -> Bool {
  kind is (StyleText | Num | Colon | Brkt)
}

///|
/// A subgraph being read, with the value of every statement inside it as Mermaid's grammar hands them to `add_sub_graph`.
/// Besides entity names those include accessibility text and the keywords `style`, `class` and `classDef`.
priv struct Frame {
  id : String
  title : String
  list : Array[DocItem]
}

///|
priv struct Parser {
  src : String
  types : Array[Tok]
  texts : Array[String]
  starts : Array[Int32]
  db : ErDb
  mut i : Int32
}

///|
fn[T] Parser::fail(
  self : Parser,
  expected : String,
) -> T raise @errors.PeleError {
  let kind = self.types[self.i]
  let start = self.starts[self.i]
  if kind is Error {
    raise @errors.syntax_error("er", self.src, start, "", lexical=true)
  }
  let got = if kind is Char { self.texts[self.i] } else { kind.name() }
  raise @errors.syntax_error(
    "er",
    self.src,
    start,
    "Expecting \{expected}, got '\{got}'",
  )
}

///|
fn Parser::kind(self : Parser) -> Tok {
  self.types[self.i]
}

///|
fn Parser::take(self : Parser) -> String {
  let text = self.texts[self.i]
  self.i += 1
  text
}

///|
fn Parser::expect(self : Parser, kind : Tok) -> String raise @errors.PeleError {
  if self.kind().name() != kind.name() {
    self.fail("'\{kind.name()}'")
  }
  self.take()
}

///|
fn Parser::separator(self : Parser) -> Unit raise @errors.PeleError {
  if !(self.kind() is (Newline | Semi | Eof)) {
    self.fail("'EOF', 'NEWLINE', 'SEMI'")
  }
  self.i += 1
}

///|
fn Parser::entity_name(self : Parser) -> String raise @errors.PeleError {
  let kind = self.kind()
  if !is_name(kind) {
    self.fail(NAME)
  }
  let text = self.take()
  if kind is EntityName {
    unquote(text)
  } else {
    text
  }
}

///|
fn unquote(text : String) -> String {
  @util.slice(text, 1, end=text.length() - 1)
}

///|
fn Parser::id_list(self : Parser) -> Array[String] raise @errors.PeleError {
  let ids = []
  while true {
    if !(self.kind() is (UnicodeText | StyleText)) {
      self.fail("'UNICODE_TEXT', 'STYLE_TEXT'")
    }
    ids.push(self.take())
    if !(self.kind() is Comma) {
      break
    }
    self.i += 1
  }
  ids
}

///|
fn Parser::styles(self : Parser) -> Array[String] raise @errors.PeleError {
  let styles = []
  while true {
    if !is_style_component(self.kind()) {
      self.fail("'STYLE_TEXT', 'COLON', 'NUM', 'BRKT'")
    }
    let style = StringBuilder()
    style.write_string(self.take())
    while is_style_component(self.kind()) {
      style.write_string(self.take())
    }
    styles.push(style.to_string())
    if !(self.kind() is Comma) {
      break
    }
    self.i += 1
  }
  styles
}

///|
fn Parser::rel_spec(self : Parser) -> RelSpec raise @errors.PeleError {
  guard cardinality(self.kind()) is Some(card_b) else { self.fail(CARDS) }
  self.i += 1
  let rel_type : Identification = match self.kind() {
    Identifying => Identifying
    NonIdentifying => NonIdentifying
    _ => self.fail("'NON_IDENTIFYING', 'IDENTIFYING'")
  }
  self.i += 1
  guard cardinality(self.kind()) is Some(card_a) else { self.fail(CARDS) }
  self.i += 1
  { card_a, rel_type, card_b, }
}

///|
fn Parser::role(self : Parser) -> String raise @errors.PeleError {
  let kind = self.kind()
  if !(kind is (Word | EntityName | UnicodeText)) {
    self.fail("'UNICODE_TEXT', 'ENTITY_NAME', 'WORD'")
  }
  let text = self.take()
  if kind is UnicodeText {
    text
  } else {
    unquote(text)
  }
}

///|
fn Parser::is_char(self : Parser, ch : String) -> Bool {
  self.kind() is Char && self.texts[self.i] == ch
}

///|
/// The attributes last to first, as Mermaid's right-recursive rule builds them.
fn Parser::attributes(
  self : Parser,
) -> Array[ErAttribute] raise @errors.PeleError {
  let list = []
  while true {
    let mut data_type = self.expect(AttributeWord)
    if self.is_char("?") {
      data_type = data_type + self.take()
    }
    if !(self.kind() is AttributeWord) {
      self.fail(
        if data_type.has_suffix("?") {
          "'ATTRIBUTE_WORD'"
        } else {
          "'ATTRIBUTE_WORD', '?'"
        },
      )
    }
    let name = self.take()
    let keys = []
    if self.kind() is AttributeKey {
      keys.push(self.take())
      while self.is_char(",") {
        self.i += 1
        keys.push(self.expect(AttributeKey))
      }
    }
    let comment = if self.kind() is Comment { unquote(self.take()) } else { "" }
    list.push({ data_type, name, keys, comment, })
    if self.kind() is BlockStop {
      break
    }
  }
  list.rev_in_place()
  list
}

///|
/// An optional `{ ... }` block; `None` when there is none or it is empty.
fn Parser::block(self : Parser) -> Array[ErAttribute]? raise @errors.PeleError {
  if !(self.kind() is BlockStart) {
    return None
  }
  self.i += 1
  if self.kind() is BlockStop {
    self.i += 1
    return None
  }
  let list = self.attributes()
  self.i += 1
  Some(list)
}

///|
fn Parser::classes(self : Parser) -> Array[String]? raise @errors.PeleError {
  if !(self.kind() is StyleSeparator) {
    return None
  }
  self.i += 1
  Some(self.id_list())
}

///|
/// Reads an entity, with its alias or attributes, or a relationship, and returns the names it mentions.
fn Parser::entity_statement(
  self : Parser,
) -> Array[String] raise @errors.PeleError {
  let db = self.db
  let a = self.entity_name()
  if self.kind() is Sqs {
    self.i += 1
    let alias_name = self.entity_name()
    ignore(self.expect(Sqe))
    let classes = self.classes()
    let attrs = self.block()
    ignore(db.add_entity(a, alias_name~))
    if attrs is Some(attrs) {
      db.add_attributes(a, attrs)
    }
    if classes is Some(classes) {
      db.set_class([a], classes)
    }
    return [a]
  }
  let classes = self.classes()
  if cardinality(self.kind()) is Some(_) {
    let spec = self.rel_spec()
    let b = self.entity_name()
    let classes_b = self.classes()
    ignore(self.expect(Colon))
    let label = self.role()
    ignore(db.add_entity(a))
    ignore(db.add_entity(b))
    db.add_relationship(a, label, b, spec)
    if classes is Some(classes) {
      db.set_class([a], classes)
    }
    if classes_b is Some(classes_b) {
      db.set_class([b], classes_b)
    }
    return [a, b]
  }
  let attrs = self.block()
  ignore(db.add_entity(a))
  if attrs is Some(attrs) {
    db.add_attributes(a, attrs)
  }
  if classes is Some(classes) {
    db.set_class([a], classes)
  }
  [a]
}

///|
/// Reads an ER diagram into `db` as Mermaid's grammar does, raising Mermaid's syntax errors.
pub fn parse_er(src : String, db : ErDb) -> Unit raise @errors.PeleError {
  let tokens = tokenize(src)
  let p : Parser = {
    src,
    types: tokens.types,
    texts: tokens.texts,
    starts: tokens.starts,
    db,
    i: 0,
  }
  ignore(p.expect(ErDiagram))
  // Subgraphs nest on this stack rather than on the call stack; the first frame is the diagram itself.
  let frames : Array[Frame] = [{ id: "", title: "", list: [], }]
  while true {
    let nested = frames.length() > 1
    let frame = frames[frames.length() - 1]
    let kind = p.kind()
    match kind {
      Newline => p.i += 1
      Eof => {
        p.i += 1
        if nested {
          p.fail("'END', \{LINE}")
        }
        return
      }
      EndKw => {
        if !nested {
          p.fail(LINE)
        }
        p.i += 1
        let id = db.add_sub_graph(frame.id, frame.list, frame.title)
        ignore(frames.pop())
        if frames.length() > 1 {
          frames[frames.length() - 1].list.push(Name(id))
        }
      }
      Subgraph => {
        p.i += 1
        let id = p.entity_name()
        let mut title = id
        if p.kind() is Sqs {
          p.i += 1
          let words = StringBuilder()
          words.write_string(p.entity_name())
          while is_name(p.kind()) {
            words.write_char(' ')
            words.write_string(p.entity_name())
          }
          title = words.to_string()
          ignore(p.expect(Sqe))
        }
        p.separator()
        frames.push({ id, title, list: [], })
      }
      AccTitle => {
        p.i += 1
        let value = @util.trim(p.expect(AccTitleValue))
        db.set_acc_title(value)
        if nested {
          frame.list.push(Name(value))
        }
      }
      AccDescr => {
        p.i += 1
        let value = @util.trim(p.expect(AccDescrValue))
        db.set_acc_description(value)
        if nested {
          frame.list.push(Name(value))
        }
      }
      AccDescrMultilineValue => {
        let value = @util.trim(p.take())
        db.set_acc_description(value)
        if nested {
          frame.list.push(Name(value))
        }
      }
      DirectionTb | DirectionBt | DirectionRl | DirectionLr => {
        p.i += 1
        let value = match kind {
          DirectionTb => "TB"
          DirectionBt => "BT"
          DirectionRl => "RL"
          _ => "LR"
        }
        if nested {
          frame.list.push(Dir(value))
        } else {
          db.set_direction(value)
        }
      }
      ClassDef => {
        let keyword = p.take()
        let ids = p.id_list()
        let styles = p.styles()
        p.separator()
        db.add_class(ids, styles)
        if nested {
          frame.list.push(Name(keyword))
        }
      }
      Class => {
        let keyword = p.take()
        let ids = p.id_list()
        db.set_class(ids, p.id_list())
        if nested {
          frame.list.push(Name(keyword))
        }
      }
      Style => {
        let keyword = p.take()
        let ids = p.id_list()
        let styles = p.styles()
        p.separator()
        db.add_css_styles(ids, styles)
        if nested {
          frame.list.push(Name(keyword))
        }
      }
      _ => {
        if !is_name(kind) {
          p.fail(if nested { "'END', \{LINE}" } else { LINE })
        }
        let names = p.entity_statement()
        if nested {
          for name in names {
            frame.list.push(Name(name))
          }
        }
      }
    }
  }
}
