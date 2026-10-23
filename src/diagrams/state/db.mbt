///|
/// Mermaid's StateDB in its version 2 form, which is what Mermaid uses for both `stateDiagram` and `stateDiagram-v2`.
/// The legacy version, which numbers `[*]` states, is not ported.
pub struct StateDb {
  mut root_doc : Array[Stmt]
  mut states : Map[String, StateStmt]
  mut relations : Array[StateRelation]
  mut classes : Map[String, StateClassDef]
  links : Map[String, StateLink]
  title : String?
  mut acc_title : String?
  mut acc_descr : String?
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
    divider_count: 0,
  }
}

///|
/// The direction the root document is laid out in: its last `direction` statement.
pub fn StateDb::direction(self : StateDb) -> String {
  ignore(self)
  "TB"
}

///|
/// Takes the parsed document, gives each `[*]` and region its id, and collects the root document's states, relations and classes.
pub fn StateDb::set_root_doc(self : StateDb, doc : Array[Stmt]) -> Unit {
  self.root_doc = doc
  self.states = Map([])
  self.relations = []
  self.classes = Map([])
}

///|
/// Adds a state, or merges what is given into the state of that id.
pub fn StateDb::add_state(
  self : StateDb,
  id : String,
  kind? : String,
  doc? : Array[Stmt],
  description? : Description,
  note? : StateNote,
  classes? : Array[String],
) -> Unit {
  ignore((self, id, kind, doc, description, note, classes))
}

///|
/// Adds a transition, and its two states where they are new.
pub fn StateDb::add_relation(
  self : StateDb,
  item1 : StateStmt,
  item2 : StateStmt,
  title? : String,
) -> Unit {
  ignore((self, item1, item2, title))
}

///|
/// Adds a description line to a state, without one leading colon.
pub fn StateDb::add_description(
  self : StateDb,
  id : String,
  description : String,
) -> Unit {
  ignore((self, id, description))
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
  ignore((self, id, attributes))
}

///|
/// Gives a class to each state a comma-separated list of ids names, creating the states that do not exist yet.
pub fn StateDb::set_css_class(
  self : StateDb,
  ids : String,
  class_name : String,
) -> Unit {
  ignore((self, ids, class_name))
}

///|
/// Records a `direction` statement in the root document.
pub fn StateDb::set_direction(self : StateDb, dir : String) -> Unit {
  ignore((self, dir))
}

///|
/// The text of a description without its leading colon, trimmed.
pub fn StateDb::trim_colon(self : StateDb, text : String) -> String {
  ignore(self)
  text
}

///|
/// Sets the accessible title, without leading whitespace.
pub fn StateDb::set_acc_title(self : StateDb, text : String) -> Unit {
  ignore(text)
  self.acc_title = None
}

///|
/// Sets the accessible description, without the indentation of its lines.
pub fn StateDb::set_acc_description(self : StateDb, text : String) -> Unit {
  ignore(text)
  self.acc_descr = None
}
