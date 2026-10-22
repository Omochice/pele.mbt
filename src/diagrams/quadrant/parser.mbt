///|
fn flags(tokens : Array[Int32]) -> FixedArray[Bool] {
  let out = FixedArray::make(EOF + 1, false)
  for token in tokens {
    out[token] = true
  }
  out
}

///|
/// The tokens that make up the text of a label, apart from strings, spaces and dashes.
let word_tokens : FixedArray[Bool] = flags([
  PUNCTUATION,
  AMP,
  NUM,
  ALPHA,
  COMMA,
  PLUS,
  EQUALS,
  MULT,
  DOT,
  BRKT,
  UNDERSCORE,
  UNICODE_TEXT,
])

///|
let id_tokens : FixedArray[Bool] = flags([
  ALPHA,
  NUM,
  MINUS,
  COMMA,
  COLON,
  AMP,
  BRKT,
  MULT,
  UNICODE_TEXT,
])

///|
let style_tokens : FixedArray[Bool] = flags([
  ALPHA,
  NUM,
  COLON,
  SPACE,
  BRKT,
  MINUS,
])

///|
let end_of_statement : FixedArray[Bool] = flags([NEWLINE, SEMI, EOF])

///|
const TEXT_TOKENS : String = "'STR', 'MD_STR', 'ALPHA', 'NUM', 'UNICODE_TEXT', 'PUNCTUATION'"

///|
priv struct Parser {
  src : String
  tokens : Tokens
  mut at : Int32
}

///|
fn Parser::kind(self : Parser) -> Int32 {
  self.tokens.types[self.at]
}

///|
fn Parser::error(self : Parser, expected : String) -> @errors.PeleError {
  let kind = self.kind()
  let start = self.tokens.starts[self.at]
  if kind == ERROR {
    @errors.syntax_error("quadrantChart", self.src, start, "", lexical=true)
  } else {
    @errors.syntax_error(
      "quadrantChart",
      self.src,
      start,
      "Expecting \{expected}, got '\{token_names[kind]}'",
    )
  }
}

///|
/// Takes the text of the next token, which has to be a `kind`.
fn Parser::expect(
  self : Parser,
  kind : Int32,
) -> String raise @errors.PeleError {
  if self.kind() != kind {
    raise self.error("'\{token_names[kind]}'")
  }
  let text = self.tokens.texts[self.at]
  self.at += 1
  text
}

///|
fn is_text(kind : Int32) -> Bool {
  kind == STR || kind == MD_STR || word_tokens[kind]
}

///|
/// Reads a label: a string or a word, and anything made of words, spaces and dashes after it.
fn Parser::text(self : Parser) -> QuadrantText raise @errors.PeleError {
  let first = self.kind()
  if !is_text(first) {
    raise self.error(TEXT_TOKENS)
  }
  let text = StringBuilder()
  text.write_string(self.tokens.texts[self.at])
  self.at += 1
  while word_tokens[self.kind()] || self.kind() == SPACE || self.kind() == MINUS {
    text.write_string(self.tokens.texts[self.at])
    self.at += 1
  }
  { text: text.to_string(), markdown: first == MD_STR, }
}

///|
/// Reads styles separated by commas.
fn Parser::styles(self : Parser) -> Array[String] raise @errors.PeleError {
  let out = []
  while true {
    if !style_tokens[self.kind()] {
      raise self.error("'ALPHA', 'NUM', 'COLON', 'SPACE', 'BRKT', 'MINUS'")
    }
    let text = StringBuilder()
    text.write_string(self.tokens.texts[self.at])
    self.at += 1
    while style_tokens[self.kind()] {
      text.write_string(self.tokens.texts[self.at])
      self.at += 1
    }
    out.push(@util.trim(text.to_string()))
    if self.kind() != COMMA {
      break
    }
    self.at += 1
  }
  out
}

///|
fn Parser::axis(
  self : Parser,
  start : Int32,
  db : QuadrantDb,
) -> Unit raise @errors.PeleError {
  self.at += 1
  let from = self.text()
  let mut to = None
  let mut from_text = from.text
  if self.kind() == DELIMITER {
    self.at += 1
    if is_text(self.kind()) {
      to = Some(self.text())
    } else {
      from_text = from_text + " ⟶ "
    }
  }
  let from = { text: from_text, markdown: from.markdown, }
  if start == X_AXIS {
    db.set_x_axis_left_text(from)
    if to is Some(to) {
      db.set_x_axis_right_text(to)
    }
  } else {
    db.set_y_axis_bottom_text(from)
    if to is Some(to) {
      db.set_y_axis_top_text(to)
    }
  }
}

///|
fn Parser::statement(
  self : Parser,
  db : QuadrantDb,
) -> Unit raise @errors.PeleError {
  let kind = self.kind()
  match kind {
    CLASSDEF => {
      self.at += 1
      ignore(self.expect(SPACE))
      if !id_tokens[self.kind()] {
        raise self.error("'ALPHA', 'NUM', 'UNICODE_TEXT'")
      }
      let name = StringBuilder()
      name.write_string(self.tokens.texts[self.at])
      self.at += 1
      while id_tokens[self.kind()] {
        name.write_string(self.tokens.texts[self.at])
        self.at += 1
      }
      ignore(self.expect(SPACE))
      db.add_class(name.to_string(), self.styles())
    }
    X_AXIS | Y_AXIS => self.axis(kind, db)
    QUADRANT_1 | QUADRANT_2 | QUADRANT_3 | QUADRANT_4 => {
      self.at += 1
      db.set_quadrant_text(kind - QUADRANT_1 + 1, self.text())
    }
    TITLE => {
      self.at += 1
      db.set_diagram_title(@util.trim(self.expect(TITLE_VALUE)))
    }
    ACC_TITLE => {
      self.at += 1
      db.set_acc_title(@util.trim(self.expect(ACC_TITLE_VALUE)))
    }
    ACC_DESCR => {
      self.at += 1
      db.set_acc_description(@util.trim(self.expect(ACC_DESCR_VALUE)))
    }
    ACC_DESCR_MULTILINE_VALUE => {
      db.set_acc_description(@util.trim(self.tokens.texts[self.at]))
      self.at += 1
    }
    _ =>
      if is_text(kind) {
        let label = self.text()
        let class_name = if self.kind() == CLASS_NAME {
          let name = self.tokens.texts[self.at]
          self.at += 1
          name
        } else {
          ""
        }
        ignore(self.expect(POINT_START))
        let x = self.expect(POINT_X)
        let y = self.expect(POINT_Y)
        let styles = if style_tokens[self.kind()] { self.styles() } else { [] }
        db.add_point(label, class_name, x, y, styles)
      }
  }
}

///|
/// Reads a quadrant chart into `db`.
/// Raises a syntax `PeleError` with Mermaid's message on text its grammar does not accept, or what `db` raises for a style it rejects.
pub fn parse_quadrant(
  source : String,
  db : QuadrantDb,
) -> Unit raise @errors.PeleError {
  let parser = { src: source, tokens: tokenize(source), at: 0, }
  while end_of_statement[parser.kind()] || parser.kind() == SPACE {
    parser.at += 1
  }
  ignore(parser.expect(QUADRANT))
  while parser.kind() != END {
    while parser.kind() == SPACE {
      parser.at += 1
    }
    parser.statement(db)
    if !end_of_statement[parser.kind()] {
      raise parser.error("'NEWLINE', 'SEMI', 'EOF'")
    }
    parser.at += 1
  }
}
