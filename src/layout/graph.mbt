///|
/// The graph that gets ordered and positioned: every edge cut into rank-to-rank segments, and a bend for each rank an edge passes.
priv struct Graph {
  n : Int32
  real : Int32
  max_rank : Int32
  w : FixedArray[Double]
  kind : FixedArray[Kind]
  /// Segment endpoints, and where each segment attaches on them.
  ef : FixedArray[Int32]
  et : FixedArray[Int32]
  efd : FixedArray[Double]
  etd : FixedArray[Double]
  succ_start : FixedArray[Int32]
  succ_e : FixedArray[Int32]
  pred_start : FixedArray[Int32]
  pred_e : FixedArray[Int32]
  layer_start : FixedArray[Int32]
  order : FixedArray[Int32]
  pos : FixedArray[Int32]
  offsets : Bool
  /// Ranks whose order must remain fixed.
  fixed : FixedArray[Bool]
  grp : FixedArray[Int32]?
  group_parent : Array[Int32]?
}

///|
/// What the end of a segment is to the node it meets, for the ends that may move along the node's side.
let end_held = 0

///|
let end_leaves = 1

///|
let end_arrives = 2

///|
fn is_dummy(kind : Kind) -> Bool {
  kind is (Dummy | Label)
}
