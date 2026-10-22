///|
/// The path of a route with no markers.
fn bare(route : Array[Double], curve? : String) -> String {
  describe_path(@svg.route_path(route, curve, 0, 0))
}

///|
test "route_path draws one curve between two points not in line, leaving and arriving along the flow" {
  inspect(
    bare([0, 0, 0, 100, 48, 0]),
    content="M0,0C0,24 100,24 100,48 0 0 0 -1 100 48 0 1",
  )
  inspect(
    bare([0, 0, 0, -100, 48, 0]),
    content="M0,0C0,24 -100,24 -100,48 0 0 0 -1 -100 48 0 1",
  )
  inspect(
    bare([0, 0, 0, 100, 200, 0]),
    content="M0,0C0,100 100,100 100,200 0 0 0 -1 100 200 0 1",
  )
  inspect(
    bare([0, 0, 0, 30, 48, 0]),
    content="M0,0C0,24 30,24 30,48 0 0 0 -1 30 48 0 1",
  )
  inspect(
    bare([0, 0, 0, 30, -48, 0]),
    content="M0,0C0,-24 30,-24 30,-48 0 0 0 1 30 -48 0 -1",
  )
}

///|
test "route_path draws the same curve on its side in a diagram that runs from left to right" {
  inspect(
    bare([0, 0, 1, 48, 100, 1]),
    content="M0,0C24,0 24,100 48,100 0 0 -1 0 48 100 1 0",
  )
  inspect(
    bare([0, 0, 1, 48, -30, 1]),
    content="M0,0C24,0 24,-30 48,-30 0 0 -1 0 48 -30 1 0",
  )
}

///|
test "route_path turns sooner on a run much wider than the gap it crosses, and never sharper than a limit" {
  inspect(
    bare([0, 0, 0, 200, 48, 0]),
    content="M0,0C0,24 200,24 200,48 0 0 0 -1 200 48 0 1",
  )
  inspect(
    bare([0, 0, 0, 480, 48, 0]),
    content="M0,0C0,19.2 480,28.8 480,48 0 0 0 -1 480 48 0 1",
  )
  inspect(
    bare([0, 0, 0, -4800, 48, 0]),
    content="M0,0C0,12 -4800,36 -4800,48 0 0 0 -1 -4800 48 0 1",
  )
  inspect(
    bare([0, 0, 1, 40, 400, 1]),
    content="M0,0C16,0 24,400 40,400 0 0 -1 0 40 400 1 0",
  )
}

///|
test "route_path draws a straight line between two points in line" {
  inspect(bare([0, 0, 0, 0, 48, 0]), content="M0,0L0,48 0 0 0 -1 0 48 0 1")
}
