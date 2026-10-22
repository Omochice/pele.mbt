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
