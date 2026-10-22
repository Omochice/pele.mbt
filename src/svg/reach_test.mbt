///|
test "side_reach keeps the farthest any marker on a side of a node needs" {
  let reach = @svg.SideReach::new()
  reach.add(1, 0, "arrow_point")
  reach.add(1, 0, "arrow_cross")
  reach.add(1, 2, "arrow_cross")
  reach.add(0, 1, "arrow_circle")
  inspect(reach.of(1, 0), content="13")
  inspect(reach.of(1, 2), content="10")
  inspect(reach.of(0, 1), content="14")
}

///|
test "side_reach needs nothing where no marker is, nor off any side" {
  let reach = @svg.SideReach::new()
  reach.add(1, -1, "arrow_circle")
  reach.add(2, 3, "none")
  inspect(reach.of(1, -1), content="0")
  inspect(reach.of(2, 3), content="0")
  inspect(reach.of(0, 0), content="0")
}
