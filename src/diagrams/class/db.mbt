///|
/// The model of a class diagram, built up statement by statement as Mermaid's ClassDB is.
pub struct ClassDb {
  mut direction : String
  classes : Map[String, ClassNode]
  relations : Array[ClassRelation]
  notes : Map[String, ClassNote]
  namespaces : Map[String, NamespaceNode]
  interfaces : Array[ClassInterface]
  style_classes : Map[String, StyleClass]
  title : String?
  mut acc_title : String?
  mut acc_descr : String?
}

///|
/// An empty model that runs top to bottom, with the title front matter gave.
pub fn ClassDb::new(title? : String) -> ClassDb {
  {
    direction: "TB",
    classes: Map([]),
    relations: [],
    notes: Map([]),
    namespaces: Map([]),
    interfaces: [],
    style_classes: Map([]),
    title,
    acc_title: None,
    acc_descr: None,
  }
}

///|
/// Adds the class a name with an optional generic type names, if it is new.
pub fn ClassDb::add_class(self : ClassDb, id : String) -> Unit {
  ignore((self, id))
}

///|
/// Sets the label a class is shown with, adding the class if it is new.
pub fn ClassDb::set_class_label(
  self : ClassDb,
  id : String,
  label : String,
) -> Unit {
  ignore((self, id, label))
}

///|
/// Adds a relation, with an interface in place of a lone lollipop end.
pub fn ClassDb::add_relation(self : ClassDb, relation : ClassRelation) -> Unit {
  ignore((self, relation))
}

///|
/// Adds an annotation to a class, adding the class if it is new.
pub fn ClassDb::add_annotation(
  self : ClassDb,
  class_name : String,
  annotation : String,
) -> Unit {
  ignore((self, class_name, annotation))
}

///|
/// Adds a member to a class: an annotation in `<<` and `>>`, a method, or an attribute.
pub fn ClassDb::add_member(
  self : ClassDb,
  class_name : String,
  text : String,
) -> Unit {
  ignore((self, class_name, text))
}

///|
/// Adds the members of a class body, which the grammar collects last to first.
pub fn ClassDb::add_members(
  self : ClassDb,
  class_name : String,
  list : Array[String],
) -> Unit {
  ignore((self, class_name, list))
}

///|
/// Adds a note and returns its id.
pub fn ClassDb::add_note(
  self : ClassDb,
  text : String,
  class_id? : String,
) -> String {
  ignore((self, text, class_id))
  ""
}

///|
/// The text of a `:` label, without the colon.
pub fn ClassDb::cleanup_label(self : ClassDb, label : String) -> String {
  ignore((self, label))
  ""
}

///|
/// Adds a css class to each class of a comma-separated list.
pub fn ClassDb::set_css_class(
  self : ClassDb,
  ids : String,
  class_name : String,
) -> Unit {
  ignore((self, ids, class_name))
}

///|
/// Defines a classDef and styles the classes that already carry it.
pub fn ClassDb::define_class(
  self : ClassDb,
  ids : Array[String],
  style : Array[String],
) -> Unit {
  ignore((self, ids, style))
}

///|
/// Sets the tooltip of each class of a comma-separated list.
pub fn ClassDb::set_tooltip(
  self : ClassDb,
  ids : String,
  tooltip : String?,
) -> Unit {
  ignore((self, ids, tooltip))
}

///|
/// Links each class of a comma-separated list, through a sanitized URL.
pub fn ClassDb::set_link(
  self : ClassDb,
  ids : String,
  link : String,
  target? : String,
) -> Unit {
  ignore((self, ids, link, target))
}

///|
/// Marks each class of a comma-separated list as having a callback.
pub fn ClassDb::set_click_event(self : ClassDb, ids : String) -> Unit {
  ignore((self, ids))
}

///|
/// Sets the direction the diagram runs in.
pub fn ClassDb::set_direction(self : ClassDb, dir : String) -> Unit {
  self.direction = dir
}

///|
/// Sets the accessible title, without its leading whitespace.
pub fn ClassDb::set_acc_title(self : ClassDb, text : String) -> Unit {
  self.acc_title = Some(text)
}

///|
/// Sets the accessible description, with the indentation of its lines removed.
pub fn ClassDb::set_acc_description(self : ClassDb, text : String) -> Unit {
  self.acc_descr = Some(text)
}

///|
/// Opens a namespace inside the one open, with its ancestors, and returns its full name.
pub fn ClassDb::add_namespace(
  self : ClassDb,
  id : String,
  label? : String,
) -> String {
  ignore((self, id, label))
  ""
}

///|
/// Closes the namespace opened last.
pub fn ClassDb::pop_namespace(self : ClassDb) -> Unit {
  ignore(self)
}

///|
/// Puts classes and notes into a namespace.
pub fn ClassDb::add_classes_to_namespace(
  self : ClassDb,
  id : String,
  class_names : Array[String],
  note_names : Array[String],
) -> Unit {
  ignore((self, id, class_names, note_names))
}

///|
/// Adds the declarations of a `style` statement to a class.
pub fn ClassDb::set_css_style(
  self : ClassDb,
  id : String,
  styles : Array[String],
) -> Unit {
  ignore((self, id, styles))
}
