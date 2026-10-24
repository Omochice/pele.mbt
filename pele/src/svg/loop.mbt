///|
/// A self-loop beside node `c` of drawn size `w` by `h`: out of the side that lies across the flow and back in.
/// `k` counts the loops already on the node, so each one reaches a little further, from `base` for the first.
/// `trim` leaves room for the marker at its end.
/// Also places the edge's label beyond the loop.
pub fn loop_path(
  c : @layout.CNode,
  w : Double,
  h : Double,
  k : Int32,
  sideways : Bool,
  base : Double,
  trim : Double,
  e : @layout.CEdge,
) -> EdgePath {
  let half = (if sideways { w } else { h }) / 2
  let spread = @util.js_min(half - 4, 8 + k.to_double() * 6)
  let reach = base + k.to_double() * 8
  let len = or_one(@util.js_hypot(reach, spread))
  // Local frame: `out` points away from the node, `along` runs along its side.
  let at = fn(out : Double, along : Double) -> String {
    if sideways {
      "\{num(c.x + along)},\{num(c.y + h / 2 + out)}"
    } else {
      "\{num(c.x + w / 2 + out)},\{num(c.y + along)}"
    }
  }
  let tx = reach / len * trim
  let ty = spread / len * trim
  let d = "M\{at(0, -spread)}C\{at(reach, -spread * 2)} \{at(reach, spread * 2)} \{at(tx, spread + ty)}"
  if sideways {
    e.label_x = c.x
    e.label_y = c.y + h / 2 + reach + 4 + e.label_h / 2
    let y = c.y + h / 2
    {
      d,
      sx: c.x - spread,
      sy: y,
      sdx: 0,
      sdy: -1,
      ex: c.x + spread,
      ey: y,
      edx: -spread / len,
      edy: -reach / len,
    }
  } else {
    e.label_x = c.x + w / 2 + reach + 4 + e.label_w / 2
    e.label_y = c.y
    let x = c.x + w / 2
    {
      d,
      sx: x,
      sy: c.y - spread,
      sdx: -1,
      sdy: 0,
      ex: x,
      ey: c.y + spread,
      edx: -reach / len,
      edy: -spread / len,
    }
  }
}
