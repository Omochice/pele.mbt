// The expected routes were taken from pele's route.ts, given the same boxes in the same order.

///|
fn box(
  id : Int32,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  form : String,
) -> Box {
  { id, x, y, w, h, form, }
}

///|
/// Routes each (from, to, shift, start trim, end trim) in turn through one set of lanes, and describes every route and the
/// squeezed count.
fn run_routes(
  boxes : Array[Box],
  others : Array[Int32]?,
  frames : Array[Int32],
  routes : Array[(Int32, Int32, Double, Double, Double)],
) -> String {
  let lanes = Lanes::new()
  for f in frames {
    lanes.frame(boxes[f])
  }
  let others = others.map(list => list.map(i => boxes[i]))
  let out = []
  for spec in routes {
    let (a, b, shift, start_trim, end_trim) = spec
    let r = route(
      boxes[a],
      boxes[b],
      shift,
      others,
      lanes,
      start_trim,
      end_trim,
    )
    out.push("d=\{r.d}")
    out.push("start=\{r.sx},\{r.sy} towards \{r.sdx},\{r.sdy}")
    out.push("end=\{r.ex},\{r.ey} towards \{r.edx},\{r.edy}")
    out.push(
      "label=\{r.x0},\{r.y0} \{r.x1},\{r.y1} side=\{r.nx},\{r.ny} lean=\{r.lean} room=\{r.room}",
    )
    out.push("points=\{r.points.map(p => p.to_string()).join(",")}")
  }
  out.push("squeezed=\{lanes.squeezed}")
  out.join("\n")
}

///|
test "joins neighbours in a row with a level line" {
  let boxes = [box(0, 0, 0, 216, 66, "rect"), box(1, 316, 0, 216, 66, "rect")]
  inspect(
    run_routes(boxes, Some([0, 1]), [], [(0, 1, 0, 0, 7)]),
    content=(
      #|d=M216,33L309,33
      #|start=216,33 towards -1,0
      #|end=316,33 towards 1,0
      #|label=216,33 316,33 side=0,0 lean=0 room=88
      #|points=216,33,316,33
      #|squeezed=0
    ),
  )
}

///|
test "shifts a reversed pair apart" {
  let boxes = [box(0, 0, 0, 216, 66, "rect"), box(1, 316, 0, 216, 66, "rect")]
  inspect(
    run_routes(boxes, Some([0, 1]), [], [(0, 1, 7, 0, 7), (1, 0, 7, 7, 7)]),
    content=(
      #|d=M216,40L309,40
      #|start=216,40 towards -1,0
      #|end=316,40 towards 1,0
      #|label=216,40 316,40 side=0,1 lean=0 room=88
      #|points=216,40,316,40
      #|d=M309,26L223,26
      #|start=316,26 towards 1,0
      #|end=216,26 towards -1,0
      #|label=316,26 216,26 side=0,-1 lean=0 room=88
      #|points=316,26,216,26
      #|squeezed=0
    ),
  )
}

///|
test "joins boxes that only partly share a column through the shared span" {
  let boxes = [box(0, 0, 0, 216, 66, "rect"), box(1, 150, 166, 216, 66, "rect")]
  inspect(
    run_routes(boxes, Some([0, 1]), [], [(0, 1, 0, 0, 7), (1, 0, 7, 0, 7)]),
    content=(
      #|d=M183,66L183,159
      #|start=183,66 towards 0,-1
      #|end=183,166 towards 0,1
      #|label=183,66 183,166 side=0,0 lean=0 room=160
      #|points=183,66,183,166
      #|d=M190,166L190,73
      #|start=190,166 towards 0,1
      #|end=190,66 towards 0,-1
      #|label=190,166 190,66 side=1,0 lean=0 room=160
      #|points=190,166,190,66
      #|squeezed=0
    ),
  )
}

///|
test "ends on the outline of a person, a cylinder and a queue" {
  let boxes = [
    box(0, 0, 0, 216, 90, "person"),
    box(1, 0, 178, 216, 90, "cyl"),
    box(2, 0, 356, 216, 80, "h-cyl"),
    box(3, 316, 500, 216, 80, "h-cyl"),
    box(4, 400, 40, 216, 90, "person"),
  ]
  inspect(
    run_routes(boxes, Some([0, 1, 2, 3, 4]), [], [
      (0, 1, 0, 0, 7),
      (1, 2, 0, 7, 7),
      (2, 3, 0, 0, 7),
      (4, 1, 0, 0, 7),
      (3, 4, 0, 0, 7),
    ]),
    content=(
      #|d=M108,90L108,171
      #|start=108,90 towards 0,-1
      #|end=108,178.00000000000009 towards 0,1
      #|label=108,90 108,178.00000000000009 side=0,0 lean=0 room=160
      #|points=108,90,108,178.00000000000009
      #|d=M108,275L108,349
      #|start=108,268 towards 0,-1
      #|end=108,356 towards 0,1
      #|label=108,268 108,356 side=0,0 lean=0 room=160
      #|points=108,268,108,356
      #|d=M195.78,436L329.85,497.1
      #|start=195.77777777777777,436 towards -0.9099715902585186,-0.41467059809248946
      #|end=336.22222222222223,500 towards 0.9099715902585186,0.41467059809248946
      #|label=195.77777777777777,436 336.22222222222223,500 side=0,0 lean=0 room=88
      #|points=195.77777777777777,436,336.22222222222223,500
      #|d=M400,122.26L219.09,184.67
      #|start=400,122.26 towards 0.9453227407152556,-0.32613634554676313
      #|end=212.47102986161013,186.9574946977445 towards -0.9453227407152556,0.32613634554676313
      #|label=400,122.26 212.47102986161013,186.9574946977445 side=0,0 lean=0 room=88
      #|points=400,122.26,212.47102986161013,186.9574946977445
      #|d=M466,500L466,137
      #|start=466,500 towards 0,1
      #|end=466,130 towards 0,-1
      #|label=466,500 466,130 side=0,0 lean=0 room=160
      #|points=466,500,466,130
      #|squeezed=0
    ),
  )
}

///|
test "joins a boundary and a shape inside it" {
  let boxes = [
    box(0, 0, 0, 300, 200, "rect"),
    box(1, 40, 60, 216, 66, "rect"),
    box(2, 40, 100, 216, 90, "person"),
  ]
  inspect(
    run_routes(boxes, Some([1]), [], [
      (0, 1, 0, 0, 7),
      (1, 0, 0, 0, 7),
      (2, 0, 0, 7, 0),
    ]),
    content=(
      #|d=M0,93L33,93
      #|start=0,93 towards -1,0
      #|end=40,93 towards 1,0
      #|label=0,93 40,93 side=0,0 lean=0 room=88
      #|points=0,93,40,93
      #|d=M40,93L7,93
      #|start=40,93 towards 1,0
      #|end=0,93 towards -1,0
      #|label=40,93 0,93 side=0,0 lean=0 room=88
      #|points=40,93,0,93
      #|d=M148,197L148,200
      #|start=148,190 towards 0,-1
      #|end=148,200 towards 0,1
      #|label=148,190 148,200 side=0,0 lean=0 room=160
      #|points=148,190,148,200
      #|squeezed=0
    ),
  )
}

///|
test "loops a relation from a shape to itself" {
  let boxes = [box(0, 0, 0, 216, 66, "rect"), box(1, 0, 0, 216, 10, "rect")]
  inspect(
    run_routes(boxes, Some([0]), [], [(0, 0, 0, 0, 7), (1, 1, 0, 7, 7)]),
    content=(
      #|d=M216,23C244,13 244,53 222.59,45.35
      #|start=216,23 towards -0.9417419115948374,0.3363363969981562
      #|end=216,43 towards -0.9417419115948374,-0.3363363969981562
      #|label=248,33 248,33 side=1,0 lean=0 room=64
      #|points=
      #|d=M223,3.75C244,3 244,7 223,6.25
      #|start=216,4 towards -0.9993628543475497,0.03569153051241249
      #|end=216,6 towards -0.9993628543475497,-0.03569153051241249
      #|label=248,5 248,5 side=1,0 lean=0 room=64
      #|points=
      #|squeezed=0
    ),
  )
}

///|
test "goes around a shape between two in a row" {
  let boxes = [
    box(0, 0, 0, 216, 66, "rect"),
    box(1, 316, 0, 216, 66, "rect"),
    box(2, 632, 0, 216, 66, "rect"),
  ]
  inspect(
    run_routes(boxes, Some([0, 1, 2]), [], [
      (0, 2, 0, 0, 7),
      (2, 0, 0, 0, 7),
      (0, 2, 0, 7, 7),
    ]),
    content=(
      #|d=M162,0V-12Q162,-20 170,-20H678Q686,-20 686,-12V-7
      #|start=162,0 towards 0,1
      #|end=686,0 towards 0,1
      #|label=162,-20 686,-20 side=0,0 lean=0 room=160
      #|points=162,0,162,-20,686,-20,686,0
      #|d=M686,66V78Q686,86 678,86H170Q162,86 162,78V73
      #|start=686,66 towards 0,-1
      #|end=162,66 towards 0,-1
      #|label=686,86 162,86 side=0,0 lean=0 room=160
      #|points=686,66,686,86,162,86,162,66
      #|d=M174,-7V-19Q174,-27 182,-27H690Q698,-27 698,-19V-7
      #|start=174,0 towards 0,1
      #|end=698,0 towards 0,1
      #|label=174,-27 698,-27 side=0,0 lean=0 room=160
      #|points=174,0,174,-27,698,-27,698,0
      #|squeezed=0
    ),
  )
}

///|
test "goes around a shape between two in a column" {
  let boxes = [
    box(0, 0, 0, 216, 66, "rect"),
    box(1, 0, 154, 216, 66, "rect"),
    box(2, 0, 308, 216, 66, "rect"),
  ]
  inspect(
    run_routes(boxes, Some([0, 1, 2]), [], [(0, 2, 0, 0, 7), (2, 0, 0, 0, 7)]),
    content=(
      #|d=M216,49.5H228Q236,49.5 236,57.5V316.5Q236,324.5 228,324.5H223
      #|start=216,49.5 towards -1,0
      #|end=216,324.5 towards -1,0
      #|label=236,49.5 236,324.5 side=1,0 lean=30 room=88
      #|points=216,49.5,236,49.5,236,324.5,216,324.5
      #|d=M0,324.5H-12Q-20,324.5 -20,316.5V57.5Q-20,49.5 -12,49.5H-7
      #|start=0,324.5 towards 1,0
      #|end=0,49.5 towards 1,0
      #|label=-20,324.5 -20,49.5 side=-1,0 lean=30 room=88
      #|points=0,324.5,-20,324.5,-20,49.5,0,49.5
      #|squeezed=0
    ),
  )
}

///|
test "leaves a blocked line straight when nothing is steered around" {
  let boxes = [
    box(0, 0, 0, 216, 66, "rect"),
    box(1, 316, 0, 216, 66, "rect"),
    box(2, 632, 0, 216, 66, "rect"),
  ]
  inspect(
    run_routes(boxes, None, [], [(0, 2, 0, 0, 7)]),
    content=(
      #|d=M216,33L625,33
      #|start=216,33 towards -1,0
      #|end=632,33 towards 1,0
      #|label=216,33 632,33 side=0,0 lean=0 room=88
      #|points=216,33,632,33
      #|squeezed=0
    ),
  )
}

///|
test "bends a diagonal line through the gaps around a shape in its way" {
  let boxes = [
    box(0, 0, 0, 216, 66, "rect"),
    box(1, 316, 77, 216, 66, "rect"),
    box(2, 632, 154, 216, 66, "rect"),
    box(3, 0, 154, 216, 66, "rect"),
    box(4, 632, 0, 216, 66, "rect"),
  ]
  inspect(
    run_routes(boxes, Some([0, 1, 2, 3, 4]), [], [
      (0, 2, 0, 0, 7),
      (3, 4, 0, 0, 7),
      (2, 0, 0, 7, 7),
      (4, 3, 0, 0, 7),
    ]),
    content=(
      #|d=M216,59.32L625.2,159.03
      #|start=216,59.31645569620254 towards -0.971572105504356,-0.2367438358349222
      #|end=632,160.68354430379748 towards 0.971572105504356,0.2367438358349222
      #|label=216,59.31645569620254 632,160.68354430379748 side=0,0 lean=0 room=88
      #|points=216,59.31645569620254,632,160.68354430379748
      #|d=M216,160.68L625.2,60.97
      #|start=216,160.68354430379748 towards -0.971572105504356,0.2367438358349222
      #|end=632,59.31645569620254 towards 0.971572105504356,-0.2367438358349222
      #|label=216,160.68354430379748 632,59.31645569620254 side=0,0 lean=0 room=88
      #|points=216,160.68354430379748,632,59.31645569620254
      #|d=M625.2,159.03L222.8,60.97
      #|start=632,160.68354430379748 towards 0.971572105504356,0.2367438358349222
      #|end=216,59.31645569620254 towards -0.971572105504356,-0.2367438358349222
      #|label=632,160.68354430379748 216,59.31645569620254 side=0,0 lean=0 room=88
      #|points=632,160.68354430379748,216,59.31645569620254
      #|d=M632,59.32L222.8,159.03
      #|start=632,59.31645569620254 towards 0.971572105504356,-0.2367438358349222
      #|end=216,160.68354430379748 towards -0.971572105504356,0.2367438358349222
      #|label=632,59.31645569620254 216,160.68354430379748 side=0,0 lean=0 room=88
      #|points=632,59.31645569620254,216,160.68354430379748
      #|squeezed=4
    ),
  )
}

///|
test "keeps detours inside a frame apart from it" {
  let boxes = [
    box(0, 30, 40, 216, 66, "rect"),
    box(1, 346, 40, 216, 66, "rect"),
    box(2, 662, 40, 216, 66, "rect"),
    box(3, 0, 0, 908, 140, "rect"),
    box(4, 30, 200, 216, 66, "rect"),
    box(5, 346, 200, 216, 66, "rect"),
    box(6, 662, 200, 216, 66, "rect"),
  ]
  inspect(
    run_routes(boxes, Some([0, 1, 2, 4, 5, 6]), [3], [
      (0, 2, 0, 0, 7),
      (2, 0, 0, 0, 7),
      (4, 6, 0, 0, 7),
      (6, 4, 0, 0, 7),
      (0, 6, 0, 0, 7),
      (4, 2, 0, 0, 7),
    ]),
    content=(
      #|d=M192,40V28Q192,20 200,20H708Q716,20 716,28V33
      #|start=192,40 towards 0,1
      #|end=716,40 towards 0,1
      #|label=192,20 716,20 side=0,0 lean=0 room=160
      #|points=192,40,192,20,716,20,716,40
      #|d=M728,40V21Q728,13 720,13H212Q204,13 204,21V33
      #|start=728,40 towards 0,1
      #|end=204,40 towards 0,1
      #|label=728,13 204,13 side=0,0 lean=0 room=160
      #|points=728,40,728,13,204,13,204,40
      #|d=M192,266V278Q192,286 200,286H708Q716,286 716,278V273
      #|start=192,266 towards 0,-1
      #|end=716,266 towards 0,-1
      #|label=192,286 716,286 side=0,0 lean=0 room=160
      #|points=192,266,192,286,716,286,716,266
      #|d=M728,266V285Q728,293 720,293H212Q204,293 204,285V273
      #|start=728,266 towards 0,-1
      #|end=204,266 towards 0,-1
      #|label=728,293 204,293 side=0,0 lean=0 room=160
      #|points=728,266,728,293,204,293,204,266
      #|d=M246,100.34L655.21,203.94
      #|start=246,100.34177215189874 towards -0.9694163745330328,-0.24542186697038804
      #|end=662,205.65822784810126 towards 0.9694163745330328,0.24542186697038804
      #|label=246,100.34177215189874 662,205.65822784810126 side=0,0 lean=0 room=88
      #|points=246,100.34177215189874,662,205.65822784810126
      #|d=M246,205.66L655.21,102.06
      #|start=246,205.65822784810126 towards -0.9694163745330328,0.24542186697038804
      #|end=662,100.34177215189874 towards 0.9694163745330328,-0.24542186697038804
      #|label=246,205.65822784810126 662,100.34177215189874 side=0,0 lean=0 room=88
      #|points=246,205.65822784810126,662,100.34177215189874
      #|squeezed=0
    ),
  )
}

///|
test "detours across a grid where both sides hold shapes" {
  let boxes = [
    box(0, 0, 0, 216, 66, "rect"),
    box(1, 316, 0, 216, 66, "rect"),
    box(2, 632, 0, 216, 66, "rect"),
    box(3, 0, 154, 216, 66, "rect"),
    box(4, 316, 154, 216, 66, "rect"),
    box(5, 632, 154, 216, 66, "rect"),
    box(6, 0, 308, 216, 66, "rect"),
    box(7, 316, 308, 216, 66, "rect"),
    box(8, 632, 308, 216, 66, "rect"),
  ]
  inspect(
    run_routes(boxes, Some([0, 1, 2, 3, 4, 5, 6, 7, 8]), [], [
      (3, 5, 0, 0, 7),
      (5, 3, 0, 0, 7),
      (1, 7, 0, 0, 7),
      (7, 1, 0, 0, 7),
      (0, 8, 0, 0, 7),
      (6, 2, 0, 0, 7),
      (3, 5, 0, 7, 7),
      (0, 2, 0, 0, 7),
      (2, 0, 0, 0, 7),
      (6, 8, 0, 0, 7),
    ]),
    content=(
      #|d=M162,154V142Q162,134 170,134H678Q686,134 686,142V147
      #|start=162,154 towards 0,1
      #|end=686,154 towards 0,1
      #|label=162,134 686,134 side=0,0 lean=0 room=160
      #|points=162,154,162,134,686,134,686,154
      #|d=M686,220V232Q686,240 678,240H170Q162,240 162,232V227
      #|start=686,220 towards 0,-1
      #|end=162,220 towards 0,-1
      #|label=686,240 162,240 side=0,0 lean=0 room=160
      #|points=686,220,686,240,162,240,162,220
      #|d=M532,49.5H544Q552,49.5 552,57.5V316.5Q552,324.5 544,324.5H539
      #|start=532,49.5 towards -1,0
      #|end=532,324.5 towards -1,0
      #|label=552,49.5 552,324.5 side=1,0 lean=30 room=88
      #|points=532,49.5,552,49.5,552,324.5,532,324.5
      #|d=M316,324.5H304Q296,324.5 296,316.5V57.5Q296,49.5 304,49.5H309
      #|start=316,324.5 towards 1,0
      #|end=316,49.5 towards 1,0
      #|label=296,324.5 296,49.5 side=-1,0 lean=30 room=88
      #|points=316,324.5,296,324.5,296,49.5,316,49.5
      #|d=M175.71,66L665.99,304.93
      #|start=175.71428571428567,66 towards -0.8989324224937065,-0.43808731982288224
      #|end=672.2857142857143,308 towards 0.8989324224937065,0.43808731982288224
      #|label=175.71428571428567,66 672.2857142857143,308 side=0,0 lean=0 room=88
      #|points=175.71428571428567,66,672.2857142857143,308
      #|d=M175.71,308L665.99,69.07
      #|start=175.71428571428567,308 towards -0.8989324224937065,0.43808731982288224
      #|end=672.2857142857143,66 towards 0.8989324224937065,-0.43808731982288224
      #|label=175.71428571428567,308 672.2857142857143,66 side=0,0 lean=0 room=88
      #|points=175.71428571428567,308,672.2857142857143,66
      #|d=M174,147V135Q174,127 182,127H690Q698,127 698,135V147
      #|start=174,154 towards 0,1
      #|end=698,154 towards 0,1
      #|label=174,127 698,127 side=0,0 lean=0 room=160
      #|points=174,154,174,127,698,127,698,154
      #|d=M162,0V-12Q162,-20 170,-20H678Q686,-20 686,-12V-7
      #|start=162,0 towards 0,1
      #|end=686,0 towards 0,1
      #|label=162,-20 686,-20 side=0,0 lean=0 room=160
      #|points=162,0,162,-20,686,-20,686,0
      #|d=M698,0V-19Q698,-27 690,-27H182Q174,-27 174,-19V-7
      #|start=698,0 towards 0,1
      #|end=174,0 towards 0,1
      #|label=698,-27 174,-27 side=0,0 lean=0 room=160
      #|points=698,0,698,-27,174,-27,174,0
      #|d=M162,374V386Q162,394 170,394H678Q686,394 686,386V381
      #|start=162,374 towards 0,-1
      #|end=686,374 towards 0,-1
      #|label=162,394 686,394 side=0,0 lean=0 room=160
      #|points=162,374,162,394,686,394,686,374
      #|squeezed=2
    ),
  )
}

///|
test "bends a diagonal line along the gap between rows" {
  let boxes = [
    box(0, 0, 0, 216, 66, "rect"),
    box(1, 316, 40, 216, 66, "rect"),
    box(2, 632, 154, 216, 66, "rect"),
    box(3, 0, 200, 216, 66, "person"),
  ]
  inspect(
    run_routes(boxes, Some([0, 1, 2, 3]), [], [
      (0, 2, 0, 0, 7),
      (2, 0, 0, 7, 7),
      (0, 2, 7, 0, 7),
      (3, 1, 0, 0, 7),
    ]),
    content=(
      #|d=M162,66V102Q162,110 170,110H678Q686,110 686,118V147
      #|start=162,66 towards 0,-1
      #|end=686,154 towards 0,1
      #|label=162,110 686,110 side=0,0 lean=0 room=160
      #|points=162,66,162,110,686,110,686,154
      #|d=M698,147V140Q698,132 690,132H182Q174,132 174,124V73
      #|start=698,154 towards 0,1
      #|end=174,66 towards 0,-1
      #|label=698,132 174,132 side=0,0 lean=0 room=160
      #|points=698,154,698,132,174,132,174,66
      #|d=M213.86,66L625.2,166.23
      #|start=213.8607477286928,66 towards -0.971572105504356,-0.23674383583492223
      #|end=632,167.88836210408437 towards 0.971572105504356,0.23674383583492223
      #|label=213.8607477286928,66 632,167.88836210408437 side=-0.23674383583492223,0.971572105504356 lean=0 room=88
      #|points=213.8607477286928,66,632,167.88836210408437
      #|d=M121.82,226L352.58,109.16
      #|start=121.82499999999999,226 towards -0.8921571581552188,0.451725143369731
      #|end=358.825,106 towards 0.8921571581552188,-0.451725143369731
      #|label=121.82499999999999,226 358.825,106 side=0,0 lean=0 room=88
      #|points=121.82499999999999,226,358.825,106
      #|squeezed=1
    ),
  )
}
