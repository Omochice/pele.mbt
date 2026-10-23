// The expected layouts were taken from pele's layout.ts with the metrics measurer, at font size 16 with small text at 13.

///|
/// Every boundary drawn, in order, with the shapes it holds; or the parse error.
fn laid_out(source : String, room : Double?, gap : Double) -> String {
  let db = C4Db::new()
  parse_c4(source, db) catch {
    @errors.PeleError(failure) => return "error: \{failure.message}"
  }
  let layout = layout_c4(db, @text.metrics_measurer, 16, 13, room, gap)
  let out = []
  for group in layout.order {
    let b = group.box
    let heights = group.labels.map(l => l.height.to_string()).join(",")
    out.push(
      "group \{group.boundary.alias_} at \{b.x},\{b.y} size \{b.w}x\{b.h} head=\{group.head} headW=\{group.head_w} labels=\{heights}",
    )
    for node in group.nodes {
      let n = node.box
      let labels = node.labels.map(l => "\{l.width}/\{l.height}").join(",")
      out.push(
        "  node \{node.shape.alias_} \{n.form} at \{n.x},\{n.y} size \{n.w}x\{n.h} textH=\{node.text_h} labels=\{labels}",
      )
    }
  }
  out.push("boxes=\{layout.boxes.length()}")
  out.join("\n")
}

///|
test "lays shapes out in rows of four and boundaries in rows of two" {
  inspect(
    laid_out(
      "C4Context\nSystem(s1, \"S1\")\nSystem(s2, \"S2\")\nSystem(s3, \"S3\")\nSystem(s4, \"S4\")\nSystem(s5, \"S5\")\nBoundary(b1, \"B1\") {\n System(i1, \"I1\")\n}\nBoundary(b2, \"B2\") {\n System(i2, \"I2\")\n}\nBoundary(b3, \"B3\") {\n System(i3, \"I3\")\n}",
      None,
      36,
    ),
    content=(
      #|group global at 0,0 size 1164x664 head=28 headW=0 labels=
      #|  node s1 rect at 0,0 size 216x66 textH=42 labels=51.924/18,19.568/24,0/0,0/0
      #|  node s2 rect at 316,0 size 216x66 textH=42 labels=51.924/18,19.568/24,0/0,0/0
      #|  node s3 rect at 632,0 size 216x66 textH=42 labels=51.924/18,19.568/24,0/0,0/0
      #|  node s4 rect at 948,0 size 216x66 textH=42 labels=51.924/18,19.568/24,0/0,0/0
      #|  node s5 rect at 0,154 size 216x66 textH=42 labels=51.924/18,19.568/24,0/0,0/0
      #|group b1 at 0,268 size 272x174 head=80 headW=48.399 labels=24,20,0
      #|  node i1 rect at 28,348 size 216x66 textH=42 labels=51.924/18,13.344/24,0/0,0/0
      #|group b2 at 320,268 size 272x174 head=80 headW=48.399 labels=24,20,0
      #|  node i2 rect at 348,348 size 216x66 textH=42 labels=51.924/18,13.344/24,0/0,0/0
      #|group b3 at 0,490 size 272x174 head=80 headW=48.399 labels=24,20,0
      #|  node i3 rect at 28,570 size 216x66 textH=42 labels=51.924/18,13.344/24,0/0,0/0
      #|boxes=11
    ),
  )
}

///|
test "gives each kind of element its shape and stretches a row to its tallest" {
  inspect(
    laid_out(
      "C4Container\nPerson(p, \"P\")\nPerson_Ext(pe, \"PE\", \"A person outside\")\nSystem(s, \"S\")\nSystemDb(sd, \"SD\")\nSystemQueue(sq, \"SQ\")\nContainer_Ext(ce, \"CE\", \"Go\")\nContainerDb_Ext(cde, \"CDE\")\nComponentQueue_Ext(cqe, \"CQE\")",
      None,
      36,
    ),
    content=(
      #|group global at 0,0 size 1164x294 head=28 headW=0 labels=
      #|  node p person at 0,0 size 216x116 textH=42 labels=50.604/18,10.672/24,0/0,0/0
      #|  node pe person at 316,0 size 216x116 textH=66 labels=96.624/18,21.344/24,0/0,97.552/20
      #|  node s rect at 632,0 size 216x116 textH=42 labels=51.924/18,10.672/24,0/0,0/0
      #|  node sd cyl at 948,0 size 216x116 textH=42 labels=68.604/18,22.224/24,0/0,0/0
      #|  node sq h-cyl at 0,204 size 216x90 textH=42 labels=88.62/18,23.12/24,0/0,0/0
      #|  node ce rect at 316,204 size 216x90 textH=62 labels=109.296/18,22.224/24,24.57/20,0/0
      #|  node cde cyl at 632,204 size 216x90 textH=42 labels=125.976/18,33.776/24,0/0,0/0
      #|  node cqe h-cyl at 948,204 size 216x90 textH=60 labels=112.344/36,34.672/24,0/0,0/0
      #|boxes=8
    ),
  )
}

///|
test "takes a shape from $shape, $sprite or $tags" {
  inspect(
    laid_out(
      "C4Context\nSystem(a, \"A\", $tags=\"v1, cylinder\")\nSystem(b, \"B\", $sprite=\"QUEUE\")\nSystem(c, \"C\")\nUpdateElementStyle(c, $shape=\"Person\")\nSystem(d, \"D\", $tags=\"constructor\")\nSystemDb(e, \"E\", $shape=\"box\")",
      None,
      36,
    ),
    content=(
      #|group global at 0,0 size 1164x246 head=28 headW=0 labels=
      #|  node a cyl at 0,0 size 216x92 textH=42 labels=51.924/18,11.552/24,0/0,0/0
      #|  node b h-cyl at 316,0 size 216x92 textH=42 labels=51.924/18,11.552/24,0/0,0/0
      #|  node c person at 632,0 size 216x92 textH=42 labels=51.924/18,11.552/24,0/0,0/0
      #|  node d rect at 948,0 size 216x92 textH=42 labels=51.924/18,11.552/24,0/0,0/0
      #|  node e rect at 0,180 size 216x66 textH=42 labels=68.604/18,10.672/24,0/0,0/0
      #|boxes=5
    ),
  )
}

///|
test "wraps long text and widens for a word that cannot wrap" {
  inspect(
    laid_out(
      "C4Context\nSystem(a, \"A\", \"word word word word word word word word word word word word word word word word word word word word\")\nSystem(b, \"WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW\")\nContainer(c, \"C\", \"Node.js\", \"Serves <b>requests</b><br/>all day\")",
      None,
      36,
    ),
    content=(
      #|group global at 0,0 size 1264.1599999999999x150 head=28 headW=0 labels=
      #|  node a rect at 0,0 size 216x150 textH=126 labels=51.924/18,11.552/24,0/0,187.096/80
      #|  node b rect at 316,0 size 632.16x150 textH=42 labels=51.924/18,604.16/24,0/0,0/0
      #|  node c rect at 1048.1599999999999,0 size 216x150 textH=106 labels=63.276/18,11.552/24,51.298/20,98.25399999999999/40
      #|boxes=3
    ),
  )
}

///|
test "nests boundaries and sizes each around what it holds" {
  inspect(
    laid_out(
      "C4Deployment\nDeployment_Node(outer, \"Outer\", \"Linux\", \"A machine\") {\n  Node(inner, \"Inner\") {\n    Container(app, \"App\")\n  }\n  Node_L(left, \"Left\") {\n    Container(other, \"Other\")\n  }\n}",
      None,
      36,
    ),
    content=(
      #|group global at 0,0 size 648x302 head=28 headW=0 labels=
      #|group outer at 0,0 size 648x302 head=100 headW=61.412 labels=24,20,20
      #|group inner at 28,100 size 272x174 head=80 headW=39.12 labels=24,20,0
      #|  node app rect at 56,180 size 216x66 textH=42 labels=63.276/18,31.104/24,0/0,0/0
      #|group left at 348,100 size 272x174 head=80 headW=36.14 labels=24,20,0
      #|  node other rect at 376,180 size 216x66 textH=42 labels=63.276/18,42.672/24,0/0,0/0
      #|boxes=5
    ),
  )
}

///|
test "follows UpdateLayoutConfig" {
  inspect(
    laid_out(
      "C4Context\nSystem(a, \"A\")\nSystem(b, \"B\")\nSystem(c, \"C\")\nBoundary(x, \"X\") {\n System(d, \"D\")\n}\nBoundary(y, \"Y\") {\n System(e, \"E\")\n}\nUpdateLayoutConfig($c4ShapeInRow=\"1\", $c4BoundaryInRow=\"1\")",
      None,
      36,
    ),
    content=(
      #|group global at 0,0 size 272x818 head=28 headW=0 labels=
      #|  node a rect at 0,0 size 216x66 textH=42 labels=51.924/18,11.552/24,0/0,0/0
      #|  node b rect at 0,154 size 216x66 textH=42 labels=51.924/18,11.552/24,0/0,0/0
      #|  node c rect at 0,308 size 216x66 textH=42 labels=51.924/18,11.552/24,0/0,0/0
      #|group x at 0,422 size 272x174 head=80 headW=48.399 labels=24,20,0
      #|  node d rect at 28,502 size 216x66 textH=42 labels=51.924/18,11.552/24,0/0,0/0
      #|group y at 0,644 size 272x174 head=80 headW=48.399 labels=24,20,0
      #|  node e rect at 28,724 size 216x66 textH=42 labels=51.924/18,10.672/24,0/0,0/0
      #|boxes=7
    ),
  )
}

///|
test "leaves out a boundary that ends up inside itself" {
  inspect(
    laid_out(
      "C4Context\nSystem(ok, \"OK\")\nBoundary(a, \"A\") {\n  Boundary(b, \"B\") {\n    Boundary(a, \"A again\") {\n      System(lost, \"Lost\")\n    }\n  }\n}",
      None,
      36,
    ),
    content=(
      #|group global at 0,0 size 216x66 head=28 headW=0 labels=
      #|  node ok rect at 0,0 size 216x66 textH=42 labels=51.924/18,24/24,0/0,0/0
      #|boxes=1
    ),
  )
}

///|
test "widens a boundary for a long heading" {
  inspect(
    laid_out(
      "C4Context\nBoundary(b, \"A boundary with a rather long name to show\", \"custom type\", $descr=\"described\") {\n  System(s, \"S\")\n}",
      None,
      36,
    ),
    content=(
      #|group global at 0,0 size 369.84x194 head=28 headW=0 labels=
      #|group b at 0,0 size 369.84x194 head=100 headW=337.84 labels=24,20,20
      #|  node s rect at 28,100 size 216x66 textH=42 labels=51.924/18,10.672/24,0/0,0/0
      #|boxes=2
    ),
  )
}

///|
test "fits rows into the room it has" {
  inspect(
    laid_out(
      "C4Context\nSystem(s1, \"S1\")\nSystem(s2, \"S2\")\nSystem(s3, \"S3\")\nSystem(s4, \"S4\")\nSystem(s5, \"S5\")\nBoundary(b1, \"B1\") {\n System(i1, \"I1\")\n}\nBoundary(b2, \"B2\") {\n System(i2, \"I2\")\n}\nBoundary(b3, \"B3\") {\n System(i3, \"I3\")\n}",
      Some(704),
      36,
    ),
    content=(
      #|group global at 0,0 size 528x786 head=12 headW=0 labels=
      #|  node s1 rect at 0,0 size 216x66 textH=42 labels=51.924/18,19.568/24,0/0,0/0
      #|  node s2 rect at 252,0 size 216x66 textH=42 labels=51.924/18,19.568/24,0/0,0/0
      #|  node s3 rect at 0,154 size 216x66 textH=42 labels=51.924/18,19.568/24,0/0,0/0
      #|  node s4 rect at 252,154 size 216x66 textH=42 labels=51.924/18,19.568/24,0/0,0/0
      #|  node s5 rect at 0,308 size 216x66 textH=42 labels=51.924/18,19.568/24,0/0,0/0
      #|group b1 at 0,422 size 240x158 head=80 headW=48.399 labels=24,20,0
      #|  node i1 rect at 12,502 size 216x66 textH=42 labels=51.924/18,13.344/24,0/0,0/0
      #|group b2 at 288,422 size 240x158 head=80 headW=48.399 labels=24,20,0
      #|  node i2 rect at 300,502 size 216x66 textH=42 labels=51.924/18,13.344/24,0/0,0/0
      #|group b3 at 0,628 size 240x158 head=80 headW=48.399 labels=24,20,0
      #|  node i3 rect at 12,708 size 216x66 textH=42 labels=51.924/18,13.344/24,0/0,0/0
      #|boxes=11
    ),
  )
}

///|
test "narrows shapes and headings in little room" {
  inspect(
    laid_out(
      "C4Deployment\nDeployment_Node(outer, \"Outer node with a long heading\", \"Linux\", \"A machine\") {\n  Node(inner, \"Inner\") {\n    Container(app, \"App\", \"Go\", \"Serves requests all day long\")\n  }\n  Node_L(left, \"Left\") {\n    Container(other, \"Other\")\n  }\n}\nPerson(p, \"Somebody with a long name\")",
      Some(304),
      60,
    ),
    content=(
      #|group global at 0,0 size 264x708 head=12 headW=0 labels=
      #|  node p person at 0,0 size 216x116 textH=66 labels=50.604/18,169.808/48,0/0,0/0
      #|group outer at 0,164 size 264x544 head=124 headW=135.136 labels=48,20,20
      #|group inner at 12,288 size 240x202 head=80 headW=39.12 labels=24,20,0
      #|  node app rect at 24,368 size 216x110 textH=86 labels=63.276/18,31.104/24,24.57/20,163.293/20
      #|group left at 12,538 size 240x158 head=80 headW=36.14 labels=24,20,0
      #|  node other rect at 24,618 size 216x66 textH=42 labels=63.276/18,42.672/24,0/0,0/0
      #|boxes=6
    ),
  )
}

///|
test "puts named shapes in the top level" {
  inspect(
    laid_out(
      "C4Context\nSystem($tags=\"t\", \"Anonymous\")\nSystem(global, \"G\")\nBoundary(global, \"Everything\") {\n System(a, \"A\")\n}",
      None,
      36,
    ),
    content=(
      #|group global at 0,0 size 532x288 head=28 headW=0 labels=
      #|  node  rect at 0,0 size 216x66 textH=42 labels=51.924/18,92.448/24,0/0,0/0
      #|  node global rect at 316,0 size 216x66 textH=42 labels=51.924/18,12.448/24,0/0,0/0
      #|group global at 0,114 size 272x174 head=80 headW=82.688 labels=24,20,0
      #|  node a rect at 28,194 size 216x66 textH=42 labels=51.924/18,11.552/24,0/0,0/0
      #|boxes=4
    ),
  )
}
