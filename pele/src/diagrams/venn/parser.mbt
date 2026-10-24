///|
const STATEMENT = "'EOF', 'NEWLINE', 'TITLE', 'SET', 'UNION', 'TEXT', 'INDENT_TEXT', 'STYLE'"

///|
const VALUE = "'NUMERIC', 'IDENTIFIER', 'STRING', 'HEXCOLOR', 'RGBCOLOR', 'RGBACOLOR'"

///|
/// A token is read only when the grammar has to look at one to decide, because the lexer asks
/// the model whether an indented `text` continues a set, and the statements are what tell the
/// model so.
priv struct VennParser {
  src : String
  db : VennDb
  lexer : VennLexer
  mut kind : Int32
}

///|
fn VennParser::peek(self : VennParser) -> Int32 {
  if self.kind == -1 {
    self.kind = self.lexer.next()
  }
  self.kind
}

///|
fn[T] VennParser::fail(
  self : VennParser,
  expected : String,
) -> T raise @errors.PeleError {
  if self.peek() == T_ERROR {
    raise @errors.syntax_error(
      "venn",
      self.src,
      self.lexer.start,
      "",
      lexical=true,
    )
  }
  raise @errors.syntax_error(
    "venn",
    self.src,
    self.lexer.start,
    "Expecting \{expected}, got '\{token_names[self.kind]}'",
  )
}

///|
fn VennParser::take(self : VennParser) -> String {
  self.kind = -1
  self.lexer.text
}

///|
fn VennParser::expect(
  self : VennParser,
  wanted : Int32,
) -> String raise @errors.PeleError {
  if self.peek() != wanted {
    self.fail("'\{token_names[wanted]}'")
  }
  self.take()
}

///|
fn VennParser::identifier(self : VennParser) -> String raise @errors.PeleError {
  if self.peek() != T_IDENTIFIER && self.kind != T_STRING {
    self.fail("'IDENTIFIER', 'STRING'")
  }
  self.take()
}

///|
fn VennParser::identifiers(
  self : VennParser,
) -> Array[String] raise @errors.PeleError {
  let list = [self.identifier()]
  while self.peek() == T_COMMA {
    self.take() |> ignore
    list.push(self.identifier())
  }
  list
}

///|
/// What `parseFloat` makes of a NUMERIC token, which always starts with a sign or a digit or a point.
fn number_value(text : String) -> Double {
  let negative = @util.code_at(text, 0) == '-'.to_int()
  let unsigned = if negative || @util.code_at(text, 0) == '+'.to_int() {
    @util.slice(text, 1)
  } else {
    text
  }
  let digits = if @util.code_at(unsigned, 0) == '.'.to_int() {
    "0" + unsigned
  } else {
    unsigned
  }
  let value = @string.parse_double(digits) catch { _ => @double.not_a_number }
  if negative {
    -value
  } else {
    value
  }
}

///|
fn VennParser::subset(
  self : VennParser,
  ids : Array[String],
  union : Bool,
) -> Unit raise @errors.PeleError {
  let label = if self.peek() == T_BRACKET_LABEL {
    Some(self.take())
  } else {
    None
  }
  let mut size = None
  if self.peek() == T_COLON {
    self.take() |> ignore
    size = Some(number_value(self.expect(T_NUMERIC)))
  }
  if union {
    if ids.length() < 2 {
      raise @errors.pele_error(
        "union requires multiple identifiers",
        code=Semantic,
        kind="venn",
      )
    }
    self.db.validate_union_identifiers(ids)
  }
  self.db.add_subset_data(ids, label, size)
  self.db.indent = true
}

///|
/// The id of a text, and the label in brackets that an id which is not a number may carry.
fn VennParser::text(
  self : VennParser,
  sets : () -> Array[String] raise @errors.PeleError,
) -> Unit raise @errors.PeleError {
  let kind = self.peek()
  if kind != T_IDENTIFIER && kind != T_STRING && kind != T_NUMERIC {
    self.fail("'NUMERIC', 'IDENTIFIER', 'STRING'")
  }
  let id = self.take()
  let label = if kind != T_NUMERIC && self.peek() == T_BRACKET_LABEL {
    Some(self.take())
  } else {
    None
  }
  self.db.add_text_data(sets(), id, label)
}

///|
fn VennParser::style(self : VennParser) -> Unit raise @errors.PeleError {
  let ids = self.identifiers()
  let styles = []
  while true {
    let key = self.expect(T_IDENTIFIER)
    self.expect(T_COLON) |> ignore
    let value = if self.peek() == T_STRING {
      self.take()
    } else {
      let parts = []
      while self.peek() == T_IDENTIFIER ||
            (self.kind >= T_NUMERIC && self.kind <= T_RGBACOLOR) {
        parts.push(self.take())
      }
      if parts.is_empty() {
        self.fail(VALUE)
      }
      parts.join(" ")
    }
    styles.push((key, value))
    if self.peek() != T_COMMA {
      break
    }
    self.take() |> ignore
  }
  self.db.add_style_data(ids, styles)
}

///|
/// Reads a venn diagram, which is `venn-beta` followed by statements, into a model.
/// Raises a syntax `PeleError` with Mermaid's message on invalid text, and a semantic one for a
/// union of fewer than two sets or of a set that was not declared.
pub fn parse_venn(source : String) -> VennDb raise @errors.PeleError {
  let db = VennDb::new()
  let parser = { src: source, db, lexer: VennLexer::new(source, db), kind: -1, }
  while parser.peek() == T_NEWLINE {
    parser.take() |> ignore
  }
  parser.expect(T_VENN) |> ignore
  while true {
    let statement = parser.peek()
    if statement == T_EOF {
      break
    }
    if statement < T_NEWLINE || statement > T_STYLE || statement == T_VENN {
      parser.fail(STATEMENT)
    }
    parser.take() |> ignore
    if statement == T_TITLE {
      db.title = Some(@util.slice(parser.lexer.text, 6))
    } else if statement == T_SET {
      parser.subset([parser.identifier()], false)
    } else if statement == T_UNION {
      parser.subset(parser.identifiers(), true)
    } else if statement == T_TEXT {
      let ids = parser.identifiers()
      parser.text(() => ids)
    } else if statement == T_INDENT_TEXT {
      parser.text(() => {
        match db.current {
          Some(current) => current
          None =>
            raise @errors.pele_error(
              "text requires set",
              code=Semantic,
              kind="venn",
            )
        }
      })
    } else if statement == T_STYLE {
      parser.style()
    }
  }
  db
}
