// Ported from pele v1.8.0, tests/render/block.test.ts; the snapshots were taken from pele's render.

///|
fn block_render(
  source : String,
  max_width? : Double,
) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), max_width, }
  Ok(@core.render([@block.block], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn block_svg(source : String) -> String {
  match block_render(source) {
    Ok(result) => result.svg
    Err(failure) => failure.message
  }
}

///|
fn snapshot(source : String, max_width? : Double) -> String {
  match block_render(source, max_width?) {
    Ok(result) => "\{result.width}x\{result.height} \{result.svg}"
    Err(failure) => failure.message
  }
}

///|
fn occurrences(text : String, needle : String) -> Int32 {
  let mut n = 0
  let mut at = @util.index_of(text, needle)
  while at != -1 {
    n += 1
    at = @util.index_of(text, needle, from=at + needle.length())
  }
  n
}

///|
/// The text from `from` up to the next `close`.
fn read_until(text : String, from : Int32, close : String) -> String {
  let end = @util.index_of(text, close, from~)
  @util.slice(text, from, end~)
}

///|
priv struct Box {
  x : Double
  y : Double
  w : Double
  h : Double
}

///|
fn attribute(attrs : String, name : String) -> Double {
  let at = @util.index_of(attrs, name + "=\"")
  if at == -1 {
    return 0
  }
  @util.parse_float(read_until(attrs, at + name.length() + 2, "\""))
}

///|
/// The center of every drawn block and the box of every composite, by id.
fn boxes(svg : String) -> Map[String, Box] {
  let out : Map[String, Box] = Map([])
  let open = "<g class=\""
  let mut at = @util.index_of(svg, open)
  while at != -1 {
    let class_at = at + open.length()
    let classes = read_until(svg, class_at, "\"")
    let id_at = class_at + classes.length() + 1
    at = @util.index_of(svg, open, from=id_at)
    guard @util.starts_with_at(svg, " data-id=\"", id_at) else { continue }
    let id = read_until(svg, id_at + 10, "\"")
    let kind = read_until(classes + " ", 0, " ")
    let rest = id_at + 10 + id.length() + 1
    if kind == "pele-node" {
      let move_at = rest + " transform=\"translate(".length()
      let x = @util.parse_float(read_until(svg, move_at, ","))
      let y_at = @util.index_of(svg, ",", from=move_at) + 1
      let y = @util.parse_float(read_until(svg, y_at, ")"))
      let attrs = read_until(svg, @util.index_of(svg, "><", from=y_at) + 2, ">")
      out.set(id, {
        x,
        y,
        w: attribute(attrs, "width"),
        h: attribute(attrs, "height"),
      })
    } else if kind == "pele-cluster" {
      let attrs = read_until(svg, rest + 2, ">")
      let w = attribute(attrs, "width")
      let h = attribute(attrs, "height")
      out.set(id, {
        x: attribute(attrs, "x") + w / 2,
        y: attribute(attrs, "y") + h / 2,
        w,
        h,
      })
    }
  }
  out
}

///|
fn layout_of(source : String) -> Map[String, Box] {
  boxes(block_svg(source))
}

///|
fn edge_paths(svg : String) -> Array[String] {
  let out = []
  let open = "class=\"pele-edge\" data-id=\""
  let mut at = @util.index_of(svg, open)
  while at != -1 {
    let d_at = @util.index_of(svg, "<path d=\"", from=at) + 9
    out.push(read_until(svg, d_at, "\""))
    at = @util.index_of(svg, open, from=d_at)
  }
  out
}

///|
/// The numbers of a path of one straight line, `M x1,y1 L x2,y2`.
fn line_ends(d : String) -> Array[Double]? {
  guard d is [.. "M", .. rest] else { return None }
  let parts = rest.split("L").map(p => p.to_owned()).to_array()
  guard parts.length() == 2 else { return None }
  let out = []
  for part in parts {
    let xy = part
      .split(",")
      .map(p => @util.parse_float(p.to_owned()))
      .to_array()
    guard xy.length() == 2 else { return None }
    out.append(xy)
  }
  Some(out)
}

///|
fn box_of(at : Map[String, Box], id : String) -> Box raise {
  guard at.get(id) is Some(found) else { fail("no box for \{id}") }
  found
}

///|
/// The id and centered box of every edge label, in drawing order.
fn edge_labels(svg : String) -> Array[(String, Box)] {
  let out = []
  let open = "class=\"pele-edge-label\" data-id=\""
  let mut at = @util.index_of(svg, open)
  while at != -1 {
    let id = read_until(svg, at + open.length(), "\"")
    let rect_at = @util.index_of(svg, "<rect ", from=at)
    let attrs = read_until(svg, rect_at, ">")
    let w = attribute(attrs, "width")
    let h = attribute(attrs, "height")
    out.push(
      (
        id,
        {
          x: attribute(attrs, "x") + w / 2,
          y: attribute(attrs, "y") + h / 2,
          w,
          h,
        },
      ),
    )
    at = @util.index_of(svg, open, from=rect_at)
  }
  out
}

///|
/// Checks that every labelled edge keeps one label inside the drawing, and that no two labels overlap.
fn expect_separate_labels(source : String, count : Int32) -> Unit raise {
  guard block_render(source) is Ok(result) else { fail("rejected \{source}") }
  let db = parsed_db(source)
  let labels = edge_labels(result.svg)
  assert_eq(labels.length(), count, msg=source)
  assert_eq(
    labels.map(label => label.0),
    db.edges.filter(edge => edge.label != "").map(edge => edge.id),
    msg=source,
  )
  assert_eq(edge_paths(result.svg).length(), db.edges.length(), msg=source)
  for i, label in labels {
    let (id, a) = label
    assert_true(a.w > 0, msg=id)
    assert_true(a.h > 0, msg=id)
    assert_true(a.x - a.w / 2 >= 0, msg=id)
    assert_true(a.y - a.h / 2 >= 0, msg=id)
    assert_true(a.x + a.w / 2 <= result.width, msg=id)
    assert_true(a.y + a.h / 2 <= result.height, msg=id)
    for j in (i + 1)..<labels.length() {
      let (other, b) = labels[j]
      let overlap_x = (a.w + b.w) / 2 - (a.x - b.x).abs()
      let overlap_y = (a.h + b.h) / 2 - (a.y - b.y).abs()
      assert_true(
        @util.js_min(overlap_x, overlap_y) <= 0.01,
        msg="\{id} overlaps \{other}",
      )
    }
    // Labels paint last, so a label's center must belong to that label alone.
    let hits = labels
      .filter(entry => {
        let b = entry.1
        (a.x - b.x).abs() < b.w / 2 && (a.y - b.y).abs() < b.h / 2
      })
      .map(entry => entry.0)
    assert_eq(hits, [id], msg=source)
  }
  assert_eq(block_svg(source), result.svg, msg=source)
}

///|
test "draws blocks, composites, arrows and edges as pele does" {
  assert_eq(
    snapshot(
      "block\n  columns 3\n  a[\"A\"] b((\"Circle\")) c<[\"go\"]>(right)\n  block:g[\"Group\"]:2\n    d e\n  end\n  f{\"F\"}\n  a --> f\n  b -- \"label\" --> e\n  c -.-> c\n  a ==x b",
    ),
    "271x228 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-block\" viewBox=\"0 0 271 228\" width=\"271\" height=\"228\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"block\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"g\"><rect x=\"8\" y=\"120\" width=\"165.95\" height=\"100\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"90.98\" y=\"147.6\" text-anchor=\"middle\">Group</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"1-a-f\"><path d=\"M84.98,82.22L199.34,154.2\"/><path class=\"pele-marker\" d=\"M205.26,157.93L196.7,156.51L200.28,150.83Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"1-b-e\"><path d=\"M132.86,89.59L132.86,153\"/><path class=\"pele-marker\" d=\"M132.86,160L129.5,152L136.22,152Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"1-c-c\"><path d=\"M239.34,35A10,10 0 1 1 255.78,42.65\" stroke-dasharray=\"3 4\"/><path class=\"pele-marker\" d=\"M249.34,45L255.7,39.1L258,45.41Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"1-a-b\"><path d=\"M84.98,58L99.76,58\" stroke-width=\"2.5\"/><path class=\"pele-marker\" d=\"M96.26,54.5L103.26,61.5M96.26,61.5L103.26,54.5\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"a\" transform=\"translate(46.49,58)\"><rect x=\"-38.49\" y=\"-50\" width=\"76.98\" height=\"100\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-shape-circle\" data-id=\"b\" transform=\"translate(135.46,58)\"><circle r=\"31.7\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Circle</text></g><g class=\"pele-node pele-shape-block-arrow\" data-id=\"c\" transform=\"translate(224.44,58)\"><polygon points=\"-24.9,-16 4.9,-16 4.9,-23 24.9,0 4.9,23 4.9,16 -24.9,16\" stroke-linejoin=\"round\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><text class=\"pele-label\" x=\"-10\" y=\"5.6\" text-anchor=\"middle\">go</text></g><g class=\"pele-node pele-shape-diam\" data-id=\"f\" transform=\"translate(224.44,170)\"><polygon points=\"0,-24.05 38.49,0 0,24.06 -38.49,0\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">F</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"d\" transform=\"translate(52.49,184)\"><rect x=\"-32.49\" y=\"-24\" width=\"64.98\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">d</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"e\" transform=\"translate(129.46,184)\"><rect x=\"-32.49\" y=\"-24\" width=\"64.98\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">e</text></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"1-b-e\"><rect x=\"114.07\" y=\"114.3\" width=\"37.57\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"132.86\" y=\"129.7\" text-anchor=\"middle\">label</text></g></g></svg>",
  )
}

///|
test "draws a title, shapes from classes and styles, and circle markers" {
  assert_eq(
    snapshot(
      "---\ntitle: Systems\n---\nblock\n  classDef hot fill:#f96,color:#400\n  a[(\"Store\")] space b>\"Flag\"]\n  class a hot\n  style b stroke:red\n  a o--o b",
    ),
    "369x116 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-block\" viewBox=\"0 0 369 116\" width=\"369\" height=\"116\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"block\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"184.5\" y=\"25.6\">Systems</tspan></text><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"1-o-b\"><path d=\"M281.36,76L277.36,76\"/><circle class=\"pele-marker\" cx=\"273.36\" cy=\"76\" r=\"3.5\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-cyl hot\" data-id=\"a\" transform=\"translate(47.56,76)\"><path d=\"M-39.56,-26A39.56,6 0 0 1 39.56,-26V26A39.56,6 0 0 1 -39.56,26Z\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"fill:#f96;\"/><path d=\"M-39.56,-26A39.56,6 0 0 0 39.56,-26\" fill=\"none\" stroke=\"var(--_b)\"/><text class=\"pele-label\" style=\"fill:#400;\" x=\"0\" y=\"8.6\" text-anchor=\"middle\">Store</text></g><g class=\"pele-node pele-shape-odd\" data-id=\"b\" transform=\"translate(229.8,76)\"><polygon points=\"-39.56,-24 39.56,-24 39.56,24 -39.56,24 -27.56,0\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"stroke:red;\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Flag</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"o\" transform=\"translate(320.92,76)\"><rect x=\"-39.56\" y=\"-32\" width=\"79.12\" height=\"64\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">o</text></g></g></svg>",
  )
}

///|
test "draws tightly on a narrow host" {
  assert_eq(
    snapshot(
      "block\n  a[\"A long label here\"] b[\"Another long label\"] c[\"And yet another one\"]\n  block:g[\"A composite with a long title\"]\n    d\n  end\n  a --> c",
      max_width=400,
    ),
    "876x104 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-block\" viewBox=\"0 0 876 104\" width=\"876\" height=\"104\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"block\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"g\"><rect x=\"656.91\" y=\"8\" width=\"210.3\" height=\"88\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"762.06\" y=\"32.6\" text-anchor=\"middle\">A composite with a long title</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"1-a-c\"><path d=\"M218.3,52L433.61,52\"/><path class=\"pele-marker\" d=\"M440.61,52L432.61,55.36L432.61,48.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"a\" transform=\"translate(113.15,52)\"><rect x=\"-105.15\" y=\"-44\" width=\"210.3\" height=\"88\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"-4.9\">A long</tspan><tspan x=\"0\" y=\"16.1\">label here</tspan></text></g><g class=\"pele-node pele-shape-rect\" data-id=\"b\" transform=\"translate(329.46,52)\"><rect x=\"-105.15\" y=\"-44\" width=\"210.3\" height=\"88\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"-4.9\">Another</tspan><tspan x=\"0\" y=\"16.1\">long label</tspan></text></g><g class=\"pele-node pele-shape-rect\" data-id=\"c\" transform=\"translate(545.76,52)\"><rect x=\"-105.15\" y=\"-44\" width=\"210.3\" height=\"88\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"-15.4\">And yet</tspan><tspan x=\"0\" y=\"5.6\">another</tspan><tspan x=\"0\" y=\"26.6\">one</tspan></text></g><g class=\"pele-node pele-shape-rect\" data-id=\"d\" transform=\"translate(762.06,66)\"><rect x=\"-99.15\" y=\"-24\" width=\"198.3\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">d</text></g></g></svg>",
  )
}

///|
test "renders every input that parses without NaN or Infinity, and the same each time" {
  let mut rendered = 0
  for item in parser_cases {
    let (src, expected) = item
    guard expected is [.. "ok", ..] else { continue }
    guard block_render(src) is Ok(result) else { continue }
    rendered += 1
    assert_false(result.svg.contains("NaN"), msg=src)
    assert_false(result.svg.contains("Infinity"), msg=src)
    assert_eq(block_svg(src), result.svg, msg=src)
  }
  assert_true(rendered > 60)
}

///|
test "reports size and type for both keywords" {
  guard block_render("block\n  a b c") is Ok(result) else { fail("rejected") }
  assert_eq(result.kind, "block")
  assert_true(
    result.svg.contains("viewBox=\"0 0 \{result.width} \{result.height}\""),
  )
  assert_true(
    result.svg
    is [
      .. "<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-block\"",
      ..,
    ],
  )
  assert_eq(result.links.length(), 0)
  assert_eq(block_svg("block-beta\n  a b c"), result.svg)
}

///|
test "puts blocks on one row without a column count" {
  let at = layout_of("block\n  a b c")
  let a = box_of(at, "a")
  let b = box_of(at, "b")
  let c = box_of(at, "c")
  assert_eq(a.y, b.y)
  assert_eq(b.y, c.y)
  assert_eq(b.x - a.x, c.x - b.x)
}

///|
test "wraps to a new row after the column count" {
  let at = layout_of("block\n  columns 3\n  a b c d")
  assert_eq(box_of(at, "d").x, box_of(at, "a").x)
  assert_true(box_of(at, "d").y > box_of(at, "a").y)
  let stacked = layout_of("block\n  columns 1\n  a b")
  assert_eq(box_of(stacked, "a").x, box_of(stacked, "b").x)
}

///|
test "makes every column as wide as the widest block and every row as tall as the tallest" {
  let at = layout_of(
    "block\n  columns 2\n  a[\"A much longer label\"] b\n  c[\"two<br>lines\"] d",
  )
  let first = box_of(at, "a")
  for id in ["a", "b", "c", "d"] {
    assert_eq(box_of(at, id).w, first.w)
    assert_eq(box_of(at, id).h, first.h)
  }
  assert_true(first.h > box_of(layout_of("block\n a"), "a").h)
}

///|
test "spans columns, with the gap between them included" {
  let at = layout_of("block\n  columns 3\n  a[\"A label\"] b:2 c:2 d")
  let a = box_of(at, "a")
  let b = box_of(at, "b")
  let d = box_of(at, "d")
  assert_eq(b.w, 2 * a.w + 12)
  assert_true((box_of(at, "c").x - (a.x + (a.w + 12) / 2)).abs() < 0.05)
  assert_true((d.x - (a.x + 2 * (a.w + 12))).abs() < 0.05)
  assert_eq(d.y, box_of(at, "c").y)
}

///|
test "stops a block that is wider than the rest of its row at the last column" {
  let at = layout_of("block\n  columns 3\n  a b:3 c")
  let a = box_of(at, "a")
  assert_eq(box_of(at, "b").w, 2 * a.w + 12)
  assert_eq(box_of(at, "c").x, a.x)
  assert_true(box_of(at, "c").y > a.y)
  let every = layout_of("block\n  a:0 b")
  assert_eq(box_of(every, "a").w, box_of(every, "b").w)
}

///|
test "leaves room for space blocks" {
  let at = layout_of("block\n  columns 3\n  a space b\n  c d e")
  assert_eq(box_of(at, "b").x, box_of(at, "e").x)
  assert_eq(box_of(at, "d").x, (box_of(at, "a").x + box_of(at, "b").x) / 2)
  let wide = layout_of("block\n  ida space:3 idb idc")
  let step = box_of(wide, "idc").x - box_of(wide, "idb").x
  assert_true(
    (box_of(wide, "idb").x - box_of(wide, "ida").x - 4 * step).abs() < 0.05,
  )
  assert_eq(
    occurrences(block_svg("block\n  a space b"), "class=\"pele-node "),
    2,
  )
}

///|
test "sizes a composite from its children and lets it use its own columns" {
  let at = layout_of(
    "block\n  columns 1\n  top\n  block:group\n    columns 2\n    a b c d\n  end",
  )
  let group = box_of(at, "group")
  for id in ["a", "b", "c", "d"] {
    let b = box_of(at, id)
    assert_true(b.x - b.w / 2 >= group.x - group.w / 2 + 12)
    assert_true(b.x + b.w / 2 <= group.x + group.w / 2 - 12)
    assert_true(b.y - b.h / 2 >= group.y - group.h / 2 + 12)
    assert_true(b.y + b.h / 2 <= group.y + group.h / 2 - 12)
  }
  assert_eq(box_of(at, "c").x, box_of(at, "a").x)
  assert_eq(box_of(at, "top").w, group.w)
}

///|
test "stretches the children of a composite that spans a wider cell" {
  let at = layout_of(
    "block\n  columns 3\n  a[\"A wide block label here\"]:3\n  block:g:2\n    x y\n  end\n  z",
  )
  let g = box_of(at, "g")
  let x = box_of(at, "x")
  assert_true((g.w - (2 * (box_of(at, "a").w - 24) / 3 + 12)).abs() < 0.01)
  assert_true((x.w * 2 + 36.0 - g.w).abs() < 0.01)
}

///|
test "makes rows with a plain block as tall as the tallest block, and rows of composites as tall as they need" {
  let at = layout_of(
    "block\n  columns 3\n  a:3\n  block:group1:2\n    columns 2\n    h i j k\n  end\n  g\n  block:group2:3\n    l m n o p q r\n  end",
  )
  let plain = box_of(layout_of("block\n  l"), "l").h
  assert_eq(box_of(at, "group1").h, 2 * plain + 3 * 12)
  assert_eq(box_of(at, "a").h, box_of(at, "group1").h)
  assert_eq(box_of(at, "g").h, box_of(at, "group1").h)
  assert_eq(box_of(at, "group2").h, plain + 2 * 12)
  assert_eq(box_of(at, "l").h, plain)
  assert_eq(box_of(at, "group2").w, box_of(at, "a").w)
}

///|
test "draws a composite title above its children" {
  let svg = block_svg("block\n  block:g[\"Group title\"]\n    a b\n  end")
  let at = boxes(svg)
  assert_true(svg.contains("class=\"pele-cluster-label\""))
  assert_true(svg.contains(">Group title<"))
  let label_at = @util.index_of(svg, "class=\"pele-cluster-label\"")
  let y_at = @util.index_of(svg, " y=\"", from=label_at) + 4
  let title_y = @util.parse_float(read_until(svg, y_at, "\""))
  assert_true(title_y < box_of(at, "a").y - box_of(at, "a").h / 2)
  let plain = layout_of("block\n  block:g\n    a b\n  end")
  assert_true(box_of(at, "g").h > box_of(plain, "g").h)
}

///|
test "honours block.padding" {
  guard block_render(
      "---\nconfig:\n  block:\n    padding: 2\n---\nblock\n  a b c",
    )
    is Ok(tight) else {
    fail("rejected")
  }
  guard block_render(
      "---\nconfig:\n  block:\n    padding: 40\n---\nblock\n  a b c",
    )
    is Ok(loose) else {
    fail("rejected")
  }
  assert_eq(loose.width - tight.width, 2 * 38)
}

///|
test "draws each bracket shape" {
  let shapes = [
    ("a", "rect"),
    ("a[\"x\"]", "rect"),
    ("a(\"x\")", "rounded"),
    ("a([\"x\"])", "stadium"),
    ("a[[\"x\"]]", "fr-rect"),
    ("a[(\"x\")]", "cyl"),
    ("a((\"x\"))", "circle"),
    ("a(((\"x\")))", "dbl-circ"),
    ("a>\"x\"]", "odd"),
    ("a{\"x\"}", "diam"),
    ("a{{\"x\"}}", "hex"),
    ("a[/\"x\"/]", "lean-r"),
    ("a[\\\"x\"\\]", "lean-l"),
    ("a[/\"x\"\\]", "trap-b"),
    ("a[\\\"x\"/]", "trap-t"),
    ("a<[\"x\"]>(right)", "block-arrow"),
    ("a(\"x\"]", "rect"),
  ]
  for item in shapes {
    let (source, shape) = item
    assert_true(
      block_svg("block\n  \{source}").contains(
        "class=\"pele-node pele-shape-\{shape}\"",
      ),
      msg=source,
    )
  }
}

///|
test "keeps circles and diamonds at their own size in a larger cell" {
  let svg = block_svg(
    "block\n  columns 1\n  a((\"x\"))\n  b[\"A much wider block than the circle\"]",
  )
  let r_at = @util.index_of(svg, "<circle r=\"") + 11
  let r = @util.parse_float(read_until(svg, r_at, "\""))
  assert_true(r * 2 < box_of(boxes(svg), "b").w / 2)
}

///|
test "draws block arrows for every direction" {
  let points = (dirs : String) => {
    let svg = block_svg("block\n  a<[\"Label\"]>(\{dirs})")
    let at = @util.index_of(svg, "<polygon points=\"") + 17
    occurrences(read_until(svg, at, "\""), " ") + 1
  }
  for dir in ["right", "left", "up", "down"] {
    assert_eq(points(dir), 7, msg=dir)
  }
  assert_eq(points("x"), 10)
  assert_eq(points("y"), 10)
  assert_eq(points("x, down"), 13)
  assert_eq(points("x, y"), 16)
  assert_eq(points("up, up"), 7)
  assert_eq(points(" up "), 7)
  guard block_render("block\n  a<[\"Label\"]>(right)") is Ok(labelled) else {
    fail("rejected")
  }
  guard block_render("block\n  a<[\"&nbsp;&nbsp;&nbsp;\"]>(right)") is Ok(blank) else {
    fail("rejected")
  }
  assert_true(blank.height < labelled.height)
  assert_not_eq(
    block_svg("block\n  a<[\"x\"]>(right)"),
    block_svg("block\n  a<[\"x\"]>(left)"),
  )
}

///|
test "joins blocks in one row or column with a straight line between their borders" {
  let row = block_svg("block\n  a space b\n  a --> b")
  let at = boxes(row)
  guard line_ends(edge_paths(row)[0]) is Some(m) else { fail("not a line") }
  assert_eq(m[0], box_of(at, "a").x + box_of(at, "a").w / 2)
  assert_eq(m[1], box_of(at, "a").y)
  assert_eq(m[3], m[1])
  assert_true(m[2] < box_of(at, "b").x - box_of(at, "b").w / 2)
  guard line_ends(
      edge_paths(block_svg("block\n  columns 1\n  a space b\n  b --> a"))[0],
    )
    is Some(v) else {
    fail("not a line")
  }
  assert_eq(v[0], v[2])
  assert_true(v[3] < v[1])
}

///|
test "bends once between blocks that share neither, when the corner is free" {
  let d = edge_paths(
      block_svg(
        "block\n  columns 3\n  a space:2\n  space:3\n  space:2 b\n  a --> b",
      ),
    )[0]
  assert_true(d.contains("Q"), msg=d)
  assert_eq(occurrences(d, "L"), 2, msg=d)
}

///|
test "goes straight across when a block sits on each corner" {
  let d = edge_paths(block_svg("block\n  columns 2\n  a b\n  c d\n  a --> d"))[0]
  assert_true(line_ends(d) is Some(_), msg=d)
}

///|
test "draws arrowheads, line styles and labels" {
  let svg = block_svg(
    "block\n  columns 3\n  a space b\n  c space d\n  a --> b\n  c --o d\n  a --x c\n  b <--> d\n  a == \"thick\" ==> b\n  c -. \"dotted\" .-> d\n  b --- d",
  )
  assert_eq(occurrences(svg, "class=\"pele-edge\""), 7)
  assert_eq(occurrences(svg, "<circle class=\"pele-marker\""), 1)
  assert_true(svg.contains("stroke-width=\"2.5\""))
  assert_true(svg.contains("stroke-dasharray=\"3 4\""))
  assert_true(svg.contains(">thick<"))
  assert_true(svg.contains(">dotted<"))
  assert_eq(occurrences(svg, "class=\"pele-edge-label\""), 2)
}

///|
test "spreads edges between the same two blocks" {
  let paths = edge_paths(block_svg("block\n  a space b\n  a --> b\n  b --> a"))
  let y = (d : String) => read_until(d, @util.index_of(d, ",") + 1, "L")
  assert_not_eq(y(paths[0]), y(paths[1]))
}

///|
test "separates labels on opposite vertical edges" {
  expect_separate_labels(
    "block\n  columns 1\n  a[\"Upper layer\"]\n  space:3\n  b[\"Lower layer\"]\n  a -- \"12 production conforming\" --> b\n  b -- \"12 production deviation\" --> a",
    2,
  )
}

///|
test "separates labels on opposite horizontal edges" {
  expect_separate_labels(
    "block\n  a[\"Left layer\"] space:3 b[\"Right layer\"]\n  a -- \"12 production<br>conforming\" --> b\n  b -- \"12 production<br>deviation\" --> a",
    2,
  )
}

///|
test "keeps disjoint labels on their original straight parallel routes" {
  let src = "block\n  a space:3 b\n  a -- \"forward\" --> b\n  b -- \"reverse\" --> a"
  expect_separate_labels(src, 2)
  for d in edge_paths(block_svg(src)) {
    assert_true(line_ends(d) is Some(_), msg=d)
  }
}

///|
test "separates wide labels when narrow endpoints clamp the parallel routes" {
  expect_separate_labels(
    "block\n  columns 1\n  a[\"A\"]\n  space\n  b[\"B\"]\n  a -- \"144 production conforming\" --> b\n  b -- \"144 production deviation\" --> a",
    2,
  )
}

///|
test "keeps every label for several edges between the same blocks" {
  expect_separate_labels(
    "block\n  columns 1\n  a[\"A\"]\n  space:2\n  b[\"B\"]\n  a -- \"7 production policy\" --> b\n  a -- \"7 test policy\" --> b\n  a -- \"7 production exception\" --> b\n  b -- \"7 production deviation\" --> a",
    4,
  )
}

///|
test "draws a self-loop as an arc" {
  let svg = block_svg("block\n  a\n  a -- \"again\" --> a")
  assert_true(edge_paths(svg)[0].contains("A10,10 0 1 1 "))
  assert_true(svg.contains(">again<"))
}

///|
test "joins a block to a composite that holds it" {
  let svg = block_svg("block\n  block:g\n    a b\n  end\n  a --> g\n  g --> b")
  assert_eq(edge_paths(svg).length(), 2)
  assert_false(svg.contains("NaN"))
}

///|
test "applies styles and classes, also when they come before the block" {
  let svg = block_svg(
    "block\n  classDef hot fill:#f96,stroke:#333,color:#400;\n  class a hot\n  style b fill:red;stroke:blue,stroke-width:2px\n  a b c\n  class b, c hot",
  )
  assert_true(
    svg.contains("<g class=\"pele-node pele-shape-rect hot\" data-id=\"a\""),
  )
  assert_true(
    svg.contains("<g class=\"pele-node pele-shape-rect hot\" data-id=\"c\""),
  )
  assert_true(svg.contains("style=\"rx:var(--_r);fill:#f96;stroke:#333;\""))
  assert_true(
    svg.contains(
      "style=\"rx:var(--_r);fill:red;stroke:blue;stroke-width:2px;\"",
    ),
  )
  assert_true(svg.contains("style=\"fill:#400;\""))
  assert_eq(boxes(svg).length(), 3)
}

///|
test "gives blocks without a class the default class" {
  let svg = block_svg(
    "block\n  a b\n  classDef default stroke:#f00\n  classDef other fill:#0f0\n  class b other",
  )
  assert_eq(occurrences(svg, "stroke:#f00"), 1)
}

///|
test "styles a composite" {
  let svg = block_svg(
    "block\n  block:g\n    a\n  end\n  style g fill:#fee,stroke:#f00",
  )
  let at = @util.index_of(svg, "class=\"pele-cluster\" data-id=\"g\"><rect ")
  assert_true(at != -1)
  assert_true(
    read_until(svg, at, "/>").contains(
      "style=\"rx:var(--_r);fill:#fee;stroke:#f00;\"",
    ),
  )
}

///|
test "draws the front matter title" {
  guard block_render("block\n  a") is Ok(plain) else { fail("rejected") }
  guard block_render("---\ntitle: Systems\n---\nblock\n  a") is Ok(titled) else {
    fail("rejected")
  }
  assert_true(
    titled.svg.contains("class=\"pele-title\" font-weight=\"var(--_tw)\""),
  )
  assert_true(titled.svg.contains(">Systems<"))
  assert_true(titled.height > plain.height)
}

///|
test "escapes label text and decodes entities" {
  let svg = block_svg(
    "block\n  a[\"<b>bold</b> & #quot;q#quot; #9829;\"]\n  b[\"<img src=x onerror=alert(1)>\"]",
  )
  assert_false(svg.contains("<img"))
  assert_true(svg.contains("&quot;q&quot; ♥"))
  assert_true(svg.contains("font-weight=\"var(--_w)\""))
}

///|
test "rejects a column count of zero the way Mermaid does" {
  match block_render("block\n  columns 0\n  a b") {
    Err(failure) => {
      assert_eq(failure.message, "Columns must be an integer !== 0.")
      assert_eq(failure.code.to_string(), "semantic")
    }
    Ok(_) => fail("accepted")
  }
  assert_eq(
    block_svg("block\n  columns auto\n  a b"),
    block_svg("block\n  a b"),
  )
}

///|
test "renders deep nesting without running out of stack" {
  let src = "block\n" + "block\n".repeat(3000) + "a\n" + "end\n".repeat(3000)
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
  let svg = @core.render([@block.block], src, options).svg
  assert_eq(occurrences(svg, "class=\"pele-cluster\""), 3000)
}
