///|
/// Mermaid's StateDB in its version 2 form, which is what Mermaid uses for both `stateDiagram` and `stateDiagram-v2`.
/// Mermaid's legacy version, which numbers `[*]` states, has no counterpart here because pele has none to port.
/// pele detects `stateDiagram` and `stateDiagram-v2` as the same type and its `parse` builds this form for every source while ignoring the config, so no input or option reaches the legacy numbering.
pub struct StateDb {
  mut root_doc : Array[Stmt]
  mut states : Map[String, StateStmt]
  mut relations : Array[StateRelation]
  mut classes : Map[String, StateClassDef]
  links : Map[String, StateLink]
  title : String?
  mut acc_title : String?
  mut acc_descr : String?
  mut graph : StateGraph
  priv mut divider_count : Int32
}

///|
/// An empty model, titled from front matter when there is a title.
pub fn StateDb::new(title? : String) -> StateDb {
  {
    root_doc: [],
    states: Map([]),
    relations: [],
    classes: Map([]),
    links: Map([]),
    title,
    acc_title: None,
    acc_descr: None,
    graph: { nodes: [], edges: [], },
    divider_count: 0,
  }
}

///|
/// The direction a document is laid out in: its last `direction` statement, or TB.
fn doc_direction(doc : Array[Stmt]) -> String {
  let mut dir = "TB"
  for item in doc {
    if item is Dir(stmt) {
      dir = stmt.value
    }
  }
  dir
}

///|
/// The direction the root document is laid out in: its last `direction` statement.
pub fn StateDb::direction(self : StateDb) -> String {
  doc_direction(self.root_doc)
}

///|
/// Splits text at each separator, as JavaScript's `split` does.
fn split(text : String, separator : String) -> Array[String] {
  let parts = []
  let mut from = 0
  while true {
    let at = @util.index_of(text, separator, from~)
    if at == -1 {
      break
    }
    parts.push(@util.slice(text, from, end=at))
    from = at + separator.length()
  }
  parts.push(@util.slice(text, from))
  parts
}

///|
/// The text with the first occurrence of `old` replaced, as JavaScript's `replace` with a string does.
fn replace_first(text : String, old : String, new : String) -> String {
  let at = @util.index_of(text, old)
  if at == -1 {
    text
  } else {
    @util.slice(text, 0, end=at) + new + @util.slice(text, at + old.length())
  }
}

///|
/// Takes the parsed document, gives each `[*]` and region its id, and collects the root document's states, relations and classes.
pub fn StateDb::set_root_doc(
  self : StateDb,
  doc : Array[Stmt],
) -> Unit raise @errors.PeleError {
  self.root_doc = doc
  self.translate()
  self.extract(doc)
}

///|
/// Only the root document's statements become states, relations and classes here; the statements inside composites are read when the graph is built.
fn StateDb::extract(
  self : StateDb,
  doc : Array[Stmt],
) -> Unit raise @errors.PeleError {
  self.states = Map([])
  self.relations = []
  self.classes = Map([])
  for item in doc {
    match item {
      Other(_) | Dir(_) => ()
      State(s) =>
        self.add_state(
          @util.trim(s.id),
          kind?=s.kind,
          doc?=s.doc,
          description?=s.description,
          note?=s.note,
        )
      Relation(state1, state2, description) =>
        self.add_relation(state1, state2, title?=description)
      ClassDef(id, classes) =>
        self.add_style_class(@util.trim(id), attributes=classes)
      Style(id, style_class) => {
        let styles = split(style_class, ",").map(s => {
          @util.trim(s.replace_all(old=";", new=""))
        })
        for state in self.named(@util.trim(id)) {
          state.styles = styles.copy()
        }
      }
      ApplyClass(id, style_class) =>
        self.set_css_class(@util.trim(id), style_class)
      Click(id, url, tooltip) => self.add_link(id.id, url, tooltip)
    }
  }
  self.graph = build_state_graph(doc, self.states, self.classes)
}

///|
/// A document waiting to be translated: the root's, or a statement's.
priv enum Pending {
  Root
  Item(Stmt)
}

///|
/// Mermaid's docTranslator: gives each `[*]` an id scoped to its parent, and turns a document split by `--` into one region per part.
fn StateDb::translate(self : StateDb) -> Unit {
  let pending : Array[(String, Pending, Bool)] = [("root", Root, true)]
  while pending.pop() is Some((parent_id, node, first)) {
    let (id, doc, owner) = match node {
      Item(Relation(state1, state2, _)) => {
        pending.push((parent_id, Item(State(state2)), false))
        pending.push((parent_id, Item(State(state1)), true))
        continue
      }
      Item(State(s)) => {
        if s.id == "[*]" {
          s.id = parent_id + (if first { "_start" } else { "_end" })
          s.start = Some(first)
        } else {
          s.id = @util.trim(s.id)
        }
        guard s.doc is Some(doc) else { continue }
        (s.id, doc, Some(s))
      }
      Item(_) => continue
      Root => ("root", self.root_doc, None)
    }
    let regions : Array[Stmt] = []
    let mut current : Array[Stmt] = []
    for item in doc {
      if item is State(s) && s.kind == Some("divider") && s.doc is None {
        regions.push(State({ ..s, doc: Some(current), }))
        current = []
      } else {
        current.push(item)
      }
    }
    // Mermaid names the region after the last divider with a random id; here it continues the divider numbering.
    // Mermaid also leaves a document that ends with a divider ungrouped and then fails to draw it; here the regions before that divider are kept.
    let doc = if regions.length() > 0 {
      if current.length() > 0 {
        regions.push(
          State(
            StateStmt::new(self.get_divider_id(), kind="divider", doc=current),
          ),
        )
      }
      // As in pele, a split root document is not written back to the model; the grammar never puts a divider there.
      if owner is Some(s) {
        s.doc = Some(regions)
      }
      regions
    } else {
      doc
    }
    for i = doc.length() - 1; i >= 0; i = i - 1 {
      pending.push((id, Item(doc[i]), true))
    }
  }
}

///|
/// Adds a state, or merges what is given into the state of that id.
pub fn StateDb::add_state(
  self : StateDb,
  id : String,
  kind~ : String = "default",
  doc? : Array[Stmt],
  description? : Description,
  note? : StateNote,
  classes? : Array[String],
) -> Unit {
  let trimmed = @util.trim(id)
  match self.states.get(trimmed) {
    None =>
      self.states.set(trimmed, {
        id: trimmed,
        kind: Some(kind),
        description: None,
        descriptions: [],
        doc,
        note: None,
        start: None,
        classes: [],
        styles: [],
        text_styles: [],
      })
    Some(state) => {
      if state.doc is None {
        state.doc = doc
      }
      if state.kind is (None | Some("")) {
        state.kind = Some(kind)
      }
    }
  }
  match description {
    Some(Text(text)) if text != "" =>
      self.add_description(trimmed, @util.trim(text))
    Some(Lines(lines)) =>
      for text in lines {
        self.add_description(trimmed, @util.trim(text))
      }
    _ => ()
  }
  if note is Some(_) {
    self.states.get(trimmed).unwrap().note = note
  }
  if classes is Some(classes) {
    for name in classes {
      self.set_css_class(trimmed, @util.trim(name))
    }
  }
}

///|
/// Records the target of a click statement on a state.
fn StateDb::add_link(
  self : StateDb,
  state_id : String,
  url : String,
  tooltip : String,
) -> Unit {
  self.links.set(state_id, { url, tooltip, })
}

///|
/// Adds a transition, and its two states where they are new.
pub fn StateDb::add_relation(
  self : StateDb,
  item1 : StateStmt,
  item2 : StateStmt,
  title~ : String = "",
) -> Unit {
  for item in [item1, item2] {
    self.add_state(
      item.id,
      kind?=item.kind,
      doc?=item.doc,
      description?=item.description,
      note?=item.note,
      classes=item.classes,
    )
  }
  self.relations.push({
    id1: @util.trim(item1.id),
    id2: @util.trim(item2.id),
    relation_title: title,
  })
}

///|
/// Adds a description line to a state, without one leading colon.
pub fn StateDb::add_description(
  self : StateDb,
  id : String,
  description : String,
) -> Unit {
  guard self.states.get(id) is Some(state) else { return }
  state.descriptions.push(
    if description.has_prefix(":") {
      @util.trim(@util.slice(description, 1))
    } else {
      description
    },
  )
}

///|
/// The id of the next region of a composite.
pub fn StateDb::get_divider_id(self : StateDb) -> String {
  self.divider_count += 1
  "divider-id-\{self.divider_count}"
}

///|
/// Adds the styles of a comma-separated `classDef` list to the class of that id.
pub fn StateDb::add_style_class(
  self : StateDb,
  id : String,
  attributes~ : String = "",
) -> Unit {
  let found = match self.classes.get(id) {
    Some(found) => found
    None => {
      let made = { id, styles: [], text_styles: [], }
      self.classes.set(id, made)
      made
    }
  }
  if attributes == "" {
    return
  }
  for attribute in split(attributes, ",") {
    let fixed = @util.trim(replace_first(attribute, ";", ""))
    if attribute.contains("color") {
      found.text_styles.push(
        replace_first(replace_first(fixed, "fill", "bgFill"), "color", "fill"),
      )
    }
    found.styles.push(fixed)
  }
}

///|
/// Gives a class to each state a comma-separated list of ids names, creating the states that do not exist yet.
pub fn StateDb::set_css_class(
  self : StateDb,
  ids : String,
  class_name : String,
) -> Unit {
  for state in self.named(ids) {
    state.classes.push(class_name)
  }
}

///|
/// The states a comma-separated list of ids names, created where they do not exist yet.
/// As in Mermaid, an id is looked up as written and trimmed only when it has to be created.
fn StateDb::named(self : StateDb, ids : String) -> Array[StateStmt] {
  let out = []
  for id in split(ids, ",") {
    let state = match self.states.get(id) {
      Some(state) => Some(state)
      None => {
        self.add_state(id)
        self.states.get(@util.trim(id))
      }
    }
    if state is Some(state) {
      out.push(state)
    }
  }
  out
}

///|
/// Records a `direction` statement in the root document.
/// The grammar calls this while it is still building the document, so the statement lands in the previous root document and the direction is read from the parsed `dir` statements instead.
pub fn StateDb::set_direction(self : StateDb, dir : String) -> Unit {
  for item in self.root_doc {
    if item is Dir(stmt) {
      stmt.value = dir
      return
    }
  }
  self.root_doc.insert(0, Dir({ value: dir, }))
}

///|
/// The text of a description without its leading colon, trimmed.
pub fn StateDb::trim_colon(_self : StateDb, text : String) -> String {
  if text.has_prefix(":") {
    @util.trim(@util.slice(text, 1))
  } else {
    @util.trim(text)
  }
}

///|
/// Sets the accessible title, without leading whitespace.
pub fn StateDb::set_acc_title(self : StateDb, text : String) -> Unit {
  self.acc_title = Some(@util.trim_start(text))
}

///|
/// Sets the accessible description, without the indentation of its lines.
pub fn StateDb::set_acc_description(self : StateDb, text : String) -> Unit {
  // `/\n\s+/g`: a line feed and the whitespace after it, line feeds included, become one line feed.
  let out = StringBuilder()
  let n = text.length()
  let mut from = 0
  let mut i = 0
  while i < n {
    if @util.code_at(text, i) == 10 &&
      @util.is_space(@util.code_at(text, i + 1)) {
      @util.write_range(out, text, from, i + 1)
      i += 1
      while i < n && @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
      from = i
      continue
    }
    i += 1
  }
  @util.write_range(out, text, from, n)
  self.acc_descr = Some(out.to_string())
}
