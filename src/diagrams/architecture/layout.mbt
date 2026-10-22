// Grid placement. Mermaid hands the edge sides to a force-directed solver as relative placement
// constraints. Pele applies them directly: every service and junction takes a cell, an edge
// `a:R -- L:b` puts b in the cell to the right of a, and a group is a solid rectangle of cells, so a
// group never encloses a node that is not in it. Each container (the diagram, then every group) is
// laid out on its own, innermost first, and a finished group is placed in its parent as one block.

///|
/// Cells of the nodes and groups, in the order they were passed in.
/// A parent is a group's index, or -1 for the diagram itself.
pub(all) struct Grid {
  col : Array[Int32]
  row : Array[Int32]
  group_col : Array[Int32]
  group_row : Array[Int32]
  /// The size of each group in cells. A group with nothing in it takes one cell.
  group_cols : Array[Int32]
  group_rows : Array[Int32]
  group_parent : Array[Int32]
  group_empty : Array[Bool]
  node_parent : Array[Int32]
}

///|
/// Places every node and group on a grid of cells, following the sides that edges and
/// alignments name.
pub fn place_on_grid(
  nodes : Array[ArchNode],
  groups : Array[ArchGroup],
  edges : Array[ArchEdge],
  hints : Array[ArchLayoutHint],
) -> Grid {
  ignore((nodes, groups, edges, hints))
  {
    col: [],
    row: [],
    group_col: [],
    group_row: [],
    group_cols: [],
    group_rows: [],
    group_parent: [],
    group_empty: [],
    node_parent: [],
  }
}
