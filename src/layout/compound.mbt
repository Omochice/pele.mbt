///|
/// The way a diagram's ranks run.
pub(all) enum Dir {
  TB
  BT
  LR
  RL
}

///|
/// A node or group of a graph whose nodes may be nested in groups.
pub(all) struct CNode {
  mut w : Double
  mut h : Double
  mut parent : Int32
  mut is_group : Bool
  mut dir : Dir?
  mut pad_x : Double
  mut pad_top : Double
  mut pad_bottom : Double
  mut min_w : Double
  /// Declaration order; a group takes the smallest value among its members.
  mut seq : Double
  /// How much of a side its edges may spread along, measured across the flow; 0 keeps them at its middle.
  mut span : Double
  mut x : Double
  mut y : Double
}

///|
/// An edge of a compound graph, and where the layout routes it.
pub(all) struct CEdge {
  mut src : Int32
  mut dst : Int32
  minlen : Int32
  label_w : Double
  label_h : Double
  /// x, y, axis triples; axis is 0 where the edge runs vertically into the point, 1 horizontally.
  mut route : Array[Double]
  mut label_x : Double
  mut label_y : Double
}

///|
/// A node of the given size, in `parent` or at the top level for -1.
pub fn cnode(w : Double, h : Double, parent~ : Int32 = -1) -> CNode {
  {
    w,
    h,
    parent,
    is_group: false,
    dir: None,
    pad_x: 0,
    pad_top: 0,
    pad_bottom: 0,
    min_w: 0,
    seq: 0,
    span: 0,
    x: 0,
    y: 0,
  }
}
