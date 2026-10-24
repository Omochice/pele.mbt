///|
/// Start and end offsets in the source, end exclusive.
type Span = (Int32, Int32)

///|
priv struct DraftLabel {
  text : String
  label_type : String
}

///|
priv enum PropertyValue {
  Text(String)
  Flag(Bool)
}

///|
/// A property of a metadata block; `key_span` is also where an error about it points.
priv struct DraftProperty {
  key : String
  value : PropertyValue
  key_span : Span
}

///|
priv struct DraftBoundary {
  id : String
  label : DraftLabel
  span : Span
  generated : Bool
  classes : Array[String]
}

///|
/// A mention that declares an actor or use case, with what it says about it.
priv struct DraftElement {
  id : String
  kind : String
  label : DraftLabel
  span : Span
  generated : Bool
  parent : DraftBoundary?
  shape : String?
  metadata : Array[DraftProperty]?
  stereotype : String?
  classes : Array[String]
}

///|
priv struct DraftJson {
  id : String
  mut value : Map[String, Json]
  span : Span
  classes : Array[String]
}

///|
/// An end of a relationship: whether this mention declares the element, and whether it carries a
/// `:::` suffix.
priv struct DraftEndpoint {
  id : String
  label : DraftLabel
  span : Span
  generated : Bool
  declares : Bool
  classed : Bool
}

///|
priv struct DraftRelationship {
  source : DraftEndpoint
  target : DraftEndpoint
  span : Span
  id : String?
  id_span : Span?
  rel_type : String
  arrow_type : Int32
  label : DraftLabel?
  minlen : Int32
}

///|
priv struct DraftNote {
  target : String
  span : Span
  label : DraftLabel
}

///|
priv struct DraftMetadata {
  target : String
  span : Span
  properties : Array[DraftProperty]
}

///|
priv struct DraftClassAssignment {
  targets : Array[(String, Span)]
  classes : Array[String]
}

///|
priv struct DraftStyle {
  target : String
  span : Span
  styles : Array[String]
}

///|
priv struct DraftClassDef {
  ids : Array[String]
  styles : Array[String]
}

///|
/// Everything the parser read, in source order, before any of it is resolved.
priv struct Drafts {
  elements : Array[DraftElement]
  boundaries : Array[DraftBoundary]
  jsons : Array[DraftJson]
  relationships : Array[DraftRelationship]
  notes : Array[DraftNote]
  metadata : Array[DraftMetadata]
  classes : Array[DraftClassAssignment]
  styles : Array[DraftStyle]
  class_defs : Array[DraftClassDef]
  mut direction : String?
  mut acc_title : String
  mut acc_description : String
}

///|
fn empty_drafts() -> Drafts {
  {
    elements: [],
    boundaries: [],
    jsons: [],
    relationships: [],
    notes: [],
    metadata: [],
    classes: [],
    styles: [],
    class_defs: [],
    direction: None,
    acc_title: "",
    acc_description: "",
  }
}
