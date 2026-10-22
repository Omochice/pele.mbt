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
test "route_path turns a corner of the route as widely as its legs allow" {
  inspect(
    bare([0, 0, 0, 0, 20, 0, 100, 20, 0, 100, 48, 0]),
    content="M0,0C0,12.4 19,20 50,20C81,20 100,30.64 100,48 0 0 0 -1 100 48 0 1",
  )
  inspect(
    bare([0, 0, 0, 0, 20, 0, 100, 20, 0, 100, 48, 0], curve="basis"),
    content="M0,0C0,12.4 19,20 50,20C81,20 100,30.64 100,48 0 0 0 -1 100 48 0 1",
  )
  inspect(
    bare([0, 0, 0, 0, 40, 0, 100, 40, 0, 100, 60, 0, 160, 60, 1, 160, 100, 0]),
    content="M0,0C0,24.8 19,40 50,40C81,40 100,43.8 100,50C100,56.2 111.4,60 130,60C148.6,60 160,75.2 160,100 0 0 0 -1 160 100 0 1",
  )
}

///|
test "route_path leaves the corners of a linear route sharp" {
  inspect(
    bare([0, 0, 0, 0, 20, 0, 100, 20, 0, 100, 48, 0], curve="linear"),
    content="M0,0L0,20L100,20L100,48 0 0 0 -1 100 48 0 1",
  )
  inspect(
    describe_path(
      @svg.route_path([0, 0, 0, 30, 40, 0, 30, 60, 0], Some("linear"), 0, 7),
    ),
    content="M0,0L30,40L30,53 0 0 -0.6 -0.8 30 60 0 1",
  )
  inspect(
    describe_path(@svg.route_path([0, 0, 0, 30, 40, 0], Some("linear"), 0, 7)),
    content="M0,0L25.8,34.4 0 0 -0.6 -0.8 30 40 0.6 0.8",
  )
}

///|
test "route_path drops a point part of the way along one straight run, but not where the run turns back" {
  inspect(
    bare([0, 0, 0, 0, 20, 0, 0, 48, 0]),
    content="M0,0L0,48 0 0 0 -1 0 48 0 1",
  )
  inspect(
    bare([0, 0, 0, 0, 48, 0, 0, 20, 0]),
    content="M0,0L0,48L0,20 0 0 0 -1 0 20 0 -1",
  )
  inspect(
    bare([0, 0, 0, 30, 40, 0, 30, 60, 0]),
    content="M0,0C0,20 30,20 30,40L30,60 0 0 0 -1 30 60 0 1",
  )
}

///|
/// The path of a stepped route with the given trims.
fn stepped(
  route : Array[Double],
  curve : String,
  start_trim : Double,
  end_trim : Double,
) -> String {
  describe_path(@svg.route_path(route, Some(curve), start_trim, end_trim))
}

///|
test "route_path rounds the corners of a stepped route a little" {
  inspect(
    stepped([0, 0, 0, 0, 20, 0, 100, 20, 0, 100, 48, 0], "step", 0, 0),
    content="M0,0L0,8Q0,20 12,20L88,20Q100,20 100,32L100,48 0 0 0 -1 100 48 0 1",
  )
  inspect(
    stepped([0, 0, 0, 0, 20, 0, 10, 20, 0, 10, 48, 0], "step", 0, 0),
    content="M0,0L0,15Q0,20 5,20Q10,20 10,25L10,48 0 0 0 -1 10 48 0 1",
  )
}

///|
test "route_path turns a stepped route at right angles, with markers along its runs" {
  inspect(
    stepped([0, 0, 0, 100, 48, 0], "step", 0, 7),
    content="M0,0L0,12Q0,24 12,24L88,24Q100,24 100,36L100,41 0 0 0 -1 100 48 0 1",
  )
  inspect(
    stepped([0, 0, 1, 48, 100, 1], "step", 4, 8),
    content="M4,0L12,0Q24,0 24,12L24,88Q24,100 36,100L40,100 0 0 -1 0 48 100 1 0",
  )
  inspect(
    stepped([0, 0, 0, 100, 48, 0, 30, 120, 0], "step", 7, 7),
    content="M0,7L0,12Q0,24 12,24L88,24Q100,24 100,36L100,72Q100,84 88,84L42,84Q30,84 30,96L30,113 0 0 0 -1 30 120 0 1",
  )
  inspect(
    stepped([0, 0, 0, 5, 48, 0], "step", 0, 0),
    content="M0,0L0,21.5Q0,24 2.5,24Q5,24 5,26.5L5,48 0 0 0 -1 5 48 0 1",
  )
}

///|
test "route_path steps before or after the run across the flow" {
  inspect(
    stepped([0, 0, 0, 100, 48, 0], "stepAfter", 0, 0),
    content="M0,0L0,36Q0,48 12,48L100,48 0 0 0 -1 100 48 1 0",
  )
  inspect(
    stepped([0, 0, 1, 48, 100, 1], "stepBefore", 0, 0),
    content="M0,0L0,88Q0,100 12,100L48,100 0 0 0 -1 48 100 1 0",
  )
  inspect(
    stepped([0, 0, 0, 100, 48, 0], "stepBefore", 0, 0),
    content="M0,0L88,0Q100,0 100,12L100,48 0 0 -1 0 100 48 0 1",
  )
  inspect(
    stepped([0, 0, 1, 48, 100, 1], "stepAfter", 0, 0),
    content="M0,0L36,0Q48,0 48,12L48,100 0 0 -1 0 48 100 0 1",
  )
}

///|
test "route_path draws a line between stepped points nearly in line" {
  inspect(
    stepped([0, 0, 0, 0.005, 48, 0], "step", 0, 0),
    content="M0,0L0.01,48 0 0 -0.00010416666610152636 -0.999999994574653 0.005 48 0.00010416666610152636 0.999999994574653",
  )
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
test "route_path runs straight into a marker after a corner" {
  inspect(
    marked([0, 0, 0, 0, 20, 0, 100, 20, 0, 100, 60, 0], 0, 7),
    content="M0,0C0,12.4 19,20 50,20C81,20 100,30.26 100,47L100,53 0 0 0 -1 100 60 0 1",
  )
  inspect(
    marked([0, 0, 0, 0, 20, 0, 100, 20, 0, 100, 60, 0], 7, 7),
    content="M0,7L0,10.25C0,16.3 19,20 50,20C81,20 100,30.26 100,47L100,53 0 0 0 -1 100 60 0 1",
  )
  inspect(
    marked(
      [0, 0, 0, 0, 40, 0, 100, 40, 0, 100, 60, 0, 160, 60, 1, 160, 100, 0],
      0,
      7,
    ),
    content="M0,0C0,24.8 19,40 50,40C81,40 100,43.8 100,50C100,56.2 111.4,60 130,60C148.6,60 160,70.26 160,87L160,93 0 0 0 -1 160 100 0 1",
  )
  inspect(
    marked([0, 0, 1, 40, 0, 1, 40, 80, 0, 120, 80, 1], 4, 8),
    content="M4,0L10,0C28.6,0 40,15.2 40,40C40,64.8 65.08,80 106,80L112,80 0 0 -1 0 120 80 1 0",
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
