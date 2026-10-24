///|
/// Mermaid's typeC4Shape for each shape keyword, indexed from PERSON.
let kinds : Array[String] = [
  "person", "external_person", "system", "system_db", "system_queue", "external_system",
  "external_system_db", "external_system_queue", "container", "container_db", "container_queue",
  "external_container", "external_container_db", "external_container_queue", "component",
  "component_db", "component_queue", "external_component", "external_component_db",
  "external_component_queue",
]

///|
let rel_types : Array[String] = [
  "rel", "birel", "rel_u", "rel_d", "rel_l", "rel_r", "rel_b", "rel",
]

///|
let node_types : Array[String] = ["node", "nodeL", "nodeR"]

///|
const HEADERS : String = "'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'C4_CONTEXT', 'C4_CONTAINER', 'C4_COMPONENT', 'C4_DYNAMIC', 'C4_DEPLOYMENT'"

///|
const ATTRIBUTES : String = "'STR', 'STR_KEY', 'ATTRIBUTE', 'ATTRIBUTE_EMPTY'"

///|
const STATEMENTS : String = "'title', 'accDescription', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'PERSON', 'REL'"

///|
/// A statement is required.
const P_ITEM : Int32 = 0

///|
/// Only a diagram statement may come next: the first one in a boundary, or one written straight after a title.
const P_DIAGRAM : Int32 = 1

///|
const P_ITEM_OR_END : Int32 = 2

///|
const P_AFTER_OTHER : Int32 = 3

///|
const P_AFTER_DIAGRAM : Int32 = 4

///|
fn is_other(t : Int32) -> Bool {
  t == TITLE ||
  t == ACC_DESCRIPTION ||
  t == ACC_TITLE ||
  t == ACC_DESCR ||
  t == ACC_DESCR_MULTILINE_VALUE
}

///|
fn is_diagram(t : Int32) -> Bool {
  t >= PERSON && t <= UPDATE_LAYOUT_CONFIG
}

///|
/// The reading position in a token stream.
priv struct Reader {
  src : String
  tokens : C4Tokens
  mut i : Int32
}

///|
fn Reader::kind(self : Reader) -> Int32 {
  self.tokens.types[self.i]
}

///|
fn Reader::text(self : Reader, at : Int32) -> String {
  @util.slice(self.src, self.tokens.starts[at], end=self.tokens.ends[at])
}

///|
fn[T] Reader::fail(
  self : Reader,
  expected : String,
) -> T raise @errors.PeleError {
  let t = self.kind()
  let at = self.tokens.starts[self.i]
  if t == ERROR {
    raise @errors.syntax_error("c4", self.src, at, "", lexical=true)
  }
  raise @errors.syntax_error(
    "c4",
    self.src,
    at,
    "Expecting \{expected}, got '\{token_names[t]}'",
  )
}

///|
fn Reader::expect(self : Reader, type_ : Int32) -> Unit raise @errors.PeleError {
  if self.kind() != type_ {
    self.fail("'\{token_names[type_]}'")
  }
  self.i += 1
}

///|
fn Reader::attributes(self : Reader) -> Array[C4Attr] raise @errors.PeleError {
  let attrs = []
  while true {
    let t = self.kind()
    if t == STR {
      attrs.push(Text(@util.trim(self.text(self.i))))
      self.i += 1
    } else if t == ATTRIBUTE_EMPTY {
      attrs.push(Text(""))
      self.i += 1
    } else if t == STR_KEY {
      self.i += 1
      if self.kind() != STR_VALUE {
        self.fail("'STR_VALUE'")
      }
      attrs.push(
        Named({
          key: @util.trim(self.text(self.i - 1)),
          value: @util.trim(self.text(self.i)),
        }),
      )
      self.i += 1
    } else {
      break
    }
  }
  if attrs.length() == 0 {
    self.fail(ATTRIBUTES)
  }
  attrs
}

///|
fn Reader::other(
  self : Reader,
  db : C4Db,
  t : Int32,
) -> Unit raise @errors.PeleError {
  if t == TITLE {
    db.set_title(@util.slice(self.text(self.i), 6))
    self.i += 1
  } else if t == ACC_DESCRIPTION {
    db.set_acc_description(@util.slice(self.text(self.i), 15))
    self.i += 1
  } else if t == ACC_DESCR_MULTILINE_VALUE {
    db.set_acc_description(@util.trim(self.text(self.i)))
    self.i += 1
  } else {
    self.i += 1
    if t == ACC_TITLE {
      if self.kind() != ACC_TITLE_VALUE {
        self.fail("'acc_title_value'")
      }
      // The grammar hands `accTitle:` to setTitle, so it becomes the visible title.
      db.set_title(@util.trim(self.text(self.i)))
    } else {
      if self.kind() != ACC_DESCR_VALUE {
        self.fail("'acc_descr_value'")
      }
      db.set_acc_description(@util.trim(self.text(self.i)))
    }
    self.i += 1
  }
}

///|
/// Reads one diagram statement into `db`; true when it opens a boundary.
fn Reader::diagram(
  self : Reader,
  db : C4Db,
  t : Int32,
) -> Bool raise @errors.PeleError {
  self.i += 1
  let attrs = self.attributes()
  if t <= SYSTEM_EXT_QUEUE {
    db.add_person_or_system(kinds[t - PERSON], attrs)
  } else if t <= CONTAINER_EXT_QUEUE {
    db.add_container(kinds[t - PERSON], attrs)
  } else if t <= COMPONENT_EXT_QUEUE {
    db.add_component(kinds[t - PERSON], attrs)
  } else if t <= NODE_R {
    // JavaScript's splice inserts at the end when the list is shorter than the index.
    let at = if attrs.length() < 2 { attrs.length() } else { 2 }
    if t == ENTERPRISE_BOUNDARY {
      attrs.insert(at, Text("ENTERPRISE"))
    } else if t == SYSTEM_BOUNDARY {
      attrs.insert(at, Text("SYSTEM"))
    } else if t == CONTAINER_BOUNDARY {
      attrs.insert(at, Text("CONTAINER"))
    }
    if t >= NODE {
      db.add_deployment_node(node_types[t - NODE], attrs)
    } else if t == CONTAINER_BOUNDARY {
      db.add_container_boundary(attrs)
    } else {
      db.add_person_or_system_boundary(attrs)
    }
    if self.kind() == LBRACE {
      self.i += 1
      self.expect(NEWLINE)
    } else if self.kind() == NEWLINE {
      self.i += 1
      self.expect(LBRACE)
      if self.kind() == NEWLINE {
        self.i += 1
      }
    } else {
      self.fail("'NEWLINE', 'LBRACE'")
    }
    return true
  } else if t <= REL_INDEX {
    // RelIndex takes a sequence number first, which Mermaid ignores.
    if t == REL_INDEX {
      attrs.remove(0) |> ignore
    }
    db.add_rel(rel_types[t - REL], attrs)
  } else if t == UPDATE_EL_STYLE {
    db.update_el_style(attrs)
  } else if t == UPDATE_REL_STYLE {
    db.update_rel_style(attrs)
  } else {
    db.update_layout_config(attrs)
  }
  false
}

///|
/// Reads a C4 diagram into `db` as the parser Jison generates from c4Diagram.jison does, raising its syntax errors.
/// It calls the model in the order the grammar's actions do; boundaries nest through a counter, not recursion.
pub fn parse_c4(src : String, db : C4Db) -> Unit raise @errors.PeleError {
  let reader : Reader = { src, tokens: tokenize(src), i: 0, }
  let header = reader.kind()
  if header < C4_CONTEXT || header > C4_DEPLOYMENT {
    reader.fail(HEADERS)
  }
  reader.i += 1
  reader.expect(NEWLINE)
  let mut depth = 0
  let mut state = P_ITEM
  while true {
    let t = reader.kind()
    if state == P_AFTER_OTHER || state == P_AFTER_DIAGRAM {
      if t == NEWLINE {
        reader.i += 1
        state = P_ITEM_OR_END
        continue
      }
      if state == P_AFTER_OTHER && is_diagram(t) {
        state = P_DIAGRAM
        continue
      }
    } else if is_diagram(t) {
      if reader.diagram(db, t) {
        depth += 1
        state = P_DIAGRAM
      } else {
        state = P_AFTER_DIAGRAM
      }
      continue
    } else if is_other(t) && state != P_DIAGRAM {
      reader.other(db, t)
      state = P_AFTER_OTHER
      continue
    } else if state != P_ITEM_OR_END {
      reader.fail(STATEMENTS)
    }
    if depth > 0 {
      if t != RBRACE {
        reader.fail("'NEWLINE', 'RBRACE'")
      }
      reader.i += 1
      db.pop_boundary_parse_stack()
      depth -= 1
      state = P_AFTER_DIAGRAM
    } else {
      if t != EOF {
        reader.fail("'NEWLINE', 'EOF'")
      }
      reader.i += 1
      reader.expect(END)
      db.set_c4_type(reader.text(0))
      return
    }
  }
}
