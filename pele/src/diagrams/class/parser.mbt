///|
const NAME_TOKENS : String = "'UNICODE_TEXT', 'NUM', 'ALPHA', 'MINUS', 'BQUOTE_STR'"

///|
const STATEMENT_TOKENS : String = "'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'NAMESPACE', 'ANNOTATION_START', 'CLASS', 'MEMBER', 'NOTE_FOR', 'NOTE', 'CLASSDEF', 'direction_tb', 'CALLBACK', 'LINK', 'CLICK', 'STYLE', 'CSSCLASS', 'ALPHA', 'MINUS', 'BQUOTE_STR'"

///|
fn is_alpha_num(kind : Tok) -> Bool {
  kind is (UnicodeText | Alpha | Minus)
}

///|
fn is_style_part(kind : Tok) -> Bool {
  kind is (Alpha | Colon | Brkt | Style | Pct | Label)
}

///|
fn is_line(kind : Tok) -> Bool {
  kind is (Line | DottedLine)
}

///|
/// Mermaid's relationType of an end marker token.
fn end_type(kind : Tok) -> Int32? {
  match kind {
    Aggregation => Some(0)
    Extension => Some(1)
    Composition => Some(2)
    Dependency => Some(3)
    Lollipop => Some(4)
    _ => None
  }
}

///|
/// A namespace being read, with the classes and notes declared directly in it.
priv struct Frame {
  id : String
  classes : Array[String]
  notes : Array[String]
}

///|
priv struct Parser {
  src : String
  types : Array[Tok]
  texts : Array[String]
  starts : Array[Int32]
  db : ClassDb
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
    raise @errors.syntax_error("class", self.src, start, "", lexical=true)
  }
  raise @errors.syntax_error(
    "class",
    self.src,
    start,
    "Expecting \{expected}, got '\{kind.name()}'",
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
fn Parser::alpha_num(self : Parser) -> String raise @errors.PeleError {
  if !is_alpha_num(self.kind()) {
    self.fail("'UNICODE_TEXT', 'NUM', 'ALPHA', 'MINUS'")
  }
  self.take()
}

///|
/// The texts joined, without a copy when there is only one.
/// A doubling builder would need a block past what wasm allocates for a text of hundreds of
/// millions of characters, which `join` sizes before it copies.
fn joined(parts : Array[String]) -> String {
  if parts.length() == 1 {
    parts[0]
  } else {
    parts.join("")
  }
}

///|
/// A class name: words joined by dots, or a backtick name, with the generic type after it when `generic`.
fn Parser::name(
  self : Parser,
  generic : Bool,
) -> String raise @errors.PeleError {
  let out : Array[String] = []
  while true {
    if self.kind() is BquoteStr {
      out.push(self.take())
      break
    }
    if !is_alpha_num(self.kind()) {
      self.fail(NAME_TOKENS)
    }
    out.push(self.take())
    let next = self.kind()
    if next is Dot {
      out.push(".")
      self.i += 1
    } else if !is_alpha_num(next) && !(next is BquoteStr) {
      break
    }
  }
  if generic && self.kind() is GenericType {
    out.push("~")
    out.push(self.take())
    out.push("~")
  }
  joined(out)
}

///|
fn Parser::class_label(self : Parser) -> String raise @errors.PeleError {
  self.i += 1
  let label = self.expect(Str)
  ignore(self.expect(Sqe))
  label
}

///|
fn Parser::members(self : Parser) -> Array[String] raise @errors.PeleError {
  if !(self.kind() is Member) {
    self.fail("'STRUCT_STOP', 'MEMBER'")
  }
  let list = []
  while self.kind() is Member {
    list.push(self.take())
  }
  ignore(self.expect(StructStop))
  // The grammar collects members last to first, and add_members turns them back.
  list.rev_in_place()
  list
}

///|
fn Parser::class_body(
  self : Parser,
  id : String,
) -> Unit raise @errors.PeleError {
  if self.kind() is StructStop {
    self.i += 1
  } else {
    self.db.add_members(id, self.members())
  }
}

///|
fn Parser::class_statement(self : Parser) -> String raise @errors.PeleError {
  self.i += 1
  let id = self.name(true)
  self.db.add_class(id)
  if self.kind() is Sqs {
    self.db.set_class_label(id, self.class_label())
  }
  match self.kind() {
    StyleSeparator => {
      self.i += 1
      let css = self.alpha_num()
      self.db.set_css_class(id, css)
      if self.kind() is StructStart {
        self.i += 1
        self.db.add_members(id, self.members())
      }
    }
    StructStart => {
      self.i += 1
      self.class_body(id)
    }
    AnnotationStart => {
      self.i += 1
      let annotation = self.alpha_num()
      ignore(self.expect(AnnotationEnd))
      self.db.add_annotation(id, annotation)
      if self.kind() is StructStart {
        self.i += 1
        self.class_body(id)
      }
    }
    _ => ()
  }
  id
}

///|
fn Parser::note_statement(self : Parser) -> String raise @errors.PeleError {
  let kind = self.kind()
  self.i += 1
  if kind is Note {
    return self.db.add_note(self.expect(Str))
  }
  let id = self.name(true)
  self.db.add_note(self.expect(Str), class_id=id)
}

///|
/// Namespaces nest, so they are parsed with a stack of open ones.
fn Parser::namespace_statement(self : Parser) -> Unit raise @errors.PeleError {
  let open : Array[Frame] = []
  while true {
    self.i += 1
    let ns = self.name(false)
    let id = if self.kind() is Sqs {
      let label = self.class_label()
      self.db.add_namespace(ns, label~)
    } else {
      self.db.add_namespace(ns)
    }
    ignore(self.expect(StructStart))
    if self.kind() is Newline {
      self.i += 1
    }
    open.push({ id, classes: [], notes: [], })
    let mut item = true
    while item {
      let frame = open[open.length() - 1]
      match self.kind() {
        Namespace => break
        Class => frame.classes.push(self.class_statement())
        Note | NoteFor => frame.notes.push(self.note_statement())
        _ => self.fail("'NAMESPACE', 'CLASS', 'NOTE_FOR', 'NOTE'")
      }
      while true {
        if self.kind() is Newline {
          if self.types[self.i + 1] is (Namespace | Class | Note | NoteFor) {
            self.i += 1
            break
          }
          self.i += 1
        }
        ignore(self.expect(StructStop))
        let done = open.unsafe_pop()
        self.db.add_classes_to_namespace(done.id, done.classes, done.notes)
        self.db.pop_namespace()
        if open.length() == 0 {
          item = false
          break
        }
      }
    }
    if open.length() == 0 {
      return
    }
  }
}

///|
fn Parser::relation_end(self : Parser) -> Int32? {
  let kind = end_type(self.kind())
  if kind is Some(_) {
    self.i += 1
  }
  kind
}

///|
fn Parser::class_or_relation(self : Parser) -> Unit raise @errors.PeleError {
  let id1 = self.name(true)
  let kind = self.kind()
  if kind is Label {
    self.db.add_member(id1, self.db.cleanup_label(self.take()))
    return
  }
  let mut title1 = "none"
  if kind is Str {
    title1 = self.take()
  } else if end_type(kind) is None && !is_line(kind) {
    return
  }
  let type1 = self.relation_end()
  let line = self.kind()
  if !is_line(line) {
    self.fail(
      "'AGGREGATION', 'EXTENSION', 'COMPOSITION', 'DEPENDENCY', 'LOLLIPOP', 'LINE', 'DOTTED_LINE'",
    )
  }
  self.i += 1
  let type2 = self.relation_end()
  let title2 = if self.kind() is Str { self.take() } else { "none" }
  let id2 = self.name(true)
  let title = if self.kind() is Label {
    Some(self.db.cleanup_label(self.take()))
  } else {
    None
  }
  self.db.add_relation({
    id1,
    id2,
    relation: { type1, type2, line_type: if line is Line { 0 } else { 1 }, },
    relation_title1: title1,
    relation_title2: title2,
    title,
  })
}

///|
fn Parser::styles(self : Parser) -> Array[String] raise @errors.PeleError {
  let out = []
  while true {
    if !is_style_part(self.kind()) {
      self.fail(
        "'ALPHA', 'NUM', 'COLON', 'UNIT', 'SPACE', 'BRKT', 'STYLE', 'PCT', 'LABEL'",
      )
    }
    let s = [self.take()]
    while is_style_part(self.kind()) {
      s.push(self.take())
    }
    out.push(joined(s))
    if !(self.kind() is Comma) {
      break
    }
    self.i += 1
  }
  out
}

///|
fn Parser::tooltip(self : Parser, id : String) -> Unit {
  if self.kind() is Str {
    self.db.set_tooltip(id, Some(self.take()))
  }
}

///|
fn Parser::link_statement(
  self : Parser,
  id : String,
) -> Unit raise @errors.PeleError {
  let href = self.expect(Str)
  let tip = if self.kind() is Str { Some(self.take()) } else { None }
  if self.kind() is LinkTarget {
    self.db.set_link(id, href, target=self.take())
  } else {
    self.db.set_link(id, href)
  }
  self.db.set_tooltip(id, tip)
}

///|
fn Parser::statement(self : Parser) -> Unit raise @errors.PeleError {
  let kind = self.kind()
  match kind {
    UnicodeText | Alpha | Minus | BquoteStr => self.class_or_relation()
    Namespace => self.namespace_statement()
    Class => ignore(self.class_statement())
    Member => self.i += 1
    AnnotationStart => {
      self.i += 1
      let annotation = self.alpha_num()
      ignore(self.expect(AnnotationEnd))
      self.db.add_annotation(self.name(true), annotation)
    }
    Callback => {
      self.i += 1
      let id = self.name(true)
      ignore(self.expect(Str))
      self.db.set_click_event(id)
      self.tooltip(id)
    }
    Link => {
      self.i += 1
      let id = self.name(true)
      self.link_statement(id)
    }
    Click => {
      self.i += 1
      let id = self.name(true)
      if self.kind() is Href {
        self.i += 1
        self.link_statement(id)
        return
      }
      ignore(self.expect(CallbackName))
      if self.kind() is CallbackArgs {
        self.i += 1
      }
      self.db.set_click_event(id)
      self.tooltip(id)
    }
    Style => {
      self.i += 1
      let id = self.expect(Alpha)
      self.db.set_css_style(id, self.styles())
    }
    CssClass => {
      self.i += 1
      let ids = self.expect(Str)
      self.db.set_css_class(ids, self.expect(Alpha))
    }
    Note | NoteFor => ignore(self.note_statement())
    ClassDef => {
      self.i += 1
      let ids = [self.expect(Alpha)]
      while self.kind() is Comma {
        self.i += 1
        ids.push(self.expect(Alpha))
      }
      self.db.define_class(ids, self.styles())
    }
    DirectionTb | DirectionBt | DirectionRl | DirectionLr => {
      self.i += 1
      self.db.set_direction(
        match kind {
          DirectionTb => "TB"
          DirectionBt => "BT"
          DirectionRl => "RL"
          _ => "LR"
        },
      )
    }
    AccTitle => {
      self.i += 1
      self.db.set_acc_title(@util.trim(self.expect(AccTitleValue)))
    }
    AccDescr => {
      self.i += 1
      self.db.set_acc_description(@util.trim(self.expect(AccDescrValue)))
    }
    AccDescrMultilineValue =>
      self.db.set_acc_description(@util.trim(self.take()))
    _ => self.fail(STATEMENT_TOKENS)
  }
}

///|
/// Reads a class diagram into `db`, failing as Mermaid's grammar does.
pub fn parse_class(src : String, db : ClassDb) -> Unit raise @errors.PeleError {
  let { types, texts, starts, } = tokenize(src)
  let parser = { src, types, texts, starts, db, i: 0, }
  // Mermaid's grammar also accepts statements with no `classDiagram` line before them.
  let header = parser.kind() is ClassDiagram
  if header {
    parser.i += 1
    ignore(parser.expect(Newline))
  }
  while true {
    parser.statement()
    if !(parser.kind() is Newline) {
      break
    }
    parser.i += 1
    if parser.kind() is (Eof | End) {
      break
    }
  }
  if header {
    ignore(parser.expect(Eof))
  }
  ignore(parser.expect(End))
}
