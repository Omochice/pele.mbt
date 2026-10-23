///|
/// A cluster 200 wide and 100 high whose top left corner is at the origin.
fn cluster() -> @layout.CNode {
  let c = @layout.cnode(200, 100)
  c.x = 100
  c.y = 50
  c
}

///|
/// Where a title 40 wide goes on the cluster with the given route marked, and whether an edge still runs through it there.
fn place(route : Array[Double]) -> String {
  let crossings = @svg.Crossings::new()
  @svg.mark_crossings(crossings, route)
  let c = cluster()
  let x = @svg.cluster_title_x(c, 40, crossings, 16)
  "\{x} \{@svg.title_crossed(c, 40, x, crossings)}"
}

///|
test "cluster_title_x keeps the title at the left where no edge enters the top" {
  inspect(place([]), content="30 false")
  inspect(place([30, 10, 0]), content="30 false")
  inspect(place([100, 0.4, 0]), content="30 false")
  inspect(place([0, 0, 0, 200, 0, 0, 30, 5, 0]), content="30 false")
}

///|
test "cluster_title_x moves the title to the middle or the right, clear of the edges" {
  inspect(place([30, -0.4, 0]), content="100 false")
  inspect(place([55, 0, 0]), content="100 false")
  inspect(place([30, 0, 0, 105, 0.2, 0]), content="170 false")
}

///|
test "cluster_title_x takes the place with the most room when none is clear" {
  inspect(place([30, 0, 0, 105, 0, 0, 160, 0, 0]), content="30 true")
  inspect(place([53.5, 0, 0, 124, 0, 0, 147.4, 0, 0]), content="30 true")
}

///|
test "cluster_title_x centers a title with no width, which nothing runs through" {
  let crossings = @svg.Crossings::new()
  @svg.mark_crossings(crossings, [30, 0, 0])
  inspect(@svg.cluster_title_x(cluster(), 0, crossings, 16), content="100")
  inspect(@svg.title_crossed(cluster(), 0, 30, crossings), content="false")
}

///|
test "mark_crossings files points on either side of zero under the same row" {
  let crossings = @svg.Crossings::new()
  @svg.mark_crossings(crossings, [30, -0.3, 0, 170, 0.3, 1])
  inspect(@svg.cluster_title_x(cluster(), 40, crossings, 16), content="100")
  inspect(@svg.title_crossed(cluster(), 40, 170, crossings), content="true")
}

///|
test "Crossings::at gives the x of the points marked on the row of y, in the order they were marked" {
  let crossings = @svg.Crossings::new()
  @svg.mark_crossings(crossings, [30, -0.3, 0, 170, 0.4, 1, 80, 9.6, 0])
  @svg.mark_crossings(crossings, [5, 0.2, 0])
  let row = (y : Double) => {
    match crossings.at(y) {
      Some(xs) => xs.map(x => x.to_string()).join(" ")
      None => "none"
    }
  }
  inspect(row(0), content="30 170 5")
  inspect(row(0.4), content="30 170 5")
  inspect(row(10), content="80")
  inspect(row(5), content="none")
}
