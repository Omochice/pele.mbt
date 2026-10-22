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

///|
/// The path of a curve with the given trims and reaches.
fn marked(
  route : Array[Double],
  start_trim : Double,
  end_trim : Double,
  start_reach? : Double,
  end_reach? : Double,
) -> String {
  describe_path(
    @svg.route_path(route, None, start_trim, end_trim, start_reach?, end_reach?),
  )
}

///|
test "route_path runs straight into a marker, out of the curve" {
  inspect(
    marked([0, 0, 0, 40, 48, 0], 0, 7),
    content="M0,0C0,17.5 40,17.5 40,35L40,41 0 0 0 -1 40 48 0 1",
  )
  inspect(
    marked([0, 0, 0, 40, 48, 0], 7, 0),
    content="M0,7L0,13C0,30.5 40,30.5 40,48 0 0 0 -1 40 48 0 1",
  )
}

///|
test "route_path turns as far from a node whatever marker its end carries" {
  inspect(
    marked([0, 0, 0, 40, 48, 0], 0, 0, end_reach=13),
    content="M0,0C0,17.5 40,17.5 40,35L40,48 0 0 0 -1 40 48 0 1",
  )
  inspect(
    marked([0, 0, 0, 40, 48, 0], 0, 8, end_reach=14),
    content="M0,0C0,17 40,17 40,34L40,40 0 0 0 -1 40 48 0 1",
  )
  inspect(
    marked([0, 0, 0, 40, 48, 0], 0, 7, end_reach=14),
    content="M0,0C0,17 40,17 40,34L40,41 0 0 0 -1 40 48 0 1",
  )
  inspect(
    marked([0, 0, 0, 40, 48, 0], 4, 4, start_reach=14, end_reach=0),
    content="M0,4L0,14C0,29 40,29 40,44 0 0 0 -1 40 48 0 1",
  )
  inspect(
    marked([0, 0, 1, 100, 40, 1], 8, 4, start_reach=20, end_reach=10),
    content="M8,0L20,0C55,0 55,40 90,40L96,40 0 0 -1 0 100 40 1 0",
  )
}

///|
test "route_path runs straight for no more than a quarter of the way where there is little room" {
  inspect(
    marked([0, 0, 0, 15, 19, 0], 0, 7),
    content="M0,0C0,4.5 15,4.5 15,9L15,12 0 0 0 -1 15 19 0 1",
  )
}

///|
test "route_path trims a straight edge without a run to clear" {
  inspect(
    marked([0, 0, 0, 0, 48, 0], 0, 7),
    content="M0,0L0,41 0 0 0 -1 0 48 0 1",
  )
}

///|
test "route_path keeps both ends of a curve heading along the flow, however far across it runs" {
  inspect(
    marked([0, 0, 0, 96, 48, 0], 0, 7),
    content="M0,0C0,17.5 96,17.5 96,35L96,41 0 0 0 -1 96 48 0 1",
  )
  inspect(
    marked([0, 0, 0, -96, 48, 0], 0, 7),
    content="M0,0C0,17.5 -96,17.5 -96,35L-96,41 0 0 0 -1 -96 48 0 1",
  )
  inspect(
    marked([0, 0, 0, 900, 48, 0], 0, 7),
    content="M0,0C0,8.75 900,26.25 900,35L900,41 0 0 0 -1 900 48 0 1",
  )
}
