///|
/// What a node of a layered graph stands for.
pub(all) enum Kind {
  Node
  Dummy
  Label
  StartPort
  EndPort
}

///|
/// A node of one flat graph, and where the layout puts it.
pub(all) struct LNode {
  mut w : Double
  mut h : Double
  mut kind : Kind
  mut pin : Int32
  /// Port's cross-flow destination; NaN if unknown. Fully hinted port ranks keep this order.
  mut hint : Double
  /// Initial cross-flow position; NaN if unknown. Used only when every node in a rank has one.
  mut key : Double
  /// How much of the side that edges meet may be shared out between them; 0 keeps them all at its middle.
  mut span : Double
  mut x : Double
  mut y : Double
  mut rank : Int32
}

///|
/// An edge of one flat graph, and how the layout routes it.
pub(all) struct LEdge {
  mut tail : Int32
  mut head : Int32
  mut minlen : Int32
  mut label_w : Double
  mut label_h : Double
  mut tail_dx : Double
  mut head_dx : Double
  /// An end that is held where its offset puts it, and takes no part in sharing out a node's side.
  mut tail_fixed : Bool
  mut head_fixed : Bool
  mut reversed : Bool
  mut points : Array[Double]
  mut label_x : Double
  mut label_y : Double
}

///|
/// Groups that keep their nodes contiguous within ranks.
/// `of` maps nodes to groups and `parent` maps groups to parents, with -1 for none.
pub(all) struct LayeredGroups {
  of : Array[Int32]
  parent : Array[Int32]
}

///|
/// How a layered graph is spaced and routed.
pub(all) struct LayeredOptions {
  node_sep : Double
  edge_sep : Double
  rank_sep : Double
  port_sep : Double
  /// Route edges at right angles, each on a track of its own across the gap between two ranks.
  tracks : Bool
  /// Draw every edge straight from point to point: none is given a level to turn onto.
  straight : Bool
  /// The caller sets the ends of the edges on one side of a node apart itself, so two edges between the same two nodes need no bend to keep them from being drawn as one.
  apart : Bool
  /// The room that the marker at the head of an edge takes.
  /// A rank of labels whose edges all head the same way sits half of this nearer their tails.
  head_room : Double
  groups : LayeredGroups?
  /// Compute cross-flow positions in `x` without full routing.
  order_only : Bool
}

///|
/// Options with the given spacing and every other choice off.
pub fn LayeredOptions::new(
  node_sep~ : Double,
  edge_sep~ : Double,
  rank_sep~ : Double,
  port_sep~ : Double,
  tracks~ : Bool = false,
  straight~ : Bool = false,
  apart~ : Bool = false,
  head_room~ : Double = 0,
  groups? : LayeredGroups,
  order_only~ : Bool = false,
) -> LayeredOptions {
  {
    node_sep,
    edge_sep,
    rank_sep,
    port_sep,
    tracks,
    straight,
    apart,
    head_room,
    groups,
    order_only,
  }
}

///|
/// The size of a laid out graph.
/// With `order_only`, also the final crossings and those before grouping or reordering.
pub(all) struct LayeredResult {
  width : Double
  height : Double
  crossings : Int32
  declared : Int32
}

///|
/// A node of the given size.
pub fn lnode(w : Double, h : Double, kind~ : Kind = Node) -> LNode {
  {
    w,
    h,
    kind,
    pin: 0,
    hint: @double.not_a_number,
    key: @double.not_a_number,
    span: 0,
    x: 0,
    y: 0,
    rank: 0,
  }
}

///|
/// An edge from `tail` to `head`.
pub fn ledge(
  tail : Int32,
  head : Int32,
  minlen~ : Int32 = 1,
  label_w~ : Double = 0,
  label_h~ : Double = 0,
) -> LEdge {
  {
    tail,
    head,
    minlen,
    label_w,
    label_h,
    tail_dx: 0,
    head_dx: 0,
    tail_fixed: false,
    head_fixed: false,
    reversed: false,
    points: [],
    label_x: 0,
    label_y: 0,
  }
}

///|
/// Lays out one flat graph in ranks down the y axis, Sugiyama style, writing positions into `nodes` and routes into `edges`.
/// Callers rotate the result for other directions.
pub fn layered(
  nodes : Array[LNode],
  edges : Array[LEdge],
  opt : LayeredOptions,
) -> LayeredResult {
  ignore(nodes)
  ignore(edges)
  ignore(opt)
  { width: 0, height: 0, crossings: 0, declared: 0, }
}
