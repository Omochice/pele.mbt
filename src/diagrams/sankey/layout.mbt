///|
/// Which column a node takes when it does not simply follow its distance from a source.
pub(all) enum Alignment {
  Justify
  Left
  Right
  Center
}

///|
pub(all) struct LayoutOptions {
  width : Double
  height : Double
  node_width : Double
  node_padding : Double
  /// Height of a label line; thin nodes are kept at least this far apart where there is room.
  label_height : Double
  alignment : Alignment
}

///|
pub(all) struct PlacedNode {
  layer : Int32
  /// Total flow through the node, in the diagram's units.
  value : Double
  x : Double
  mut y : Double
  mut height : Double
}

///|
pub(all) struct PlacedLink {
  source : Int32
  target : Int32
  value : Double
  mut thickness : Double
  /// Vertical centers of the band where it leaves its source and where it enters its target.
  mut source_y : Double
  mut target_y : Double
}

///|
pub(all) struct SankeyLayout {
  nodes : Array[PlacedNode]
  links : Array[PlacedLink]
}

///|
/// Places nodes in columns by their distance from a source, sizes them by their flow, and
/// then lets each column settle next to its neighbours so that the bands cross less.
/// Raises a semantic `PeleError` when the links form a cycle.
pub fn layout_sankey(
  db : SankeyDb,
  options : LayoutOptions,
) -> SankeyLayout raise @errors.PeleError {
  ignore(db)
  ignore(options)
  raise @errors.pele_error("not implemented")
}
