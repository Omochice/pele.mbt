///|
/// A `$key="value"` argument.
pub(all) struct C4Named {
  key : String
  value : String
}

///|
/// An argument of a statement: positional text, or a named argument.
pub(all) enum C4Attr {
  Text(String)
  Named(C4Named)
}

///|
/// A shape or a boundary.
/// pele keeps both in one interface too, since style updates and relations reach either by alias.
pub(all) struct C4Element {
  mut alias_ : String
  mut label : String
  /// A named argument written where the alias or the label belongs; it is applied to the field it names.
  mut alias_attr : C4Named?
  mut label_attr : C4Named?
  mut parent : C4Element?
  mut type_ : String?
  mut descr : String?
  mut techn : String?
  mut sprite : String?
  mut tags : String?
  mut link : String?
  mut bg_color : String?
  mut font_color : String?
  mut border_color : String?
  mut shadowing : String?
  mut shape : String?
  mut legend_text : String?
  mut legend_sprite : String?
  /// Named arguments that set no known field, in the order they were first given.
  mut extra : Map[String, String]?
  /// Mermaid's typeC4Shape for a shape, such as person or external_system_db; empty for a boundary.
  mut kind : String
  /// Set on deployment nodes: node, nodeL or nodeR.
  mut node_type : String?
}

///|
/// A relation between two shapes or boundaries.
pub(all) struct C4Rel {
  mut type_ : String
  mut from : String
  mut to : String
  mut label : String
  mut from_attr : C4Named?
  mut to_attr : C4Named?
  mut label_attr : C4Named?
  mut techn : String?
  mut descr : String?
  mut sprite : String?
  mut tags : String?
  mut link : String?
  mut text_color : String?
  mut line_color : String?
  /// What `parseInt` made of the offset, NaN included.
  mut offset_x : Double?
  mut offset_y : Double?
  mut extra : Map[String, String]?
}
