///|
/// The ancestors of the last node, each with its level.
priv struct Db {
  mut root : IshikawaNode?
  stack : Array[(Int32, IshikawaNode)]
  mut base_level : Int32?
}

///|
/// The first line is the effect.
/// Every later line is a cause, nested by its indentation relative to the first cause, so the
/// effect itself may be indented more than the causes.
fn Db::add_node(self : Db, raw_level : Int32, text : String) -> Unit {
  let node = { text, children: [], }
  if self.root is None {
    self.root = Some(node)
    self.stack.push((0, node))
    return
  }
  let base = match self.base_level {
    Some(base) => base
    None => {
      self.base_level = Some(raw_level)
      raw_level
    }
  }
  let level = @util.js_max((raw_level - base + 1).to_double(), 1).to_int()
  while self.stack.length() > 1 &&
        self.stack[self.stack.length() - 1].0 >= level {
    ignore(self.stack.pop())
  }
  self.stack[self.stack.length() - 1].1.children.push(node)
  self.stack.push((level, node))
}

///|
let stop : String = "'SPACELINE', 'NL', 'EOF'"

///|
/// Parses an Ishikawa diagram into its outline.
/// `title` is the front matter title.
/// Raises a syntax error where Mermaid's parser would.
///
/// Follows the parser Jison builds from Mermaid's grammar: blank lines and comments may come
/// first, then the keyword and at most one line break, then statements.
/// A statement is a line of text, with or without indentation, or a blank line; each is ended by
/// a blank line, a line break or the end of the text, and any number of line breaks after that.
pub fn parse_ishikawa(
  src : String,
  title? : String,
) -> IshikawaModel raise @errors.PeleError {
  let { types, starts, ends, } = tokenize(src)
  let db : Db = { root: None, stack: [], base_level: None, }
  let mut i = 0
  let fail = (expected : String) => {
    raise @errors.syntax_error(
      "ishikawa",
      src,
      starts[i],
      "Expecting \{expected}, got '\{types[i].name()}'",
    )
  }
  let ends_statement = (k : Int32) => types[k] is (Spaceline | Nl | Eof)
  if types[i] is Spaceline {
    i += 1
    while types[i] is (Spaceline | Nl) {
      i += 1
    }
    if !(types[i] is Ishikawa) {
      fail("'SPACELINE', 'NL', 'ISHIKAWA'")
    }
  } else if !(types[i] is Ishikawa) {
    fail("'SPACELINE', 'ISHIKAWA'")
  }
  i += 1
  if types[i] is Nl {
    i += 1
  }
  while true {
    let type_ = types[i]
    if type_ is Text || (type_ is Spacelist && types[i + 1] is Text) {
      let text = if type_ is Text { i } else { i + 1 }
      i = text + 1
      if !ends_statement(i) {
        fail(stop)
      }
      let level = if type_ is Text {
        0
      } else {
        ends[text - 1] - starts[text - 1]
      }
      db.add_node(
        level,
        @util.trim(@util.slice(src, starts[text], end=ends[text])),
      )
    } else if type_ is (Spaceline | Spacelist) {
      i += 1
      if !ends_statement(i) {
        fail(if type_ is Spacelist { "\{stop}, 'TEXT'" } else { stop })
      }
    } else {
      fail("'SPACELINE', 'SPACELIST', 'TEXT'")
    }
    i += 1
    while types[i] is (Nl | Eof) {
      i += 1
    }
    if types[i] is End {
      break
    }
  }
  { title, root: db.root, }
}
