///|
/// Where an edge crosses the border of the group that `inner` belongs to.
priv struct PortEdge {
  e : Int32
  inner : Int32
  out : Bool
  mut side : Int32
  /// Cross-flow position outside the group from a previous layout; NaN if unknown.
  mut hint : Double
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

///|
fn same_dir(a : Dir, b : Dir) -> Bool {
  match (a, b) {
    (TB, TB) | (BT, BT) | (LR, LR) | (RL, RL) => true
    _ => false
  }
}

///|
/// Everything a layout attempt writes, so that a worse attempt can be undone.
priv struct Snapshot {
  nodes : Array[Double]
  routes : Array[Array[Double]]
  labels : Array[Double]
  levels : Array[Double]
  total : CompoundResult
}

///|
fn Snapshot::take(
  nodes : Array[CNode],
  edges : Array[CEdge],
  levels : Array[Level],
  total : CompoundResult,
) -> Snapshot {
  let at = []
  for c in nodes {
    at.push(c.x)
    at.push(c.y)
    at.push(c.w)
    at.push(c.h)
  }
  let labels = []
  for e in edges {
    labels.push(e.label_x)
    labels.push(e.label_y)
  }
  let places = []
  for level in levels {
    places.push(level.x)
    places.push(level.y)
    for port in level.ports {
      places.push(port.px)
      places.push(port.py)
    }
  }
  { nodes: at, routes: edges.map(e => e.route), labels, levels: places, total, }
}

///|
fn Snapshot::restore(
  self : Snapshot,
  nodes : Array[CNode],
  edges : Array[CEdge],
  levels : Array[Level],
) -> CompoundResult {
  for i, c in nodes {
    c.x = self.nodes[4 * i]
    c.y = self.nodes[4 * i + 1]
    c.w = self.nodes[4 * i + 2]
    c.h = self.nodes[4 * i + 3]
  }
  for i, e in edges {
    e.route = self.routes[i]
    e.label_x = self.labels[2 * i]
    e.label_y = self.labels[2 * i + 1]
  }
  let mut k = 0
  for level in levels {
    level.x = self.levels[k]
    level.y = self.levels[k + 1]
    k += 2
    for port in level.ports {
      port.px = self.levels[k]
      port.py = self.levels[k + 1]
      k += 2
    }
  }
  self.total
}
