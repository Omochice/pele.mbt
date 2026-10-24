///|
fn model(source : String) -> String {
  let db = @flowchart.FlowDb::new()
  @flowchart.parse_flowchart(source, db) catch {
    @errors.PeleError(failure) =>
      return "error \{failure.code.to_string()} \{failure.message}"
  }
  dump(db)
}

///|
test "nodes and links are read into the model as pele does" {
  inspect(
    model("graph TD;A-->B;"),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="B" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "A" "B" id="L_A_B_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("graph TD\nA-->B\nA-->B\nB-->A"),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="B" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "A" "B" id="L_A_B_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_2" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "B" "A" id="L_B_A_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("graph TD;A & B --> C & D"),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="B" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "C" text="C" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "D" text="D" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "A" "C" id="L_A_C_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "D" id="L_A_D_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "B" "C" id="L_B_C_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "B" "D" id="L_B_D_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("graph TD\nA --> B --> C\n"),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="B" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "C" text="C" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "A" "B" id="L_A_B_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "B" "C" id="L_B_C_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}

///|
test "link types are read into the model as pele does" {
  inspect(
    model(
      "graph TD;A--xB;A--oB;A<-->B;Ax--xB;Ao--oB;A---B;A-.-B;A-.->B;A==>B;A===B;A~~~B;A----->B;A-...->B;A-------------->B",
    ),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="B" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "Ax" text="Ax" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "Ao" text="Ao" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "A" "B" id="L_A_B_0" user=false type="arrow_cross" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_2" user=false type="arrow_circle" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_3" user=false type="double_arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "Ax" "B" id="L_Ax_B_0" user=false type="arrow_cross" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "Ao" "B" id="L_Ao_B_0" user=false type="arrow_circle" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_4" user=false type="arrow_open" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_5" user=false type="arrow_open" text="" lt=text stroke="dotted" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_6" user=false type="arrow_point" text="" lt=text stroke="dotted" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_7" user=false type="arrow_point" text="" lt=text stroke="thick" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_8" user=false type="arrow_open" text="" lt=text stroke="thick" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_9" user=false type="arrow_open" text="" lt=text stroke="invisible" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_10" user=false type="arrow_point" text="" lt=text stroke="normal" length=4 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_11" user=false type="arrow_point" text="" lt=text stroke="dotted" length=3 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_12" user=false type="arrow_point" text="" lt=text stroke="normal" length=10 style=- classes=[] interpolate=- animate=- animation=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model(
      "graph TD;A-- text -->B;A-. text .->B;A== text ==>B;A<-- text -->B;A--x|t|B;A x-- text -->B",
    ),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="B" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "A" "B" id="L_A_B_0" user=false type="arrow_point" text="text" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_2" user=false type="arrow_point" text="text" lt=text stroke="dotted" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_3" user=false type="arrow_point" text="text" lt=text stroke="thick" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_4" user=false type="double_arrow_point" text="text" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_5" user=false type="arrow_cross" text="t" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_6" user=false type="INVALID" text="text" lt=text stroke="INVALID" length=- style=- classes=[] interpolate=- animate=- animation=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}

///|
test "node shapes are read into the model as pele does" {
  inspect(
    model(
      "graph TD\nA[a]\nB(b)\nC((c))\nD>d]\nE{e}\nF{{f}}\nG[/g/]\nH[\\h\\]\nI[/i\\]\nJ[\\j/]\nK[(k)]\nL[[l]]\nM([m])\nN(((n)))\nO(-o-)\nP[|borders:lt|p]\nQ",
    ),
    content=(
      #|dir "TB"
      #|node "A" text="a" lt=text type="square" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="b" lt=text type="round" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "C" text="c" lt=text type="circle" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "D" text="d" lt=text type="odd" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "E" text="e" lt=text type="diamond" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "F" text="f" lt=text type="hexagon" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "G" text="g" lt=text type="lean_right" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "H" text="h" lt=text type="lean_left" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "I" text="i" lt=text type="trapezoid" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "J" text="j" lt=text type="inv_trapezoid" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "K" text="k" lt=text type="cylinder" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "L" text="l" lt=text type="subroutine" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "M" text="m" lt=text type="stadium" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "N" text="n" lt=text type="doublecircle" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "O" text="o" lt=text type="ellipse" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "P" text="p" lt=text type="rect" styles=[] classes=[] dir=- props={"borders":"lt"} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "Q" text="Q" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}

///|
test "labels are read into the model as pele does" {
  inspect(
    model(
      "graph TD\nA[\"a b\"]-->B[\"`**md**`\"]\nC[  spaced  ]\nD[\"  quoted  \"]\nA-->|\"edge str\"|B\nA-->|\"`md`\"|B\nF[\"a\"]",
    ),
    content=(
      #|dir "TB"
      #|node "A" text="a b" lt=string type="square" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="**md**" lt=markdown type="square" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "C" text="spaced" lt=text type="square" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "D" text="quoted" lt=string type="square" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "F" text="a" lt=string type="square" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "A" "B" id="L_A_B_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_2" user=false type="arrow_point" text="edge str" lt=string stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "B" id="L_A_B_3" user=false type="arrow_point" text="md" lt=markdown stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model(
      "graph TD\nA[Hello &amp; bye]\nB(\u{65e5}\u{672c}\u{8a9e})\nC-->|\u{65e5}\u{672c}|D\n\u{e4} --> \u{f6}",
    ),
    content=(
      #|dir "TB"
      #|node "A" text="Hello &amp; bye" lt=text type="square" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="日本語" lt=text type="round" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "C" text="C" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "D" text="D" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "ä" text="ä" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "ö" text="ö" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "C" "D" id="L_C_D_0" user=false type="arrow_point" text="日本" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "ä" "ö" id="L_ä_ö_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}

///|
test "subgraphs are read into the model as pele does" {
  inspect(
    model("graph TB\nsubgraph One\na1-->a2\nend"),
    content=(
      #|dir "TB"
      #|node "a1" text="a1" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "a2" text="a2" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "a1" "a2" id="L_a1_a2_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|subgraph "One" title="One" lt=text dir=- nodes=["a2","a1"] classes=[] metadata=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("graph TB\nsubgraph \"Some Title\"\na1-->a2\nend"),
    content=(
      #|dir "TB"
      #|node "a1" text="a1" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "a2" text="a2" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "a1" "a2" id="L_a1_a2_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|subgraph "subGraph0" title="Some Title" lt=text dir=- nodes=["a2","a1"] classes=[] metadata=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("graph TB\nsubgraph some-id[Some title]\na1-->a2\nend"),
    content=(
      #|dir "TB"
      #|node "a1" text="a1" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "a2" text="a2" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "a1" "a2" id="L_a1_a2_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|subgraph "some-id" title="Some title" lt=text dir=- nodes=["a2","a1"] classes=[] metadata=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("graph TB\nsubgraph a b c\na1\nend\nsubgraph\nend"),
    content=(
      #|dir "TB"
      #|node "a1" text="a1" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|subgraph "subGraph0" title="a b c" lt=text dir=- nodes=["a1"] classes=[] metadata=-
      #|subgraph "subGraph1" title="" lt=markdown dir=- nodes=[] classes=[] metadata=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model(
      "graph TB\nsubgraph outer\nsubgraph inner\ndirection LR\na-->b\nend\nc\nend\nouter-->inner",
    ),
    content=(
      #|dir "TB"
      #|node "a" text="a" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "b" text="b" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "c" text="c" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "outer" text="outer" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "inner" text="inner" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "a" "b" id="L_a_b_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "outer" "inner" id="L_outer_inner_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|subgraph "inner" title="inner" lt=text dir="LR" nodes=["b","a"] classes=[] metadata=-
      #|subgraph "outer" title="outer" lt=text dir=- nodes=["inner","c"] classes=[] metadata=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("graph TB\nsubgraph S;a;b;end"),
    content=(
      #|dir "TB"
      #|node "a" text="a" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "b" text="b" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|subgraph "S" title="S" lt=text dir=- nodes=["a","b"] classes=[] metadata=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model(
      "flowchart LR\nsubgraph A\nend\nsubgraph A\nB\nend\nsubgraph C[\"`md`\"]\nC\nend",
    ),
    content=(
      #|dir "LR"
      #|node "B" text="B" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "C" text="C" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|subgraph "A" title="A" lt=text dir=- nodes=["B"] classes=[] metadata=-
      #|subgraph "C" title="md" lt=markdown dir=- nodes=[] classes=[] metadata=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("graph TD\nsubgraph S\naccTitle: t\nA & B --> C\nend"),
    content=(
      #|dir "TB"
      #|accTitle "t"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="B" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "C" text="C" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "A" "C" id="L_A_C_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "B" "C" id="L_B_C_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|subgraph "S" title="S" lt=text dir=- nodes=["t","C","A","B"] classes=[] metadata=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}

///|
test "styles and classes are read into the model as pele does" {
  inspect(
    model(
      "graph TD\nclassDef exClass background:#bbb,border:1px solid red;\nclassDef a,b fill:#f9f,color:red,stroke\\,x:1\nclass A,B exClass\nstyle A fill:red,stroke:blue\nC:::a-->D:::b\nstyle Z color:blue",
    ),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type=- styles=["fill:red","stroke:blue"] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "C" text="C" lt=text type=- styles=[] classes=["a"] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "D" text="D" lt=text type=- styles=[] classes=["b"] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "Z" text="Z" lt=text type=- styles=["color:blue"] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "C" "D" id="L_C_D_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|class "exClass" styles=["background:#bbb","border:1px solid red"] text=[]
      #|class "a" styles=["fill:#f9f","color:red","stroke,x:1"] text=["color:red"]
      #|class "b" styles=["fill:#f9f","color:red","stroke,x:1"] text=["color:red"]
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model(
      "graph TD\nA-->B\nB-->C\nlinkStyle 0 stroke:red\nlinkStyle 0,1 interpolate basis stroke:blue,fill:none\nlinkStyle default stroke:green\nlinkStyle default interpolate linear\nC-->D",
    ),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="B" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "C" text="C" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "D" text="D" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "A" "B" id="L_A_B_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=["stroke:blue","fill:none"] classes=[] interpolate="basis" animate=- animation=-
      #|edge "B" "C" id="L_B_C_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=["stroke:blue","fill:none"] classes=[] interpolate="basis" animate=- animation=-
      #|edge "C" "D" id="L_C_D_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate="linear" animate=- animation=-
      #|defaultStyle=["stroke:green"] defaultInterpolate="linear"
    ),
  )
  inspect(
    model(
      "graph TD\nA-->B\nlinkStyle 0 interpolate step\nclassDef x fill:#f00\nclass L_A_B_0 x",
    ),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="B" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "A" "B" id="L_A_B_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=["x"] interpolate="step" animate=- animation=-
      #|class "x" styles=["fill:#f00"] text=[]
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}

///|
test "click statements are read into the model as pele does" {
  inspect(
    model(
      "graph TD\nA-->B\nclick A callback\nclick B call cb()\nclick A href \"x.html\" \"tip\" _blank\nclick B \"https://www.github.com\" _self\nclick C \"javascript:alert(1)\" \"t\"",
    ),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type=- styles=[] classes=["clickable","clickable"] dir=- props={} link="x.html" target="_blank" icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="B" lt=text type=- styles=[] classes=["clickable","clickable"] dir=- props={} link="https://www.github.com/" target="_self" icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "A" "B" id="L_A_B_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|tooltip "A" "tip"
      #|tooltip "C" "t"
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model(
      "graph TD\nA\nclick A call cb(\"x\", 1) \"tooltip\"\nclick A callback \"tip2\"\nclick A \"  \" \"t\"",
    ),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type=- styles=[] classes=["clickable","clickable","clickable"] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|tooltip "A" "t"
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}

///|
test "accessibility statements are read into the model as pele does" {
  inspect(
    model("graph TD\naccTitle:   My title  \naccDescr: d\nA"),
    content=(
      #|dir "TB"
      #|accTitle "My title"
      #|accDescr "d"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("graph TD\naccDescr {\n  line one\n    line two\n}\nA"),
    content=(
      #|dir "TB"
      #|accDescr "line one\nline two"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}

///|
test "node data are read into the model as pele does" {
  inspect(
    model(
      "flowchart TD\nA@{ shape: rounded, label: \"x\" }\nB@{ icon: \"fa:user\", form: square, pos: t, w: 60, h: \"0x20\" }\nC@{ img: \"https://x/i.png\", constraint: on, label: \"\" }\nD@{ shape: diamond }\nA e1@--> B\ne1@{ animate: true, animation: fast, curve: linear }\nsubgraph S\nA\nend\nS@{ view: collapsed }",
    ),
    content=(
      #|dir "TB"
      #|node "A" text="x" lt=markdown type="rounded" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon="fa:user" form="square" pos="t" img=- constraint=- w=60 h=32
      #|node "C" text="" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img="https://x/i.png" constraint="on" w=- h=-
      #|node "D" text="D" lt=text type="diamond" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "S" text="S" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "A" "B" id="e1" user=true type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate="linear" animate=true animation="fast"
      #|subgraph "S" title="S" lt=text dir=- nodes=["A"] classes=[] metadata={"view":"collapsed"}
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model(
      "flowchart TD\nA@{ shape: rect } & B@{ shape: circle } --> C@{ label: \"multi\n  line\" }",
    ),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type="rect" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="B" lt=text type="circle" styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "C" text="multi<br/>line" lt=markdown type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "A" "C" id="L_A_C_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "B" "C" id="L_B_C_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("flowchart TD\nA@{ shape: Rect }"),
    content=(
      #|error semantic No such shape: Rect. Shape names should be lowercase.
    ),
  )
  inspect(
    model("flowchart TD\nA@{ shape: nope }"),
    content=(
      #|error semantic No such shape: nope.
    ),
  )
  inspect(
    model("flowchart TD\nA@{ shape: lean_right }"),
    content=(
      #|error semantic No such shape: lean_right. Shape names should be lowercase.
    ),
  )
  inspect(
    model("flowchart TD\nA@{ label: [unclosed }"),
    content=(
      #|error syntax Metadata of "A" is not valid YAML. YAML: unexpected end of the stream within a flow collection
    ),
  )
  inspect(
    model(
      "flowchart TD\nA@{ label: \"a\", labelType: string }\nB@{ label: 5, labelType: text }\nC@{ label: true }",
    ),
    content=(
      #|dir "TB"
      #|node "A" text="a" lt=string type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="5" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "C" text="true" lt=markdown type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}

///|
test "directions are read into the model as pele does" {
  inspect(
    model("graph >\nA"),
    content=(
      #|dir "LR"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("graph <\nA"),
    content=(
      #|dir "RL"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("graph ^\nA"),
    content=(
      #|dir "BT"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("graph v\nA"),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("graph TD\nA"),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("flowchart\nA"),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("graph RL;A"),
    content=(
      #|dir "RL"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    model("graph TB\nsubgraph s\ndirection RL\nend\ndirection BT"),
    content=(
      #|dir "TB"
      #|subgraph "s" title="s" lt=text dir="RL" nodes=[] classes=[] metadata=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}

///|
test "syntax errors are read into the model as pele does" {
  inspect(
    model("graph TD\nA-->B\nB --> [oops]"),
    content=(
      #|error syntax Parse error on line 3:
      #|B --> [oops]
      #|------^
      #|Expecting 'NODE_STRING', got 'SQS'
    ),
  )
  inspect(
    model("graph TD\nA[x"),
    content=(
      #|error syntax Parse error on line 2:
      #|A[x
      #|---^
      #|Expecting 'SQE', 'UNICODE_TEXT', 'TEXT', 'TAGSTART', got '$end'
    ),
  )
  inspect(
    model("graph TD\nsubgraph s\nA"),
    content=(
      #|error syntax Parse error on line 3:
      #|A
      #|-^
      #|Expecting 'end', got '$end'
    ),
  )
  inspect(
    model("graph TD\nA(-x)]"),
    content=(
      #|error syntax Lexical error on line 2. Unrecognized text.
      #|A(-x)]
      #|----^
    ),
  )
  inspect(
    model("graph\nA -->"),
    content=(
      #|error syntax Parse error on line 2:
      #|A -->
      #|-----^
      #|Expecting 'NODE_STRING', got 'EOF'
    ),
  )
  inspect(
    model("graph TD\nlinkStyle 1 stroke-width:1px;"),
    content=(
      #|error semantic The index 1 for linkStyle is out of bounds. Valid indices for linkStyle are between 0 and -1. (Help: Ensure that the index is within the range of existing edges.)
    ),
  )
  inspect(
    model("graph TD\nA-->B\nlinkStyle 1 stroke-width:1px;"),
    content=(
      #|error semantic The index 1 for linkStyle is out of bounds. Valid indices for linkStyle are between 0 and 0. (Help: Ensure that the index is within the range of existing edges.)
    ),
  )
  inspect(
    model("graph TD\nA & B@{ shape: rect }C"),
    content=(
      #|error syntax Parse error on line 2:
      #|A & B@{ shape: rect }C
      #|---------------------^
      #|Expecting 'SEMI', 'NEWLINE', 'EOF', got 'NODE_STRING'
    ),
  )
}
