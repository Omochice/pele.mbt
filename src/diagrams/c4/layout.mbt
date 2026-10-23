///|
/// A laid out shape.
pub(all) struct Node {
  box : Box
  shape : C4Element
  /// Type, name, technology, description.
  labels : Array[@text.Label]
  text_h : Double
}

///|
/// A laid out boundary.
pub(all) struct Group {
  box : Box
  boundary : C4Element
  kids : Array[Group]
  nodes : Array[Node]
  /// Name, type, description.
  labels : Array[@text.Label]
  head : Double
  head_w : Double
  mut head_x : Double
}

///|
/// Where everything is drawn.
pub(all) struct Layout {
  /// The boundaries that are drawn, parents before children. The first is the unnamed top level.
  order : Array[Group]
  /// The box of each element that is drawn, by element id.
  boxes : Map[Int32, Box]
}

///|

///|
/// Mermaid's grid: in each boundary, its shapes in rows of c4ShapeInRow, then the boundaries inside it in rows of
/// c4BoundaryInRow, each sized around its own content.
pub fn layout_c4(
  db : C4Db,
  measurer : @text.TextMeasurer,
  size : Double,
  small : Double,
  room : Double?,
  gap : Double,
) -> Layout {
  ignore((db, measurer, size, small, room, gap))
  { order: [], boxes: Map([]), }
}
