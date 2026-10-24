///|
const STATEMENT : String = "'NL', 'ID', 'HIDE_EMPTY', 'scale', 'COMPOSIT_STATE', 'STATE_DESCR', 'FORK', 'JOIN', 'CHOICE', 'CONCURRENT', 'note', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'CLICK', 'classDef', 'style', 'class', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'EDGE_STATE'"

///|
priv struct Parser {
  src : String
  tokens : Tokens
  mut i : Int32
}

///|
fn Parser::kind(self : Parser, at~ : Int32 = self.i) -> Tok {
  self.tokens.types[at]
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
  let at = self.tokens.starts[self.i]
  let kind = self.kind()
  if kind is Error {
    match self.tokens.error {
      Some(message) => {
        let (line, column, snippet) = @errors.locate(self.src, at)
        raise @errors.pele_error(
          message,
          code=Syntax,
          kind="state",
          line~,
          column~,
          snippet~,
        )
      }
      None =>
        raise @errors.syntax_error("state", self.src, at, "", lexical=true)
    }
  }
  raise @errors.syntax_error(
    "state",
    self.src,
    at,
    "Expecting \{expected}, got '\{kind.name()}'",
  )
}

///|
fn Parser::expect(self : Parser, kind : Tok) -> String raise @errors.PeleError {
  if self.kind().name() != kind.name() {
    self.fail("'\{kind.name()}'")
  }
  self.take()
}

///|
fn Parser::id_statement(self : Parser) -> StateStmt raise @errors.PeleError {
  if !(self.kind() is (Id | EdgeState)) {
    self.fail("'ID', 'EDGE_STATE'")
  }
  let id = @util.trim(self.take())
  if !(self.kind() is StyleSeparator) {
    return StateStmt::new(id, kind="default", description=Text(""))
  }
  self.i += 1
  let class_name = @util.trim(self.expect(Id))
  StateStmt::new(id, kind="default", description=Text(""), classes=[class_name])
}

///|
/// Parses a state diagram into `db` as Mermaid's grammar does, and returns the root document.
pub fn parse_state(
  src : String,
  db : StateDb,
) -> Array[Stmt] raise @errors.PeleError {
  let p = { src, tokens: tokenize(src), i: 0, }
  while p.kind() is Nl {
    p.i += 1
  }
  if !(p.kind() is Sd) {
    p.fail("'NL', 'SD'")
  }
  p.i += 1
  let mut doc : Array[Stmt] = []
  let outer : Array[Array[Stmt]] = []
  // The grammar drops a statement whose value is the string it uses for a blank line.
  let add = (doc : Array[Stmt], value : Stmt) => {
    if !(value is Other("nl")) {
      doc.push(value)
    }
  }
  while true {
    let kind = p.kind()
    match kind {
      Nl => p.i += 1
      Id | EdgeState => {
        let first = p.id_statement()
        if p.kind() is Descr {
          first.description = Some(Text(db.trim_colon(p.take())))
          add(doc, State(first))
        } else if p.kind() is Arrow {
          p.i += 1
          let second = p.id_statement()
          if p.kind() is Descr {
            add(doc, Relation(first, second, Some(db.trim_colon(p.take()))))
          } else {
            add(doc, Relation(first, second, None))
          }
        } else {
          add(doc, State(first))
        }
      }
      HideEmpty => add(doc, Other(p.take()))
      Scale => {
        p.i += 1
        ignore(p.expect(Width))
        add(doc, Other(p.tokens.texts[p.i - 2]))
      }
      CompositState =>
        if p.kind(at=p.i + 1) is StructStart {
          let id = p.take()
          doc = open(p, doc, outer, id, "")
        } else {
          add(doc, Other(p.take()))
        }
      StateDescr => {
        let description = p.take()
        ignore(p.expect(As))
        let id = p.expect(Id)
        if p.kind() is StructStart {
          doc = open(p, doc, outer, id, description)
        } else if id.contains(":") {
          let parts = split(id, ":")
          add(
            doc,
            State(
              StateStmt::new(
                parts[0],
                kind="default",
                description=Lines([@util.trim(description), parts[1]]),
              ),
            ),
          )
        } else {
          add(
            doc,
            State(
              StateStmt::new(
                id,
                kind="default",
                description=Text(@util.trim(description)),
              ),
            ),
          )
        }
      }
      Fork => add(doc, State(StateStmt::new(p.take(), kind="fork")))
      Join => add(doc, State(StateStmt::new(p.take(), kind="join")))
      Choice => add(doc, State(StateStmt::new(p.take(), kind="choice")))
      Concurrent => {
        p.i += 1
        add(doc, State(StateStmt::new(db.get_divider_id(), kind="divider")))
      }
      Note => {
        let keyword = p.take()
        if p.kind() is (LeftOf | RightOf) {
          let position = @util.trim(p.take())
          let id = @util.trim(p.expect(Id))
          let text = @util.trim(p.expect(NoteText))
          add(doc, State(StateStmt::new(id, note={ position, text, })))
        } else {
          if !(p.kind() is NoteText) {
            p.fail("'NOTE_TEXT', 'left_of', 'right_of'")
          }
          p.i += 1
          ignore(p.expect(As))
          ignore(p.expect(Id))
          add(doc, Other(keyword))
        }
      }
      DirectionTb | DirectionBt | DirectionRl | DirectionLr => {
        let value = match kind {
          DirectionTb => "TB"
          DirectionBt => "BT"
          DirectionRl => "RL"
          _ => "LR"
        }
        p.i += 1
        db.set_direction(value)
        add(doc, Dir({ value, }))
      }
      AccTitle => {
        p.i += 1
        let value = @util.trim(p.expect(AccTitleValue))
        db.set_acc_title(value)
        add(doc, Other(value))
      }
      AccDescr => {
        p.i += 1
        let value = @util.trim(p.expect(AccDescrValue))
        db.set_acc_description(value)
        add(doc, Other(value))
      }
      AccDescrMultilineValue => {
        let value = @util.trim(p.take())
        db.set_acc_description(value)
        add(doc, Other(value))
      }
      Click => {
        p.i += 1
        let id = p.id_statement()
        let mut tooltip = ""
        let url = if p.kind() is Href {
          p.i += 1
          p.expect(Str)
        } else {
          if !(p.kind() is Str) {
            p.fail("'STRING', 'HREF'")
          }
          let url = p.take()
          tooltip = p.expect(Str)
          url
        }
        ignore(p.expect(Nl))
        add(doc, Click(id, url, tooltip))
      }
      ClassDef => {
        p.i += 1
        let id = @util.trim(p.expect(ClassdefId))
        add(doc, ClassDef(id, @util.trim(p.expect(ClassdefStyleopts))))
      }
      Style => {
        p.i += 1
        let id = @util.trim(p.expect(StyleIds))
        add(doc, Style(id, @util.trim(p.expect(StyledefStyleopts))))
      }
      Class => {
        p.i += 1
        let id = @util.trim(p.expect(ClassentityIds))
        add(doc, ApplyClass(id, @util.trim(p.expect(Styleclass))))
      }
      StructStop => {
        guard outer.pop() is Some(enclosing) else {
          p.fail("'$end', \{STATEMENT}")
        }
        p.i += 1
        doc = enclosing
      }
      End => {
        if outer.length() > 0 {
          p.fail("'STRUCT_STOP', \{STATEMENT}")
        }
        db.set_root_doc(doc)
        return doc
      }
      _ =>
        p.fail(
          if outer.length() > 0 {
            "'STRUCT_STOP', \{STATEMENT}"
          } else {
            "'$end', \{STATEMENT}"
          },
        )
    }
  }
  doc
}

///|
/// Starts a composite at its opening brace and returns the document its statements go in.
fn open(
  p : Parser,
  doc : Array[Stmt],
  outer : Array[Array[Stmt]],
  id : String,
  description : String,
) -> Array[Stmt] {
  p.i += 1
  let inner : Array[Stmt] = []
  doc.push(
    State(
      StateStmt::new(
        id,
        kind="default",
        description=Text(description),
        doc=inner,
      ),
    ),
  )
  outer.push(doc)
  inner
}
