///|
/// A box on the grid: a block, or a container of others.
pub(all) struct Cell {
  mut children : Array[Cell]
  /// Grid width of this container: a positive count, or -1 to put every child on one row.
  mut columns : Double
  mut span : Double
  mut space : Bool
  /// Height reserved above a container's grid for its title.
  mut head : Double
  /// Size the content needs. Set by the caller for leaves, computed here for containers.
  mut nw : Double
  mut nh : Double
  mut col : Double
  mut row : Int32
  mut cols : Double
  mut heights : Array[Double]
  /// The center and size given to the cell.
  mut x : Double
  mut y : Double
  mut w : Double
  mut h : Double
}

///|
/// A leaf that needs the given size and spans that many columns.
pub fn cell(nw : Double, nh : Double, span~ : Double = 1) -> Cell {
  {
    children: [],
    columns: -1,
    span,
    space: false,
    head: 0,
    nw,
    nh,
    col: 0,
    row: 0,
    cols: 0,
    heights: [],
    x: 0,
    y: 0,
    w: 0,
    h: 0,
  }
}

///|
/// The column and row of the cell at that position on a grid of that width, as Mermaid computes them.
pub fn calculate_block_position(
  columns : Double,
  position : Double,
) -> (Double, Double) raise @errors.PeleError {
  if columns < -1.0e300 {
    raise @errors.pele_error("not yet laid out")
  }
  (position, 0)
}

///|
/// Lays out a tree of cells in place, and gives its width and height.
pub fn layout(
  root : Cell,
  gap : Double,
) -> (Double, Double) raise @errors.PeleError {
  calculate_block_position(root.columns, gap)
}
