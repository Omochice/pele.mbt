///|
/// A node placed in the treemap.
pub(all) struct Box {
  node : TreemapNode
  parent : Box?
  /// The position among the top-level nodes of the branch the box belongs to, which picks its color.
  series : Int32
  /// A leaf's own value, or the sum of the leaves under a section.
  mut value : Double
  children : Array[Box]
  mut x : Double
  mut y : Double
  mut w : Double
  mut h : Double
}

///|
/// The space between boxes, and the space a section keeps for its header and around its children.
pub(all) struct Insets {
  gap : Double
  header : Double
  side : Double
}

///|
/// Places the nodes that have a positive value as a squarified treemap in `width` by `height`.
/// Returns every placed box with its size, parents before their children.
pub fn layout_treemap(
  roots : Array[TreemapNode],
  width : Double,
  height : Double,
  insets : Insets,
) -> Array[Box] {
  ignore((roots, width, height, insets))
  []
}
