///|
/// The path of a loop on a node at (100.5, -20) and where its label goes.
fn loop_on(
  w : Double,
  h : Double,
  k : Int32,
  sideways : Bool,
  base : Double,
  trim : Double,
  label_w : Double,
  label_h : Double,
) -> String {
  let c = @layout.cnode(w, h)
  c.x = 100.5
  c.y = -20
  let e : @layout.CEdge = {
    src: 0,
    dst: 0,
    minlen: 1,
    label_w,
    label_h,
    route: [],
    label_x: 0,
    label_y: 0,
  }
  let path = @svg.loop_path(c, w, h, k, sideways, base, trim, e)
  describe_path(path) + " | \{js_number(e.label_x)} \{js_number(e.label_y)}"
}

///|
test "loop_path leaves a node across the flow and comes back, its label beyond the loop" {
  inspect(
    loop_on(80, 40, 0, false, 20, 7, 30, 18),
    content="M140.5,-28C160.5,-36 160.5,-4 147,-9.4 140.5 -28 -1 0 140.5 -12 -0.9284766908852592 -0.37139067635410367 | 179.5 -20",
  )
  inspect(
    loop_on(80, 40, 1, true, 20, 8, 30, 18),
    content="M86.5,0C72.5,28 128.5,28 118.08,7.16 86.5 0 0 -1 114.5 0 -0.4472135954999579 -0.8944271909999159 | 100.5 41",
  )
}

///|
test "loop_path reaches further for each loop already on the node" {
  inspect(
    loop_on(80, 40, 2, false, 20, 0, 0, 0),
    content="M140.5,-36C176.5,-52 176.5,12 140.5,-4 140.5 -36 -1 0 140.5 -4 -0.9138115486202573 -0.40613846605344767 | 180.5 -20",
  )
}

///|
test "loop_path keeps a loop within the side of a small node" {
  inspect(
    loop_on(10, 12, 3, true, 16, 4, 12, 10),
    content="M99.5,-14C98.5,26 102.5,26 101.6,-10 99.5 -14 0 -1 101.5 -14 -0.024992191160203066 -0.9996876464081227 | 100.5 35",
  )
  inspect(
    loop_on(6, 6, 0, false, 0, 7, 0, 0),
    content="M103.5,-19C103.5,-18 103.5,-22 103.5,-28 103.5 -19 -1 0 103.5 -21 0 1 | 107.5 -20",
  )
}
