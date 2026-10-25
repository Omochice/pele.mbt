///|
const HEAD : String = "architecture-beta\n"

///|
let docs : Array[String] = [
  "architecture-beta\n    group api(cloud)[API]\n\n    service db(database)[Database] in api\n    service disk1(disk)[Storage] in api\n    service disk2(disk)[Storage] in api\n    service server(server)[Server] in api\n\n    db:L -- R:server\n    disk1:T -- B:server\n    disk2:T -- B:db\n",
  "architecture-beta\n    group api(cloud)[API]\n    service db1(database)[DB1] in api\n    service db2(database)[DB2] in api\n    service db3(database)[DB3] in api\n    service mcp(server)[MCP] in api\n    db1:R --> L:mcp\n    db2:R --> L:mcp\n    db3:R --> L:mcp\n    align column db1 db2 db3\n",
  "architecture-beta\n    service src1(server)[Source 1]\n    service src2(server)[Source 2]\n    service src3(server)[Source 3]\n    service proc(server)[Processor]\n    src1:B --> T:proc\n    src2:B --> T:proc\n    src3:B --> T:proc\n    align row src1 src2 src3\n",
  "architecture-beta\n    group sources(cloud)[Sources]\n        service src_a(server)[Source A] in sources\n        service src_b(server)[Source B] in sources\n        service src_c(server)[Source C] in sources\n\n    group storage(database)[Storage]\n        service db_one(database)[DB One] in storage\n        service db_two(database)[DB Two] in storage\n        service db_three(database)[DB Three] in storage\n\n    group output(disk)[Output]\n        service brief(disk)[Brief] in output\n        service analyst(server)[Analyst] in output\n        service delivery(cloud)[Delivery] in output\n\n    src_a:B --> T:db_one\n    src_b:B --> T:db_two\n    src_c:B --> T:db_three\n    db_two:B --> T:brief\n    brief:R --> L:analyst\n    analyst:R --> L:delivery\n\n    align row src_a src_b src_c\n    align row db_one db_two db_three\n    align row brief analyst delivery\n\n    align column src_a db_one\n    align column src_b db_two brief\n    align column src_c db_three\n",
  "architecture-beta\n    service left_disk(disk)[Disk]\n    service top_disk(disk)[Disk]\n    service bottom_disk(disk)[Disk]\n    service top_gateway(internet)[Gateway]\n    service bottom_gateway(internet)[Gateway]\n    junction junctionCenter\n    junction junctionRight\n\n    left_disk:R -- L:junctionCenter\n    top_disk:B -- T:junctionCenter\n    bottom_disk:T -- B:junctionCenter\n    junctionCenter:R -- L:junctionRight\n    top_gateway:B -- T:junctionRight\n    bottom_gateway:T -- B:junctionRight\n",
  "architecture-beta\n    group api(logos:aws-lambda)[API]\n\n    service db(logos:aws-aurora)[Database] in api\n    service disk1(logos:aws-glacier)[Storage] in api\n    service disk2(logos:aws-s3)[Storage] in api\n    service server(logos:aws-ec2)[Server] in api\n\n    db:L -- R:server\n    disk1:T -- B:server\n    disk2:T -- B:db\n",
]

///|
fn drawn(
  source : String,
  max_width? : Double,
  icons? : @types.IconResolver,
) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), max_width, icons, }
  Ok(@core.render([@architecture.architecture], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
/// The size and drawing, or the failure, in the form the expected values were taken from pele in.
fn svg(
  source : String,
  max_width? : Double,
  icons? : @types.IconResolver,
) -> String {
  match drawn(source, max_width?, icons?) {
    Ok(result) => "\{result.width}x\{result.height} \{result.svg}"
    Err(failure) => "\{failure.code.to_string()}: \{failure.message}"
  }
}

///|
fn drawing(source : String) -> String {
  match drawn(source) {
    Ok(result) => result.svg
    Err(failure) => failure.message
  }
}

///|
fn count(text : String, needle : String) -> Int32 {
  let mut n = 0
  let mut at = @util.index_of(text, needle)
  while at != -1 {
    n += 1
    at = @util.index_of(text, needle, from=at + needle.length())
  }
  n
}

///|
/// The text between `prefix` and the next occurrence of `stop`, starting the search at `from`.
fn between(
  text : String,
  prefix : String,
  stop : String,
  from : Int32,
) -> (String, Int32)? {
  let at = @util.index_of(text, prefix, from~)
  if at == -1 {
    return None
  }
  let start = at + prefix.length()
  let end = @util.index_of(text, stop, from=start)
  Some((@util.slice(text, start, end~), end))
}

///|
priv struct Box {
  x : Double
  y : Double
  w : Double
  h : Double
}

///|
fn inside(a : Box, b : Box) -> Bool {
  a.x >= b.x && a.y >= b.y && a.x + a.w <= b.x + b.w && a.y + a.h <= b.y + b.h
}

///|
fn apart(a : Box, b : Box) -> Bool {
  a.x + a.w <= b.x || b.x + b.w <= a.x || a.y + a.h <= b.y || b.y + b.h <= a.y
}

///|
/// Icon squares of the services and junctions, by id.
fn node_boxes(out : String) -> Map[String, Box] {
  let size = match between(out, "class=\"pele-node pele-service\"", "\"", 0) {
    Some((_, at)) =>
      match between(out, "width=\"", "\"", at) {
        Some((width, _)) => @util.to_number(width)
        None => 48
      }
    None => 48
  }
  let boxes : Map[String, Box] = Map([])
  let mut from = 0
  while between(out, "class=\"pele-node pele-", "\" data-id=\"", from)
        is Some((_, at)) {
    guard! between(out, "data-id=\"", "\"", at) is Some((id, at))
    guard! between(out, "translate(", ",", at) is Some((x, at))
    guard! between(out, ",", ")", at) is Some((y, at))
    boxes.set(id, {
      x: @util.to_number(x) - size / 2,
      y: @util.to_number(y),
      w: size,
      h: size,
    })
    from = at
  }
  boxes
}

///|
fn cluster_boxes(out : String) -> Map[String, Box] {
  let boxes : Map[String, Box] = Map([])
  let mut from = 0
  while between(out, "class=\"pele-cluster\" data-id=\"", "\"", from)
        is Some((id, at)) {
    guard! between(out, "<rect x=\"", "\"", at) is Some((x, at))
    guard! between(out, "y=\"", "\"", at) is Some((y, at))
    guard! between(out, "width=\"", "\"", at) is Some((w, at))
    guard! between(out, "height=\"", "\"", at) is Some((h, at))
    boxes.set(id, {
      x: @util.to_number(x),
      y: @util.to_number(y),
      w: @util.to_number(w),
      h: @util.to_number(h),
    })
    from = at
  }
  boxes
}

///|
fn layout(body : String) -> Map[String, Box] {
  node_boxes(drawing(HEAD + body))
}

///|
/// The path of the first edge.
fn edge_path(out : String) -> String {
  guard between(out, "class=\"pele-edge\" data-id=", "/>", 0) is Some((path, _)) else {
    return ""
  }
  guard between(path, "<path d=\"", "\"", 0) is Some((d, _)) else { return "" }
  d
}

///|
/// The points of a path made only of `M` and `L` commands.
fn straight_points(d : String) -> Array[Double] {
  let points = []
  let mut i = 0
  while i < d.length() {
    let start = i + 1
    i = start
    while i < d.length() && @util.code_at(d, i) != 'L'.to_int() {
      i += 1
    }
    let pair = @util.slice(d, start, end=i)
    let comma = @util.index_of(pair, ",")
    points.push(@util.to_number(@util.slice(pair, 0, end=comma)))
    points.push(@util.to_number(@util.slice(pair, comma + 1)))
  }
  points
}

///|
fn get(boxes : Map[String, Box], id : String) -> Box {
  boxes.get(id).unwrap()
}

///|
test "draws every service, group, and edge of the documentation example" {
  match drawn(docs[0]) {
    Ok(result) => {
      inspect(result.kind, content="architecture")
      inspect(
        count(result.svg, "class=\"pele-node pele-service\""),
        content="4",
      )
      inspect(count(result.svg, "class=\"pele-cluster\""), content="1")
      inspect(count(result.svg, "class=\"pele-edge\""), content="3")
      inspect(result.svg.contains(">Database<"), content="true")
      inspect(result.svg.contains("data-icon=\"database\""), content="true")
      inspect(result.width > 100 && result.height > 100, content="true")
    }
    Err(failure) => fail(failure.message)
  }
}

///|
test "renders every documentation example, the same each time" {
  for source in docs {
    let out = drawing(source)
    inspect(out.contains("<svg"), content="true")
    inspect(out == drawing(source), content="true")
  }
}

///|
test "places a node on the side its edge names" {
  let facing = layout(
    "service a\nservice b\nservice c\nservice d\nservice e\na:R -- L:b\na:L -- R:c\na:T -- B:d\na:B -- T:e",
  )
  let a = get(facing, "a")
  inspect(get(facing, "b").x > a.x && get(facing, "b").y == a.y, content="true")
  inspect(get(facing, "c").x < a.x && get(facing, "c").y == a.y, content="true")
  inspect(get(facing, "d").y < a.y && get(facing, "d").x == a.x, content="true")
  inspect(get(facing, "e").y > a.y && get(facing, "e").x == a.x, content="true")
}

///|
test "places a node diagonally when the sides are perpendicular" {
  let bent = layout("service a\nservice b\nservice c\na:R -- T:b\na:T -- R:c")
  let a = get(bent, "a")
  inspect(get(bent, "b").x > a.x && get(bent, "b").y > a.y, content="true")
  inspect(get(bent, "c").x < a.x && get(bent, "c").y < a.y, content="true")
  let reversed = layout("service a\nservice b\nb:T -- R:a")
  inspect(
    get(reversed, "b").x > get(reversed, "a").x &&
    get(reversed, "b").y > get(reversed, "a").y,
    content="true",
  )
}

///|
fn all_apart(boxes : Array[Box]) -> Bool {
  for i in 0..<boxes.length() {
    for j in (i + 1)..<boxes.length() {
      if !apart(boxes[i], boxes[j]) {
        return false
      }
    }
  }
  true
}

///|
test "gives every node its own cell when edges ask for the same one" {
  let body = StringBuilder()
  body.write_string("service hub\n")
  for i in 0..<9 {
    if i > 0 {
      body.write_string("\n")
    }
    body.write_string("service n\{i}\nhub:R -- L:n\{i}")
  }
  let boxes = layout(body.to_string()).values().collect()
  inspect(all_apart(boxes), content="true")
  inspect(boxes[1:].iter().all(box => box.x > boxes[0].x), content="true")
}

///|
test "keeps unconnected parts apart" {
  let boxes = layout(
    "service a\nservice b\nservice c\nservice d\nservice e\njunction j\na:R -- L:b",
  )
  inspect(all_apart(boxes.values().collect()), content="true")
}

///|
test "draws a group around its members and nothing else" {
  let out = drawing(
    "architecture-beta\ngroup fe[Frontend]\ngroup be[Backend]\ngroup inner[Inner] in be\nservice web in fe\nservice gw in be\n" +
    "service auth in inner\nservice out\nservice mid\nweb:R -- L:mid\nmid:R -- L:gw\ngw:B -- T:auth\nauth:R -- L:out\nweb:B -- T:out",
  )
  let nodes = node_boxes(out)
  let clusters = cluster_boxes(out)
  let fe = get(clusters, "fe")
  let be = get(clusters, "be")
  let inner = get(clusters, "inner")
  inspect(inside(get(nodes, "web"), fe), content="true")
  inspect(inside(get(nodes, "gw"), be), content="true")
  inspect(inside(get(nodes, "auth"), inner), content="true")
  inspect(inside(inner, be), content="true")
  inspect(apart(fe, be), content="true")
  inspect(inside(get(nodes, "gw"), inner), content="false")
  for id in ["out", "mid"] {
    for box in [fe, be, inner] {
      inspect(apart(get(nodes, id), box), content="true")
    }
  }
}

///|
/// pele's seeded generator for its randomised tests.
priv struct Random {
  mut state : UInt32
}

///|
fn Random::next(self : Random) -> Double {
  self.state = self.state * 1664525U + 1013904223U
  self.state.to_double() / 4294967296.0
}

///|
fn Random::pick(self : Random, n : Int32) -> Int32 {
  (self.next() * n.to_double()).floor().to_int()
}

///|
fn within(group_parent : Array[Int32], g : Int32, ancestor : Int32) -> Bool {
  let mut p = g
  while p >= 0 {
    if p == ancestor {
      return true
    }
    p = group_parent[p]
  }
  false
}

///|
test "keeps random diagrams free of overlaps, with every group around exactly its members" {
  let rnd = Random::{ state: 11, }
  let sides = ["L", "R", "T", "B"]
  for round in 0..<300 {
    let group_count = rnd.pick(6)
    let node_count = 1 + rnd.pick(14)
    let group_parent : Array[Int32] = []
    let node_parent : Array[Int32] = []
    let src = StringBuilder()
    src.write_string(HEAD)
    for g in 0..<group_count {
      group_parent.push(
        if g > 0 && rnd.next() < 0.5 {
          rnd.pick(g)
        } else {
          -1
        },
      )
      let titled = if rnd.next() < 0.5 { "[Group title]" } else { "" }
      let parent = if group_parent[g] >= 0 {
        " in g\{group_parent[g]}"
      } else {
        ""
      }
      src.write_string("group g\{g}\{titled}\{parent}\n")
    }
    for i in 0..<node_count {
      node_parent.push(
        if group_count > 0 && rnd.next() < 0.7 {
          rnd.pick(group_count)
        } else {
          -1
        },
      )
      let where_ = if node_parent[i] >= 0 {
        " in g\{node_parent[i]}"
      } else {
        ""
      }
      if rnd.next() < 0.15 {
        src.write_string("junction n\{i}\{where_}\n")
      } else {
        let named = if rnd.next() < 0.5 { "[Name]" } else { "" }
        src.write_string("service n\{i}\{named}\{where_}\n")
      }
    }
    for k = rnd.pick(node_count * 2); k > 0; k = k - 1 {
      let a = rnd.pick(node_count)
      let sa = sides[rnd.pick(4)]
      let label = if rnd.next() < 0.2 { "[label]-" } else { "-" }
      let arrow = if rnd.next() < 0.5 { ">" } else { "" }
      let sb = sides[rnd.pick(4)]
      let b = rnd.pick(node_count)
      src.write_string("n\{a}:\{sa} -\{label}\{arrow} \{sb}:n\{b}\n")
    }
    if node_count > 2 && rnd.next() < 0.3 {
      let direction = if rnd.next() < 0.5 { "row" } else { "column" }
      src.write_string("align \{direction} n0 n1 n2\n")
    }
    let source = src.to_string()
    let out = drawing(source)
    let nodes = node_boxes(out)
    let clusters = cluster_boxes(out)
    assert_eq(nodes.length(), node_count, msg="round \{round}: \{source}")
    assert_eq(clusters.length(), group_count, msg="round \{round}: \{source}")
    for i in 0..<node_count {
      let box = get(nodes, "n\{i}")
      for j in (i + 1)..<node_count {
        assert_true(
          apart(box, get(nodes, "n\{j}")),
          msg="n\{i} n\{j} in \{source}",
        )
      }
      for g in 0..<group_count {
        let cluster = get(clusters, "g\{g}")
        let ok = if node_parent[i] >= 0 &&
          within(group_parent, node_parent[i], g) {
          inside(box, cluster)
        } else {
          apart(box, cluster)
        }
        assert_true(ok, msg="n\{i} and g\{g} in \{source}")
      }
    }
    for g in 0..<group_count {
      for k in 0..<group_count {
        if g == k {
          continue
        }
        let a = get(clusters, "g\{g}")
        let b = get(clusters, "g\{k}")
        if within(group_parent, g, k) {
          assert_true(inside(a, b), msg="g\{g} in g\{k} in \{source}")
        } else if !within(group_parent, k, g) {
          assert_true(apart(a, b), msg="g\{g} and g\{k} in \{source}")
        }
      }
    }
  }
}

///|
test "follows align directives ahead of edges" {
  let row = layout(
    "service a\nservice b\nservice c\nservice p\na:B -- T:p\nb:B -- T:p\nc:B -- T:p\nalign row a b c",
  )
  inspect(
    get(row, "a").y == get(row, "b").y && get(row, "b").y == get(row, "c").y,
    content="true",
  )
  inspect(
    get(row, "a").x < get(row, "b").x && get(row, "b").x < get(row, "c").x,
    content="true",
  )
  let column = layout("service a\nservice b\nservice c\nalign column c a b")
  inspect(get(column, "c").x == get(column, "a").x, content="true")
  inspect(
    get(column, "c").y < get(column, "a").y &&
    get(column, "a").y < get(column, "b").y,
    content="true",
  )
}

///|
test "draws arrowheads only where the edge has them" {
  let markers = edge => {
    count(
      drawing(HEAD + "service a\nservice b\n" + edge),
      "class=\"pele-marker\"",
    )
  }
  inspect(markers("a:R -- L:b"), content="0")
  inspect(markers("a:R --> L:b"), content="1")
  inspect(markers("a:R <-- L:b"), content="1")
  inspect(markers("a:R <--> L:b"), content="2")
}

///|
test "draws straight, bent, and looping edges as orthogonal paths" {
  let path = body => edge_path(drawing(HEAD + body))
  let straight = path("service a\nservice b\na:R -- L:b")
  inspect(
    count(straight, "M") == 1 && count(straight, "L") == 1,
    content="true",
  )
  inspect(count(straight, "Q"), content="0")
  inspect(count(path("service a\nservice b\na:R -- T:b"), "Q"), content="1")
  inspect(count(path("service a\nservice b\na:R -- R:b"), "Q"), content="2")
  inspect(count(path("service a\na:R -- L:a"), "Q"), content="4")
}

///|
test "draws edge labels, junctions, and titles" {
  let out = drawing(
    "architecture-beta\ntitle Platform\nservice a[Alpha]\nservice b[Beta]\njunction j\na:R -[calls]- L:j\nj:R --> L:b",
  )
  inspect(out.contains("class=\"pele-edge-label\""), content="true")
  inspect(out.contains(">calls<"), content="true")
  inspect(count(out, "class=\"pele-node pele-junction\""), content="1")
  inspect(out.contains(">Platform<"), content="true")
  inspect(
    drawing("---\ntitle: From front matter\n---\narchitecture-beta\nservice a").contains(
      "From front matter",
    ),
    content="true",
  )
  inspect(
    drawing(
      "---\ntitle: From front matter\n---\narchitecture-beta\ntitle Own\nservice a",
    ).contains(">Own<"),
    content="true",
  )
}

///|
fn close_to(actual : Double, expected : Double) -> Bool {
  (actual - expected).abs() < 0.05
}

///|
test "starts a group edge at the border of the group" {
  let out = drawing(
    "architecture-beta\ngroup one\ngroup two\nservice a in one\nservice b in two\na{group}:B --> T:b{group}",
  )
  let clusters = cluster_boxes(out)
  let one = get(clusters, "one")
  let two = get(clusters, "two")
  let points = straight_points(edge_path(out))
  inspect(points.length(), content="4")
  inspect(close_to(points[1], one.y + one.h), content="true")
  inspect(close_to(points[3], two.y - 7), content="true")
}

///|
test "carries a group edge on to a junction inside the group" {
  let out = drawing(
    "architecture-beta\ngroup one\ngroup two\njunction a in one\njunction b in two\na{group}:R --> L:b{group}",
  )
  let nodes = node_boxes(out)
  let points = straight_points(edge_path(out))
  inspect(points.length(), content="4")
  inspect(close_to(points[0], get(nodes, "a").x + 24), content="true")
  inspect(close_to(points[2], get(nodes, "b").x + 24), content="true")
  inspect(count(out, "class=\"pele-marker\""), content="1")
}

///|
test "fills icon slots from the built-in outlines" {
  // pele also asks a host resolver first; the plugin has none, so only the built-in half applies.
  let out = drawing(
    "architecture-beta\ngroup g(cloud)[G]\nservice a(database)[A] in g\nservice b(logos:aws-lambda)[B] in g\nservice c \"S3\"[C]\nservice d",
  )
  inspect(count(out, "class=\"pele-icon\""), content="3")
  let slot = name => {
    match between(out, "data-icon=\"\{name}\"", "</svg>", 0) {
      Some((inner, _)) => inner
      None => ""
    }
  }
  inspect(slot("database").contains("><path "), content="true")
  inspect(slot("logos:aws-lambda").contains("<path"), content="false")
  inspect(out.contains(">S3<"), content="true")
}

///|
test "honours iconSize, fontSize, and padding" {
  let body = "architecture-beta\ngroup g[G]\nservice a[A] in g\nservice b[B] in g\na:R -- L:b"
  let config = text => {
    "---\nconfig:\n  architecture:\n    \{text}\n---\n\{body}"
  }
  let width = source => {
    match drawn(source) {
      Ok(result) => result.width
      Err(_) => -1
    }
  }
  let plain = width(body)
  inspect(width(config("iconSize: 96")) > plain, content="true")
  inspect(
    drawing(config("iconSize: 96")).contains("width=\"96\" height=\"96\""),
    content="true",
  )
  inspect(width(config("padding: 60")) == plain + 80, content="true")
  inspect(
    drawing(config("fontSize: 24")).contains("font:24px sans-serif;"),
    content="true",
  )
  inspect(drawing(config("iconSize: -5")).contains("NaN"), content="false")
}

///|
test "rejects what Mermaid rejects, with its messages" {
  let fails = (body, message) => {
    guard drawn(HEAD + body) is Err(failure) else { fail("accepted \{body}") }
    assert_true(failure.message.contains(message), msg=failure.message)
  }
  fails(
    "service a\nservice a", "The service id [a] is already in use by another node",
  )
  fails(
    "group a\njunction a", "The junction id [a] is already in use by another group",
  )
  fails(
    "service a in g", "The service [a]'s parent does not exist. Please make sure the parent is created before this service",
  )
  fails("group g in g", "The group [g] cannot be placed within itself")
  fails("service a\nservice b in a", "The service [b]'s parent is not a group")
  fails(
    "service a\na:R -- L:b", "The right-hand id [b] does not yet exist. Please create the service/group before declaring an edge to it.",
  )
  fails(
    "group g\nservice a in g\nservice b in g\na{group}:R -- L:b", "is modified to traverse the group boundary",
  )
  fails(
    "service a\nservice b\nalign row a b c", "align row references [c], which is not a service or junction",
  )
  fails(
    "service a\nservice b\nalign column a a", "align column lists [a] more than once",
  )
  fails("group g\nservice a\na:R -- L:g", "The right-hand id [g] is a group")
}

///|
test "reads the header and ids the way Mermaid 12.1 does" {
  inspect(drawn("architecture\nservice a") is Err(_), content="true")
  // Mermaid lexes a leading L, R, T or B as an edge direction, so such ids do not parse.
  inspect(drawn("architecture-beta\nservice Lambda") is Err(_), content="true")
  inspect(
    drawing("architecture-beta\nservice lambda").contains("data-id=\"lambda\""),
    content="true",
  )
}

///|
test "draws an empty diagram and an empty group" {
  inspect(drawing("architecture-beta").contains("<svg"), content="true")
  let clusters = cluster_boxes(
    drawing("architecture-beta\ngroup g[Nothing here]\ngroup h in g"),
  )
  inspect(inside(get(clusters, "h"), get(clusters, "g")), content="true")
}

///|
test "the documentation examples are drawn as pele draws them" {
  inspect(
    svg(
      "architecture-beta\n    group api(cloud)[API]\n\n    service db(database)[Database] in api\n    service disk1(disk)[Storage] in api\n    service disk2(disk)[Storage] in api\n    service server(server)[Server] in api\n\n    db:L -- R:server\n    disk1:T -- B:server\n    disk2:T -- B:db\n",
    ),
    content="224x264 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 224 264\" width=\"224\" height=\"264\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"api\"><rect x=\"0\" y=\"0\" width=\"208\" height=\"248\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"cloud\" x=\"10\" y=\"8\" width=\"20\" height=\"20\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M7 18a4 4 0 0 1-.5-7.97A6 6 0 0 1 18 9.5a4.25 4.25 0 0 1-.5 8.5z\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"48.9\" y=\"23.6\" text-anchor=\"middle\">API</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"db-server\"><path d=\"M129,60L73,60\"/></g><g class=\"pele-edge\" data-id=\"disk1-server\"><path d=\"M49,152L49,114\"/></g><g class=\"pele-edge\" data-id=\"disk2-db\"><path d=\"M153,152L153,114\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"db\" transform=\"translate(153,36)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"database\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 6a8 3 0 1 0 16 0a8 3 0 1 0-16 0M4 6v12a8 3 0 0 0 16 0V6M4 12a8 3 0 0 0 16 0\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Database</text></g><g class=\"pele-node pele-service\" data-id=\"disk1\" transform=\"translate(49,152)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"disk\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M5 3h14v18H5zM12 6.5a4 4 0 1 0 0 8a4 4 0 1 0 0-8M12 10.5h.01M8 18h3\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Storage</text></g><g class=\"pele-node pele-service\" data-id=\"disk2\" transform=\"translate(153,152)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"disk\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M5 3h14v18H5zM12 6.5a4 4 0 1 0 0 8a4 4 0 1 0 0-8M12 10.5h.01M8 18h3\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Storage</text></g><g class=\"pele-node pele-service\" data-id=\"server\" transform=\"translate(49,36)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"server\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M3 4h18v7H3zM3 13h18v7H3zM7 7.5h.01M7 16.5h.01M11 7.5h6M11 16.5h6\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Server</text></g></g></g></svg>",
  )
  inspect(
    svg(
      "architecture-beta\n    group sources(cloud)[Sources]\n        service src_a(server)[Source A] in sources\n        service src_b(server)[Source B] in sources\n        service src_c(server)[Source C] in sources\n\n    group storage(database)[Storage]\n        service db_one(database)[DB One] in storage\n        service db_two(database)[DB Two] in storage\n        service db_three(database)[DB Three] in storage\n\n    group output(disk)[Output]\n        service brief(disk)[Brief] in output\n        service analyst(server)[Analyst] in output\n        service delivery(cloud)[Delivery] in output\n\n    src_a:B --> T:db_one\n    src_b:B --> T:db_two\n    src_c:B --> T:db_three\n    db_two:B --> T:brief\n    brief:R --> L:analyst\n    analyst:R --> L:delivery\n\n    align row src_a src_b src_c\n    align row db_one db_two db_three\n    align row brief analyst delivery\n\n    align column src_a db_one\n    align column src_b db_two brief\n    align column src_c db_three\n",
    ),
    content="476x492 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 476 492\" width=\"476\" height=\"492\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"sources\"><rect x=\"0\" y=\"0\" width=\"342\" height=\"132\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"cloud\" x=\"10\" y=\"8\" width=\"20\" height=\"20\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M7 18a4 4 0 0 1-.5-7.97A6 6 0 0 1 18 9.5a4.25 4.25 0 0 1-.5 8.5z\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"65.34\" y=\"23.6\" text-anchor=\"middle\">Sources</text></g><g class=\"pele-cluster\" data-id=\"storage\"><rect x=\"0\" y=\"172\" width=\"342\" height=\"132\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"database\" x=\"59\" y=\"180\" width=\"20\" height=\"20\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 6a8 3 0 1 0 16 0a8 3 0 1 0-16 0M4 6v12a8 3 0 0 0 16 0V6M4 12a8 3 0 0 0 16 0\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"113.02\" y=\"195.6\" text-anchor=\"middle\">Storage</text></g><g class=\"pele-cluster\" data-id=\"output\"><rect x=\"126\" y=\"344\" width=\"334\" height=\"132\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"disk\" x=\"185\" y=\"352\" width=\"20\" height=\"20\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M5 3h14v18H5zM12 6.5a4 4 0 1 0 0 8a4 4 0 1 0 0-8M12 10.5h.01M8 18h3\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"235.02\" y=\"367.6\" text-anchor=\"middle\">Output</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"src_a-db_one\"><path d=\"M53,114L53,201\"/><path class=\"pele-marker\" d=\"M53,208L49.64,200L56.36,200Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"src_b-db_two\"><path d=\"M179,114L179,201\"/><path class=\"pele-marker\" d=\"M179,208L175.64,200L182.36,200Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"src_c-db_three\"><path d=\"M287,114L287,201\"/><path class=\"pele-marker\" d=\"M287,208L283.64,200L290.36,200Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"db_two-brief\"><path d=\"M179,286L179,373\"/><path class=\"pele-marker\" d=\"M179,380L175.64,372L182.36,372Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"brief-analyst\"><path d=\"M203,404L256,404\"/><path class=\"pele-marker\" d=\"M263,404L255,407.36L255,400.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"analyst-delivery\"><path d=\"M311,404L380,404\"/><path class=\"pele-marker\" d=\"M387,404L379,407.36L379,400.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"src_a\" transform=\"translate(53,36)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"server\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M3 4h18v7H3zM3 13h18v7H3zM7 7.5h.01M7 16.5h.01M11 7.5h6M11 16.5h6\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Source A</text></g><g class=\"pele-node pele-service\" data-id=\"src_b\" transform=\"translate(179,36)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"server\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M3 4h18v7H3zM3 13h18v7H3zM7 7.5h.01M7 16.5h.01M11 7.5h6M11 16.5h6\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Source B</text></g><g class=\"pele-node pele-service\" data-id=\"src_c\" transform=\"translate(287,36)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"server\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M3 4h18v7H3zM3 13h18v7H3zM7 7.5h.01M7 16.5h.01M11 7.5h6M11 16.5h6\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Source C</text></g><g class=\"pele-node pele-service\" data-id=\"db_one\" transform=\"translate(53,208)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"database\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 6a8 3 0 1 0 16 0a8 3 0 1 0-16 0M4 6v12a8 3 0 0 0 16 0V6M4 12a8 3 0 0 0 16 0\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">DB One</text></g><g class=\"pele-node pele-service\" data-id=\"db_two\" transform=\"translate(179,208)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"database\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 6a8 3 0 1 0 16 0a8 3 0 1 0-16 0M4 6v12a8 3 0 0 0 16 0V6M4 12a8 3 0 0 0 16 0\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">DB Two</text></g><g class=\"pele-node pele-service\" data-id=\"db_three\" transform=\"translate(287,208)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"database\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 6a8 3 0 1 0 16 0a8 3 0 1 0-16 0M4 6v12a8 3 0 0 0 16 0V6M4 12a8 3 0 0 0 16 0\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">DB Three</text></g><g class=\"pele-node pele-service\" data-id=\"brief\" transform=\"translate(179,380)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"disk\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M5 3h14v18H5zM12 6.5a4 4 0 1 0 0 8a4 4 0 1 0 0-8M12 10.5h.01M8 18h3\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Brief</text></g><g class=\"pele-node pele-service\" data-id=\"analyst\" transform=\"translate(287,380)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"server\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M3 4h18v7H3zM3 13h18v7H3zM7 7.5h.01M7 16.5h.01M11 7.5h6M11 16.5h6\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Analyst</text></g><g class=\"pele-node pele-service\" data-id=\"delivery\" transform=\"translate(411,380)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"cloud\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M7 18a4 4 0 0 1-.5-7.97A6 6 0 0 1 18 9.5a4.25 4.25 0 0 1-.5 8.5z\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Delivery</text></g></g></g></svg>",
  )
  inspect(
    svg(
      "architecture-beta\n    service left_disk(disk)[Disk]\n    service top_disk(disk)[Disk]\n    service bottom_disk(disk)[Disk]\n    service top_gateway(internet)[Gateway]\n    service bottom_gateway(internet)[Gateway]\n    junction junctionCenter\n    junction junctionRight\n\n    left_disk:R -- L:junctionCenter\n    top_disk:B -- T:junctionCenter\n    bottom_disk:T -- B:junctionCenter\n    junctionCenter:R -- L:junctionRight\n    top_gateway:B -- T:junctionRight\n    bottom_gateway:T -- B:junctionRight\n",
    ),
    content="256x324 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 256 324\" width=\"256\" height=\"324\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"left_disk-junctionCenter\"><path d=\"M48,140L112,140\"/></g><g class=\"pele-edge\" data-id=\"top_disk-junctionCenter\"><path d=\"M112,78L112,140\"/></g><g class=\"pele-edge\" data-id=\"bottom_disk-junctionCenter\"><path d=\"M112,232L112,140\"/></g><g class=\"pele-edge\" data-id=\"junctionCenter-junctionRight\"><path d=\"M112,140L208,140\"/></g><g class=\"pele-edge\" data-id=\"top_gateway-junctionRight\"><path d=\"M208,78L208,140\"/></g><g class=\"pele-edge\" data-id=\"bottom_gateway-junctionRight\"><path d=\"M208,232L208,140\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"left_disk\" transform=\"translate(24,116)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"disk\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M5 3h14v18H5zM12 6.5a4 4 0 1 0 0 8a4 4 0 1 0 0-8M12 10.5h.01M8 18h3\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Disk</text></g><g class=\"pele-node pele-service\" data-id=\"top_disk\" transform=\"translate(112,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"disk\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M5 3h14v18H5zM12 6.5a4 4 0 1 0 0 8a4 4 0 1 0 0-8M12 10.5h.01M8 18h3\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Disk</text></g><g class=\"pele-node pele-service\" data-id=\"bottom_disk\" transform=\"translate(112,232)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"disk\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M5 3h14v18H5zM12 6.5a4 4 0 1 0 0 8a4 4 0 1 0 0-8M12 10.5h.01M8 18h3\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Disk</text></g><g class=\"pele-node pele-service\" data-id=\"top_gateway\" transform=\"translate(208,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"internet\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M3 12a9 9 0 1 0 18 0a9 9 0 1 0-18 0M3 12h18M12 3a13 13 0 0 0 0 18M12 3a13 13 0 0 1 0 18\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Gateway</text></g><g class=\"pele-node pele-service\" data-id=\"bottom_gateway\" transform=\"translate(208,232)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"internet\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M3 12a9 9 0 1 0 18 0a9 9 0 1 0-18 0M3 12h18M12 3a13 13 0 0 0 0 18M12 3a13 13 0 0 1 0 18\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Gateway</text></g><g class=\"pele-node pele-junction\" data-id=\"junctionCenter\" transform=\"translate(112,116)\"><circle cy=\"24\" r=\"3\" fill=\"var(--_l)\"/></g><g class=\"pele-node pele-junction\" data-id=\"junctionRight\" transform=\"translate(208,116)\"><circle cy=\"24\" r=\"3\" fill=\"var(--_l)\"/></g></g></g></svg>",
  )
  inspect(
    svg(
      "architecture-beta\n    group sources(cloud)[Sources]\n        service src_a(server)[Source A] in sources\n        service src_b(server)[Source B] in sources\n        service src_c(server)[Source C] in sources\n\n    group storage(database)[Storage]\n        service db_one(database)[DB One] in storage\n        service db_two(database)[DB Two] in storage\n        service db_three(database)[DB Three] in storage\n\n    group output(disk)[Output]\n        service brief(disk)[Brief] in output\n        service analyst(server)[Analyst] in output\n        service delivery(cloud)[Delivery] in output\n\n    src_a:B --> T:db_one\n    src_b:B --> T:db_two\n    src_c:B --> T:db_three\n    db_two:B --> T:brief\n    brief:R --> L:analyst\n    analyst:R --> L:delivery\n\n    align row src_a src_b src_c\n    align row db_one db_two db_three\n    align row brief analyst delivery\n\n    align column src_a db_one\n    align column src_b db_two brief\n    align column src_c db_three\n",
      max_width=400,
    ),
    content=(
      #|364x472 <svg xmlns="http://www.w3.org/2000/svg" class="pele pele-architecture" viewBox="0 0 364 472" width="364" height="472" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)" role="graphics-document document" aria-roledescription="architecture"><g transform="translate(8,8)"><g class="pele-clusters"><g class="pele-cluster" data-id="sources"><rect x="0" y="0" width="254" height="142" fill="var(--_a)" fill-opacity="0.5" stroke="var(--_b)" style="rx:var(--_r)"/><svg class="pele-icon" data-icon="cloud" x="10" y="8" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 18a4 4 0 0 1-.5-7.97A6 6 0 0 1 18 9.5a4.25 4.25 0 0 1-.5 8.5z" stroke="var(--_fg)" stroke-width="1.5"/></svg><text class="pele-cluster-label" fill="var(--_m)" x="65.34" y="23.6" text-anchor="middle">Sources</text></g><g class="pele-cluster" data-id="storage"><rect x="0" y="166" width="254" height="142" fill="var(--_a)" fill-opacity="0.5" stroke="var(--_b)" style="rx:var(--_r)"/><svg class="pele-icon" data-icon="database" x="10" y="174" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6a8 3 0 1 0 16 0a8 3 0 1 0-16 0M4 6v12a8 3 0 0 0 16 0V6M4 12a8 3 0 0 0 16 0" stroke="var(--_fg)" stroke-width="1.5"/></svg><text class="pele-cluster-label" fill="var(--_m)" x="64.02" y="189.6" text-anchor="middle">Storage</text></g><g class="pele-cluster" data-id="output"><rect x="94" y="332" width="254" height="124" fill="var(--_a)" fill-opacity="0.5" stroke="var(--_b)" style="rx:var(--_r)"/><svg class="pele-icon" data-icon="disk" x="141" y="340" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 3h14v18H5zM12 6.5a4 4 0 1 0 0 8a4 4 0 1 0 0-8M12 10.5h.01M8 18h3" stroke="var(--_fg)" stroke-width="1.5"/></svg><text class="pele-cluster-label" fill="var(--_m)" x="191.02" y="355.6" text-anchor="middle">Output</text></g></g><g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round" stroke-linejoin="round"><g class="pele-edge" data-id="src_a-db_one"><path d="M41,132L41,195"/><path class="pele-marker" d="M41,202L37.64,194L44.36,194Z" fill="var(--_l)" stroke="none"/></g><g class="pele-edge" data-id="src_b-db_two"><path d="M135,132L135,195"/><path class="pele-marker" d="M135,202L131.64,194L138.36,194Z" fill="var(--_l)" stroke="none"/></g><g class="pele-edge" data-id="src_c-db_three"><path d="M215,132L215,195"/><path class="pele-marker" d="M215,202L211.64,194L218.36,194Z" fill="var(--_l)" stroke="none"/></g><g class="pele-edge" data-id="db_two-brief"><path d="M135,280L135,361"/><path class="pele-marker" d="M135,368L131.64,360L138.36,360Z" fill="var(--_l)" stroke="none"/></g><g class="pele-edge" data-id="brief-analyst"><path d="M159,392L184,392"/><path class="pele-marker" d="M191,392L183,395.36L183,388.64Z" fill="var(--_l)" stroke="none"/></g><g class="pele-edge" data-id="analyst-delivery"><path d="M239,392L276,392"/><path class="pele-marker" d="M283,392L275,395.36L275,388.64Z" fill="var(--_l)" stroke="none"/></g></g><g class="pele-nodes"><g class="pele-node pele-service" data-id="src_a" transform="translate(41,36)"><rect x="-24" width="48" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><svg class="pele-icon" data-icon="server" x="-12" y="12" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 4h18v7H3zM3 13h18v7H3zM7 7.5h.01M7 16.5h.01M11 7.5h6M11 16.5h6" stroke="var(--_fg)" stroke-width="1.5"/></svg><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="68.1">Source</tspan><tspan x="0" y="89.1">A</tspan></text></g><g class="pele-node pele-service" data-id="src_b" transform="translate(135,36)"><rect x="-24" width="48" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><svg class="pele-icon" data-icon="server" x="-12" y="12" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 4h18v7H3zM3 13h18v7H3zM7 7.5h.01M7 16.5h.01M11 7.5h6M11 16.5h6" stroke="var(--_fg)" stroke-width="1.5"/></svg><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="68.1">Source</tspan><tspan x="0" y="89.1">B</tspan></text></g><g class="pele-node pele-service" data-id="src_c" transform="translate(215,36)"><rect x="-24" width="48" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><svg class="pele-icon" data-icon="server" x="-12" y="12" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 4h18v7H3zM3 13h18v7H3zM7 7.5h.01M7 16.5h.01M11 7.5h6M11 16.5h6" stroke="var(--_fg)" stroke-width="1.5"/></svg><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="68.1">Source</tspan><tspan x="0" y="89.1">C</tspan></text></g><g class="pele-node pele-service" data-id="db_one" transform="translate(41,202)"><rect x="-24" width="48" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><svg class="pele-icon" data-icon="database" x="-12" y="12" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6a8 3 0 1 0 16 0a8 3 0 1 0-16 0M4 6v12a8 3 0 0 0 16 0V6M4 12a8 3 0 0 0 16 0" stroke="var(--_fg)" stroke-width="1.5"/></svg><text class="pele-label" x="0" y="69.6" text-anchor="middle">DB One</text></g><g class="pele-node pele-service" data-id="db_two" transform="translate(135,202)"><rect x="-24" width="48" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><svg class="pele-icon" data-icon="database" x="-12" y="12" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6a8 3 0 1 0 16 0a8 3 0 1 0-16 0M4 6v12a8 3 0 0 0 16 0V6M4 12a8 3 0 0 0 16 0" stroke="var(--_fg)" stroke-width="1.5"/></svg><text class="pele-label" x="0" y="69.6" text-anchor="middle">DB Two</text></g><g class="pele-node pele-service" data-id="db_three" transform="translate(215,202)"><rect x="-24" width="48" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><svg class="pele-icon" data-icon="database" x="-12" y="12" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6a8 3 0 1 0 16 0a8 3 0 1 0-16 0M4 6v12a8 3 0 0 0 16 0V6M4 12a8 3 0 0 0 16 0" stroke="var(--_fg)" stroke-width="1.5"/></svg><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="68.1">DB</tspan><tspan x="0" y="89.1">Three</tspan></text></g><g class="pele-node pele-service" data-id="brief" transform="translate(135,368)"><rect x="-24" width="48" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><svg class="pele-icon" data-icon="disk" x="-12" y="12" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 3h14v18H5zM12 6.5a4 4 0 1 0 0 8a4 4 0 1 0 0-8M12 10.5h.01M8 18h3" stroke="var(--_fg)" stroke-width="1.5"/></svg><text class="pele-label" x="0" y="69.6" text-anchor="middle">Brief</text></g><g class="pele-node pele-service" data-id="analyst" transform="translate(215,368)"><rect x="-24" width="48" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><svg class="pele-icon" data-icon="server" x="-12" y="12" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 4h18v7H3zM3 13h18v7H3zM7 7.5h.01M7 16.5h.01M11 7.5h6M11 16.5h6" stroke="var(--_fg)" stroke-width="1.5"/></svg><text class="pele-label" x="0" y="69.6" text-anchor="middle">Analyst</text></g><g class="pele-node pele-service" data-id="delivery" transform="translate(307,368)"><rect x="-24" width="48" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><svg class="pele-icon" data-icon="cloud" x="-12" y="12" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 18a4 4 0 0 1-.5-7.97A6 6 0 0 1 18 9.5a4.25 4.25 0 0 1-.5 8.5z" stroke="var(--_fg)" stroke-width="1.5"/></svg><text class="pele-label" x="0" y="69.6" text-anchor="middle">Delivery</text></g></g></g></svg>
    ),
  )
}

///|
test "a straight edge between two services" {
  inspect(
    svg("architecture-beta\nservice a[Alpha]\nservice b[Beta]\na:R -- L:b"),
    content="152x92 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 152 92\" width=\"152\" height=\"92\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"a-b\"><path d=\"M48,24L88,24\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(24,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Alpha</text></g><g class=\"pele-node pele-service\" data-id=\"b\" transform=\"translate(112,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Beta</text></g></g></g></svg>",
  )
}

///|
test "bent, looping, and self edges" {
  inspect(
    svg("architecture-beta\nservice a\nservice b\na:R -- T:b"),
    content="152x152 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 152 152\" width=\"152\" height=\"152\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"a-b\"><path d=\"M48,24L106,24Q112,24 112,30L112,88\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(24,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g><g class=\"pele-node pele-service\" data-id=\"b\" transform=\"translate(112,88)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g></g></g></svg>",
  )
  inspect(
    svg("architecture-beta\nservice a\nservice b\na:R -- R:b"),
    content="80x152 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 80 152\" width=\"80\" height=\"152\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"a-b\"><path d=\"M48,24L54,24Q60,24 60,30L60,106Q60,112 54,112L48,112\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(24,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g><g class=\"pele-node pele-service\" data-id=\"b\" transform=\"translate(24,88)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g></g></g></svg>",
  )
  inspect(
    svg("architecture-beta\nservice a\na:R -- L:a"),
    content="96x80 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 96 80\" width=\"96\" height=\"80\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(24,8)\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"a-a\"><path d=\"M48,24L54,24Q60,24 60,30L60,54Q60,60 54,60L-6,60Q-12,60 -12,54L-12,30Q-12,24 -6,24L0,24\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(24,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g></g></g></svg>",
  )
  inspect(
    svg("architecture-beta\nservice a\na:T --> T:a"),
    content="64x80 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 64 80\" width=\"64\" height=\"80\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,24)\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"a-a\"><path d=\"M16,0L16,-6Q16,-12 22,-12L29.5,-12Q32,-12 32,-9.5L32,-7\"/><path class=\"pele-marker\" d=\"M32,0L28.64,-8L35.36,-8Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(24,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g></g></g></svg>",
  )
}

///|
test "edge labels, junctions, and titles" {
  inspect(
    svg(
      "architecture-beta\ntitle Platform\nservice a[Alpha]\nservice b[Beta]\njunction j\na:R -[calls]- L:j\nj:R --> L:b",
    ),
    content="256x128 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 256 128\" width=\"256\" height=\"128\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"128\" y=\"25.6\">Platform</tspan></text><g transform=\"translate(8,44)\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"a-j\"><path d=\"M48,24L128,24\"/></g><g class=\"pele-edge\" data-id=\"j-b\"><path d=\"M128,24L185,24\"/><path class=\"pele-marker\" d=\"M192,24L184,27.36L184,20.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"a-j\"><rect x=\"70\" y=\"13.5\" width=\"36\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"88\" y=\"28.9\" text-anchor=\"middle\">calls</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(24,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Alpha</text></g><g class=\"pele-node pele-service\" data-id=\"b\" transform=\"translate(216,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Beta</text></g><g class=\"pele-node pele-junction\" data-id=\"j\" transform=\"translate(128,0)\"><circle cy=\"24\" r=\"3\" fill=\"var(--_l)\"/></g></g></g></svg>",
  )
  inspect(
    svg(
      "architecture-beta\nservice a[Alpha]\nservice b[Beta]\na:B -[a long label on a vertical edge]-> T:b",
    ),
    content=(
      #|176x228 <svg xmlns="http://www.w3.org/2000/svg" class="pele pele-architecture" viewBox="0 0 176 228" width="176" height="228" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)" role="graphics-document document" aria-roledescription="architecture"><g transform="translate(8,8)"><g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round" stroke-linejoin="round"><g class="pele-edge" data-id="a-b"><path d="M80,78L80,129"/><path class="pele-marker" d="M80,136L76.64,128L83.36,128Z" fill="var(--_l)" stroke="none"/></g></g><g class="pele-edge-labels" font-size="14"><g class="pele-edge-label" data-id="a-b"><rect x="0.52" y="89" width="158.96" height="36" rx="3" fill="var(--_bg)"/><text text-anchor="middle" xml:space="preserve"><tspan x="80" y="102.9">a long label on a vertical</tspan><tspan x="80" y="120.9">edge</tspan></text></g></g><g class="pele-nodes"><g class="pele-node pele-service" data-id="a" transform="translate(80,0)"><rect x="-24" width="48" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="69.6" text-anchor="middle">Alpha</text></g><g class="pele-node pele-service" data-id="b" transform="translate(80,136)"><rect x="-24" width="48" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" x="0" y="69.6" text-anchor="middle">Beta</text></g></g></g></svg>
    ),
  )
  inspect(
    svg("---\ntitle: From front matter\n---\narchitecture-beta\nservice a"),
    content="151x100 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 151 100\" width=\"151\" height=\"100\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"75.5\" y=\"25.6\">From front matter</tspan></text><g transform=\"translate(52,44)\"><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(24,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g></g></g></svg>",
  )
}

///|
test "group edges start at the border of the group" {
  inspect(
    svg(
      "architecture-beta\ngroup one\ngroup two\nservice a in one\nservice b in two\na{group}:B --> T:b{group}",
    ),
    content="104x232 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 104 232\" width=\"104\" height=\"232\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"one\"><rect x=\"0\" y=\"0\" width=\"88\" height=\"88\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g><g class=\"pele-cluster\" data-id=\"two\"><rect x=\"0\" y=\"128\" width=\"88\" height=\"88\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"a-b\"><path d=\"M44,88L44,121\"/><path class=\"pele-marker\" d=\"M44,128L40.64,120L47.36,120Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(44,20)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g><g class=\"pele-node pele-service\" data-id=\"b\" transform=\"translate(44,148)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g></g></g></svg>",
  )
  inspect(
    svg(
      "architecture-beta\ngroup one\ngroup two\njunction a in one\njunction b in two\na{group}:R --> L:b{group}",
    ),
    content="232x104 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 232 104\" width=\"232\" height=\"104\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"one\"><rect x=\"0\" y=\"0\" width=\"88\" height=\"88\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g><g class=\"pele-cluster\" data-id=\"two\"><rect x=\"128\" y=\"0\" width=\"88\" height=\"88\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"a-b\"><path d=\"M44,44L172,44\"/><path class=\"pele-marker\" d=\"M128,44L120,47.36L120,40.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-junction\" data-id=\"a\" transform=\"translate(44,20)\"><circle cy=\"24\" r=\"3\" fill=\"var(--_l)\"/></g><g class=\"pele-node pele-junction\" data-id=\"b\" transform=\"translate(172,20)\"><circle cy=\"24\" r=\"3\" fill=\"var(--_l)\"/></g></g></g></svg>",
  )
}

///|
test "icons, icon text, and group badges" {
  inspect(
    svg(
      "architecture-beta\ngroup g(cloud)[G]\nservice a(database)[A] in g\nservice b(logos:aws-lambda)[B] in g\nservice c \"S3\"[C]\nservice d",
    ),
    content="192x264 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 192 264\" width=\"192\" height=\"264\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"g\"><rect x=\"0\" y=\"116\" width=\"176\" height=\"132\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"cloud\" x=\"10\" y=\"124\" width=\"20\" height=\"20\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M7 18a4 4 0 0 1-.5-7.97A6 6 0 0 1 18 9.5a4.25 4.25 0 0 1-.5 8.5z\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"42.22\" y=\"139.6\" text-anchor=\"middle\">G</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(44,152)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"database\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 6a8 3 0 1 0 16 0a8 3 0 1 0-16 0M4 6v12a8 3 0 0 0 16 0V6M4 12a8 3 0 0 0 16 0\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-service\" data-id=\"b\" transform=\"translate(132,152)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"logos:aws-lambda\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">B</text></g><g class=\"pele-node pele-service\" data-id=\"c\" transform=\"translate(44,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-icon-text\" font-size=\"12\" x=\"0\" y=\"28.2\" text-anchor=\"middle\">S3</text><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">C</text></g><g class=\"pele-node pele-service\" data-id=\"d\" transform=\"translate(132,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g></g></g></svg>",
  )
  inspect(
    svg(
      "architecture-beta\nservice a \"A very long icon text that has to be cut down to fit\"[A]\nservice b \"Wonderfully\"[B]",
    ),
    content=(
      #|152x92 <svg xmlns="http://www.w3.org/2000/svg" class="pele pele-architecture" viewBox="0 0 152 92" width="152" height="92" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)" role="graphics-document document" aria-roledescription="architecture"><g transform="translate(8,8)"><g class="pele-nodes"><g class="pele-node pele-service" data-id="a" transform="translate(24,0)"><rect x="-24" width="48" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-icon-text" font-size="12" text-anchor="middle" xml:space="preserve"><tspan x="0" y="20.2">A very</tspan><tspan x="0" y="36.2">long…</tspan></text><text class="pele-label" x="0" y="69.6" text-anchor="middle">A</text></g><g class="pele-node pele-service" data-id="b" transform="translate(112,0)"><rect x="-24" width="48" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-icon-text" font-size="12" x="0" y="28.2" text-anchor="middle">Wond…</text><text class="pele-label" x="0" y="69.6" text-anchor="middle">B</text></g></g></g></svg>
    ),
  )
}

///|
test "layout options" {
  inspect(
    svg(
      "---\nconfig:\n  architecture:\n    iconSize: 96\n---\narchitecture-beta\ngroup g[G]\nservice a[A] in g\nservice b[B] in g\na:R -- L:b",
    ),
    content="320x196 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 320 196\" width=\"320\" height=\"196\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"g\"><rect x=\"0\" y=\"0\" width=\"304\" height=\"180\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"16.22\" y=\"23.6\" text-anchor=\"middle\">G</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"a-b\"><path d=\"M116,84L188,84\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(68,36)\"><rect x=\"-48\" width=\"96\" height=\"96\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"117.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-service\" data-id=\"b\" transform=\"translate(236,36)\"><rect x=\"-48\" width=\"96\" height=\"96\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"117.6\" text-anchor=\"middle\">B</text></g></g></g></svg>",
  )
  inspect(
    svg(
      "---\nconfig:\n  architecture:\n    padding: 60\n---\narchitecture-beta\ngroup g[G]\nservice a[A] in g\nservice b[B] in g\na:R -- L:b",
    ),
    content="272x212 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 272 212\" width=\"272\" height=\"212\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"g\"><rect x=\"0\" y=\"0\" width=\"256\" height=\"196\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"16.22\" y=\"23.6\" text-anchor=\"middle\">G</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"a-b\"><path d=\"M108,84L148,84\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(84,60)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-service\" data-id=\"b\" transform=\"translate(172,60)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">B</text></g></g></g></svg>",
  )
  inspect(
    svg(
      "---\nconfig:\n  architecture:\n    fontSize: 24\n---\narchitecture-beta\ngroup g[G]\nservice a[A] in g\nservice b[B] in g\na:R -- L:b",
    ),
    content="192x172 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 192 172\" width=\"192\" height=\"172\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:24px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"g\"><rect x=\"0\" y=\"0\" width=\"176\" height=\"156\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"19.34\" y=\"32.4\" text-anchor=\"middle\">G</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"a-b\"><path d=\"M68,72L108,72\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(44,48)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"78.4\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-service\" data-id=\"b\" transform=\"translate(132,48)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"78.4\" text-anchor=\"middle\">B</text></g></g></g></svg>",
  )
  inspect(
    svg(
      "---\nconfig:\n  architecture:\n    iconSize: -5\n---\narchitecture-beta\ngroup g[G]\nservice a[A] in g\nservice b[B] in g\na:R -- L:b",
    ),
    content="120x108 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 120 108\" width=\"120\" height=\"108\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"g\"><rect x=\"0\" y=\"0\" width=\"104\" height=\"92\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"16.22\" y=\"23.6\" text-anchor=\"middle\">G</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"a-b\"><path d=\"M30,40L74,40\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(26,36)\"><rect x=\"-4\" width=\"8\" height=\"8\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"29.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-service\" data-id=\"b\" transform=\"translate(78,36)\"><rect x=\"-4\" width=\"8\" height=\"8\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"29.6\" text-anchor=\"middle\">B</text></g></g></g></svg>",
  )
}

///|
test "an empty diagram and an empty group" {
  inspect(
    svg("architecture-beta\n"),
    content="16x16 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 16 16\" width=\"16\" height=\"16\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"></svg>",
  )
  inspect(
    svg("architecture-beta\ngroup g[Nothing here]\ngroup h in g"),
    content="144x136 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 144 136\" width=\"144\" height=\"136\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"g\"><rect x=\"0\" y=\"0\" width=\"128\" height=\"120\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"55.8\" y=\"23.6\" text-anchor=\"middle\">Nothing here</text></g><g class=\"pele-cluster\" data-id=\"h\"><rect x=\"20\" y=\"36\" width=\"88\" height=\"64\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g></g></g></svg>",
  )
}

///|
test "group titles step past edges that come down through their corner" {
  inspect(
    svg(
      "architecture-beta\ngroup g[A rather long group title]\nservice top[Top]\nservice a[A] in g\nservice b[B] in g\ntop:B --> T:a\na:R -- L:b",
    ),
    content="203x264 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 203 264\" width=\"203\" height=\"264\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"g\"><rect x=\"0\" y=\"116\" width=\"187\" height=\"132\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"93.15\" y=\"139.6\" text-anchor=\"middle\">A rather long group title</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"top-a\"><path d=\"M44,78L44,145\"/><path class=\"pele-marker\" d=\"M44,152L40.64,144L47.36,144Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"a-b\"><path d=\"M68,176L108,176\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"top\" transform=\"translate(44,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Top</text></g><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(44,152)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-service\" data-id=\"b\" transform=\"translate(132,152)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">B</text></g></g></g></svg>",
  )
}

///|
test "a narrow host tightens the layout" {
  inspect(
    svg(
      "architecture-beta\ntitle A title that is long enough to wrap\ngroup g[A group title that is quite long]\nservice a[Alpha service] in g\nservice b[Beta service] in g\nservice c[Gamma]\na:R -[calls]-> L:b\nb:R -- L:c",
      max_width=400,
    ),
    content="398x184 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 398 184\" width=\"398\" height=\"184\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"199\" y=\"25.6\">A title that is long enough to wrap</tspan></text><g transform=\"translate(8,44)\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"g\"><rect x=\"0\" y=\"0\" width=\"284\" height=\"132\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"113.17\" y=\"23.6\" text-anchor=\"middle\">A group title that is quite long</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"a-b\"><path d=\"M93,60L188,60\"/><path class=\"pele-marker\" d=\"M195,60L187,63.36L187,56.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"b-c\"><path d=\"M243,60L329,60\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"a-b\"><rect x=\"126\" y=\"49.5\" width=\"36\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"144\" y=\"64.9\" text-anchor=\"middle\">calls</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(69,36)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Alpha service</text></g><g class=\"pele-node pele-service\" data-id=\"b\" transform=\"translate(219,36)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Beta service</text></g><g class=\"pele-node pele-service\" data-id=\"c\" transform=\"translate(353,36)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">Gamma</text></g></g></g></svg>",
  )
}

///|
/// A host that has exactly the icons in `pairs`, by name.
fn host(pairs : Array[(String, String)]) -> @types.IconResolver {
  let icons = Map::from_array(pairs)
  name => icons.get(name)
}

///|
test "groups, services and labels draw the icons the host has" {
  inspect(
    svg(
      "architecture-beta\n  group api(cloud)[API]\n  service db(database)[fa:fa-car DB] in api\n",
      icons=host([
        ("cloud", "<path id=\"c\"/>"),
        ("fa:fa-car", "<path id=\"car\"/>"),
      ]),
    ),
    content="104x148 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 104 148\" width=\"104\" height=\"148\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"api\"><rect x=\"0\" y=\"0\" width=\"88\" height=\"132\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"cloud\" x=\"10\" y=\"8\" width=\"20\" height=\"20\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"c\"/></svg><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"48.9\" y=\"23.6\" text-anchor=\"middle\">API</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"db\" transform=\"translate(44,36)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"database\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 6a8 3 0 1 0 16 0a8 3 0 1 0-16 0M4 6v12a8 3 0 0 0 16 0V6M4 12a8 3 0 0 0 16 0\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"-3.34\" y=\"69.6\" text-anchor=\"start\"> DB</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-23.34\" y=\"55.2\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g></g></svg>",
  )
}

///|
test "an empty drawing from the host replaces a built-in icon" {
  inspect(
    svg(
      "architecture-beta\n  group api(cloud)[API]\n  service db(database)[DB] in api\n",
      icons=host([("cloud", "")]),
    ),
    content="104x148 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 104 148\" width=\"104\" height=\"148\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"api\"><rect x=\"0\" y=\"0\" width=\"88\" height=\"132\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"cloud\" x=\"10\" y=\"8\" width=\"20\" height=\"20\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"48.9\" y=\"23.6\" text-anchor=\"middle\">API</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"db\" transform=\"translate(44,36)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"database\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 6a8 3 0 1 0 16 0a8 3 0 1 0-16 0M4 6v12a8 3 0 0 0 16 0V6M4 12a8 3 0 0 0 16 0\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">DB</text></g></g></g></svg>",
  )
}

///|
test "edge labels draw the icons the host has" {
  inspect(
    svg(
      "architecture-beta\n  service a(server)[A]\n  service b(server)[B]\n  a:R -[fa:fa-car x]- L:b\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="169x92 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-architecture\" viewBox=\"0 0 169 92\" width=\"169\" height=\"92\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"architecture\"><g transform=\"translate(8,8)\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><g class=\"pele-edge\" data-id=\"a-b\"><path d=\"M48,24L105,24\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"a-b\"><rect x=\"58.3\" y=\"13.5\" width=\"36.39\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"79.8\" y=\"28.9\" text-anchor=\"start\"> x</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"62.3\" y=\"16.3\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-service\" data-id=\"a\" transform=\"translate(24,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"server\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M3 4h18v7H3zM3 13h18v7H3zM7 7.5h.01M7 16.5h.01M11 7.5h6M11 16.5h6\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-service\" data-id=\"b\" transform=\"translate(129,0)\"><rect x=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><svg class=\"pele-icon\" data-icon=\"server\" x=\"-12\" y=\"12\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M3 4h18v7H3zM3 13h18v7H3zM7 7.5h.01M7 16.5h.01M11 7.5h6M11 16.5h6\" stroke=\"var(--_fg)\" stroke-width=\"1.5\"/></svg><text class=\"pele-label\" x=\"0\" y=\"69.6\" text-anchor=\"middle\">B</text></g></g></g></svg>",
  )
}

///|
test "icon text cut short ends with an ellipsis after its last text" {
  inspect(
    svg(
      "architecture-beta\n  service s \"aaaa fa:fa-car fa:fa-car fa:fa-car\"[T]\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content=(
      #|64x92 <svg xmlns="http://www.w3.org/2000/svg" class="pele pele-architecture" viewBox="0 0 64 92" width="64" height="92" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)" role="graphics-document document" aria-roledescription="architecture"><g transform="translate(8,8)"><g class="pele-nodes"><g class="pele-node pele-service" data-id="s" transform="translate(24,0)"><rect x="-24" width="48" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-icon-text" font-size="12" text-anchor="middle" xml:space="preserve"><tspan x="0" y="20.2">aaaa</tspan><tspan x="4.02" y="36.2" text-anchor="start">…</tspan></text><svg class="pele-icon" data-icon="fa:fa-car" x="-10.98" y="25.4" width="13.2" height="13.2" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path id="car"/></svg><text class="pele-label" x="0" y="69.6" text-anchor="middle">T</text></g></g></g></svg>
    ),
  )
}
