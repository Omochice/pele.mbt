///|
fn show(circles : Array[@venn.Circle]) -> String {
  circles.map(c => "\{c.id}:\{c.x},\{c.y},\{c.r}").join(" ")
}

///|
fn layout(source : String) -> Array[@venn.Circle] {
  let db = @venn.parse_venn("venn-beta\n" + source) catch {
    _ => abort("the test diagram does not parse")
  }
  @venn.layout_circles(db.subsets)
}

///|
fn spot_text(spot : @venn.Spot) -> String {
  "\{spot.x},\{spot.y},\{spot.margin}"
}

///|
fn subset(sets : Array[String], size : Double) -> @venn.VennSubset {
  { sets, size, label: Some(""), }
}

///|
fn rounded(value : Double) -> String {
  ((value * 100).round() / 100).to_string()
}

///|
test "one circle sits at the origin" {
  inspect(show(layout("set Only")), content="Only:0,0,1.7841241161527712")
}

///|
test "two circles are as far apart as their overlap asks" {
  inspect(
    show(layout("set A:20\nset B:12\nunion A,B:3")),
    content="A:0,0,2.5231325220201604 B:3.110684798864507,0,1.9544100476116797",
  )
  inspect(
    show(layout("set A\nset B")),
    content="A:0,0,1.7841241161527712 B:3.835866849728458,0,1.7841241161527712",
  )
  inspect(
    show(layout("set A:30\nset B:5\nunion A,B:5")),
    content="A:0,0,3.0901936161855166 B:1.8286273698617093,0,1.2615662610100802",
  )
}

///|
test "three circles are the corners of a triangle" {
  inspect(
    show(
      layout(
        "set A:20\nset B:14\nset C:9\nunion A,B:4\nunion B,C:2\nunion A,C:3",
      ),
    ),
    content="A:0,0,2.5231325220201604 B:2.994693905122728,0,2.111004122822376 C:1.5807907856008478,2.308099070405884,1.692568750643269",
  )
  inspect(
    show(layout("set X\nset Y\nset Z\nunion X,Y,Z")),
    content="X:0,0,1.7841241161527712 Y:2.2647835454917606,0,1.7841241161527712 Z:1.1323917727458803,1.9613600844688546,1.7841241161527712",
  )
}

///|
test "more circles are relaxed from a ring" {
  inspect(
    show(
      layout(
        "set A\nset B\nset C\nset D\nset E\nunion A,B\nunion C,D\nunion D,E",
      ),
    ),
    content="A:0.5700019114404836,-2.711080279255658,1.7841241161527712 B:2.4022502883240646,-1.3798739115809417,1.7841241161527712 C:0.8123337441563823,2.4304663452777127,1.7841241161527712 D:-1.3938025366194358,1.9184046121098532,1.7841241161527712 E:-2.562535787360987,-0.02151989583918484,1.7841241161527712",
  )
  let subsets = [
    subset(["A"], 10),
    subset(["B"], 20),
    subset(["C"], 5),
    subset(["D"], 5),
    subset(["A", "B"], 3),
    subset(["C", "D"], 1),
  ]
  inspect(
    show(@venn.layout_circles(subsets)),
    content="A:0.23902030825239243,-2.1989272216938653,1.7841241161527712 B:2.528742919245665,-0.4045404853731409,2.5231325220201604 C:-0.7572957408266217,2.1516135059227146,1.2615662610100802 D:-1.753653946696733,0.7330418989884656,1.2615662610100802",
  )
}

///|
test "sizes that make no sense still give circles" {
  let nines = "9".repeat(400)
  let zeros = "0".repeat(300)
  let source = "set A:0\nset B:-1000000000\nset C:\{nines}\nset D:.\{zeros}1\nunion A,B:\{nines}\nunion C,D:-5\nunion A,B,C,D[\"x\"]:0\n"
  inspect(
    show(layout(source)),
    content="A:-3.017083560932125e-8,6.592447853437214e-8,5.352372348458314e-152 B:-7.610121191905102e-8,-5.0775765479253014e-8,5.352372348458314e-152 C:5.888258664030281e-8,-7.00172393349235e-8,5.352372348458314e-152 D:4.73894608740335e-8,5.48685263908538e-8,1.7841241161527714e-151",
  )
}

///|
test "the lens of two circles" {
  inspect(@venn.lens_area(1, 1, 2), content="0")
  inspect(@venn.lens_area(3, 1, 1), content="3.141592653589793")
  inspect(@venn.lens_area(1, 1, 1), content="1.228369698608757")
}

///|
test "the distance that gives two circles a wanted overlap" {
  inspect(@venn.distance_for_overlap(1, 1, 0.5), content="1.4652165634996273")
  inspect(@venn.distance_for_overlap(3, 1, 2), content="2.728707758395867")
  inspect(@venn.distance_for_overlap(2, 5, 0.01), content="6.972978080591524")
  inspect(@venn.distance_for_overlap(1, 1, 3.1), content="0.020796701577292964")
  inspect(@venn.distance_for_overlap(2, 1, 0), content="3")
  inspect(@venn.distance_for_overlap(2, 1, -1), content="3")
  inspect(@venn.distance_for_overlap(2, 1, @math.PI), content="1")
  inspect(@venn.distance_for_overlap(2, 1, @double.not_a_number), content="3")
}

///|
test "the roomiest point of a region" {
  let circles : Array[@venn.Circle] = [
    { id: "a", x: 0, y: 0, r: 10, },
    { id: "b", x: 12, y: 0, r: 10, },
  ]
  inspect(spot_text(@venn.find_spot(circles, [0], [])), content="0,0,10")
  inspect(spot_text(@venn.find_spot(circles, [0], [1])), content="-4,0,6")
  inspect(spot_text(@venn.find_spot(circles, [0, 1], [])), content="6,0,4")
  let apart : Array[@venn.Circle] = [
    circles[0],
    { id: "c", x: 30, y: 0, r: 10, },
  ]
  inspect(spot_text(@venn.find_spot(apart, [0, 1], [])), content="15,0,-5")
  let three = layout(
    "set A:20\nset B:14\nset C:9\nunion A,B:4\nunion B,C:2\nunion A,C:3",
  )
  inspect(
    spot_text(@venn.find_spot(three, [0], [1, 2])),
    content="-0.8022506724221594,-0.21673127297517628,1.6921209828812165",
  )
  inspect(
    spot_text(@venn.find_spot(three, [0, 1], [2])),
    content="1.7050782885856526,-0.18899231816504392,0.8076121733994932",
  )
  inspect(
    spot_text(@venn.find_spot(three, [0, 1, 2], [])),
    content="1.7528928916885032,1.0877636070017687,0.4601560311786397",
  )
}

///|
test "the outline of what circles share" {
  let a : @venn.Circle = { id: "a", x: 0, y: 0, r: 5, }
  inspect(
    @venn.region_path([a], rounded),
    content="M-5,0A5,5 0 1 1 5,0A5,5 0 1 1 -5,0Z",
  )
  inspect(
    @venn.region_path([a, { id: "b", x: 6, y: 0, r: 5, }], rounded),
    content="M3,-4A5,5 0 0 1 3,4A5,5 0 0 1 3,-4Z",
  )
  inspect(
    @venn.region_path([a, { id: "b", x: 20, y: 0, r: 5, }], rounded),
    content="",
  )
  inspect(
    @venn.region_path([a, { id: "b", x: 1, y: 0, r: 2, }], rounded),
    content="M-1,0A2,2 0 1 1 3,0A2,2 0 1 1 -1,0Z",
  )
  let three = layout(
    "set A:20\nset B:14\nset C:9\nunion A,B:4\nunion B,C:2\nunion A,C:3",
  )
  inspect(
    @venn.region_path([three[0], three[1]], rounded),
    content="M1.82,-1.75A2.52,2.52 0 0 1 1.82,1.75A2.11,2.11 0 0 1 1.82,-1.75Z",
  )
  inspect(
    @venn.region_path([three[0], three[1], three[2]], rounded),
    content="M1.01,0.72A1.69,1.69 0 0 1 2.39,0.82A2.52,2.52 0 0 1 1.82,1.75A2.11,2.11 0 0 1 1.01,0.72Z",
  )
}

///|
fn pairs_added(subsets : Array[@venn.VennSubset]) -> String {
  @venn.ensure_pairwise_subsets(subsets)
  .map(s => "\{s.sets.join("|")}:\{s.size}")
  .join(" ")
}

///|
test "unions of three sets imply their pairs" {
  inspect(
    pairs_added([subset(["A", "B", "C"], 5)]),
    content="A|B|C:5 A|B:2.5 A|C:2.5 B|C:2.5",
  )
  inspect(
    pairs_added([
      subset(["A"], 10),
      subset(["B"], 10),
      subset(["C"], 10),
      subset(["B", "A", "C"], 5),
    ]),
    content="A:10 B:10 C:10 B|A|C:5 A|B:2.5 A|C:2.5 B|C:2.5",
  )
  inspect(
    pairs_added([
      subset(["A"], 10),
      subset(["B"], 10),
      subset(["C"], 10),
      subset(["A", "B", "C"], 5),
      subset(["A", "B"], 2.5),
      subset(["B", "C"], 2.5),
    ]),
    content="A:10 B:10 C:10 A|B|C:5 A|B:2.5 B|C:2.5 A|C:2.5",
  )
  inspect(
    pairs_added([subset(["A"], 10), subset(["B"], 10), subset(["A", "B"], 2.5)]),
    content="A:10 B:10 A|B:2.5",
  )
}
