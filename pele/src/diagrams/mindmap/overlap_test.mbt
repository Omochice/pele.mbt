///|
priv struct Box {
  id : String
  x : Double
  y : Double
  w : Double
  h : Double
}

///|
/// The text between `open` and the next `close` after it in `text`.
fn between(text : String, open : String, close : String) -> String {
  let start = @util.index_of(text, open) + open.length()
  let end = @util.index_of(text, close, from=start)
  @util.slice(text, start, end~)
}

///|
/// Every node here is drawn as a rectangle, so its group and rect give its bounding box.
fn boxes(svg : String) -> Array[Box] {
  let boxes = []
  let chunks = svg
    .split("<g class=\"pele-node")
    .map(s => s.to_owned())
    .collect()
  for chunk in chunks[1:] {
    let at = between(chunk, "translate(", ")")
      .split(",")
      .map(s => s.to_owned())
      .collect()
    let rect = @util.slice(chunk, @util.index_of(chunk, "<rect"))
    boxes.push({
      id: between(chunk, "data-id=\"", "\""),
      x: @util.parse_float(at[0]),
      y: @util.parse_float(at[1]),
      w: @util.parse_float(between(rect, "width=\"", "\"")),
      h: @util.parse_float(between(rect, "height=\"", "\"")),
    })
  }
  boxes
}

///|
fn box_of(boxes : Array[Box], id : String) -> Box {
  boxes.iter().find_first(b => b.id == id).unwrap()
}

///|
fn boxes_of(source : String) -> Array[Box] raise @errors.PeleError {
  let result = @core.render(
    [@mindmap.mindmap],
    source,
    @types.RenderOptions::default(),
  )
  boxes(result.svg)
}

///|
test "branches stand on both sides of the root, balanced by height" {
  let all = boxes_of(
    "mindmap\n  [root]\n    [a]\n      [a1]\n      [a2]\n      [a3]\n    [b]\n    [c]\n    [d]",
  )
  let root = box_of(all, "root")
  let a = box_of(all, "a")
  assert_true(a.x > root.x)
  assert_true(box_of(all, "a1").x > a.x)
  for id in ["b", "c", "d"] {
    assert_true(box_of(all, id).x < root.x)
  }
  assert_true(box_of(all, "a1").y < box_of(all, "a2").y)
  assert_true((box_of(all, "a2").y - a.y).abs() < 0.01)
  assert_true(box_of(all, "b").y < box_of(all, "c").y)
  assert_true((box_of(all, "c").y - root.y).abs() < 0.01)
}

///|
test "a growing final branch keeps the sides of the first ones" {
  let start = "mindmap\n  [root]\n    [Build]\n      [Prototype]\n      [Iterate]\n    [Review]\n      [Test]\n      [Refine]"
  for
    tail in [
      "", "\n    [Ship]", "\n    [Ship]\n      [Launch]", "\n    [Ship]\n      [Launch]\n      [Learn]",
    ] {
    let all = boxes_of(start + tail)
    let root = box_of(all, "root")
    assert_true(box_of(all, "Build").x > root.x)
    assert_true(box_of(all, "Review").x < root.x)
    if tail != "" {
      assert_true(box_of(all, "Ship").x < root.x)
    }
  }
}

///|
/// A tree of rectangles whose shape comes from a fixed sequence, so that the test is repeatable.
fn generated_tree(seed : Int32, count : Int32) -> String {
  let mut state = seed
  let next = (bound : Int32) => {
    state = (state * 1103515245 + 12345) & 0x7fffffff
    (state >> 8) % bound
  }
  let out = StringBuilder()
  out.write_string("mindmap\n[n0]\n")
  let mut depth = 1
  for i in 1..<count {
    depth = @cmp.maximum(1, @cmp.minimum(depth + 1, 1 + next(depth + 1)))
    let words = 1 + next(12)
    out.write_string(
      " ".repeat(depth) +
      "n\{i}[" +
      "word ".repeat(words).trim_end(chars=" ").to_owned() +
      "]\n",
    )
  }
  out.to_string()
}

///|
test "no two nodes overlap" {
  for round in 0..<30 {
    let count = 2 + round * 7 % 60
    let source = generated_tree(11 + round, count)
    let all = boxes_of(source)
    assert_eq(all.length(), count)
    for i in 0..<all.length() {
      for j in (i + 1)..<all.length() {
        let a = all[i]
        let b = all[j]
        let apart = (a.x - b.x).abs() >= (a.w + b.w) / 2 ||
          (a.y - b.y).abs() >= (a.h + b.h) / 2
        if !apart {
          fail("\{a.id} and \{b.id} overlap in \{source.escape()}")
        }
      }
    }
  }
}
