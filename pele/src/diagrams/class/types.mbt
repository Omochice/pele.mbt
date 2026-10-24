///|
/// A class: its name, generic type, label, members and the styles and links set on it.
pub(all) struct ClassNode {
  id : String
  generic_type : String
  mut label : String
  mut css_classes : String
  methods : Array[ClassMember]
  members : Array[ClassMember]
  annotations : Array[String]
  styles : Array[String]
  mut parent : String?
  mut link : String?
  mut link_target : String?
  mut have_callback : Bool
  mut tooltip : String?
}

///|
/// The ends and line of a relation.
/// An end is one of Mermaid's relation types, or `None` where it has no marker.
pub(all) struct RelationKind {
  type1 : Int32?
  type2 : Int32?
  line_type : Int32
}

///|
/// A relation between two classes, with the text at each end and along it.
pub(all) struct ClassRelation {
  mut id1 : String
  mut id2 : String
  mut relation_title1 : String
  mut relation_title2 : String
  title : String?
  relation : RelationKind
}

///|
/// A note, on its own or about the class `class_id`.
pub(all) struct ClassNote {
  id : String
  class_id : String?
  text : String
  index : Int32
  mut parent : String?
}

///|
/// The interface at the lollipop end of a relation, drawn as a ring beside its class.
pub(all) struct ClassInterface {
  id : String
  label : String
  class_id : String
}

///|
/// A namespace and what it holds.
pub(all) struct NamespaceNode {
  id : String
  mut label : String
  classes : Map[String, ClassNode]
  notes : Map[String, ClassNote]
  children : Map[String, NamespaceNode]
  mut parent : String?
  /// False for the ancestors created on the way to a dotted name such as `A.B.C`.
  mut explicit : Bool
}

///|
/// The declarations of a `classDef`.
pub(all) struct StyleClass {
  id : String
  styles : Array[String]
  text_styles : Array[String]
}
