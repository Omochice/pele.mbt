///|
/// What a node is drawn as.
pub(all) enum NodeShape {
  Rect
  ClassBox
  NoteBox
  InterfaceRing
}

///|
/// The name pele gives the shape.
pub fn NodeShape::name(self : NodeShape) -> String {
  match self {
    Rect => "rect"
    ClassBox => "classBox"
    NoteBox => "note"
    InterfaceRing => "interface"
  }
}

///|
/// A namespace, class, note or interface as it is drawn.
pub(all) struct GraphNode {
  id : String
  label : String
  is_group : Bool
  shape : NodeShape
  parent_id : String?
  /// Index of the namespace node this one is drawn in, or -1.
  mut parent : Int32
  class_node : ClassNode?
  /// Position among the classes, in declaration order. Namespaces and notes have none.
  color_index : Int32?
}

///|
/// A relation, or the line from a note to its class, as it is drawn.
pub(all) struct GraphEdge {
  id : String
  start : String
  end : String
  /// Indexes into the node list. Ids alone are ambiguous: a class may be named `note0` or `interface0`.
  source : Int32
  target : Int32
  label : String?
  arrow_type_start : String
  arrow_type_end : String
  start_label_right : String
  end_label_left : String
  pattern : String
  classes : String
}

///|
/// The nodes and edges of a class diagram.
pub(all) struct ClassGraph {
  nodes : Array[GraphNode]
  edges : Array[GraphEdge]
}

///|
/// Resolves a parsed class diagram into the nodes and edges that are drawn.
/// With `hierarchical` off, only namespaces the source declares are kept and each is labeled with its full name.
pub fn build_class_graph(
  model : ClassDb,
  hierarchical~ : Bool = true,
) -> ClassGraph {
  ignore((model, hierarchical))
  { nodes: [], edges: [], }
}
