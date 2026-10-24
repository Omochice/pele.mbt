///|
/// A loop on a node of drawn size `w` by `h` centered at (`x`, `y`), with where its label goes.
fn golden_loop(
  x : Double,
  y : Double,
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
  c.x = x
  c.y = y
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
/// The crossings of a route on a cluster centered at (`x`, `y`).
fn golden_cluster(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  route : Array[Double],
) -> (@layout.CNode, @svg.Crossings) {
  let c = @layout.cnode(w, h)
  c.x = x
  c.y = y
  let crossings = @svg.Crossings::new()
  @svg.mark_crossings(crossings, route)
  (c, crossings)
}

///|
fn golden_title_x(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  width : Double,
  pad : Double,
  route : Array[Double],
) -> String {
  let (c, crossings) = golden_cluster(x, y, w, h, route)
  js_number(@svg.cluster_title_x(c, width, crossings, pad))
}

///|
fn golden_crossed(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  width : Double,
  at : Double,
  route : Array[Double],
) -> String {
  let (c, crossings) = golden_cluster(x, y, w, h, route)
  @svg.title_crossed(c, width, at, crossings).to_string()
}

///|
/// The calls below are ones pele v1.8.0 makes while rendering the golden sources, with what it returned, run in Node and written with `String`.
test "route_path draws the routes of pele's golden diagrams as pele does" {
  inspect(
    describe_path(
      @svg.route_path(
        [106.0, 96.0, 0.0, 106.0, 116.0, 0.0],
        Some("linear"),
        0.0,
        7.0,
      ),
    ),
    content="M106,96L106,109 106 96 0 -1 106 116 0 1",
  )
  inspect(
    describe_path(
      @svg.route_path(
        [126.0, 136.0, 0.0, 126.0, 156.0, 0.0],
        Some("linear"),
        0.0,
        7.0,
      ),
    ),
    content="M126,136L126,149 126 136 0 -1 126 156 0 1",
  )
  inspect(
    describe_path(
      @svg.route_path(
        [
          138.56799999999998, 96.0, 0.0, 119.34399999999997, 144.0, 0.0, 119.34399999999997,
          192.0, 0.0, 119.34399999999997, 212.0, 0.0, 119.34399999999997, 232.0,
          0.0, 28.0, 280.0, 0.0, 28.0, 320.0, 0.0, 28.0, 340.0, 0.0, 28.0, 388.0,
          0.0, 47.448, 436.0, 0.0,
        ],
        None,
        0.0,
        7.0,
        start_reach=0.0,
        end_reach=13.0,
      ),
    ),
    content="M138.57,96C138.57,120 119.34,120 119.34,144L119.34,232C119.34,256 28,256 28,280L28,388C28,405.5 47.45,405.5 47.45,423L47.45,429 138.56799999999998 96 0 -1 47.448 436 0 1",
  )
  inspect(
    describe_path(
      @svg.route_path(
        [
          128.03199999999998, 123.96914285714286, 1.0, 176.03199999999998, 75.29942857142856,
          1.0, 297.408, 75.29942857142856, 1.0, 317.408, 75.29942857142856, 1.0,
          337.408, 75.29942857142856, 1.0, 431.6520000000001, 91.96914285714286,
          1.0, 451.6520000000001, 91.96914285714286, 1.0, 471.6520000000001, 91.96914285714286,
          1.0,
        ],
        None,
        0.0,
        7.0,
        start_reach=13.0,
        end_reach=13.0,
      ),
    ),
    content="M128.03,123.97L141.03,123.97C158.53,123.97 158.53,75.3 176.03,75.3L337.41,75.3C384.53,75.3 384.53,91.97 431.65,91.97L464.65,91.97 128.03199999999998 123.96914285714286 -1 0 471.6520000000001 91.96914285714286 1 0",
  )
  inspect(
    describe_path(
      @svg.route_path(
        [
          649.4680000000001, 179.96914285714286, 1.0, 597.4760000000001, 179.96914285714286,
          1.0, 471.6520000000001, 179.96914285714286, 1.0, 451.6520000000001, 179.96914285714286,
          1.0, 431.6520000000001, 179.96914285714286, 1.0, 411.15200000000004, 179.96914285714286,
          1.0, 364.908, 179.96914285714286, 1.0, 337.408, 196.63885714285715, 1.0,
          317.408, 196.63885714285715, 1.0, 297.408, 196.63885714285715, 1.0, 176.03199999999998,
          196.63885714285715, 1.0, 128.03199999999998, 147.96914285714286, 1.0,
        ],
        None,
        0.0,
        7.0,
        start_reach=13.0,
        end_reach=13.0,
      ),
    ),
    content="M649.47,179.97L364.91,179.97C351.16,179.97 351.16,196.64 337.41,196.64L176.03,196.64C158.53,196.64 158.53,147.97 141.03,147.97L135.03,147.97 649.4680000000001 179.96914285714286 1 0 128.03199999999998 147.96914285714286 -1 0",
  )
  inspect(
    describe_path(
      @svg.route_path(
        [
          139.0, 56.0, 0.0, 192.0, 104.0, 0.0, 192.0, 152.0, 0.0, 147.0, 200.0, 0.0,
          147.0, 240.0, 0.0, 139.0, 260.0, 0.0,
        ],
        None,
        0.0,
        7.0,
      ),
    ),
    content="M139,56C139,80 192,80 192,104L192,152C192,176 147,176 147,200L147,240C147,244.88 139,244.88 139,249.75L139,253 139 56 0 -1 139 260 0 1",
  )
  inspect(
    describe_path(
      @svg.route_path(
        [
          67.0, 587.0, 0.0, 46.0, 619.0, 0.0, 46.0, 644.0, 0.0, 45.25, 676.0, 0.0,
          45.25, 788.0, 0.0, 77.25, 877.0, 0.0,
        ],
        None,
        18.0,
        18.0,
      ),
    ),
    content="M67,605L67,608.5C67,613.75 46,613.75 46,619L46,644C46,660 45.25,660 45.25,676L45.25,788C45.25,820.5 77.25,820.5 77.25,853L77.25,859 67 587 0 -1 77.25 877 0 1",
  )
  inspect(
    describe_path(
      @svg.route_path(
        [
          357.3518702186599, 67.0, 1.0, 380.512, 66.0, 1.0, 400.512, 66.0, 1.0, 454.65999999999997,
          59.75, 1.0, 490.956, 59.75, 1.0, 545.104, 66.0, 1.0, 565.104, 66.0, 1.0,
          587.1640808651213, 67.0, 1.0,
        ],
        None,
        0.0,
        7.0,
      ),
    ),
    content="M357.35,67C368.93,67 368.93,66 380.51,66L400.51,66C427.59,66 427.59,59.75 454.66,59.75L490.96,59.75C518.03,59.75 518.03,66 545.1,66L565.1,66C570.75,66 570.75,67 576.4,67L580.16,67 357.3518702186599 67 -1 0 587.1640808651213 67 1 0",
  )
  inspect(
    describe_path(
      @svg.route_path(
        [
          79.12, 157.12, 0.0, 37.56, 187.62, 0.0, 37.56, 212.62, 0.0, 37.56, 240.12,
          0.0,
        ],
        None,
        0.0,
        7.0,
        start_reach=13.0,
        end_reach=13.0,
      ),
    ),
    content="M79.12,157.12L79.12,170C79.12,178.81 37.56,178.81 37.56,187.62L37.56,233.12 79.12 157.12 0 -1 37.56 240.12 0 1",
  )
  inspect(
    describe_path(
      @svg.route_path(
        [
          111.12, 157.12, 0.0, 143.15300000000002, 240.12, 0.0, 143.15300000000002,
          288.12, 0.0, 143.15300000000002, 336.12, 0.0, 143.15300000000002, 384.12,
          0.0, 143.15300000000002, 432.12, 0.0,
        ],
        None,
        0.0,
        7.0,
        start_reach=13.0,
        end_reach=13.0,
      ),
    ),
    content="M111.12,157.12L111.12,170.12C111.12,205.12 143.15,205.12 143.15,240.12L143.15,425.12 111.12 157.12 0 -1 143.15300000000002 432.12 0 1",
  )
  inspect(
    describe_path(
      @svg.route_path([86.0, 56.0, 0.0, 86.0, 104.0, 0.0], None, 0.0, 7.0),
    ),
    content="M86,56L86,97 86 56 0 -1 86 104 0 1",
  )
}

///|
test "loop_path draws the loops of pele's golden diagrams as pele does" {
  inspect(
    golden_loop(112.0, 128.0, 156.0, 48.0, 0, false, 26.0, 7.0, 0.0, 0.0),
    content="M190,120C216,112 216,144 196.69,138.06 190 120 -1 0 190 136 -0.95577900872195 -0.2940858488375231 | 220 128",
  )
  inspect(
    golden_loop(112.0, 32.0, 156.0, 48.0, 0, false, 26.0, 7.0, 0.0, 0.0),
    content="M190,24C216,16 216,48 196.69,42.06 190 24 -1 0 190 40 -0.95577900872195 -0.2940858488375231 | 220 32",
  )
}

///|
test "cluster titles sit where pele puts them in its golden diagrams" {
  inspect(
    golden_title_x(106.0, 264.0, 196.0, 128.0, 33.776, 20.0, [106.0, 200.0, 0.0]),
    content="38.888000000000005",
  )
  inspect(
    golden_title_x(126.0, 198.0, 196.0, 108.0, 48.896, 20.0, [126.0, 144.0, 0.0]),
    content="66.44800000000001",
  )
  inspect(
    golden_title_x(334.0, 515.0, 212.0, 238.0, 64.016, 20.0, [334.0, 396.0, 0.0]),
    content="274.008",
  )
  inspect(
    golden_title_x(106.0, 178.0, 196.0, 148.0, 33.776, 20.0, [106.0, 104.0, 0.0]),
    content="38.888000000000005",
  )
  inspect(
    golden_crossed(112.257, 325.5, 144.514, 163.0, 62.256, 85.128, [
      112.257, 244.0, 0.0, 309.22400000000005, 244.0, 0.0,
    ]),
    content="true",
  )
  inspect(
    golden_crossed(
      126.49599999999998,
      325.5,
      252.99199999999996,
      163.0,
      224.992,
      126.496,
      [126.49599999999998, 244.0, 0.0, 420.376, 244.0, 0.0],
    ),
    content="true",
  )
}
