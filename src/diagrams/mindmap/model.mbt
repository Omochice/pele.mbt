///|
/// A node of a mindmap.
pub(all) struct MindmapNode {
  id : Int32
  node_id : String
  /// The indentation relative to the root's.
  level : Int32
  descr : String
  /// Mermaid's node type: 0 for none, then rounded, rect, circle, cloud, bang and hexagon.
  node_type : Int32
  children : Array[MindmapNode]
  is_root : Bool
  /// The index of the first-level branch the node belongs to, wrapping after eleven as in Mermaid.
  mut section : Int32?
  mut class_ : String?
  mut icon : String?
}

///|
/// A mindmap ready to be drawn.
pub(all) struct MindmapModel {
  title : String?
  /// In source order, which is depth-first. The first node is the root.
  nodes : Array[MindmapNode]
}

///|
/// The database the outline parser fills.
pub struct MindmapDb {
  nodes : Array[MindmapNode]
  base_level : Int32
  open : Array[MindmapNode]
}

///|
pub fn MindmapDb::new() -> MindmapDb {
  { nodes: [], base_level: 0, open: [], }
}

///|
impl @common.OutlineDb for MindmapDb with fn add_node(
  self,
  level,
  id,
  descr,
  node_type,
  _,
) {
  ignore((self, level, id, descr, node_type))
}

///|
impl @common.OutlineDb for MindmapDb with fn decorate_node(self, decoration) {
  ignore((self, decoration))
}
