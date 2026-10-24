// Ported from pele v1.8.0, tests/compat/block/layout.spec.ts; the other layouts were printed from pele's layout given the same cells.

///|
fn grid(
  columns : Double,
  children : Array[@block.Cell],
  head~ : Double = 0,
  span~ : Double = 1,
  nw~ : Double = 0,
  nh~ : Double = 0,
) -> @block.Cell {
  let made = @block.cell(nw, nh, span~)
  made.columns = columns
  made.children = children
  made.head = head
  made
}

///|
fn gap_cell(span~ : Double = 1) -> @block.Cell {
  let made = @block.cell(0, 0, span~)
  made.space = true
  made
}

///|
fn laid_out(root : @block.Cell, gap : Double) -> String raise {
  let (width, height) = @block.layout(root, gap)
  let out = ["size \{width} \{height}"]
  fn walk(c : @block.Cell, depth : Int32) {
    out.push(
      "\{"  ".repeat(depth)}\{c.x},\{c.y} \{c.w}x\{c.h} at \{c.col},\{c.row} span \{c.span} need \{c.nw}x\{c.nh}",
    )
    for k in c.children {
      walk(k, depth + 1)
    }
  }

  walk(root, 0)
  out.join("\n")
}

///|
fn position_of(columns : Double, position : Double) -> String {
  try @block.calculate_block_position(columns, position) catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()} \{failure.message}"
  } noraise {
    (px, py) => "\{px},\{py}"
  }
}

///|
test "should calculate position correctly" {
  assert_eq(position_of(2, 0), "0,0")
  assert_eq(position_of(2, 1), "1,0")
  assert_eq(position_of(2, 2), "0,1")
  assert_eq(position_of(2, 3), "1,1")
  assert_eq(position_of(2, 4), "0,2")
  assert_eq(position_of(1, 3), "0,3")
  assert_eq(position_of(-1, 7), "7,0")
  assert_eq(position_of(1.0e20, 5), "5,0")
}

///|
test "refuses a column count that is zero or not an integer, and a position that is not a count" {
  assert_eq(position_of(0, 1), "semantic Columns must be an integer !== 0.")
  assert_eq(position_of(1.5, 1), "semantic Columns must be an integer !== 0.")
  assert_eq(
    position_of(1.0 / 0.0, 1),
    "semantic Columns must be an integer !== 0.",
  )
  assert_eq(
    position_of(2, -1),
    "semantic Position must be a non-negative integer.-1",
  )
  assert_eq(
    position_of(2, 0.5),
    "semantic Position must be a non-negative integer.0.5",
  )
}

///|
test "should read the gap it is given" {
  let two = () => grid(2, [@block.cell(100, 50), @block.cell(100, 50)])
  assert_eq(
    laid_out(two(), 4),
    (
      #|size 204 50
      #|102,25 204x50 at 0,0 span 1 need 204x50
      #|  50,25 100x50 at 0,0 span 1 need 100x50
      #|  154,25 100x50 at 1,0 span 1 need 100x50
    ),
  )
  assert_eq(
    laid_out(two(), 20),
    (
      #|size 220 50
      #|110,25 220x50 at 0,0 span 1 need 220x50
      #|  50,25 100x50 at 0,0 span 1 need 100x50
      #|  170,25 100x50 at 1,0 span 1 need 100x50
    ),
  )
}

///|
test "puts every block on one row without a column count, each as wide and tall as the largest" {
  assert_eq(
    laid_out(
      grid(-1, [@block.cell(30, 40), @block.cell(55.5, 20), @block.cell(10, 60)]),
      12,
    ),
    (
      #|size 190.5 60
      #|95.25,30 190.5x60 at 0,0 span 1 need 190.5x60
      #|  27.75,30 55.5x60 at 0,0 span 1 need 30x40
      #|  95.25,30 55.5x60 at 1,0 span 1 need 55.5x20
      #|  162.75,30 55.5x60 at 2,0 span 1 need 10x60
    ),
  )
}

///|
test "wraps rows, spans columns up to the last one, leaves spaces empty and shares out the room of a container" {
  assert_eq(
    laid_out(
      grid(3, [
        @block.cell(40, 40),
        @block.cell(100, 40, span=2),
        @block.cell(20, 30, span=5),
        gap_cell(),
        @block.cell(33, 41),
        grid(
          2,
          [@block.cell(10, 10), @block.cell(20, 20), @block.cell(30, 30)],
          head=21.5,
          span=2,
          nw=50,
          nh=30,
        ),
        @block.cell(1, 1, span=0),
      ]),
      12,
    ),
    (
      #|size 312 506
      #|156,253 312x506 at 0,0 span 1 need 312x506
      #|  48,58.75 96x117.5 at 0,0 span 1 need 40x40
      #|  210,58.75 204x117.5 at 1,0 span 2 need 100x40
      #|  156,188.25 312x117.5 at 0,1 span 3 need 20x30
      #|  48,317.75 96x117.5 at 0,2 span 1 need 0x0
      #|  156,317.75 96x117.5 at 1,2 span 1 need 33x41
      #|  264,317.75 96x117.5 at 2,2 span 1 need 96x117.5
      #|    243,307.5 30x30 at 0,0 span 1 need 10x10
      #|    285,307.5 30x30 at 1,0 span 1 need 20x20
      #|    243,349.5 30x30 at 0,1 span 1 need 30x30
      #|  48,447.25 96x117.5 at 0,3 span 1 need 1x1
    ),
  )
}

///|
test "makes a row of nothing but containers only as tall as they need" {
  assert_eq(
    laid_out(
      grid(3, [
        @block.cell(60, 40, span=3),
        grid(
          2,
          [
            @block.cell(50, 40),
            @block.cell(50, 40),
            @block.cell(50, 40),
            @block.cell(50, 40),
          ],
          span=2,
          nw=24,
          nh=24,
        ),
        @block.cell(50, 40),
        grid(
          -1,
          [@block.cell(50, 40), @block.cell(50, 40)],
          span=3,
          nw=24,
          nh=24,
        ),
      ]),
      12,
    ),
    (
      #|size 210 320
      #|105,160 210x320 at 0,0 span 1 need 210x320
      #|  105,58 210x116 at 0,0 span 3 need 60x40
      #|  68,186 136x116 at 0,1 span 2 need 136x116
      #|    37,160 50x40 at 0,0 span 1 need 50x40
      #|    99,160 50x40 at 1,0 span 1 need 50x40
      #|    37,212 50x40 at 0,1 span 1 need 50x40
      #|    99,212 50x40 at 1,1 span 1 need 50x40
      #|  179,186 62x116 at 2,1 span 1 need 50x40
      #|  105,288 210x64 at 0,2 span 3 need 136x64
      #|    55.5,288 87x40 at 0,0 span 1 need 50x40
      #|    154.5,288 87x40 at 1,0 span 1 need 50x40
    ),
  )
}

///|
test "stretches the children of a container in a wider cell" {
  assert_eq(
    laid_out(
      grid(3, [
        @block.cell(300, 40, span=3),
        grid(
          -1,
          [@block.cell(20, 40), @block.cell(20, 40)],
          span=2,
          nw=24,
          nh=24,
        ),
        @block.cell(20, 40),
      ]),
      12,
    ),
    (
      #|size 300 140
      #|150,70 300x140 at 0,0 span 1 need 300x140
      #|  150,32 300x64 at 0,0 span 3 need 300x40
      #|  98,108 196x64 at 0,1 span 2 need 76x64
      #|    52,108 80x40 at 0,0 span 1 need 20x40
      #|    144,108 80x40 at 1,0 span 1 need 20x40
      #|  254,108 92x64 at 2,1 span 1 need 20x40
    ),
  )
}

///|
test "keeps empty cells at the origin" {
  assert_eq(
    laid_out(grid(1, [gap_cell(), grid(-1, [gap_cell()])]), 0),
    (
      #|size 0 0
      #|0,0 0x0 at 0,0 span 1 need 0x0
      #|  0,0 0x0 at 0,0 span 1 need 0x0
      #|  0,0 0x0 at 0,1 span 1 need 0x0
      #|    0,0 0x0 at 0,0 span 1 need 0x0
    ),
  )
}
