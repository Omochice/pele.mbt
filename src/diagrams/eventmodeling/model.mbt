///|
pub(all) enum EntityKind {
  Ui
  Processor
  Command
  ReadModel
  Event
}

///|
pub(all) enum LaneGroup {
  Trigger
  State
  Stream
}

///|
pub(all) struct EmLane {
  /// Mermaid's ordering key: 0 for UI/Automation, 100 for Command/Read Model, 200 for Events, and the next free number after those for each namespace.
  /// Namespaces of different groups can share a number, so a lane is told apart by its `key`.
  index : Int32
  key : String
  label : String
  group : LaneGroup
  /// The namespace of the lane, which pele spells `namespace`, a reserved word here.
  scope : String?
}

///|
pub(all) struct EmBox {
  /// The frame number as written, such as "01".
  id : String
  kind : EntityKind
  entity : String
  name : String
  scope : String?
  reset : Bool
  lane : EmLane
  /// Example data from the frame or from the data block it refers to.
  data : String?
  data_type : String?
}

///|
/// A relation between two boxes of the model, told apart by their ids, which are unique.
pub(all) struct EmRelation {
  source : EmBox
  target : EmBox
}

///|
pub(all) struct EmNote {
  frame : String
  text : String
  data_type : String?
}

///|
pub(all) struct EmSpecification {
  frame : String
  given : Array[String]
  when_ : Array[String]
  then_ : Array[String]
}

///|
pub(all) struct EventModelingModel {
  title : String?
  acc_title : String?
  acc_descr : String?
  boxes : Array[EmBox]
  /// Sorted from top to bottom.
  lanes : Array[EmLane]
  relations : Array[EmRelation]
  notes : Array[EmNote]
  specifications : Array[EmSpecification]
  entities : Array[String]
}

///|
/// Builds the model of an event model, with the front matter title as the title it has none of its own.
pub fn build_event_model(
  ast : EventModelAst,
  title : String?,
) -> EventModelingModel raise @errors.PeleError {
  ignore((ast, title))
  raise @errors.pele_error("not implemented")
}
