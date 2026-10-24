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
  mut base_level : Int32
  /// The chain of nodes that can still take children, with strictly increasing levels.
  open : Array[MindmapNode]
}

///|
pub fn MindmapDb::new() -> MindmapDb {
  { nodes: [], base_level: 0, open: [], }
}

///|
const SECTIONS : Int32 = 11

///|
impl @common.OutlineDb for MindmapDb with fn add_node(
  self,
  level,
  id,
  descr,
  node_type,
  _,
) {
  let is_root = self.nodes.is_empty()
  if is_root {
    self.base_level = level
  }
  let level = level - self.base_level
  // Mermaid's parent is the last node with a smaller indentation, wherever it is in the tree.
  let open = self.open
  let mut depth = open.length()
  while depth > 0 && open[depth - 1].level >= level {
    depth -= 1
  }
  let parent = if depth > 0 { Some(open[depth - 1]) } else { None }
  if parent is None && !is_root {
    raise @errors.pele_error(
      "There can be only one root. No parent could be found for (\"\{descr}\")",
      code=Semantic,
      kind="mindmap",
    )
  }
  let node = {
    id: self.nodes.length(),
    node_id: id,
    level,
    descr,
    node_type,
    children: [],
    is_root,
    section: None,
    class_: None,
    icon: None,
  }
  if parent is Some(parent) {
    node.section = if parent.is_root {
      Some(parent.children.length() % SECTIONS)
    } else {
      parent.section
    }
    parent.children.push(node)
  }
  open.truncate(depth)
  open.push(node)
  self.nodes.push(node)
}

///|
impl @common.OutlineDb for MindmapDb with fn decorate_node(self, decoration) {
  // Mermaid throws a TypeError when a decoration comes before any node.
  // Here it is ignored.
  guard self.nodes.last() is Some(node) else { return }
  match decoration {
    Icon(icon) => if icon != "" { node.icon = Some(icon) }
    Class(class_) => if class_ != "" { node.class_ = Some(class_) }
  }
}
