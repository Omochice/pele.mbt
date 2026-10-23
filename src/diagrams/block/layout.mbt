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
  /// Size the content needs.
  /// Set by the caller for leaves, computed here for containers.
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
/// Raises a semantic error for a column count that is zero or not an integer, or a position that is not a count.
pub fn calculate_block_position(
  columns : Double,
  position : Double,
) -> (Double, Double) raise @errors.PeleError {
  if columns == 0 || !is_integer(columns) {
    raise @errors.pele_error(
      "Columns must be an integer !== 0.",
      code=Semantic,
      kind="block",
    )
  }
  if position < 0 || !is_integer(position) {
    raise @errors.pele_error(
      "Position must be a non-negative integer.\{position}",
      code=Semantic,
      kind="block",
    )
  }
  if columns < 0 {
    return (position, 0)
  }
  (position % columns, (position / columns).floor())
}

///|
/// JavaScript's `Number.isInteger`.
fn is_integer(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf() && value.floor() == value
}

///|
const MAX_SPAN : Double = 1000

///|
/// Puts each child in its grid cell and sizes the container.
/// Every column is as wide as the widest block needs.
/// Every row that holds a plain block is as tall as the tallest block in the container, as in Mermaid; a row of nothing but containers is only as tall as they need.
fn measure(
  box : Cell,
  gap : Double,
  inset : Double,
) -> Unit raise @errors.PeleError {
  let columns = box.columns
  let heights : Array[Double] = []
  let mut position = 0.0
  let mut cols = 0.0
  let mut cw = 0.0
  let mut tallest = 0.0
  for child in box.children {
    let (px, py) = calculate_block_position(columns, position)
    // Mermaid lets a block wider than the rest of its row stick out of the grid.
    // Here it stops at the last column.
    let mut span = if child.span >= 1 {
      @util.js_min(child.span, MAX_SPAN)
    } else {
      1
    }
    if columns > 0 && span > columns - px {
      span = columns - px
    }
    child.span = span
    child.col = px
    let row = py.to_int()
    child.row = row
    position += span
    if px + span > cols {
      cols = px + span
    }
    if row == heights.length() {
      heights.push(0)
    }
    if child.children.length() == 0 {
      heights[row] = -1
    } else if heights[row] >= 0 && child.nh > heights[row] {
      heights[row] = child.nh
    }
    if child.space {
      continue
    }
    let width = (child.nw - gap * (span - 1)) / span
    if width > cw {
      cw = width
    }
    if child.nh > tallest {
      tallest = child.nh
    }
  }
  let mut height = (heights.length() - 1).to_double() * gap
  for row in 0..<heights.length() {
    if heights[row] < 0 {
      heights[row] = tallest
    }
    height += heights[row]
  }
  box.cols = cols
  box.heights = heights
  box.nw = @util.js_max(box.nw, cols * cw + (cols - 1) * gap + 2 * inset)
  box.nh = height + 2 * inset + box.head
}

///|
/// Gives each child its cell, sharing out any room the container has beyond what it needs.
fn arrange(box : Cell, gap : Double, inset : Double) -> Unit {
  let cols = box.cols
  let heights = box.heights
  let rows = heights.length().to_double()
  let cw = (box.w - 2 * inset - (cols - 1) * gap) / cols
  let room = box.h - 2 * inset - box.head - (rows - 1) * gap
  let mut needed = 0.0
  for height in heights {
    needed += height
  }
  let scale : Double = if needed > 0 { room / needed } else { 0 }
  let share : Double = if needed > 0 { 0 } else { room / rows }
  let left = box.x - box.w / 2 + inset
  let mut top = box.y - box.h / 2 + inset + box.head
  let mut row = 0
  for child in box.children {
    while row < child.row {
      top += heights[row] * scale + share + gap
      row += 1
    }
    child.w = cw * child.span + gap * (child.span - 1)
    child.h = heights[row] * scale + share
    child.x = left + child.col * (cw + gap) + child.w / 2
    child.y = top + child.h / 2
  }
}

///|
/// Lays out a tree of cells in place, and gives its width and height.
/// The root has no border, so its grid starts at the origin.
/// Raises the error of `calculate_block_position` for a container whose column count is zero or not an integer.
pub fn layout(
  root : Cell,
  gap : Double,
) -> (Double, Double) raise @errors.PeleError {
  let order = [root]
  let mut i = 0
  while i < order.length() {
    order.append(order[i].children)
    i += 1
  }
  for j = order.length() - 1; j >= 0; j = j - 1 {
    let box = order[j]
    if box.children.length() > 0 {
      measure(box, gap, if j == 0 { 0 } else { gap })
    }
  }
  root.w = root.nw
  root.h = root.nh
  root.x = root.w / 2
  root.y = root.h / 2
  for j, box in order {
    if box.children.length() > 0 {
      arrange(box, gap, if j == 0 { 0 } else { gap })
    }
  }
  (root.w, root.h)
}
