// Text dumps of the model, written the way the expected dumps were taken from pele's StateDb.

///|
fn q(text : String?) -> String {
  match text {
    None => "-"
    Some(text) => {
      let escaped = text
        .replace_all(old="\\", new="\\\\")
        .replace_all(old="\"", new="\\\"")
        .replace_all(old="\n", new="\\n")
        .replace_all(old="\r", new="\\r")
        .replace_all(old="\t", new="\\t")
      "\"\{escaped}\""
    }
  }
}

///|
fn list(items : Array[String]) -> String {
  "[" + items.map(item => q(Some(item))).join(",") + "]"
}

///|
fn description_text(description : @state.Description?) -> String {
  match description {
    None => "-"
    Some(Text(text)) => q(Some(text))
    Some(Lines(lines)) => list(lines)
  }
}

///|
/// A state statement as one line; `classes` is shown only where the statement was given some, as pele's statements leave it out otherwise.
fn state_line(s : @state.StateStmt) -> String {
  let line = StringBuilder()
  line.write_string(
    "state \{q(Some(s.id))} type=\{q(s.kind)} descr=\{description_text(s.description)}",
  )
  if s.start is Some(start) {
    line.write_string(" start=\{start}")
  }
  if s.classes.length() > 0 {
    line.write_string(" classes=\{list(s.classes)}")
  }
  if s.note is Some(note) {
    line.write_string(" note=\{q(Some(note.position))}:\{q(Some(note.text))}")
  }
  line.to_string()
}

///|
fn doc_lines(
  doc : Array[@state.Stmt],
  indent : String,
  out : Array[String],
) -> Unit {
  for item in doc {
    match item {
      Other(text) => out.push("\{indent}text \{q(Some(text))}")
      State(s) =>
        match s.doc {
          Some(inner) => {
            out.push(indent + state_line(s) + " {")
            doc_lines(inner, indent + "  ", out)
            out.push(indent + "}")
          }
          None => out.push(indent + state_line(s))
        }
      Relation(state1, state2, description) => {
        out.push("\{indent}relation descr=\{q(description)}")
        out.push("\{indent}  \{state_line(state1)}")
        out.push("\{indent}  \{state_line(state2)}")
      }
      ClassDef(id, classes) =>
        out.push("\{indent}classDef \{q(Some(id))} \{q(Some(classes))}")
      Style(id, style_class) =>
        out.push("\{indent}style \{q(Some(id))} \{q(Some(style_class))}")
      ApplyClass(id, style_class) =>
        out.push("\{indent}class \{q(Some(id))} \{q(Some(style_class))}")
      Dir(dir) => out.push("\{indent}dir \{q(Some(dir.value))}")
      Click(id, url, tooltip) =>
        out.push(
          "\{indent}click \{q(Some(id.id))} \{q(Some(url))} \{q(Some(tooltip))}",
        )
    }
  }
}

///|
/// The model as text: the root document, then the states, relations, classes and links the model collected from it.
fn model_dump(db : @state.StateDb) -> String {
  let out = ["dir \{q(Some(db.direction()))}"]
  if db.title is Some(_) {
    out.push("title \{q(db.title)}")
  }
  if db.acc_title is Some(_) {
    out.push("accTitle \{q(db.acc_title)}")
  }
  if db.acc_descr is Some(_) {
    out.push("accDescr \{q(db.acc_descr)}")
  }
  doc_lines(db.root_doc, "", out)
  for key, s in db.states {
    let line = StringBuilder()
    line.write_string(
      "state \{q(Some(key))} id=\{q(Some(s.id))} type=\{q(s.kind)} descriptions=\{list(s.descriptions)} classes=\{list(s.classes)} styles=\{list(s.styles)} textStyles=\{list(s.text_styles)}",
    )
    if s.note is Some(note) {
      line.write_string(" note=\{q(Some(note.position))}:\{q(Some(note.text))}")
    }
    if s.doc is Some(doc) {
      line.write_string(" doc=\{doc.length()}")
    }
    out.push(line.to_string())
  }
  for r in db.relations {
    out.push(
      "rel \{q(Some(r.id1))} \{q(Some(r.id2))} \{q(Some(r.relation_title))}",
    )
  }
  for key, c in db.classes {
    out.push(
      "classDef \{q(Some(key))} id=\{q(Some(c.id))} styles=\{list(c.styles)} textStyles=\{list(c.text_styles)}",
    )
  }
  for key, l in db.links {
    out.push("link \{q(Some(key))} \{q(Some(l.url))} \{q(Some(l.tooltip))}")
  }
  out.join("\n")
}
