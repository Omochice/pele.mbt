///|
/// A note beside a state: `left of` or `right of`, and its text.
pub(all) struct StateNote {
  position : String
  text : String
}

///|
/// The text a state statement gives: one description, or a title and its description lines.
pub(all) enum Description {
  Text(String)
  Lines(Array[String])
}

///|
/// A state, both as a statement in a document and as the record the model keeps of it.
pub(all) struct StateStmt {
  mut id : String
  /// default, fork, join, choice or divider; absent for a note's statement.
  mut kind : String?
  mut description : Description?
  /// The descriptions the model collects for the state.
  descriptions : Array[String]
  mut doc : Array[Stmt]?
  mut note : StateNote?
  /// Set on a `[*]` once it is known to start or end its document.
  mut start : Bool?
  /// The classes a `:::` gives a statement, or every class the model gives the state.
  classes : Array[String]
  mut styles : Array[String]
  text_styles : Array[String]
}

///|
/// A state statement with nothing but the fields the grammar sets.
pub fn StateStmt::new(
  id : String,
  kind? : String,
  description? : Description,
  doc? : Array[Stmt],
  note? : StateNote,
  classes~ : Array[String] = [],
) -> StateStmt {
  {
    id,
    kind,
    description,
    descriptions: [],
    doc,
    note,
    start: None,
    classes,
    styles: [],
    text_styles: [],
  }
}

///|
/// A `direction` statement; its value is rewritten when a later one in the root document replaces it.
pub(all) struct DirStmt {
  mut value : String
}

///|
/// A statement of a document.
/// Mermaid's grammar also leaves the text of statements that have no effect in a document (`hide empty description`, `scale`, a bare `state name`, a floating note); those are `Other`.
pub(all) enum Stmt {
  Other(String)
  State(StateStmt)
  Relation(StateStmt, StateStmt, String?)
  ClassDef(String, String)
  Style(String, String)
  ApplyClass(String, String)
  Dir(DirStmt)
  Click(StateStmt, String, String)
}

///|
/// A transition between two states, by their ids.
pub(all) struct StateRelation {
  id1 : String
  id2 : String
  relation_title : String
}

///|
/// The styles a `classDef` collects, and those of them that color text.
pub(all) struct StateClassDef {
  id : String
  styles : Array[String]
  text_styles : Array[String]
}

///|
/// The target of a click statement, quotes included as Mermaid keeps them.
pub(all) struct StateLink {
  url : String
  tooltip : String
}
