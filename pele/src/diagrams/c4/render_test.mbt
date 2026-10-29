// Ported from pele v1.8.0, tests/render/c4.test.ts.
// pele reads the markup back with regular expressions; here the same values are read with string searches.

///|
fn drawn(
  source : String,
  max_width? : Double,
  font_size? : Double,
) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), max_width, font_size, }
  Ok(@core.render([@c4.c4], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn svg_of(source : String, max_width? : Double) -> String {
  match drawn(source, max_width?) {
    Ok(result) => result.svg
    Err(failure) => failure.message
  }
}

///|
fn failure_of(source : String) -> @errors.Failure {
  match drawn(source) {
    Ok(_) => abort("expected an error")
    Err(failure) => failure
  }
}

///|
fn model(source : String) -> @c4.C4Db {
  let db = @c4.C4Db::new()
  @c4.parse_c4(source, db) catch {
    _ => abort("expected a model")
  }
  db
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
/// The number written at `at`, as `[-\d.]+` reads it, and where it ends.
fn number_at(text : String, at : Int32) -> (Double, Int32) {
  let mut end = at
  while end < text.length() {
    let c = @util.code_at(text, end)
    if (c >= 48 && c <= 57) || c == 45 || c == 46 {
      end += 1
    } else {
      break
    }
  }
  (@util.to_number(@util.slice(text, at, end~)), end)
}

///|
/// The value of the attribute `name` in the first tag at or after `from`.
fn attr_after(text : String, name : String, from : Int32) -> Double {
  let at = @util.index_of(text, " \{name}=\"", from~)
  number_at(text, at + name.length() + 3).0
}

///|
/// The whole tag `<name ...>` that comes first after `marker`.
fn tag_after(text : String, marker : String, name : String) -> String {
  let at = @util.index_of(text, marker)
  guard at != -1 else { return "" }
  let start = @util.index_of(text, "<" + name, from=at)
  guard start != -1 else { return "" }
  @util.slice(text, start, end=@util.index_of(text, ">", from=start) + 1)
}

///|
/// The whole tag that `marker` is written in.
fn tag_with(text : String, marker : String) -> String {
  let at = @util.index_of(text, marker)
  guard at != -1 else { return "" }
  let start = @util.last_index_of(text, "<", from=at)
  @util.slice(text, start, end=@util.index_of(text, ">", from=at) + 1)
}

///|
/// The names of the elements opened after `marker`, up to the end of the group it is in.
fn tags_in(text : String, marker : String) -> Array[String] {
  let at = @util.index_of(text, marker)
  let end = @util.index_of(text, "</g>", from=at)
  let names = []
  let mut i = @util.index_of(text, ">", from=at) + 1
  while i < end {
    if @util.code_at(text, i) == 60 && @util.code_at(text, i + 1) != 47 {
      let mut j = i + 1
      while @util.is_word(@util.code_at(text, j)) {
        j += 1
      }
      names.push(@util.slice(text, i + 1, end=j))
    }
    i += 1
  }
  names
}

///|
/// The box of a shape or boundary, read back from the markup; for a person it is the body, without the head.
fn box(svg : String, id : String) -> (Double, Double, Double, Double) {
  let marker = "data-id=\"\{id}\" transform=\"translate("
  let node = @util.index_of(svg, marker)
  if node != -1 {
    let (tx, end) = number_at(svg, node + marker.length())
    let (ty, _) = number_at(svg, end + 1)
    let mut tag = @util.index_of(svg, "><", from=node) + 1
    if @util.starts_with_at(svg, "<a ", tag) {
      tag = @util.index_of(svg, "><", from=tag) + 1
    }
    if @util.starts_with_at(svg, "<rect ", tag) {
      return (
        tx + attr_after(svg, "x", tag),
        ty + attr_after(svg, "y", tag),
        attr_after(svg, "width", tag),
        attr_after(svg, "height", tag),
      )
    }
  }
  let group = @util.index_of(svg, "data-id=\"\{id}\"><rect ")
  guard group != -1 else { abort("No box for \{id}") }
  (
    attr_after(svg, "x", group),
    attr_after(svg, "y", group),
    attr_after(svg, "width", group),
    attr_after(svg, "height", group),
  )
}

///|
fn label_rect(svg : String, id : String) -> Int32 {
  let at = @util.index_of(svg, "class=\"pele-edge-label\" data-id=\"\{id}\">")
  @util.index_of(svg, "<rect ", from=at)
}

///|
fn label_x(svg : String, id : String) -> Double {
  attr_after(svg, "x", label_rect(svg, id))
}

///|
fn label_y(svg : String, id : String) -> Double {
  attr_after(svg, "y", label_rect(svg, id))
}

///|
/// The `d` of the line of a relation.
fn line_of(svg : String, id : String) -> String {
  let at = @util.index_of(svg, "class=\"pele-edge\" data-id=\"\{id}\"")
  guard at != -1 else { return "" }
  let d = @util.index_of(svg, "<path d=\"", from=at) + 9
  @util.slice(svg, d, end=@util.index_of(svg, "\"", from=d))
}

///|
/// The numbers of a path that is one straight line, `M x0,y0 L x1,y1`.
fn straight(d : String) -> (Double, Double, Double, Double) {
  guard d.has_prefix("M") else { abort("not a line: \{d}") }
  let (x0, e0) = number_at(d, 1)
  let (y0, e1) = number_at(d, e0 + 1)
  guard @util.code_at(d, e1) == 76 else { abort("not a line: \{d}") }
  let (x1, e2) = number_at(d, e1 + 1)
  let (y1, _) = number_at(d, e2 + 1)
  (x0, y0, x1, y1)
}

///|
/// The corners of a path of straight stretches and rounded corners, a rounded corner read as the corner itself.
fn corners(d : String) -> Array[Double] {
  let points = []
  let mut i = 0
  while i < d.length() {
    let op = @util.code_at(d, i)
    let mut j = i + 1
    while j < d.length() && !(@util.code_at(d, j) is (77 | 76 | 72 | 86 | 81)) {
      j += 1
    }
    let numbers = []
    let mut k = i + 1
    while k < j {
      let c = @util.code_at(d, k)
      if c == 32 || c == 44 {
        k += 1
        continue
      }
      let (value, end) = number_at(d, k)
      numbers.push(value)
      k = end
    }
    let (x, y) = if points.length() > 0 {
      (points[points.length() - 2], points[points.length() - 1])
    } else {
      (0.0, 0.0)
    }
    match op {
      72 => {
        points.push(numbers[0])
        points.push(y)
      }
      86 => {
        points.push(x)
        points.push(numbers[0])
      }
      81 => {
        points.push(numbers[0])
        points.push(numbers[1])
      }
      _ => {
        points.push(numbers[numbers.length() - 2])
        points.push(numbers[numbers.length() - 1])
      }
    }
    i = j
  }
  points
}

///|
/// The relations drawn without a curve, by id, with their corners.
fn lines_of(svg : String) -> Array[(String, Array[Double])] {
  let out = []
  let marker = "class=\"pele-edge\" data-id=\""
  let mut at = @util.index_of(svg, marker)
  while at != -1 {
    let start = at + marker.length()
    let id = @util.slice(svg, start, end=@util.index_of(svg, "\"", from=start))
    let d = line_of(svg, id)
    if !d.contains("C") {
      out.push((id, corners(d)))
    }
    at = @util.index_of(svg, marker, from=start)
  }
  out
}

///|
fn corners_of(svg : String, id : String) -> Array[Double] {
  corners(line_of(svg, id))
}

///|
fn component_doc() -> String {
  for doc in docs {
    if doc.contains("Accounts Summary Controller") {
      return doc
    }
  }
  abort("no component diagram")
}

///|
test "draws shapes, boundaries, and relations" {
  let result = drawn(
    (
      #|C4Context
      #|title System Context
      #|Person(user, "User", "Uses the bank")
      #|Enterprise_Boundary(bank, "Bank") {
      #|  System(app, "Banking", "Moves money")
      #|  SystemDb_Ext(ledger, "Ledger")
      #|}
      #|Rel(user, app, "Uses", "HTTPS")
      #|BiRel(app, ledger, "Syncs")
    ),
  ).unwrap()
  let svg = result.svg
  inspect(result.kind, content="c4")
  assert_true(svg.contains("class=\"pele pele-c4\""))
  inspect(count(svg, "class=\"pele-node "), content="3")
  inspect(count(svg, "class=\"pele-cluster "), content="1")
  inspect(count(svg, "class=\"pele-edge\""), content="2")
  inspect(count(svg, "class=\"pele-edge-label\""), content="2")
  inspect(count(svg, "class=\"pele-marker\""), content="3")
  assert_true(svg.contains(">System Context<"))
  assert_true(svg.contains("«person»"))
  assert_true(svg.contains("«external system db»"))
  assert_true(svg.contains(">[HTTPS]<"))
  assert_true(svg.contains(">[ENTERPRISE]<"))
}

///|
test "accepts all five diagram keywords" {
  for
    keyword in [
      "C4Context", "C4Container", "C4Component", "C4Dynamic", "C4Deployment",
    ] {
    assert_eq(model("\{keyword}\nPerson(a, \"A\")").c4_type, Some(keyword))
    assert_true(
      svg_of("\{keyword}\nPerson(a, \"A\")").contains("data-id=\"a\""),
    )
  }
}

///|
test "gives each kind of element its shape" {
  let svg = svg_of(
    (
      #|C4Container
      #|Person(p, "P")
      #|Person_Ext(pe, "PE")
      #|System(s, "S")
      #|SystemDb(sd, "SD")
      #|SystemQueue(sq, "SQ")
      #|Container_Ext(ce, "CE", "Go")
      #|ContainerDb_Ext(cde, "CDE")
      #|ComponentQueue_Ext(cqe, "CQE")
    ),
  )
  let person = tags_in(svg, "pele-shape-person pele-c4-person\" data-id=\"p\"")
  assert_eq(person[:2].to_owned(), ["rect", "circle"])
  assert_true(
    svg.contains(
      "pele-shape-person pele-c4-external_person pele-c4-external\" data-id=\"pe\"",
    ),
  )
  assert_true(svg.contains("pele-shape-rect pele-c4-system\" data-id=\"s\""))
  assert_true(svg.contains("pele-shape-cyl pele-c4-system_db\" data-id=\"sd\""))
  assert_true(
    svg.contains("pele-shape-h-cyl pele-c4-system_queue\" data-id=\"sq\""),
  )
  assert_true(
    svg.contains(
      "pele-shape-cyl pele-c4-external_container_db pele-c4-external\" data-id=\"cde\"",
    ),
  )
  assert_true(
    svg.contains(
      "pele-shape-h-cyl pele-c4-external_component_queue pele-c4-external\" data-id=\"cqe\"",
    ),
  )
  // External elements are hollow with a dashed border; the rest are filled.
  assert_true(
    tag_after(svg, "data-id=\"ce\"", "rect").contains(
      "fill=\"var(--_bg)\" stroke=\"var(--_b)\" stroke-dasharray=\"4 3\"",
    ),
  )
  assert_true(
    tag_after(svg, "data-id=\"s\"", "rect").has_suffix(
      "fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/>",
    ),
  )
}

///|
test "takes a shape from $shape, $sprite or $tags, as Mermaid does" {
  let svg = svg_of(
    (
      #|C4Context
      #|System(a, "A", $tags="v1, cylinder")
      #|System(b, "B", $sprite="queue")
      #|System(c, "C")
      #|UpdateElementStyle(c, $shape="Person")
      #|System(d, "D", $tags="constructor")
    ),
  )
  assert_true(svg.contains("pele-shape-cyl pele-c4-system\" data-id=\"a\""))
  assert_true(svg.contains("pele-shape-h-cyl pele-c4-system\" data-id=\"b\""))
  assert_true(svg.contains("pele-shape-person pele-c4-system\" data-id=\"c\""))
  assert_true(svg.contains("pele-shape-rect pele-c4-system\" data-id=\"d\""))
}

///|
test "writes the type, name, technology, and description of a shape" {
  let svg = svg_of(
    "C4Container\nContainer(api, \"API\", \"Node.js\", \"Serves <b>requests</b><br/>all day\")",
  )
  assert_true(svg.contains("«container»"))
  let name = tag_with(svg, "class=\"pele-label\" font-weight=\"var(--_hw)\"")
  let mut rest = @util.index_of(svg, name) + name.length()
  if @util.starts_with_at(svg, "<tspan", rest) {
    rest = @util.index_of(svg, ">", from=rest) + 1
  }
  assert_true(@util.starts_with_at(svg, "API<", rest))
  assert_true(svg.contains(">[Node.js]<"))
  assert_true(svg.contains("font-weight=\"var(--_w)\">requests</tspan>"))
  assert_true(svg.contains("all day"))
  assert_false(svg.contains("&lt;br"))
}

///|
test "wraps long text inside a fixed width and widens for a word that cannot wrap" {
  let wrapped = svg_of("C4Context\nSystem(a, \"A\", \"\{"word ".repeat(40)}\")")
  inspect(box(wrapped, "a").2, content="216")
  assert_true(box(wrapped, "a").3 > 150)
  let wide = svg_of("C4Context\nSystem(a, \"\{"W".repeat(40)}\")")
  assert_true(box(wide, "a").2 > 400)
}

///|
test "lays shapes out in rows of four and boundaries in rows of two by default" {
  let svg = svg_of(
    (
      #|C4Context
      #|System(s1, "S1")
      #|System(s2, "S2")
      #|System(s3, "S3")
      #|System(s4, "S4")
      #|System(s5, "S5")
      #|Boundary(b1, "B1") {
      #| System(i1, "I1")
      #|}
      #|Boundary(b2, "B2") {
      #| System(i2, "I2")
      #|}
      #|Boundary(b3, "B3") {
      #| System(i3, "I3")
      #|}
    ),
  )
  let s = [1, 2, 3, 4, 5].map(i => box(svg, "s\{i}"))
  for i in 1..<4 {
    assert_eq(s[i].1, s[0].1)
  }
  assert_true(s[1].0 > s[0].0 + s[0].2)
  assert_eq(s[4].0, s[0].0)
  assert_true(s[4].1 > s[0].1 + s[0].3)
  let b = [1, 2, 3].map(i => box(svg, "b\{i}"))
  assert_true(b[0].1 > s[4].1 + s[4].3)
  assert_eq(b[1].1, b[0].1)
  assert_true(b[1].0 > b[0].0 + b[0].2)
  assert_eq(b[2].0, b[0].0)
  assert_true(b[2].1 > b[0].1 + b[0].3)
}

///|
test "follows UpdateLayoutConfig" {
  let src = (config : String) => {
    "C4Context\nSystem(a, \"A\")\nSystem(b, \"B\")\nSystem(c, \"C\")\nBoundary(x, \"X\") {\n System(d, \"D\")\n}\nBoundary(y, \"Y\") {\n System(e, \"E\")\n}\n\{config}"
  }
  let stacked = svg_of(
    src("UpdateLayoutConfig($c4ShapeInRow=\"1\", $c4BoundaryInRow=\"1\")"),
  )
  assert_eq(box(stacked, "b").0, box(stacked, "a").0)
  assert_true(box(stacked, "b").1 > box(stacked, "a").1)
  assert_eq(box(stacked, "y").0, box(stacked, "x").0)
  let positional = svg_of(src("UpdateLayoutConfig(\"2\", \"2\")"))
  assert_eq(box(positional, "b").1, box(positional, "a").1)
  assert_true(box(positional, "c").1 > box(positional, "a").1)
  assert_eq(box(positional, "y").1, box(positional, "x").1)
  // Values below one are ignored. The slot decides what a value sets, not its name, as in Mermaid.
  assert_eq(model(src("UpdateLayoutConfig(\"0\", \"-3\")")).shape_in_row, 4)
  assert_eq(
    model(src("UpdateLayoutConfig($c4BoundaryInRow=\"3\")")).shape_in_row,
    3,
  )
  assert_eq(
    model(src("UpdateLayoutConfig($c4BoundaryInRow=\"3\")")).boundary_in_row,
    2,
  )
}

///|
test "nests boundaries and sizes each around what it holds" {
  let svg = svg_of(
    (
      #|C4Deployment
      #|Deployment_Node(outer, "Outer", "Linux", "A machine") {
      #|  Node(inner, "Inner") {
      #|    Container(app, "App")
      #|  }
      #|  Node_L(left, "Left") {
      #|    Container(other, "Other")
      #|  }
      #|}
    ),
  )
  let inside = (
    a : (Double, Double, Double, Double),
    b : (Double, Double, Double, Double),
  ) => a.0 > b.0 && a.1 > b.1 && a.0 + a.2 < b.0 + b.2 && a.1 + a.3 < b.1 + b.3
  let outer = box(svg, "outer")
  let inner = box(svg, "inner")
  assert_true(inside(inner, outer))
  assert_true(inside(box(svg, "app"), inner))
  assert_true(inside(box(svg, "left"), outer))
  assert_true(svg.contains(">[Linux]<"))
  assert_true(svg.contains(">A machine<"))
  assert_true(svg.contains(">[node]<"))
  // Deployment nodes have a solid border; other boundaries are dashed.
  assert_true(
    tag_after(
      svg, "class=\"pele-cluster pele-c4-node\" data-id=\"outer\">", "rect",
    ).has_suffix("stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/>"),
  )
  let dashed = svg_of("C4Context\nBoundary(b, \"B\") {\nSystem(s, \"S\")\n}")
  assert_true(
    tag_after(
      dashed, "class=\"pele-cluster pele-c4-boundary\" data-id=\"b\">", "rect",
    ).has_suffix("stroke-dasharray=\"6 4\" style=\"rx:var(--_r)\"/>"),
  )
}

///|
test "labels each kind of boundary with its type" {
  let svg = svg_of(
    (
      #|C4Container
      #|Enterprise_Boundary(e, "E") {
      #|  System_Boundary(s, "S") {
      #|    Container_Boundary(c, "C") {
      #|      Boundary(b, "B") {
      #|        Boundary(t, "T", "custom") {
      #|          System(x, "X")
      #|        }
      #|      }
      #|    }
      #|  }
      #|}
    ),
  )
  for type_ in ["ENTERPRISE", "SYSTEM", "CONTAINER", "system", "custom"] {
    assert_true(svg.contains(">[\{type_}]<"))
  }
}

///|
test "draws an arrowhead for each end a relation points at" {
  let markers = (rel : String) => {
    count(
      svg_of("C4Context\nSystem(a, \"A\")\nSystem(b, \"B\")\n\{rel}"),
      "pele-marker",
    )
  }
  for
    name in [
      "Rel", "Rel_U", "Rel_Up", "Rel_D", "Rel_Down", "Rel_L", "Rel_Left", "Rel_R",
      "Rel_Right",
    ] {
    assert_eq(markers("\{name}(a, b, \"x\")"), 1)
  }
  assert_eq(markers("BiRel(a, b, \"x\")"), 2)
  assert_eq(markers("Rel_Back(a, b, \"x\")"), 1)
  let forward = svg_of(
    "C4Context\nSystem(a, \"A\")\nSystem(b, \"B\")\nRel(a, b, \"x\")",
  )
  let back = svg_of(
    "C4Context\nSystem(a, \"A\")\nSystem(b, \"B\")\nRel_Back(a, b, \"x\")",
  )
  let tip = (svg : String) => {
    let marker = "class=\"pele-marker\" d=\"M"
    number_at(svg, @util.index_of(svg, marker) + marker.length()).0
  }
  assert_eq(tip(forward), box(forward, "b").0)
  assert_eq(tip(back), box(back, "a").0 + box(back, "a").2)
}

///|
test "ignores the index of RelIndex and a relation without a label" {
  let m = model(
    "C4Dynamic\nSystem(a, \"A\")\nSystem(b, \"B\")\nRelIndex(7, a, b, \"x\")\nRel(b, \"a\")",
  )
  inspect(m.rels.length(), content="1")
  assert_eq(
    (m.rels[0].type_, m.rels[0].from, m.rels[0].to, m.rels[0].label),
    ("rel", "a", "b", "x"),
  )
}

///|
test "numbers relations in a dynamic diagram" {
  let src = "System(a, \"A\")\nSystem(b, \"B\")\nSystem(c, \"C\")\nRel(a, b, \"first\")\nRel(b, c, \"second\")"
  let dynamic = svg_of("C4Dynamic\n" + src)
  assert_true(dynamic.contains(">1: first<"))
  assert_true(dynamic.contains(">2: second<"))
  assert_true(svg_of("C4Context\n" + src).contains(">first<"))
}

///|
test "joins neighbours with a straight line between their borders" {
  let svg = svg_of(
    "C4Context\nSystem(a, \"A\")\nSystem(b, \"B\")\nRel(a, b, \"x\")",
  )
  let a = box(svg, "a")
  let b = box(svg, "b")
  let (x0, y0, x1, y1) = straight(line_of(svg, "a-b"))
  assert_eq(x0, a.0 + a.2)
  assert_eq(y0, a.1 + a.3 / 2)
  assert_true((x1 - (b.0 - 7)).abs() < 0.000005)
  assert_eq(y1, y0)
}

///|
test "fits the label of a line between neighbours in the gap between them" {
  for
    args in [
      "\"Sends a fairly long description of the relationship\"", "\"Makes API calls to\", \"JSON/HTTPS\"",
    ] {
    let svg = svg_of(
      "C4Context\nSystem(a, \"A\")\nSystem(b, \"B\")\nRel(a, b, \{args})",
    )
    let a = box(svg, "a")
    let b = box(svg, "b")
    let label = box(svg, "a-b")
    assert_eq(b.1, a.1)
    assert_true(label.0 >= a.0 + a.2)
    assert_true(label.0 + label.2 <= b.0)
  }
}

///|
test "ends a line on the outline of a person, a database, and a queue" {
  let svg = svg_of(
    (
      #|C4Context
      #|UpdateLayoutConfig("1", "1")
      #|Person(p, "P")
      #|SystemDb(d, "D")
      #|SystemQueue(q, "Q")
      #|Rel(p, d, "x")
      #|Rel(d, q, "y")
    ),
  )
  let p = box(svg, "p")
  let (_, py0, _, py1) = straight(line_of(svg, "p-d"))
  assert_eq(py0, p.1 + p.3)
  // The top of a cylinder is the crown of its lid: one radius above where its side starts.
  let lid_marker = "data-id=\"d\" transform=\"translate("
  let lid = @util.index_of(svg, lid_marker)
  let (_, end) = number_at(svg, lid + lid_marker.length())
  let (ty, _) = number_at(svg, end + 1)
  let d = @util.index_of(svg, "<path d=\"M", from=lid) + 10
  let (_, e0) = number_at(svg, d)
  let (my, e1) = number_at(svg, e0 + 1)
  let (_, e2) = number_at(svg, e1 + 1)
  let (ry, _) = number_at(svg, e2 + 1)
  let top = ty + my - ry
  assert_true((py1 - (top - 7)).abs() < 0.000005)
  // A queue is entered through the middle of its rounded end.
  let (qx0, qy0, qx1, qy1) = straight(line_of(svg, "d-q"))
  assert_eq(qx0, qx1)
  assert_true(qy1 > qy0 + 50)
}

///|
test "goes around the shapes between two in the same row or column" {
  let row = svg_of(
    "C4Context\nSystem(a, \"A\")\nSystem(b, \"B\")\nSystem(c, \"C\")\nRel(a, c, \"over\")\nRel(c, a, \"under\")",
  )
  let a = box(row, "a")
  let over = corners_of(row, "a-c")
  inspect(line_of(row, "a-c").has_prefix("M"), content="true")
  assert_eq(over[1], a.1)
  assert_true(over[3] < a.1)
  let under = corners_of(row, "c-a")
  assert_true(under[3] > a.1 + a.3)
  let column = svg_of(
    "C4Context\nUpdateLayoutConfig(\"1\", \"1\")\nSystem(a, \"A\")\nSystem(b, \"B\")\nSystem(c, \"C\")\nRel(a, c, \"x\")",
  )
  let d = line_of(column, "a-c")
  let (_, e0) = number_at(d, 1)
  let (_, e1) = number_at(d, e0 + 1)
  assert_eq(@util.code_at(d, e1), 72)
  // Neighbours need no detour.
  assert_false(row.contains("data-id=\"a-b\""))
  assert_false(
    svg_of("C4Context\nSystem(a, \"A\")\nSystem(b, \"B\")\nRel(a, b, \"x\")").contains(
      "Q",
    ),
  )
}

///|
/// Whether any corner-to-corner stretch of `points` runs inside the box, sampled as pele samples it.
fn runs_behind(
  points : Array[Double],
  b : (Double, Double, Double, Double),
) -> Bool {
  for i = 2; i < points.length(); i = i + 2 {
    let (x0, y0, x1, y1) = (
      points[i - 2],
      points[i - 1],
      points[i],
      points[i + 1],
    )
    let mut t = 0.0
    while t <= 1 {
      let x = x0 + (x1 - x0) * t
      let y = y0 + (y1 - y0) * t
      if x > b.0 + 1 && x < b.0 + b.2 - 1 && y > b.1 + 1 && y < b.1 + b.3 - 1 {
        return true
      }
      t += 0.02
    }
  }
  false
}

///|
/// Whether the path that starts at `at` with `x,y` goes on with H or V, which pele's pattern asks of a shape's outline.
fn is_upright_or_level(svg : String, at : Int32) -> Bool {
  let (_, e0) = number_at(svg, at)
  let (_, e1) = number_at(svg, e0 + 1)
  @util.code_at(svg, e1) is (72 | 86)
}

///|
/// Every shape drawn, by id, with its box; a cylinder is a path, and its box here leaves out the bulge of its caps.
fn drawn_shapes(
  svg : String,
) -> Array[(String, (Double, Double, Double, Double))] {
  let out = []
  let marker = "class=\"pele-node "
  let mut at = @util.index_of(svg, marker)
  while at != -1 {
    let id_at = @util.index_of(svg, "data-id=\"", from=at) + 9
    let id = @util.slice(svg, id_at, end=@util.index_of(svg, "\"", from=id_at))
    let translate = @util.index_of(svg, "transform=\"translate(", from=id_at) +
      21
    let (cx, end) = number_at(svg, translate)
    let (cy, _) = number_at(svg, end + 1)
    let mut tag = @util.index_of(svg, "><", from=translate) + 1
    if @util.starts_with_at(svg, "<a ", tag) {
      tag = @util.index_of(svg, "><", from=tag) + 1
    }
    if @util.starts_with_at(svg, "<rect", tag) {
      out.push((id, box(svg, id)))
    } else if @util.starts_with_at(svg, "<path d=\"M", tag) &&
      is_upright_or_level(svg, tag + 10) {
      let (mx, e0) = number_at(svg, tag + 10)
      let (my, e1) = number_at(svg, e0 + 1)
      let op = @util.code_at(svg, e1)
      let (stop, _) = number_at(svg, e1 + 1)
      let w = if op == 72 { stop - mx } else { -2 * mx }
      let h = if op == 86 { stop - my } else { -2 * my }
      out.push((id, (cx + mx, cy + my, w, h)))
    }
    at = @util.index_of(svg, marker, from=at + 1)
  }
  out
}

///|
test "keeps every line clear of the shapes it does not join" {
  let behind = []
  for source in docs {
    let rels = model(source).rels
    for max_width in [None, Some(640.0), Some(480.0), Some(320.0)] {
      let svg = match drawn(source, max_width?) {
        Ok(result) => result.svg
        Err(failure) => abort(failure.message)
      }
      let shapes = drawn_shapes(svg)
      for index, line in lines_of(svg) {
        let (id, points) = line
        let rel = match rels.search_by(r => "\{r.from}-\{r.to}" == id) {
          Some(i) => rels[i]
          None => rels[index]
        }
        for shape in shapes {
          let (name, b) = shape
          if name == rel.from || name == rel.to {
            continue
          }
          if runs_behind(points, b) {
            let width = match max_width {
              Some(w) => w.to_string()
              None => "full"
            }
            let title = @util.trim(source.split("\n").collect()[1].to_owned())
            let entry = "\{id} behind \{name} at \{width} width in \{title}"
            if !behind.contains(entry) {
              behind.push(entry)
            }
          }
        }
      }
    }
  }
  // In the full container diagram no line with two corners goes around Mobile App, so one stays behind it.
  assert_eq(behind, [
    "backend_api-banking_system behind mobile_app at full width in title Container diagram for Internet Banking System",
  ])
}

///|
test "bends a line that would cross behind a shape through the gap between columns, apart from the others there" {
  let svg = svg_of(component_doc(), max_width=640)
  let lane = (id : String) => {
    let points = corners_of(svg, id)
    for i = 2; i < points.length(); i = i + 2 {
      assert_true(points[i] == points[i - 2] || points[i + 1] == points[i - 1])
    }
    points[4]
  }
  let spa = box(svg, "spa")
  let accounts = box(svg, "accounts")
  for id in ["spa-accounts", "ma-sign"] {
    assert_true(lane(id) > spa.0 + spa.2)
    assert_true(lane(id) < accounts.0)
  }
  assert_true((lane("spa-accounts") - lane("ma-sign")).abs() >= 10)
}

///|
test "takes a detour along the outside of the drawing when its column is at the edge" {
  let svg = svg_of(component_doc(), max_width=640)
  let spa = box(svg, "spa")
  let mbs = box(svg, "mbs")
  assert_true(corners_of(svg, "spa-sign")[4] < spa.0)
  assert_true(corners_of(svg, "mbsfacade-mbs")[4] > mbs.0 + mbs.2)
}

///|
test "separates two relations that run opposite ways and puts their labels on either side" {
  let svg = svg_of(
    "C4Context\nSystem(a, \"A\")\nSystem(b, \"B\")\nRel(a, b, \"there\")\nRel(b, a, \"back\")",
  )
  let y = (id : String) => straight(line_of(svg, id)).1
  inspect((y("a-b") - y("b-a")).abs(), content="14")
  assert_true(label_y(svg, "a-b") > y("a-b"))
  assert_true(label_y(svg, "b-a") + 20 < y("b-a"))
}

///|
test "draws a relation from a shape to itself as a loop" {
  let svg = svg_of("C4Context\nSystem(a, \"A\")\nRel(a, a, \"again\")")
  let d = line_of(svg, "a-a")
  let (_, e0) = number_at(d, 1)
  let (_, e1) = number_at(d, e0 + 1)
  assert_eq(@util.code_at(d, e1), 67)
  assert_true(label_x(svg, "a-a") > box(svg, "a").0 + box(svg, "a").2)
}

///|
test "connects a boundary as an end of a relation" {
  let svg = svg_of(
    (
      #|C4Context
      #|System(out, "Out")
      #|Boundary(b, "B") {
      #|  System(in, "In")
      #|}
      #|Rel(out, b, "to boundary")
      #|Rel(b, in, "into")
    ),
  )
  let b = box(svg, "b")
  assert_true((straight(line_of(svg, "out-b")).3 - (b.1 - 7)).abs() < 0.000005)
  assert_eq(straight(line_of(svg, "b-in")).0, b.0)
}

///|
test "rejects a relation to something that does not exist, as Mermaid does" {
  let failure = failure_of(
    "C4Context\nSystem(a, \"A\")\nRel(a, missing, \"x\")",
  )
  inspect(
    failure.message,
    content="C4 rel \"a\" -> \"missing\" references an unknown shape or boundary",
  )
  inspect(failure.code.to_string(), content="semantic")
  assert_eq(failure.kind, Some("c4"))
  inspect(
    failure_of("C4Context\nSystem(a, \"A\")\nRel($x=\"y\", a, \"x\")").code.to_string(),
    content="semantic",
  )
}

///|
test "applies UpdateElementStyle to shapes and boundaries" {
  let svg = svg_of(
    (
      #|C4Context
      #|Person(a, "A", "desc")
      #|Boundary(b, "B") {
      #|  System(c, "C")
      #|}
      #|UpdateElementStyle(a, $fontColor="red", $bgColor="grey", $borderColor="blue")
      #|UpdateElementStyle(b, "#eee", "green", "orange")
      #|UpdateElementStyle(nobody, "red")
    ),
  )
  assert_true(
    tag_after(svg, "data-id=\"a\"", "rect").contains(
      "style=\"fill:grey;stroke:blue;\"",
    ),
  )
  assert_true(
    tag_after(svg, "data-id=\"a\"", "circle").contains(
      "style=\"fill:grey;stroke:blue;\"",
    ),
  )
  inspect(count(svg, "style=\"fill:red;\""), content="3")
  assert_true(
    tag_after(svg, "data-id=\"b\">", "rect").contains(
      "style=\"rx:var(--_r);fill:#eee;stroke:orange;\"",
    ),
  )
  assert_true(
    tag_with(svg, "class=\"pele-cluster-label\"").contains(
      "style=\"fill:green;\"",
    ),
  )
}

///|
test "picks a contrasting text color on fills a style sets" {
  let svg = svg_of(
    (
      #|C4Context
      #|Boundary(b, "B", "Kind") {
      #|  System(c, "C", "about c")
      #|}
      #|System(d, "D", "about d")
      #|System(e, "E")
      #|UpdateElementStyle(b, $bgColor="lightyellow")
      #|UpdateElementStyle(c, $bgColor="navy")
      #|UpdateElementStyle(d, $bgColor="navy", $fontColor="#ddd")
    ),
  )
  let group = (id : String) => {
    let from = @util.index_of(svg, "data-id=\"\{id}\"")
    @util.slice(svg, from, end=@util.index_of(svg, "</g>", from~))
  }
  inspect(
    count(group("c"), "fill=\"var(--pele-fg-on-dark,#fff)\""),
    content="3",
  )
  assert_true(
    group("b").contains(
      "<text class=\"pele-cluster-label\" font-weight=\"var(--_hw)\" fill=\"var(--pele-fg-on-light,#1f1f1f)\"",
    ),
  )
  assert_true(
    tag_with(group("b"), "class=\"pele-c4-type\"").contains(
      " fill=\"var(--pele-fg-on-light,#1f1f1f)\"",
    ),
  )
  assert_false(group("d").contains("--pele-fg-on"))
  assert_false(group("e").contains("--pele-fg-on"))
}

///|
/// What the group of casings in a drawing holds, or an empty string when it has none.
fn casings_of(svg : String) -> String {
  let open = @util.index_of(svg, "<g class=\"pele-casings\"")
  if open == -1 {
    return ""
  }
  let start = @util.index_of(svg, ">", from=open) + 1
  @util.slice(
    svg,
    start,
    end=@util.index_of(svg, "</g><g class=\"pele-edges\"", from=start),
  )
}

///|
test "cases relations that cross a boundary fill a style sets and inks those inside it" {
  let source =
    #|C4Context
    #|Boundary(b, "B") {
    #|  System(x, "X")
    #|  System(y, "Y")
    #|}
    #|System(z, "Z")
    #|System(w, "W")
    #|Rel(x, y, "in")
    #|Rel(y, z, "out")
    #|Rel(z, w, "away")
    #|UpdateElementStyle(b, $bgColor="lightyellow")
  let svg = svg_of(source)
  let casings = casings_of(svg)
  inspect(
    ["x-y", "y-z", "z-w"]
    .map(id => "\{id} \{casings.contains("<path d=\"\{line_of(svg, id)}\"/>")}")
    .join("\n"),
    content=(
      #|x-y false
      #|y-z true
      #|z-w false
    ),
  )
  // x --> y lies inside the boundary and takes its ink; y --> z crosses out of it.
  let head = (svg : String, id : String) => {
    let at = @util.index_of(svg, "class=\"pele-edge\" data-id=\"\{id}\"")
    let marker = @util.index_of(svg, "<path class=\"pele-marker\"", from=at)
    @util.slice(svg, at, end=@util.index_of(svg, ">", from=at) + 1) +
    " " +
    @util.slice(svg, marker, end=@util.index_of(svg, "/>", from=marker) + 2)
  }
  inspect(
    head(svg, "x-y"),
    content=(
      #|class="pele-edge" data-id="x-y" stroke="var(--pele-fg-on-light,#1f1f1f)"> <path class="pele-marker" d="M364,227L356,230.36L356,223.64Z" fill="var(--pele-fg-on-light,#1f1f1f)" stroke="none"/>
    ),
  )
  let plain = svg_of(
    source.replace(
      old="UpdateElementStyle(b, $bgColor=\"lightyellow\")",
      new="",
    ),
  )
  inspect(plain.contains("pele-casings"), content="false")
  inspect(plain.contains("stroke=\"var(--pele-fg-on"), content="false")
  let looped = svg_of(
    "C4Context\nBoundary(S, \"S\") {\n  System(A, \"A\")\n}\nRel(A, A, \"self\")\nUpdateElementStyle(S, $bgColor=\"white\")",
  )
  inspect(
    head(looped, "A-A"),
    content=(
      #|class="pele-edge" data-id="A-A" stroke="var(--pele-fg-on-light,#1f1f1f)"> <path class="pele-marker" d="M244,123L252.66,122.53L250.4,128.85Z" fill="var(--pele-fg-on-light,#1f1f1f)" stroke="none"/>
    ),
  )
}

///|
test "applies UpdateRelStyle colours and offsets" {
  let base = "C4Context\nUpdateLayoutConfig(\"1\", \"1\")\nSystem(a, \"A\")\nSystem(b, \"B\")\nRel(a, b, \"x\")\n"
  let plain = svg_of(base)
  let styled = svg_of(
    base +
    "UpdateRelStyle(a, b, $textColor=\"red\", $lineColor=\"blue\", $offsetX=\"30\", $offsetY=\"-10\")",
  )
  assert_true(
    styled.contains(
      "<g class=\"pele-edge\" data-id=\"a-b\" style=\"stroke:blue;\">",
    ),
  )
  assert_true(
    tag_with(styled, "class=\"pele-marker\"").contains("fill=\"blue\""),
  )
  let label = @util.index_of(
    styled, "class=\"pele-edge-label\" data-id=\"a-b\"><rect",
  )
  let after_rect = @util.index_of(styled, "/>", from=label) + 2
  assert_true(
    @util.starts_with_at(styled, "<text style=\"fill:red;\"", after_rect),
  )
  assert_eq(label_x(styled, "a-b"), label_x(plain, "a-b") + 30)
  assert_eq(label_y(styled, "a-b"), label_y(plain, "a-b") - 10)
  let positional = svg_of(
    base + "UpdateRelStyle(a, b, \"red\", \"blue\", \"30\", \"-10\")",
  )
  assert_eq(positional, styled)
  // Named in any order: Mermaid turns colours in the last two places into NaN.
  let swapped = svg_of(
    base +
    "UpdateRelStyle(a, b, $offsetX=\"30\", $offsetY=\"-10\", $lineColor=\"blue\", $textColor=\"red\")",
  )
  assert_eq(swapped, styled)
}

///|
test "keeps a label on its line when an offset would put it on a shape" {
  let base = "C4Context\nSystem(a, \"A\")\nSystem(b, \"B\")\nRel(a, b, \"x\")\n"
  let plain = svg_of(base)
  assert_eq(svg_of(base + "UpdateRelStyle(a, b, $offsetX=\"-120\")"), plain)
  assert_eq(
    label_y(svg_of(base + "UpdateRelStyle(a, b, $offsetY=\"-60\")"), "a-b"),
    label_y(plain, "a-b") - 60,
  )
  assert_true(
    drawn(base + "UpdateRelStyle(a, b, $offsetX=\"9999999999\")").unwrap().width <
    3000,
  )
  assert_eq(
    svg_of(base + "UpdateRelStyle(a, b, $offsetX=\"abc\", $offsetY=\"x1\")"),
    plain,
  )
}

///|
/// Renders a model straight, as pele's render does when it is given one, with the same options as the plugin would pass.
fn render_model(db : @c4.C4Db, max_width : Double) -> String {
  let options = {
    ..@types.RenderOptions::default(),
    max_width: Some(max_width),
  }
  (@c4.render_c4(db, Map([]), options) catch { _ => abort("render failed") }).svg
}

///|
/// The source without its UpdateRelStyle lines, as pele removes them with /^\s*UpdateRelStyle\([^\n]+\)\s*$/gm.
fn without_rel_styles(source : String) -> String {
  let lines = source.split("\n").map(line => line.to_owned()).collect()
  lines
  .map(line => {
    let trimmed = @util.trim(line)
    if trimmed.has_prefix("UpdateRelStyle(") && trimmed.has_suffix(")") {
      ""
    } else {
      line
    }
  })
  .join("\n")
}

///|
test "reattaches manually offset labels to their arrows when the component layout compacts" {
  let source = component_doc()
  let without_offsets = without_rel_styles(source)
  let parsed = model(source)
  let before = parsed.rels.map(show_rel).join("\n")
  for max_width in [320.0, 480, 568] {
    let compact = render_model(parsed, max_width)
    assert_eq(compact, svg_of(without_offsets, max_width~))
  }
  assert_eq(parsed.rels.map(show_rel).join("\n"), before)
  let svg = render_model(parsed, 568)
  for pair in [("sign", "security"), ("accounts", "mbsfacade")] {
    let (from, to) = pair
    let a = box(svg, from)
    let b = box(svg, to)
    let x = label_x(svg, "\{from}-\{to}")
    let y = label_y(svg, "\{from}-\{to}")
    assert_true(x > a.0)
    assert_true(x < a.0 + a.2)
    assert_true(y > a.1 + a.3)
    assert_true(y + 20 < b.1)
  }
  let wide = drawn(source).unwrap()
  assert_eq(render_model(parsed, wide.width), wide.svg)
  assert_true(wide.svg != svg_of(without_offsets))
}

///|
test "moves a boundary heading out of the way of a line" {
  let heading_x = (svg : String) => {
    attr_after(svg, "x", @util.index_of(svg, "class=\"pele-cluster-label\""))
  }
  let svg = svg_of(
    (
      #|C4Context
      #|System(top, "Top")
      #|Boundary(b, "Boundary name") {
      #|  System(in, "In")
      #|  System(other, "Other")
      #|}
      #|Rel(top, in, "x")
    ),
  )
  let heading = heading_x(svg)
  let line = straight(line_of(svg, "top-in")).0
  assert_true((heading - line).abs() > 20)
  let alone = svg_of(
    "C4Context\nBoundary(b, \"Boundary name\") {\n System(in, \"In\")\n System(other, \"Other\")\n}",
  )
  assert_true(heading_x(alone) < heading)
}

///|
test "wraps a shape, a boundary heading, or a relation label in a link" {
  let result = drawn(
    (
      #|C4Context
      #|System(a, "A", $link="https://example.com/a")
      #|Boundary(b, "B", $link="https://example.com/b") {
      #|  System(c, "C", $link="javascript:alert(1)")
      #|}
      #|Rel(a, c, "x", $link="https://example.com/rel")
    ),
  ).unwrap()
  let svg = result.svg
  let a = @util.index_of(svg, "data-id=\"a\" transform=\"")
  let a_body = @util.index_of(svg, "><", from=a) + 1
  assert_true(
    @util.starts_with_at(
      svg, "<a href=\"https://example.com/a\" rel=\"noopener\"><rect", a_body,
    ),
  )
  let b = @util.index_of(svg, "data-id=\"b\"><rect")
  let b_body = @util.index_of(svg, "/>", from=b) + 2
  assert_true(
    @util.starts_with_at(
      svg, "<a href=\"https://example.com/b\" rel=\"noopener\"><text", b_body,
    ),
  )
  let rel = @util.index_of(
    svg, "class=\"pele-edge-label\" data-id=\"a-c\"><rect",
  )
  let rel_body = @util.index_of(svg, "/>", from=rel) + 2
  assert_true(
    @util.starts_with_at(svg, "<a href=\"https://example.com/rel\"", rel_body),
  )
  assert_false(svg.contains("javascript"))
  inspect(
    result.links.map(l => "\{l.id} \{l.href} \{l.internal}").join("\n"),
    content=(
      #|a-c https://example.com/rel false
      #|a https://example.com/a false
      #|b https://example.com/b false
    ),
  )
}

///|
test "stores sprites, tags, and legend arguments without drawing them" {
  let src = "C4Context\nSystem(a, \"A\", \"d\", \"sprite\", \"t1,t2\")\nUpdateElementStyle(a, $legendText=\"L\", $legendSprite=\"S\", $shadowing=\"true\")"
  let shape = model(src).shapes[0]
  assert_eq(shape.sprite, Some("sprite"))
  assert_eq(shape.tags, Some("t1,t2"))
  assert_eq(shape.legend_text, Some("L"))
  assert_eq(shape.legend_sprite, Some("S"))
  assert_eq(shape.shadowing, Some("true"))
  let svg = svg_of(src)
  assert_false(svg.contains("sprite"))
  assert_false(svg.contains("t1"))
  inspect(count(svg, "<image"), content="0")
}

///|
test "shows the description of a relation as a tooltip" {
  assert_true(
    svg_of(
      "C4Context\nSystem(a, \"A\")\nSystem(b, \"B\")\nRel(a, b, \"x\", \"t\", \"why <it> matters\")",
    ).contains("<title>why &lt;it&gt; matters</title>"),
  )
}

///|
test "takes the title from the diagram, then from front matter" {
  let own = svg_of("C4Context\ntitle Own title\nSystem(a, \"A\")")
  assert_true(own.contains("class=\"pele-title\" font-weight=\"var(--_tw)\""))
  assert_true(own.contains("Own title"))
  assert_true(
    svg_of("---\ntitle: From front matter\n---\nC4Context\nSystem(a, \"A\")").contains(
      "From front matter",
    ),
  )
  assert_false(
    svg_of(
      "---\ntitle: From front matter\n---\nC4Context\ntitle Own\nSystem(a, \"A\")",
    ).contains("From front matter"),
  )
  let wide = drawn(
    "C4Context\ntitle \{"A long title ".repeat(8)}\nSystem(a, \"A\")",
  ).unwrap()
  assert_true(wide.width > 600)
}

///|
test "treats accTitle as the title, as the grammar does, and accDescr as the description" {
  let svg = svg_of(
    "C4Context\naccTitle: Shown on top\naccDescr: For screen readers\nSystem(a, \"A\")",
  )
  assert_true(svg.contains("Shown on top</t"))
  assert_true(svg.contains("<desc id=\"pele-desc\">For screen readers</desc>"))
  assert_false(svg.contains("<title"))
  assert_eq(
    model("C4Context\naccDescr {\n  two\n  lines\n}\nSystem(a, \"A\")").acc_descr,
    Some("two\nlines"),
  )
  assert_eq(
    model("C4Context\naccDescription one line\nSystem(a, \"A\")").acc_descr,
    Some("one line"),
  )
}

///|
test "applies a named argument wherever it is written" {
  let m = model(
    (
      #|C4Container
      #|Person(a, $sprite="users")
      #|Container(b, "B", $descr="described")
      #|Container($tags="t", "Anonymous")
      #|Node(n, "N", "t", "d", $link="https://example.com") {
      #|  Container(c, "C", $unknown="kept", $__proto__="safe")
      #|}
      #|Rel(a, b, $techn="HTTP")
    ),
  )
  assert_eq(
    (m.shapes[0].alias_, m.shapes[0].label, m.shapes[0].sprite),
    ("a", "", Some("users")),
  )
  assert_eq((m.shapes[1].label, m.shapes[1].descr), ("B", Some("described")))
  assert_eq(m.shapes[1].techn, None)
  assert_eq(
    (m.shapes[2].alias_, m.shapes[2].label, m.shapes[2].tags),
    ("", "Anonymous", Some("t")),
  )
  let n = m.boundaries[1]
  assert_eq(
    (n.type_, n.descr, n.link, n.node_type),
    (Some("t"), Some("d"), Some("https://example.com"), Some("node")),
  )
  let extra = m.shapes[3].extra.unwrap()
  assert_eq(extra.iter().map(pair => "\{pair.0}=\{pair.1}").collect(), [
    "unknown=kept", "__proto__=safe",
  ])
  assert_eq((m.rels[0].label, m.rels[0].techn), ("", Some("HTTP")))
  assert_true(
    svg_of(
      "C4Context\nPerson(a, $sprite=\"users\")\nSystem($link=\"https://example.com\", \"B\")",
    ).contains(">B<"),
  )
}

///|
test "merges a repeated alias and keeps the first position" {
  let m = model(
    (
      #|C4Context
      #|System(a, "First", "d1")
      #|System(b, "B")
      #|Boundary(x, "X") {
      #|  Person(a, "Second")
      #|}
      #|Rel(a, b, "one", "t")
      #|BiRel(a, b, "two")
    ),
  )
  assert_eq(m.shapes.map(s => s.alias_), ["a", "b"])
  assert_eq(
    (m.shapes[0].label, m.shapes[0].descr, m.shapes[0].kind),
    ("Second", Some("d1"), "person"),
  )
  assert_eq(m.shapes[0].parent.map(p => p.alias_), Some("x"))
  inspect(m.rels.length(), content="1")
  assert_eq(
    (m.rels[0].type_, m.rels[0].label, m.rels[0].techn),
    ("birel", "two", Some("t")),
  )
}

///|
test "draws a boundary named global, which Mermaid swallows" {
  let svg = svg_of(
    "C4Context\nBoundary(global, \"Everything\") {\n System(a, \"A\")\n}",
  )
  assert_true(svg.contains("data-id=\"global\""))
  assert_true(svg.contains("data-id=\"a\""))
}

///|
test "leaves out a boundary that ends up inside itself" {
  let svg = svg_of(
    (
      #|C4Context
      #|System(ok, "OK")
      #|Boundary(a, "A") {
      #|  Boundary(b, "B") {
      #|    Boundary(a, "A again") {
      #|      System(lost, "Lost")
      #|    }
      #|  }
      #|}
    ),
  )
  assert_true(svg.contains("data-id=\"ok\""))
  assert_false(svg.contains("data-id=\"lost\""))
  assert_false(svg.contains("data-id=\"b\""))
}

///|
test "reports syntax errors the way Jison words them" {
  assert_true(
    failure_of("C4Context\nPerson (a, \"A\")").message.has_prefix(
      "Lexical error on line 2. Unrecognized text.",
    ),
  )
  let two = failure_of("C4Context\nPerson(a, \"A\") Person(b, \"B\")").message
  assert_true(two.has_prefix("Parse error on line 2:"))
  assert_true(two.contains("Expecting 'NEWLINE', 'EOF', got 'PERSON'"))
  assert_true(
    failure_of("C4Context\nBoundary(b, \"B\")\nSystem(a, \"A\")").message.contains(
      "Expecting 'LBRACE', got 'SYSTEM'",
    ),
  )
  assert_true(
    failure_of("C4Context\nBoundary(b, \"B\") {\nSystem(a, \"A\")").message.contains(
      "got 'EOF'",
    ),
  )
  inspect(failure_of("C4Context\n").code.to_string(), content="syntax")
  // An empty named value has no STR_VALUE token in the grammar.
  assert_true(
    failure_of("C4Context\nPerson(a, \"A\", $link=\"\")").message.contains(
      "Expecting 'STR_VALUE'",
    ),
  )
  assert_eq(failure_of("C4Context\nPerson(a, \"A\"").kind, Some("c4"))
}

///|
test "reads an unquoted last argument through to the next comma, as Mermaid does" {
  let m = model("C4Context\nPerson(a, plain label)\nSystem(b, \"B\")")
  inspect(m.shapes.length(), content="1")
  assert_eq(m.shapes[0].label, "plain label)\nSystem(b")
}

///|
test "gives the same output every time" {
  for source in docs {
    assert_eq(svg_of(source), svg_of(source))
  }
}

///|
test "renders every documentation example" {
  let mut rendered = 0
  for source in docs {
    let result = drawn(source).unwrap()
    let svg = result.svg
    assert_false(
      svg.contains("NaN") ||
      svg.contains("Infinity") ||
      svg.contains("undefined"),
    )
    assert_true(result.width > 100)
    assert_true(result.height > 50)
    let mut at = @util.index_of(svg, "<text")
    while at != -1 {
      let tag = @util.slice(svg, at, end=@util.index_of(svg, ">", from=at))
      let x = @util.index_of(tag, " x=\"")
      if x != -1 {
        let value = @util.slice(
          tag,
          x + 4,
          end=@util.index_of(tag, "\"", from=x + 4),
        )
        assert_true(
          value != "" &&
          value.iter().all(c => c.is_ascii_digit() || c is ('-' | '.')),
        )
      }
      at = @util.index_of(svg, "<text", from=at + 1)
    }
    rendered += 1
  }
  assert_true(rendered >= 5)
}

///|
test "scales with the font size option" {
  let src = "C4Context\nSystem(a, \"A\", \"Some description text that wraps over lines\")"
  assert_true(
    drawn(src, font_size=24).unwrap().height > drawn(src).unwrap().height,
  )
}

///|
test "a bare title is no title, and a title after a tab is kept" {
  let bare = model("C4Context\ntitle\nPerson(a, \"Alice\")\nPerson(b, \"Bob\")")
  inspect(bare.title is None, content="true")
  inspect(bare.shapes.map(shape => shape.label).join("|"), content="Alice|Bob")
  inspect(
    model("C4Context\ntitle\tOwn\nSystem(a, \"A\")").title.unwrap_or("-"),
    content="Own",
  )
}
