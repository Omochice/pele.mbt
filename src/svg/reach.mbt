///|
/// How far an edge runs straight before a marker at its end, where it has the room.
pub const LEAD : Double = 6

///|
/// How far from each side of each node the edges that meet it start to turn: as far as the largest marker there needs, for every edge on the side, so that none turns sooner than its neighbour and crosses it.
pub struct SideReach {
  priv reach : Map[Int32, Double]
}

///|
/// A reach that has seen no markers yet.
pub fn SideReach::new() -> SideReach {
  { reach: {}, }
}

///|
/// Records an end of an edge on `side` of `node` that carries a marker of Mermaid's `type_`.
/// A negative side is no side of the node and is not recorded.
pub fn SideReach::add(
  self : SideReach,
  node : Int32,
  side : Int32,
  type_ : String,
) -> Unit {
  let trim = marker_trim(type_)
  let key = node * 4 + side
  if side >= 0 && trim > 0 && trim + LEAD > self.reach.get(key).unwrap_or(0) {
    self.reach[key] = trim + LEAD
  }
}

///|
/// How far from `side` of `node` its edges start to turn.
pub fn SideReach::of(self : SideReach, node : Int32, side : Int32) -> Double {
  if side >= 0 {
    self.reach.get(node * 4 + side).unwrap_or(0)
  } else {
    0
  }
}
