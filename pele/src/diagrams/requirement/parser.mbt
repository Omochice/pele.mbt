///|
/// What the keyword tokens stand for, from `T_REQUIREMENT` to `T_TRACES` in token order.
let keyword_values : Array[String] = [
  "Requirement", "Functional Requirement", "Interface Requirement", "Performance Requirement",
  "Physical Requirement", "Design Constraint", "Low", "Medium", "High", "Analysis",
  "Demonstration", "Inspection", "Test", "", "contains", "copies", "derives", "satisfies",
  "verifies", "refines", "traces",
]

///|
fn is_style_part(t : Int32) -> Bool {
  t == T_ALPHA ||
  t == T_COLON ||
  t == T_BRKT ||
  t == T_MINUS ||
  t == T_SEMICOLON
}

///|
priv struct Parser {
  src : String
  tokens : Tokens
  db : RequirementDb
  mut i : Int32
  fields : Array[Int32]
  values : Array[String]
}

///|
fn Parser::peek(self : Parser) -> Int32 {
  self.tokens.types[self.i]
}

///|
fn Parser::take(self : Parser) -> String {
  let text = self.tokens.texts[self.i]
  self.i += 1
  text
}

///|
/// Fails with Jison's wording, naming the token types `from` to `to` and then `others` as expected.
fn[A] Parser::fail(
  self : Parser,
  from : Int32,
  to? : Int32,
  others~ : Array[Int32] = [],
) -> A raise @errors.PeleError {
  let to = to.unwrap_or(from)
  let t = self.peek()
  let offset = self.tokens.starts[self.i]
  if t == T_ERROR {
    raise @errors.syntax_error(
      "requirement",
      self.src,
      offset,
      "",
      lexical=true,
    )
  }
  let expected = []
  for k in from..<=to {
    expected.push(k)
  }
  expected.append(others)
  let names = expected.map(k => "'\{token_names[k]}'").join(", ")
  raise @errors.syntax_error(
    "requirement",
    self.src,
    offset,
    "Expecting \{names}, got '\{token_names[t]}'",
  )
}

///|
fn Parser::expect(
  self : Parser,
  kind : Int32,
) -> String raise @errors.PeleError {
  if self.peek() != kind {
    self.fail(kind)
  }
  self.take()
}

///|
/// The value of the next token if it is a keyword in the given range of token types.
fn Parser::keyword(
  self : Parser,
  from : Int32,
  to : Int32,
) -> String raise @errors.PeleError {
  let t = self.peek()
  if t < from || t > to {
    self.fail(from, to~)
  }
  self.i += 1
  keyword_values[t - T_REQUIREMENT]
}

///|
fn Parser::string(self : Parser) -> String raise @errors.PeleError {
  let t = self.peek()
  if t != T_UNQSTRING && t != T_QSTRING {
    self.fail(T_QSTRING, to=T_UNQSTRING)
  }
  self.take()
}

///|
fn Parser::directive(self : Parser) -> Bool raise @errors.PeleError {
  let t = self.peek()
  if t == T_ACC_TITLE {
    self.i += 1
    self.db.set_acc_title(@util.trim(self.expect(T_ACC_TITLE_VALUE)))
  } else if t == T_ACC_DESCR {
    self.i += 1
    self.db.set_acc_description(@util.trim(self.expect(T_ACC_DESCR_VALUE)))
  } else if t == T_ACC_DESCR_MULTILINE_VALUE {
    self.db.set_acc_description(@util.trim(self.take()))
  } else {
    return false
  }
  true
}

///|
fn Parser::id_list(self : Parser) -> Array[String] raise @errors.PeleError {
  let list = []
  while true {
    let t = self.peek()
    if t != T_ALPHA && t != T_UNQSTRING && t != T_QSTRING {
      self.fail(T_QSTRING, to=T_UNQSTRING, others=[T_ALPHA])
    }
    list.push(self.take())
    if self.peek() != T_COMMA {
      break
    }
    self.i += 1
  }
  list
}

///|
fn Parser::styles(self : Parser) -> Array[String] raise @errors.PeleError {
  let styles = []
  while true {
    if !is_style_part(self.peek()) {
      self.fail(T_ALPHA, to=T_SEMICOLON, others=[T_MINUS, T_BRKT])
    }
    let style = StringBuilder()
    style.write_string(self.take())
    while is_style_part(self.peek()) {
      style.write_string(self.take())
    }
    styles.push(style.to_string())
    if self.peek() != T_COMMA {
      break
    }
    self.i += 1
  }
  styles
}

///|
fn Parser::class_list(self : Parser) -> Array[String]? raise @errors.PeleError {
  let mut classes = None
  let t = self.peek()
  if t == T_STYLE_SEPARATOR {
    self.i += 1
    classes = Some(self.id_list())
    ignore(self.expect(T_STRUCT_START))
  } else if t == T_STRUCT_START {
    self.i += 1
  } else {
    self.fail(T_STRUCT_START, others=[T_STYLE_SEPARATOR])
  }
  ignore(self.expect(T_NEWLINE))
  classes
}

///|
/// Reads a body up to its closing brace.
/// The grammar is right recursive, so Mermaid applies the fields last to first and the first of
/// two repeated fields wins.
fn Parser::body(
  self : Parser,
  requirement : Bool,
) -> Unit raise @errors.PeleError {
  self.fields.clear()
  self.values.clear()
  while true {
    let t = self.peek()
    if t == T_STRUCT_STOP {
      self.i += 1
      break
    }
    if t == T_NEWLINE {
      self.i += 1
      continue
    }
    if requirement {
      if t < T_ID || t > T_VERIFYMTHD {
        self.fail(T_ID, to=T_VERIFYMTHD, others=[T_NEWLINE, T_STRUCT_STOP])
      }
    } else if t != T_TYPE && t != T_DOCREF {
      self.fail(T_TYPE, to=T_DOCREF, others=[T_NEWLINE, T_STRUCT_STOP])
    }
    self.i += 1
    ignore(self.expect(T_COLONSEP))
    let value = if t == T_RISK {
      self.keyword(T_LOW_RISK, T_HIGH_RISK)
    } else if t == T_VERIFYMTHD {
      self.keyword(T_VERIFY_ANALYSIS, T_VERIFY_TEST)
    } else {
      self.string()
    }
    self.values.push(value)
    self.fields.push(t)
    ignore(self.expect(T_NEWLINE))
  }
  for k = self.fields.length() - 1; k >= 0; k = k - 1 {
    let value = self.values[k]
    match self.fields[k] {
      T_ID => self.db.set_new_req_id(value)
      T_TEXT => self.db.set_new_req_text(value)
      T_RISK => self.db.set_new_req_risk(value)
      T_VERIFYMTHD => self.db.set_new_req_verify_method(value)
      T_TYPE => self.db.set_new_element_type(value)
      _ => self.db.set_new_element_doc_ref(value)
    }
  }
}

///|
fn Parser::statement(self : Parser) -> Bool raise @errors.PeleError {
  let t = self.peek()
  if t == T_EOF {
    return false
  }
  if t == T_NEWLINE {
    self.i += 1
  } else if self.directive() {
    ()
  } else if t >= T_DIRECTION_TB && t <= T_DIRECTION_LR {
    self.i += 1
    self.db.set_direction(
      if t == T_DIRECTION_TB {
        "TB"
      } else if t == T_DIRECTION_BT {
        "BT"
      } else if t == T_DIRECTION_RL {
        "RL"
      } else {
        "LR"
      },
    )
  } else if t >= T_REQUIREMENT && t <= T_DESIGN_CONSTRAINT {
    let kind = self.keyword(T_REQUIREMENT, T_DESIGN_CONSTRAINT)
    let name = self.string()
    let classes = self.class_list()
    self.body(true)
    self.db.add_requirement(name, kind)
    if classes is Some(classes) {
      self.db.set_class([name], classes)
    }
  } else if t == T_ELEMENT {
    self.i += 1
    let name = self.string()
    let classes = self.class_list()
    self.body(false)
    self.db.add_element(name)
    if classes is Some(classes) {
      self.db.set_class([name], classes)
    }
  } else if t == T_STYLE {
    self.i += 1
    let ids = self.id_list()
    self.db.set_css_style(ids, self.styles())
  } else if t == T_CLASSDEF {
    self.i += 1
    let ids = self.id_list()
    self.db.define_class(ids, self.styles())
  } else if t == T_CLASS {
    self.i += 1
    let ids = self.id_list()
    self.db.set_class(ids, self.id_list())
  } else if t == T_UNQSTRING || t == T_QSTRING {
    let id = self.take()
    let next = self.peek()
    if next == T_STYLE_SEPARATOR {
      self.i += 1
      self.db.set_class([id], self.id_list())
    } else if next == T_END_ARROW_L || next == T_LINE {
      self.i += 1
      let relationship = self.keyword(T_CONTAINS, T_TRACES)
      ignore(self.expect(if next == T_LINE { T_END_ARROW_R } else { T_LINE }))
      let other = self.string()
      if next == T_LINE {
        self.db.add_relationship(relationship, id, other)
      } else {
        self.db.add_relationship(relationship, other, id)
      }
    } else {
      self.fail(T_STYLE_SEPARATOR, others=[T_END_ARROW_L, T_LINE])
    }
  } else {
    self.fail(T_NEWLINE, to=T_EOF, others=[
      T_ACC_TITLE,
      T_ACC_DESCR,
      T_ACC_DESCR_MULTILINE_VALUE,
      T_DIRECTION_TB,
      T_DIRECTION_BT,
      T_DIRECTION_RL,
      T_DIRECTION_LR,
      T_REQUIREMENT,
      T_FUNCTIONAL_REQUIREMENT,
      T_INTERFACE_REQUIREMENT,
      T_PERFORMANCE_REQUIREMENT,
      T_PHYSICAL_REQUIREMENT,
      T_DESIGN_CONSTRAINT,
      T_ELEMENT,
      T_CLASSDEF,
      T_CLASS,
      T_STYLE,
      T_UNQSTRING,
      T_QSTRING,
    ])
  }
  true
}

///|
/// Reads a requirement diagram into `db`, as Mermaid's requirement grammar does.
/// Raises a syntax error where the grammar rejects the text, and a limit error from the model.
pub fn parse_requirement(
  src : String,
  db : RequirementDb,
) -> Unit raise @errors.PeleError {
  let parser = { src, tokens: tokenize(src), db, i: 0, fields: [], values: [], }
  while parser.directive() {
    if parser.peek() == T_NEWLINE {
      parser.i += 1
    }
  }
  if parser.peek() != T_RD {
    parser.fail(T_RD, others=[
      T_ACC_TITLE,
      T_ACC_DESCR,
      T_ACC_DESCR_MULTILINE_VALUE,
    ])
  }
  parser.i += 1
  ignore(parser.expect(T_NEWLINE))
  while parser.statement() {

  }
}
