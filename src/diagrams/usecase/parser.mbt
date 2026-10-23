// Mermaid parses use case diagrams with a Chevrotain parser, which decides each choice by looking at most three tokens ahead and reports the first token that fits nowhere.
// This parser makes the same decisions from the same lookahead, so it accepts the same text and names the same token in its errors.
// It collects drafts that are resolved into the model once the whole text is read.

///|
const LINE : Int32 = 1

///|
const RELATION : Int32 = 2

///|
const STYLE_PART : Int32 = 4

///|
const FOLLOWS_NAME : Int32 = 8

///|
const BOUNDARY_LINE : Int32 = 16

///|
const CLOSES_LABEL : Int32 = 32

///|
const METADATA_FIRST : Int32 = 64

///|
const ARROWS : String = "DEPENDENCY_ARROW|GENERALIZATION|FORWARD_SOLID|BACKWARD_SOLID|MARKERLESS_SOLID|FORWARD_CIRCLE|BACKWARD_CIRCLE|FORWARD_CROSS|BACKWARD_CROSS"

///|
const NAMES : String = "IDENTIFIER|PLAIN_STRING|MARKDOWN_STRING"

///|
const LABELS : String = "PLAIN_STRING|MARKDOWN_STRING|LABEL_TEXT"

///|
const STATEMENTS : String = "ACC_TITLE_LINE|ACC_DESCR_LINE|ACC_DESCR_BLOCK|DIRECTION|ACTOR|SYSTEM_BOUNDARY|NOTE|JSON_DECLARATION_START|CLASS_DEF|CLASS|STYLE"

///|
const STYLE_PARTS : String = "WORD|PLAIN_STRING|NUMBER|HASH_COLOR|CSS_IDENTIFIER|CSS_ESCAPED_COMMA|DASH|DOT|PERCENT|CSS_PUNCTUATION|COLON|LPAREN|RPAREN|LBRACKET|RBRACKET|LBRACE|RBRACE|AT|MARKERLESS_SOLID"

///|
let flags : FixedArray[Int32] = build_flags()

///|
fn build_flags() -> FixedArray[Int32] {
  let table = FixedArray::make(RPAREN + 1, 0)
  let flag = (names : String, bits : Int32) => {
    for view in names.split("|") {
      let name = view.to_owned()
      // WORD is a category: every keyword and IDENTIFIER.
      if name == "WORD" {
        for t in USECASE..<=IDENTIFIER {
          table[t] = table[t] | bits
        }
      } else {
        for t, known in token_names {
          if known == name {
            table[t] = table[t] | bits
          }
        }
      }
    }
  }
  flag("NEWLINE|COMMENT|\{STATEMENTS}|\{NAMES}", LINE)
  flag("IDENTIFIER|\{ARROWS}", RELATION)
  flag(STYLE_PARTS, STYLE_PART)
  flag(
    "STEREOTYPE_START|CLASS_SEPARATOR|IDENTIFIER|\{ARROWS}|NEWLINE|EOF",
    FOLLOWS_NAME,
  )
  flag("NEWLINE|COMMENT|ACTOR|\{NAMES}", BOUNDARY_LINE)
  flag(
    "FORWARD_SOLID|MARKERLESS_SOLID|FORWARD_CIRCLE|FORWARD_CROSS",
    CLOSES_LABEL,
  )
  flag("NEWLINE|IDENTIFIER|PLAIN_STRING|RBRACE", METADATA_FIRST)
  table
}

///|
/// Every token sequence that can start a statement, as Chevrotain lists them.
let statement_sequences : String = build_statement_sequences()

///|
fn build_statement_sequences() -> String {
  let names = NAMES.split("|").map(name => name.to_owned()).to_array()
  let metadata = []
  for name in names {
    for next in ["NEWLINE", "IDENTIFIER", "PLAIN_STRING", "RBRACE"] {
      metadata.push("\{name}, METADATA_START, \{next}")
    }
  }
  let follows = "STEREOTYPE_START|CLASS_SEPARATOR|IDENTIFIER|\{ARROWS}|NEWLINE|EOF"
    .split("|")
    .map(name => name.to_owned())
    .to_array()
  let entities = []
  for i, name in names {
    let nexts = if i == 0 { ["LPAREN", "LBRACKET"] + follows } else { follows }
    for next in nexts {
      entities.push("\{name}, \{next}")
    }
  }
  ([STATEMENTS] + metadata + entities + metadata).join("|")
}

///|
/// The PlantUML statements people are most likely to try, which Mermaid turns away.
let forbidden : Array[String] = [
  "allowmixing", "newpage", "package", "rectangle", "skinparam",
]

///|
/// A name with what its mention says: the id, the label, and what follows it.
priv struct Item {
  id : String
  label : DraftLabel
  span : Span
  generated : Bool
  mut shape : String?
  mut metadata : Array[DraftProperty]?
  mut stereotype : String?
  classes : Array[String]
  /// Whether this mention says something about the element, and so declares it.
  mut explicit : Bool
}

///|
/// What follows the source of a relationship: its operator, label and target.
priv struct Tail {
  explicit_id : String?
  explicit_id_span : Span?
  rel_type : String
  arrow_type : Int32
  label : DraftLabel?
  minlen : Int32
  target : Item
  span : Span
}

///|
priv struct Parser {
  src : String
  types : Array[Int32]
  starts : Array[Int32]
  ends : Array[Int32]
  mut p : Int32
  drafts : Drafts
  mut parent : DraftBoundary?
  pending_json : Array[(DraftJson, Int32)]
}

///|
fn Parser::kind(self : Parser, k : Int32) -> Int32 {
  self.types[k]
}

///|
fn Parser::image(self : Parser, k : Int32) -> String {
  @util.slice(self.src, self.starts[k], end=self.ends[k])
}

///|
fn Parser::span(self : Parser, k : Int32) -> Span {
  (self.starts[k], self.ends[k])
}

///|
fn[T] Parser::fail(self : Parser, detail : String) -> T raise @errors.PeleError {
  let start = self.starts[self.p]
  let (line, column) = line_column(self.src, start)
  raise @errors.pele_error(
    "Error parsing usecase diagram: \{detail} at line \{line}, column \{column} [\{start},\{self.ends[self.p]})",
    code=Syntax,
    kind="usecase",
    line~,
    column~,
  )
}

///|
fn[T] Parser::mismatch(
  self : Parser,
  name : String,
) -> T raise @errors.PeleError {
  self.fail(
    "Expecting token of type --> \{name} <-- but found --> '\{self.image(self.p)}' <--",
  )
}

///|
fn Parser::expect(self : Parser, kind : Int32) -> Int32 raise @errors.PeleError {
  if self.kind(self.p) != kind {
    self.mismatch(token_names[kind])
  }
  self.p += 1
  self.p - 1
}

///|
/// Chevrotain lists every token sequence that would have been accepted.
fn[T] Parser::no_alternative(
  self : Parser,
  expected : String,
) -> T raise @errors.PeleError {
  let list = []
  for i, sequence in expected.split("|").to_array() {
    list.push("  \{i + 1}. [\{sequence}]")
  }
  self.fail(
    "Expecting: one of these possible Token sequences:\n\{list.join("\n")}\nbut found: '\{self.image(self.p)}'",
  )
}

///|
fn is_word_token(kind : Int32) -> Bool {
  kind >= USECASE && kind <= IDENTIFIER
}

///|
fn is_label_text(kind : Int32) -> Bool {
  kind >= USECASE && kind <= LABEL_SYMBOL
}

///|
fn Parser::line_end(self : Parser) -> Unit raise @errors.PeleError {
  let kind = self.kind(self.p)
  if kind == NEWLINE {
    self.p += 1
  } else if kind != EOF {
    self.no_alternative("NEWLINE|EOF")
  }
}

///|
/// The text of a name or string token, without its quotes.
fn Parser::content(self : Parser, k : Int32) -> Span {
  let kind = self.kind(k)
  let trim = if kind == MARKDOWN_STRING {
    2
  } else if kind == PLAIN_STRING {
    1
  } else {
    0
  }
  (self.starts[k] + trim, self.ends[k] - trim)
}

///|
fn Parser::token_label(self : Parser, k : Int32) -> DraftLabel {
  let (from, to) = self.content(k)
  {
    text: @util.slice(self.src, from, end=to),
    label_type: if self.kind(k) == MARKDOWN_STRING {
      "markdown"
    } else {
      "text"
    },
  }
}

///|
/// The id Mermaid makes from a label: every character but a letter, digit or `_` becomes `_`.
fn generated_id(label : String) -> String {
  let out = StringBuilder()
  for i in 0..<label.length() {
    let c = @util.code_at(label, i)
    if @util.is_word(c) {
      out.write_char(c.unsafe_to_char())
    } else {
      out.write_char('_')
    }
  }
  out.to_string()
}

///|
/// An unquoted label runs to the next delimiter and is taken from the source as written.
fn Parser::label(self : Parser) -> DraftLabel raise @errors.PeleError {
  let kind = self.kind(self.p)
  if kind == PLAIN_STRING || kind == MARKDOWN_STRING {
    self.p += 1
    return self.token_label(self.p - 1)
  }
  if !is_label_text(kind) {
    self.no_alternative(LABELS)
  }
  let first = self.p
  while is_label_text(self.kind(self.p)) {
    self.p += 1
  }
  let from = self.starts[first]
  let to = self.ends[self.p - 1]
  { text: @util.slice(self.src, from, end=to), label_type: "text", }
}

///|
fn is_key(kind : Int32) -> Bool {
  kind == IDENTIFIER || kind == PLAIN_STRING
}

///|
fn Parser::property(self : Parser) -> DraftProperty raise @errors.PeleError {
  let key = self.p
  if !is_key(self.kind(self.p)) {
    self.no_alternative("IDENTIFIER|PLAIN_STRING")
  }
  self.p += 1
  self.expect(COLON) |> ignore
  let value = self.p
  let kind = self.kind(value)
  if !is_key(kind) && kind != TRUE && kind != FALSE {
    self.no_alternative("IDENTIFIER|PLAIN_STRING|TRUE|FALSE")
  }
  self.p += 1
  let key_span = self.content(key)
  let (from, to) = self.content(value)
  {
    key: @util.slice(self.src, key_span.0, end=key_span.1),
    value: if kind == TRUE {
      Flag(true)
    } else if kind == FALSE {
      Flag(false)
    } else {
      Text(@util.slice(self.src, from, end=to))
    },
    key_span,
  }
}

///|
/// Whether another property follows.
/// A comma or line breaks before the closing brace do not count, but Chevrotain looks only three tokens ahead, so a comma and two line breaks, or three line breaks, are taken for a separator and the brace after them is then an error.
fn Parser::separator_ahead(self : Parser) -> Bool {
  let a = self.kind(self.p)
  let b = self.kind(self.p + 1)
  let c = self.kind(self.p + 2)
  if a == COMMA {
    return is_key(b) || (b == NEWLINE && (c == NEWLINE || is_key(c)))
  }
  if a != NEWLINE {
    return false
  }
  b == COMMA ||
  is_key(b) ||
  (b == NEWLINE && (c == NEWLINE || c == COMMA || is_key(c)))
}

///|
fn Parser::skip_newlines(self : Parser) -> Unit {
  while self.kind(self.p) == NEWLINE {
    self.p += 1
  }
}

///|
fn Parser::metadata(
  self : Parser,
) -> Array[DraftProperty] raise @errors.PeleError {
  self.expect(METADATA_START) |> ignore
  let properties = []
  self.skip_newlines()
  if is_key(self.kind(self.p)) {
    properties.push(self.property())
    while self.separator_ahead() {
      if self.kind(self.p) == COMMA {
        self.p += 1
      } else {
        self.skip_newlines()
        if self.kind(self.p) == COMMA {
          self.p += 1
        }
      }
      self.skip_newlines()
      properties.push(self.property())
    }
    if self.kind(self.p) == COMMA {
      self.p += 1
    }
    self.skip_newlines()
  }
  self.expect(RBRACE) |> ignore
  properties
}

///|
fn Parser::class_suffix(
  self : Parser,
  classes : Array[String],
) -> Unit raise @errors.PeleError {
  while true {
    self.p += 1
    let id = self.expect(IDENTIFIER)
    classes.push(self.image(id))
    if self.kind(self.p) != COMMA {
      break
    }
  }
}

///|
/// An id with an optional label in parentheses or brackets, or a string that stands for both.
fn Parser::name(self : Parser, brackets : Bool) -> Item raise @errors.PeleError {
  let k = self.p
  let kind = self.kind(k)
  let span = self.content(k)
  if kind == IDENTIFIER {
    self.p += 1
    let open = self.kind(self.p)
    let mut shape = None
    let label = if open == LPAREN || (brackets && open == LBRACKET) {
      self.p += 1
      let label = self.label()
      self.expect(if open == LPAREN { RPAREN } else { RBRACKET }) |> ignore
      shape = Some(if open == LPAREN { "ellipse" } else { "rect" })
      label
    } else {
      self.token_label(k)
    }
    {
      id: self.image(k),
      label,
      span,
      generated: false,
      shape,
      metadata: None,
      stereotype: None,
      classes: [],
      explicit: false,
    }
  } else if kind == PLAIN_STRING || kind == MARKDOWN_STRING {
    self.p += 1
    let label = self.token_label(k)
    {
      id: generated_id(label.text),
      label,
      span,
      generated: true,
      shape: None,
      metadata: None,
      stereotype: None,
      classes: [],
      explicit: false,
    }
  } else {
    self.no_alternative(NAMES)
  }
}

///|
fn Parser::element(self : Parser, actor : Bool) -> Item raise @errors.PeleError {
  let item = self.name(!actor)
  if actor {
    item.shape = None
  }
  if self.kind(self.p) == METADATA_START {
    item.metadata = Some(self.metadata())
  }
  if self.kind(self.p) == STEREOTYPE_START {
    self.p += 1
    let text = self.expect(STEREOTYPE_TEXT)
    self.expect(STEREOTYPE_END) |> ignore
    item.stereotype = Some(@util.trim(self.image(text)))
  }
  if self.kind(self.p) == CLASS_SEPARATOR {
    self.class_suffix(item.classes)
  }
  item.explicit = item.shape is Some(_) ||
    item.metadata is Some(_) ||
    item.stereotype is Some(_)
  item
}

///|
fn Parser::draft(self : Parser, item : Item, kind : String) -> DraftElement {
  {
    id: item.id,
    kind,
    label: item.label,
    span: item.span,
    generated: item.generated,
    parent: self.parent,
    shape: item.shape,
    metadata: item.metadata,
    stereotype: item.stereotype,
    classes: item.classes,
  }
}

///|
fn endpoint(item : Item, declares : Bool) -> DraftEndpoint {
  {
    id: item.id,
    label: item.label,
    span: item.span,
    generated: item.generated,
    declares,
    classed: item.classes.length() > 0,
  }
}

///|
/// Whether a label and then one of the operators that can close it come next.
fn Parser::labeled_right(self : Parser, closers : Int32) -> Bool {
  let first = self.kind(self.p)
  if first < USECASE || first > MARKDOWN_STRING {
    return false
  }
  let mut k = self.p + 1
  while true {
    let kind = self.kind(k)
    if kind == MARKERLESS_SOLID || (flags[kind] & closers) != 0 {
      return true
    }
    if kind < USECASE || kind > MARKDOWN_STRING {
      return false
    }
    k += 1
  }
  false
}

///|
/// Each dash beyond the second asks for one more rank between the two ends.
fn Parser::minimum_length(self : Parser, k : Int32) -> Int32 {
  let dashes = self.ends[k] -
    self.starts[k] -
    (if self.kind(k) == MARKERLESS_SOLID { 0 } else { 1 })
  if dashes - 1 > 1 {
    dashes - 1
  } else {
    1
  }
}

///|
fn Parser::relation_tail(self : Parser) -> Tail raise @errors.PeleError {
  let first = self.p
  let mut explicit_id = None
  let mut explicit_id_span = None
  if self.kind(self.p) == IDENTIFIER && self.kind(self.p + 1) == AT {
    explicit_id = Some(self.image(self.p))
    explicit_id_span = Some(self.span(self.p))
    self.p += 2
  }
  let k = self.p
  let kind = self.kind(k)
  self.p += 1
  let mut rel_type = "association"
  let mut arrow_type = SOLID_ARROW
  let mut minlen = 1
  let mut label = None
  if kind == DEPENDENCY_ARROW {
    self.expect(COLON) |> ignore
    let which = self.kind(self.p)
    if which != INCLUDE && which != EXTEND {
      self.no_alternative("INCLUDE|EXTEND")
    }
    rel_type = if which == INCLUDE { "include" } else { "extend" }
    label = Some({ text: rel_type, label_type: "text", })
    self.p += 1
  } else if kind == GENERALIZATION {
    rel_type = "generalization"
  } else if kind == FORWARD_SOLID {
    minlen = self.minimum_length(k)
  } else if kind == BACKWARD_SOLID {
    arrow_type = BACK_ARROW
    // Only the shortest operator can open a label: `A <-- label -- B`.
    if self.ends[k] - self.starts[k] == 3 && self.labeled_right(0) {
      label = Some(self.label())
      minlen = self.minimum_length(self.expect(MARKERLESS_SOLID))
    } else {
      minlen = self.minimum_length(k)
    }
  } else if kind == MARKERLESS_SOLID {
    arrow_type = LINE_SOLID
    if self.ends[k] - self.starts[k] == 2 && self.labeled_right(CLOSES_LABEL) {
      label = Some(self.label())
      let close = self.kind(self.p)
      if close == FORWARD_SOLID {
        arrow_type = SOLID_ARROW
      } else if close == FORWARD_CIRCLE {
        arrow_type = CIRCLE_ARROW
      } else if close == FORWARD_CROSS {
        arrow_type = CROSS_ARROW
      } else if close != MARKERLESS_SOLID {
        self.no_alternative(
          "FORWARD_SOLID|MARKERLESS_SOLID|FORWARD_CIRCLE|FORWARD_CROSS",
        )
      }
      if arrow_type == SOLID_ARROW || arrow_type == LINE_SOLID {
        minlen = self.minimum_length(self.p)
      }
      self.p += 1
    } else {
      minlen = self.minimum_length(k)
    }
  } else if kind == FORWARD_CIRCLE {
    arrow_type = CIRCLE_ARROW
  } else if kind == FORWARD_CROSS {
    arrow_type = CROSS_ARROW
  } else if kind == BACKWARD_CIRCLE || kind == BACKWARD_CROSS {
    arrow_type = if kind == BACKWARD_CIRCLE {
      CIRCLE_ARROW_REVERSED
    } else {
      CROSS_ARROW_REVERSED
    }
    if self.labeled_right(0) {
      label = Some(self.label())
      self.expect(MARKERLESS_SOLID) |> ignore
    }
  } else {
    self.p -= 1
    self.no_alternative(ARROWS)
  }
  let target = self.element(false)
  {
    explicit_id,
    explicit_id_span,
    rel_type,
    arrow_type,
    label,
    minlen,
    target,
    span: (self.starts[first], self.ends[self.p - 1]),
  }
}

///|
fn Parser::relationship(
  self : Parser,
  source : Item,
  declaration : Bool,
  tail : Tail,
) -> Unit {
  let target = tail.target
  if target.explicit {
    self.drafts.elements.push(self.draft(target, "usecase"))
  }
  self.drafts.relationships.push({
    source: endpoint(source, declaration),
    target: endpoint(target, target.explicit),
    span: tail.span,
    id: tail.explicit_id,
    id_span: tail.explicit_id_span,
    rel_type: tail.rel_type,
    arrow_type: tail.arrow_type,
    label: tail.label,
    minlen: tail.minlen,
  })
}

///|
/// `actor A, B` declares several actors; at the top level `actor A --> B` declares one and relates it.
fn Parser::actors(self : Parser, top : Bool) -> Unit raise @errors.PeleError {
  self.p += 1
  let items = [self.element(true)]
  let mut tail = None
  if self.kind(self.p) == COMMA {
    while self.kind(self.p) == COMMA {
      self.p += 1
      items.push(self.element(true))
    }
  } else if top && (flags[self.kind(self.p)] & RELATION) != 0 {
    tail = Some(self.relation_tail())
  }
  self.line_end()
  for item in items {
    self.drafts.elements.push(self.draft(item, "actor"))
  }
  if tail is Some(tail) {
    self.relationship(items[0], true, tail)
  }
}

///|
fn Parser::entity(self : Parser, top : Bool) -> Unit raise @errors.PeleError {
  let source = self.element(false)
  let tail = if top && (flags[self.kind(self.p)] & RELATION) != 0 {
    Some(self.relation_tail())
  } else {
    None
  }
  self.line_end()
  if tail is None {
    source.explicit = true
    if source.shape is None {
      source.shape = Some("ellipse")
    }
  }
  if source.explicit {
    self.drafts.elements.push(self.draft(source, "usecase"))
  }
  if tail is Some(tail) {
    self.relationship(source, source.explicit, tail)
  }
}

///|
fn Parser::boundary(self : Parser) -> Unit raise @errors.PeleError {
  self.p += 1
  let named = self.name(true)
  let group = {
    id: named.id,
    label: named.label,
    span: named.span,
    generated: named.generated,
    classes: named.classes,
  }
  let inline = if self.kind(self.p) == METADATA_START {
    Some(self.metadata())
  } else {
    None
  }
  if self.kind(self.p) == CLASS_SEPARATOR {
    self.class_suffix(named.classes)
  }
  self.line_end()
  self.drafts.boundaries.push(group)
  self.parent = Some(group)
  while (flags[self.kind(self.p)] & BOUNDARY_LINE) != 0 {
    self.line(false)
  }
  self.parent = None
  self.expect(END) |> ignore
  self.line_end()
  if inline is Some(properties) {
    self.drafts.metadata.push({
      target: group.id,
      span: group.span,
      properties,
    })
  }
}

///|
fn Parser::style(self : Parser) -> String raise @errors.PeleError {
  let first = self.p
  let kind = self.kind(self.p)
  if is_word_token(kind) || kind == CSS_IDENTIFIER {
    self.p += 1
  } else if kind == MARKERLESS_SOLID {
    self.p += 1
    if !is_word_token(self.kind(self.p)) {
      self.mismatch("WORD")
    }
    self.p += 1
  } else {
    self.no_alternative("WORD|CSS_IDENTIFIER|MARKERLESS_SOLID")
  }
  self.expect(COLON) |> ignore
  if (flags[self.kind(self.p)] & STYLE_PART) == 0 {
    self.fail(
      "Expecting: expecting at least one iteration which starts with one of these possible Token sequences::\n  <[\{STYLE_PARTS.replace_all(old="|", new="] ,[")}]>\nbut found: '\{self.image(self.p)}'",
    )
  }
  while (flags[self.kind(self.p)] & STYLE_PART) != 0 {
    self.p += 1
  }
  // The value is taken from the source, so the spaces inside `1px solid red` survive.
  @util.slice(self.src, self.starts[first], end=self.ends[self.p - 1]).replace_all(
    old="\\,",
    new=",",
  )
}

///|
fn Parser::styles(self : Parser) -> Array[String] raise @errors.PeleError {
  let out = [self.style()]
  while self.kind(self.p) == COMMA {
    self.p += 1
    out.push(self.style())
  }
  out
}

///|
fn Parser::identifiers(self : Parser) -> Array[Int32] raise @errors.PeleError {
  let out = [self.expect(IDENTIFIER)]
  while self.kind(self.p) == COMMA {
    self.p += 1
    out.push(self.expect(IDENTIFIER))
  }
  out
}

///|
/// The text after the first `:` of an accessibility line, or inside the braces of a block.
fn accessible_text(text : String, block : Bool) -> String {
  if block {
    @util.trim(
      @util.slice(
        text,
        @util.index_of(text, "{") + 1,
        end=@util.last_index_of(text, "}"),
      ),
    )
  } else {
    @util.trim(@util.slice(text, @util.index_of(text, ":") + 1))
  }
}

///|
fn Parser::top_statement(self : Parser) -> Unit raise @errors.PeleError {
  let k = self.p
  let kind = self.kind(k)
  if kind == ACC_TITLE_LINE || kind == ACC_DESCR_LINE || kind == ACC_DESCR_BLOCK {
    self.p += 1
    let text = accessible_text(self.image(k), kind == ACC_DESCR_BLOCK)
    if kind == ACC_TITLE_LINE {
      self.drafts.acc_title = text
    } else {
      self.drafts.acc_description = text
    }
  } else if kind == DIRECTION {
    self.p += 1
    let value = self.kind(self.p)
    if value < TD || value > RL {
      self.no_alternative("TD|TB|BT|LR|RL")
    }
    self.drafts.direction = Some(
      if value == TD {
        "TB"
      } else {
        self.image(self.p)
      },
    )
    self.p += 1
  } else if kind == ACTOR {
    return self.actors(true)
  } else if kind == SYSTEM_BOUNDARY {
    return self.boundary()
  } else if kind == NOTE {
    self.p += 1
    self.expect(FOR) |> ignore
    let target = self.expect(IDENTIFIER)
    let label = self.label()
    self.drafts.notes.push({
      target: self.image(target),
      span: self.span(target),
      label,
    })
  } else if kind == JSON_DECLARATION_START {
    self.p += 1
    let literal = self.expect(JSON_OBJECT_LITERAL)
    let classes = []
    if self.kind(self.p) == CLASS_SEPARATOR {
      self.class_suffix(classes)
    }
    let mut from = self.starts[k] + 4
    while @util.is_blank(@util.code_at(self.src, from)) {
      from += 1
    }
    let mut to = from
    while @util.is_word(@util.code_at(self.src, to)) {
      to += 1
    }
    let json = {
      id: @util.slice(self.src, from, end=to),
      value: Map([]),
      span: (from, to),
      classes,
    }
    self.drafts.jsons.push(json)
    self.pending_json.push((json, literal))
  } else if kind == CLASS_DEF {
    self.p += 1
    let ids = self.identifiers().map(id => self.image(id))
    self.drafts.class_defs.push({ ids, styles: self.styles(), })
  } else if kind == CLASS {
    self.p += 1
    let targets = self.identifiers().map(id => (self.image(id), self.span(id)))
    let classes = self.identifiers().map(id => self.image(id))
    self.drafts.classes.push({ targets, classes, })
  } else if kind == STYLE {
    self.p += 1
    let target = self.expect(IDENTIFIER)
    self.drafts.styles.push({
      target: self.image(target),
      span: self.span(target),
      styles: self.styles(),
    })
  } else {
    let next = self.kind(self.p + 1)
    if next == METADATA_START {
      if (flags[self.kind(self.p + 2)] & METADATA_FIRST) == 0 {
        self.no_alternative(statement_sequences)
      }
      self.p += 1
      let span = self.content(k)
      let id = if kind == IDENTIFIER {
        self.image(k)
      } else {
        generated_id(@util.slice(self.src, span.0, end=span.1))
      }
      let properties = self.metadata()
      self.drafts.metadata.push({ target: id, span, properties, })
    } else {
      let follows = (flags[next] & FOLLOWS_NAME) != 0 ||
        (kind == IDENTIFIER && (next == LPAREN || next == LBRACKET))
      if !follows ||
        (kind == IDENTIFIER && forbidden.contains(self.image(k).to_lower())) {
        self.no_alternative(statement_sequences)
      }
      return self.entity(true)
    }
  }
  self.line_end()
}

///|
fn Parser::line(self : Parser, top : Bool) -> Unit raise @errors.PeleError {
  let kind = self.kind(self.p)
  if kind == NEWLINE {
    self.p += 1
  } else if kind == COMMENT {
    self.p += 1
    self.line_end()
  } else if top {
    self.top_statement()
  } else if kind == ACTOR {
    self.actors(false)
  } else {
    self.entity(false)
  }
}

///|
/// Parses a use case diagram into its model, with Mermaid's messages for what it rejects.
pub fn parse_usecase(
  source : String,
  title? : String,
) -> UsecaseModel raise @errors.PeleError {
  let tokens = tokenize(source)
  let parser = {
    src: source,
    types: tokens.types,
    starts: tokens.starts,
    ends: tokens.ends,
    p: 0,
    drafts: empty_drafts(),
    parent: None,
    pending_json: [],
  }
  parser.expect(USECASE) |> ignore
  parser.line_end()
  while (flags[parser.kind(parser.p)] & LINE) != 0 {
    parser.line(true)
  }
  if parser.kind(parser.p) != EOF {
    parser.fail(
      "Redundant input, expecting EOF but found: \{parser.image(parser.p)}",
    )
  }
  // The whole text has to be well formed before the JSON in it is looked at, as in Mermaid.
  for pending in parser.pending_json {
    let (json, literal) = pending
    json.value = parse_ordered_json(parser.image(literal), () => {
      line_column(source, parser.starts[literal])
    })
  }
  resolve_usecase(source, parser.drafts, title)
}
