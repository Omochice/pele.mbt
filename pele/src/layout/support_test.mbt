///|
fn edge(
  src : Int32,
  dst : Int32,
  label_w~ : Double = 0,
  label_h~ : Double = 0,
) -> @layout.CEdge {
  { src, dst, minlen: 1, label_w, label_h, route: [], label_x: 0, label_y: 0, }
}

///|
/// The spacing pele's compound layout tests use.
fn options(
  tracks~ : Bool = false,
  head_room~ : Double = 0,
) -> @layout.LayeredOptions {
  @layout.LayeredOptions::new(
    node_sep=40,
    edge_sep=16,
    rank_sep=48,
    port_sep=20,
    tracks~,
    head_room~,
  )
}

///|
let dirs : Array[@layout.Dir] = [TB, BT, LR, RL]

///|
fn nodes_in_order(sizes : Array[(Double, Double)]) -> Array[@layout.CNode] {
  sizes.mapi((i, size) => {
    let node = @layout.cnode(size.0, size.1)
    node.seq = i.to_double()
    node
  })
}

///|
fn on_border(node : @layout.CNode, x : Double, y : Double) -> Bool {
  let dx = (x - node.x).abs()
  let dy = (y - node.y).abs()
  let inside = dx <= node.w / 2 + 0.5 && dy <= node.h / 2 + 0.5
  let edge_x = (dx - node.w / 2).abs() <= 0.5
  let edge_y = (dy - node.h / 2).abs() <= 0.5
  inside && (edge_x || edge_y)
}

///|
/// Pele's seeded random numbers for its test corpus, a linear congruential generator in 32 bits.
fn random(seed : Int32) -> () -> Double {
  let mut state = seed.reinterpret_as_uint()
  () => {
    state = state * 1664525U + 1013904223U
    state.to_double() / 4294967296.0
  }
}

///|
fn near(actual : Double, expected : Double) -> Bool {
  (actual - expected).abs() < 5.0e-6
}
