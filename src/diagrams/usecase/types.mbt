///|
/// An actor; `actor_type` is `normal`, `hollow`, `awesome` or `icon`, and `label_type` is
/// `text` or `markdown`.
pub(all) struct Actor {
  id : String
  label : String
  label_type : String
  actor_type : String
  icon : String?
  business : Bool
  stereotype : String?
  parent_id : String?
  classes : Array[String]
  styles : Array[String]
}

///|
/// A use case; `shape` is `ellipse` or `rect`.
pub(all) struct UseCase {
  id : String
  label : String
  label_type : String
  shape : String
  business : Bool
  stereotype : String?
  parent_id : String?
  classes : Array[String]
  styles : Array[String]
}

///|
/// A system boundary; `boundary_type` is `rect` or `package`, and `members` are the ids of the
/// elements declared in it.
pub(all) struct SystemBoundary {
  id : String
  label : String
  label_type : String
  mut boundary_type : String
  mut members : Array[String]
  mut classes : Array[String]
  styles : Array[String]
}

///|
/// An association with an arrowhead at its target, as `-->` draws it.
/// The arrow types are numbered in Mermaid's order.
pub const SOLID_ARROW : Int32 = 0

///|
/// An association with an arrowhead at its source, as `<--` draws it.
pub const BACK_ARROW : Int32 = 1

///|
/// An association with no marker, as `--` draws it.
pub const LINE_SOLID : Int32 = 2

///|
/// An association with a circle at its target, as `--o` draws it.
pub const CIRCLE_ARROW : Int32 = 3

///|
/// An association with a cross at its target, as `--x` draws it.
pub const CROSS_ARROW : Int32 = 4

///|
/// An association with a circle at its source, as `o--` draws it.
pub const CIRCLE_ARROW_REVERSED : Int32 = 5

///|
/// An association with a cross at its source, as `x--` draws it.
pub const CROSS_ARROW_REVERSED : Int32 = 6

///|
/// A relationship; `rel_type` is `association`, `include`, `extend` or `generalization`, and
/// `animation` is `fast` or `slow`.
pub(all) struct Relationship {
  id : String
  explicit_id : Bool
  source : String
  target : String
  rel_type : String
  arrow_type : Int32
  label : String?
  label_type : String?
  minlen : Int32
  classes : Array[String]
  styles : Array[String]
  mut animate : Bool
  mut animation : String?
}

///|
/// A note about an actor or use case.
pub(all) struct UsecaseNote {
  id : String
  target : String
  label : String
  label_type : String
}

///|
/// A `json` node: the members of its object.
pub(all) struct UsecaseJsonNode {
  id : String
  value : Array[(String, JsonValue)]
  classes : Array[String]
  styles : Array[String]
}

///|
/// A class definition.
pub(all) struct ClassDef {
  id : String
  styles : Array[String]
}

///|
/// A parsed use case diagram; `direction` is `TB`, `BT`, `RL` or `LR`.
/// pele also keeps the source and the spans of its statements for Mermaid's syntax tree, which
/// nothing here draws from.
pub(all) struct UsecaseModel {
  actors : Map[String, Actor]
  use_cases : Map[String, UseCase]
  system_boundaries : Map[String, SystemBoundary]
  relationships : Array[Relationship]
  notes : Map[String, UsecaseNote]
  json_nodes : Map[String, UsecaseJsonNode]
  class_defs : Map[String, ClassDef]
  mut direction : String
  mut title : String?
  mut acc_title : String
  mut acc_descr : String
}

///|
fn empty_model() -> UsecaseModel {
  {
    actors: Map([]),
    use_cases: Map([]),
    system_boundaries: Map([]),
    relationships: [],
    notes: Map([]),
    json_nodes: Map([]),
    class_defs: Map([]),
    direction: "LR",
    title: None,
    acc_title: "",
    acc_descr: "",
  }
}
