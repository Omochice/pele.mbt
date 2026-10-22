///|
/// Where an edge crosses the border of the group that `inner` belongs to.
priv struct PortEdge {
  e : Int32
  inner : Int32
  out : Bool
  mut side : Int32
  /// Cross-flow position outside the group from a previous layout; NaN if unknown.
  hint : Double
  mut px : Double
  mut py : Double
  mut route : Array[Double]
}

///|
/// An edge laid out in a level, between the two items of that level that hold its ends.
priv struct LevelEdge {
  e : Int32
  a : Int32
  b : Int32
}

///|
/// The top level or one group: the items laid out together as one flat graph.
priv struct Level {
  id : Int32
  dir : Dir
  mut items : Array[Int32]
  edges : Array[LevelEdge]
  ports : Array[PortEdge]
  port_of : Map[Int32, PortEdge]
  routes : Map[Int32, Array[Double]]
  mut x : Double
  mut y : Double
}

///|
let side_top = 0

///|
let side_right = 1

///|
let side_bottom = 2

///|
let side_left = 3

///|
fn start_side(dir : Dir) -> Int32 {
  match dir {
    TB => side_top
    BT => side_bottom
    LR => side_left
    RL => side_right
  }
}

///|
fn opposite(side : Int32) -> Int32 {
  (side + 2) & 3
}

///|
fn is_vertical(dir : Dir) -> Bool {
  dir is (TB | BT)
}
