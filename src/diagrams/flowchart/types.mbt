///|
/// How a label is written: plain text, a quoted string, or Markdown.
pub(all) enum LabelType {
  Text
  Str
  Markdown
}

///|
/// The name pele gives the label type.
pub fn LabelType::to_string(self : LabelType) -> String {
  match self {
    Text => "text"
    Str => "string"
    Markdown => "markdown"
  }
}

///|
/// A label as written, with how it is to be read.
pub(all) struct FlowText {
  text : String
  kind : LabelType
}

///|
/// A node of the flowchart. `kind` is pele's `type`: the shape the syntax or node data gave it.
pub(all) struct FlowNode {
  id : String
  mut text : String?
  mut label_type : LabelType
  mut kind : String?
  styles : Array[String]
  classes : Array[String]
  mut dir : String?
  mut props : Map[String, String]?
  mut link : String?
  mut link_target : String?
  mut icon : String?
  mut form : String?
  mut pos : String?
  mut img : String?
  mut constraint : String?
  mut asset_width : Double?
  mut asset_height : Double?
}

///|
/// An edge of the flowchart. `kind` is pele's `type`, such as `arrow_point`.
/// Node data can set `interpolate`, `animate` and `animation` to any YAML value, as in pele.
pub(all) struct FlowEdge {
  start : String
  end : String
  mut kind : String?
  mut text : String
  mut label_type : LabelType
  mut stroke : String?
  mut length : Int32?
  mut style : Array[String]?
  classes : Array[String]
  mut id : String
  mut is_user_defined_id : Bool
  mut interpolate : Json?
  mut animate : Json?
  mut animation : Json?
}

///|
/// A `classDef`: its styles, and those of them that apply to text.
pub(all) struct FlowClassDef {
  id : String
  styles : Array[String]
  text_styles : Array[String]
}

///|
/// A subgraph and the ids it holds, in the order they were first listed.
pub(all) struct FlowSubgraph {
  id : String
  nodes : Array[String]
  title : String
  classes : Array[String]
  dir : String?
  label_type : LabelType
  mut metadata : Map[String, Json]?
}

///|
/// What a link token says about the edge: its arrow type, stroke, length, label and id.
pub(all) struct LinkInfo {
  mut kind : String
  stroke : String
  mut length : Int32?
  mut text : FlowText?
  mut id : String?
}

///|
/// An entry of a subgraph's body: a node id, the ids of a statement, or a `direction`.
pub(all) enum DocItem {
  Id(String)
  Ids(Array[String])
  Direction(String)
}
