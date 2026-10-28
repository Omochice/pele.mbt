///|
fn leaf(name : String, value : Double) -> @treemap.TreemapNode {
  {
    name,
    children: None,
    value: Some(value),
    class_selector: None,
    css_compiled_styles: None,
  }
}

///|
fn section(
  name : String,
  children : Array[@treemap.TreemapNode],
) -> @treemap.TreemapNode {
  {
    name,
    children: Some(children),
    value: None,
    class_selector: None,
    css_compiled_styles: None,
  }
}

///|
let insets : @treemap.Insets = { gap: 4, header: 28, side: 6, }

///|
fn describe_box(b : @treemap.Box) -> String {
  "\{b.node.name} s\{b.series} v\{b.value} @\{b.x},\{b.y} \{b.w}x\{b.h}"
}

///|
fn laid_out(
  nodes : Array[@treemap.TreemapNode],
  width : Double,
  height : Double,
  insets~ : @treemap.Insets = insets,
) -> String {
  @treemap.layout_treemap(nodes, width, height, insets)
  .map(describe_box)
  .join("\n")
}

///|
fn overlap(a : @treemap.Box, b : @treemap.Box) -> Bool {
  a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h
}

///|
test "boxes are placed in rows along the shorter side, largest first" {
  let nodes = [40.0, 30.0, 20.0, 8.0, 2.0].mapi((i, v) => leaf("n\{i}", v))
  inspect(
    laid_out(nodes, 1000, 600, insets={ gap: 0, header: 28, side: 6, }),
    content=(
      #|n0 s0 v40 @0,0 400x600
      #|n1 s1 v30 @400,0 300x600
      #|n2 s2 v20 @700,0 300x400
      #|n3 s3 v8 @700,400 240x200
      #|n4 s4 v2 @940,400 60x200
    ),
  )
}

///|
test "a row stops growing when another box would make its boxes less square" {
  inspect(
    laid_out(
      [leaf("a", 7), leaf("b", 7), leaf("c", 3), leaf("d", 3), leaf("e", 1)],
      640,
      400,
    ),
    content=(
      #|a s0 v7 @0,0 211x400
      #|b s1 v7 @215,0 210x400
      #|c s2 v3 @429,0 211x169
      #|d s3 v3 @429,173 211x169
      #|e s4 v1 @429,346 211x54
    ),
  )
}

///|
test "each box has an area in proportion to its value and no two boxes overlap" {
  let nodes = [40.0, 30.0, 20.0, 8.0, 2.0].mapi((i, v) => leaf("n\{i}", v))
  let boxes = @treemap.layout_treemap(nodes, 1000, 600, {
    gap: 0,
    header: 28,
    side: 6,
  })
  inspect(boxes.length(), content="5")
  for a in boxes {
    inspect((a.w * a.h / 600000 - a.value / 100).abs() < 0.005, content="true")
    for b in boxes {
      if !physical_equal(a, b) {
        inspect(overlap(a, b), content="false")
      }
    }
  }
}

///|
test "boxes stay close to square" {
  let nodes = Array::makei(40, i => leaf("n\{i}", (1 + i % 7).to_double()))
  let boxes = @treemap.layout_treemap(nodes, 800, 500, {
    gap: 0,
    header: 28,
    side: 6,
  })
  let mut sum = 0.0
  let mut worst = 0.0
  for b in boxes {
    let ratio = @util.js_max(b.w / b.h, b.h / b.w)
    sum += ratio
    worst = @util.js_max(worst, ratio)
  }
  inspect(sum / boxes.length().to_double() < 1.6, content="true")
  inspect(worst < 4, content="true")
}

///|
test "the boxes fill the frame and the gap lies between siblings" {
  inspect(
    laid_out([leaf("a", 1), leaf("b", 1)], 400, 200, insets={
      gap: 10,
      header: 28,
      side: 6,
    }),
    content=(
      #|a s0 v1 @0,0 195x200
      #|b s1 v1 @205,0 195x200
    ),
  )
}

///|
test "children are nested inside their section, under its header" {
  let tree = [
    section("s", [leaf("a", 3), section("t", [leaf("b", 1), leaf("c", 1)])]),
    leaf("d", 2),
  ]
  inspect(
    laid_out(tree, 600, 400),
    content=(
      #|s s0 v5 @0,0 427x400
      #|d s1 v2 @431,0 169x400
      #|a s0 v3 @6,28 247x366
      #|t s0 v2 @257,28 164x366
      #|b s0 v1 @263,56 152x164
      #|c s0 v1 @263,224 152x164
    ),
  )
}

///|
test "a leaf's own value is not summed into its section twice" {
  let boxes = @treemap.layout_treemap(
    [section("s", [leaf("a", 3), section("t", [leaf("b", 1)])])],
    600,
    400,
    insets,
  )
  inspect(
    boxes.map(b => "\{b.node.name}=\{b.value}").join(" "),
    content="s=4 a=3 t=1 b=1",
  )
}

///|
test "what has no positive value is left out" {
  inspect(
    laid_out(
      [
        leaf("a", 1),
        leaf("zero", 0),
        leaf("negative", -5),
        leaf("nan", @double.not_a_number),
        section("empty", []),
      ],
      100,
      100,
    ),
    content="a s0 v1 @0,0 100x100",
  )
  inspect(laid_out([], 100, 100), content="")
  inspect(
    laid_out([leaf("huge", 1.0e308), leaf("also", 1.0e308)], 100, 100),
    content="",
  )
}

///|
test "a section too small for its header gives its children its whole box" {
  inspect(
    laid_out([section("s", [leaf("a", 1)])], 50, 20),
    content=(
      #|s s0 v1 @0,0 50x20
      #|a s0 v1 @0,0 50x20
    ),
  )
  let tree = [
    section("s", [leaf("a", 2), section("t", [leaf("b", 1), leaf("c", 1)])]),
  ]
  let boxes = @treemap.layout_treemap(tree, 300, 30, insets)
  inspect(boxes.map(b => b.node.name).join(" "), content="s a t b c")
  let s = boxes[0]
  inspect(s.headed, content="false")
  for b in boxes[1:] {
    inspect(
      b.w * b.h > 0 &&
      b.x >= s.x &&
      b.y >= s.y &&
      b.x + b.w <= s.x + s.w &&
      b.y + b.h <= s.y + s.h,
      content="true",
    )
  }
  inspect(
    @treemap.layout_treemap(tree, 300, 300, insets)[0].headed,
    content="true",
  )
}

///|
test "a box thinner than the gap is kept, and so is one with no room at all" {
  let thin = @treemap.layout_treemap(
    [leaf("big", 397), leaf("thin", 3)],
    400,
    100,
    insets,
  )
  inspect(thin.map(b => b.node.name).join(" "), content="big thin")
  inspect(thin[1].w > 0, content="true")
  inspect(overlap(thin[0], thin[1]), content="false")
  let speck = @treemap.layout_treemap(
    [leaf("big", 1.0e6), section("s", [leaf("speck", 1)])],
    100,
    100,
    insets,
  )
  inspect(speck.map(b => b.node.name).join(" "), content="big s speck")
  for b in speck[1:] {
    inspect(b.w * b.h, content="0")
  }
}

///|
test "a frame with no area keeps its boxes with no size" {
  inspect(laid_out([leaf("a", 1)], 0, 100), content="a s0 v1 @0,0 0x100")
  inspect(laid_out([leaf("a", 1)], 100, -1), content="a s0 v1 @0,0 100x0")
}
