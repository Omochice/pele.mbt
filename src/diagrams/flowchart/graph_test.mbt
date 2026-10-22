///|
fn gdump(graph : @flowchart.FlowGraph) -> String {
  let out = []
  for n in graph.nodes {
    let color = num(n.color_index.map(c => c.to_double()))
    out.push(
      "gnode \{q(n.id)} label=\{opt(n.label)} lt=\{n.label_type.to_string()} shape=\{q(n.shape)} group=\{n.is_group} parent=\{opt(n.parent_id)} styles=\{texts(Some(n.css_styles))} compiled=\{texts(Some(n.css_compiled_styles))} classes=\{q(n.css_classes)} dir=\{opt(n.dir)} link=\{opt(n.link)} target=\{opt(n.link_target)} tooltip=\{opt(n.tooltip)} icon=\{opt(n.icon)} pos=\{opt(n.pos)} img=\{opt(n.img)} w=\{num(n.asset_width)} h=\{num(n.asset_height)} constraint=\{opt(n.constraint)} color=\{color} metadata=\{metadata(n.metadata)}",
    )
  }
  for e in graph.edges {
    let minlen = num(e.minlen.map(l => l.to_double()))
    out.push(
      "gedge \{q(e.id)} user=\{e.is_user_defined_id} \{q(e.start)} \{q(e.end)} type=\{q(e.kind)} label=\{q(e.label)} lt=\{e.label_type.to_string()} thickness=\{opt(e.thickness)} pattern=\{opt(e.pattern)} minlen=\{minlen} arrows=\{e.arrow_type_start},\{e.arrow_type_end} compiled=\{texts(Some(e.css_compiled_styles))} style=\{texts(Some(e.style))} classes=\{q(e.classes)} animate=\{json(e.animate)} animation=\{json(e.animation)} curve=\{json(e.curve)}",
    )
  }
  out.join("\n")
}

///|
fn graph_of(source : String, curve? : String) -> String raise @errors.PeleError {
  let db = @flowchart.FlowDb::new()
  @flowchart.parse_flowchart(source, db)
  gdump(@flowchart.build_flow_graph(db, default_curve?=curve))
}

///|
test "subgraphs become group nodes before the vertices" {
  inspect(
    graph_of("flowchart LR\nA-->B\nC-->A\nsubgraph sub1 [My Group]\nA\nB\nend"),
    content=(
      #|gnode "sub1" label="My Group" lt=text shape="rect" group=true parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=0 metadata=-
      #|gnode "A" label="A" lt=text shape="squareRect" group=false parent="sub1" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "B" label="B" lt=text shape="squareRect" group=false parent="sub1" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "C" label="C" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gedge "L_A_B_0" user=false "A" "B" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
      #|gedge "L_C_A_0" user=false "C" "A" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
    ),
  )
  inspect(
    graph_of(
      "flowchart LR\nsubgraph sub1 [My Group]\nA\nB\nend\nsub1@{ algorithm: elk.box }",
    ),
    content=(
      #|gnode "sub1" label="My Group" lt=text shape="rect" group=true parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=0 metadata={"algorithm":"elk.box"}
      #|gnode "A" label="A" lt=text shape="squareRect" group=false parent="sub1" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "B" label="B" lt=text shape="squareRect" group=false parent="sub1" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
    ),
  )
  inspect(
    graph_of("flowchart LR\nsubgraph S\n  x\nend\nsubgraph S\n  y\nend"),
    content=(
      #|gnode "S" label="S" lt=text shape="rect" group=true parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=0 metadata=-
      #|gnode "x" label="x" lt=text shape="squareRect" group=false parent="S" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "y" label="y" lt=text shape="squareRect" group=false parent="S" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
    ),
  )
  inspect(
    graph_of("flowchart LR\nsubgraph S\n  subgraph S\n    x\n  end\n  y\nend"),
    content=(
      #|gnode "S" label="S" lt=text shape="rect" group=true parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=0 metadata=-
      #|gnode "x" label="x" lt=text shape="squareRect" group=false parent="S" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "y" label="y" lt=text shape="squareRect" group=false parent="S" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
    ),
  )
  inspect(
    graph_of(
      "flowchart LR\nsubgraph S\nend\nsubgraph S\n  subgraph T\n    y\n  end\nend",
    ),
    content=(
      #|gnode "T" label="T" lt=text shape="rect" group=true parent="S" styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=1 metadata=-
      #|gnode "S" label="S" lt=text shape="rect" group=true parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=0 metadata=-
      #|gnode "y" label="y" lt=text shape="squareRect" group=false parent="T" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
    ),
  )
  inspect(
    graph_of(
      "flowchart TD\nsubgraph S\nA\nend\nS[Label]\nS:::x\nstyle S fill:yellow",
    ),
    content=(
      #|gnode "S" label="S" lt=text shape="rect" group=true parent=- styles=["fill:yellow"] compiled=[] classes="x" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=0 metadata=-
      #|gnode "A" label="A" lt=text shape="squareRect" group=false parent="S" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
    ),
  )
  inspect(
    graph_of("graph TB\nsubgraph S;end\nS-->A\nsubgraph E\nend"),
    content=(
      #|gnode "E" label="E" lt=text shape="rect" group=true parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=1 metadata=-
      #|gnode "S" label="S" lt=text shape="rect" group=true parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=0 metadata=-
      #|gnode "A" label="A" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gedge "L_S_A_0" user=false "S" "A" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
    ),
  )
}

///|
test "collapsed subgraphs hide their members and take their edges" {
  inspect(
    graph_of(
      "flowchart LR\nA-->B\nC-->A\nsubgraph sub1 [My Group]\nA\nB\nend\nsub1@{ view: collapsed }",
    ),
    content=(
      #|gnode "sub1" label="My Group" lt=text shape="collapsedGroup" group=false parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=0 metadata=-
      #|gnode "C" label="C" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gedge "L_C_A_0" user=false "C" "sub1" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
    ),
  )
  inspect(
    graph_of(
      "flowchart LR\nC-->A\nsubgraph outer [Outer]\nsubgraph inner [Inner]\nA\nB\nend\nend\ninner@{ view: collapsed }\nouter@{ view: collapsed }",
    ),
    content=(
      #|gnode "outer" label="Outer" lt=text shape="collapsedGroup" group=false parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=0 metadata=-
      #|gnode "C" label="C" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gedge "L_C_A_0" user=false "C" "outer" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
    ),
  )
  inspect(
    graph_of(
      "flowchart LR\nsubgraph S\n  x\nend\nS@{ view: collapsed }\nsubgraph S\n  y\nend\nx --> y\ny --> z",
    ),
    content=(
      #|gnode "S" label="S" lt=text shape="collapsedGroup" group=false parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=0 metadata=-
      #|gnode "z" label="z" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gedge "L_y_z_0" user=false "S" "z" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
    ),
  )
  inspect(
    graph_of(
      "flowchart LR\nsubgraph outer\nsubgraph inner\nA\nend\nB\nend\ninner@{ view: collapsed }\nA-->B\nB-->A",
    ),
    content=(
      #|gnode "outer" label="outer" lt=text shape="rect" group=true parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=0 metadata=-
      #|gnode "inner" label="inner" lt=text shape="collapsedGroup" group=false parent="outer" styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=1 metadata=-
      #|gnode "B" label="B" lt=text shape="squareRect" group=false parent="outer" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gedge "L_A_B_0" user=false "inner" "B" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
      #|gedge "L_B_A_0" user=false "B" "inner" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
    ),
  )
}

///|
test "subgraphs are numbered for colours in source order" {
  inspect(
    graph_of(
      "flowchart LR\nsubgraph Outer\nsubgraph InnerOne\nA\nend\nsubgraph InnerTwo\nB\nend\nend\nsubgraph Sibling\nD\nend",
    ),
    content=(
      #|gnode "Sibling" label="Sibling" lt=text shape="rect" group=true parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=3 metadata=-
      #|gnode "Outer" label="Outer" lt=text shape="rect" group=true parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=0 metadata=-
      #|gnode "InnerTwo" label="InnerTwo" lt=text shape="rect" group=true parent="Outer" styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=2 metadata=-
      #|gnode "InnerOne" label="InnerOne" lt=text shape="rect" group=true parent="Outer" styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=1 metadata=-
      #|gnode "A" label="A" lt=text shape="squareRect" group=false parent="InnerOne" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "B" label="B" lt=text shape="squareRect" group=false parent="InnerTwo" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "D" label="D" lt=text shape="squareRect" group=false parent="Sibling" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
    ),
  )
  inspect(
    graph_of(
      "flowchart LR\nsubgraph first\nA\nend\nsubgraph second\nB\nend\nsubgraph third\nC\nend\nsecond@{ view: collapsed }",
    ),
    content=(
      #|gnode "third" label="third" lt=text shape="rect" group=true parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=2 metadata=-
      #|gnode "second" label="second" lt=text shape="collapsedGroup" group=false parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=1 metadata=-
      #|gnode "first" label="first" lt=text shape="rect" group=true parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=0 metadata=-
      #|gnode "A" label="A" lt=text shape="squareRect" group=false parent="first" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "C" label="C" lt=text shape="squareRect" group=false parent="third" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
    ),
  )
}

///|
test "edge curves come from the edge, linkStyle default, then the config" {
  inspect(
    graph_of(
      "flowchart LR\nA-->B\nA e2@-->C\nB e3@-->D\nC-->D\nlinkStyle default interpolate stepBefore\nlinkStyle 0 interpolate basis\ne2@{ curve: monotoneX }\ne3@{ curve: catmullRom }",
    ),
    content=(
      #|gnode "A" label="A" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "B" label="B" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "C" label="C" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "D" label="D" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gedge "L_A_B_0" user=false "A" "B" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve="basis"
      #|gedge "e2" user=true "A" "C" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve="monotoneX"
      #|gedge "e3" user=true "B" "D" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve="catmullRom"
      #|gedge "L_C_D_0" user=false "C" "D" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve="stepBefore"
    ),
  )
  inspect(
    graph_of(
      "flowchart TD\nA-->B\nlinkStyle 0 interpolate basis\nC-->D\nE e1@-->F\ne1@{ curve: 0, animate: true, animation: slow }",
      curve="linear",
    ),
    content=(
      #|gnode "A" label="A" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "B" label="B" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "C" label="C" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "D" label="D" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "E" label="E" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "F" label="F" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gedge "L_A_B_0" user=false "A" "B" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve="basis"
      #|gedge "L_C_D_0" user=false "C" "D" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve="linear"
      #|gedge "e1" user=true "E" "F" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=true animation="slow" curve="linear"
    ),
  )
}

///|
test "classes and styles are compiled onto nodes and edges" {
  inspect(
    graph_of(
      "flowchart TD\nclassDef default fill:#eee\nclassDef node stroke:#000\nclassDef hot fill:#f00,color:white\nA:::hot-->B\nlinkStyle default stroke:red\nlinkStyle 0 stroke:blue\nclass L_A_B_0 hot\nsubgraph S\nA\nend\nclass S hot\nstyle B fill:yellow",
    ),
    content=(
      #|gnode "S" label="S" lt=text shape="rect" group=true parent=- styles=[] compiled=["fill:#f00","color:white","color:white"] classes="hot" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=0 metadata=-
      #|gnode "A" label="A" lt=text shape="squareRect" group=false parent="S" styles=[] compiled=["fill:#eee","stroke:#000","fill:#f00","color:white","color:white"] classes="default hot" dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "B" label="B" lt=text shape="squareRect" group=false parent=- styles=["fill:yellow"] compiled=["fill:#eee","stroke:#000"] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gedge "L_A_B_0" user=false "A" "B" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=["fill:#f00","color:white","color:white"] style=["stroke:red","stroke:blue","fill:none"] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
    ),
  )
}

///|
test "shapes and assets are resolved" {
  inspect(
    graph_of(
      "flowchart TD\nA[a]\nB(b)\nC{c}\nD@{ shape: cyl }\nE@{ icon: \"fa:x\", form: circle }\nF@{ img: \"https://x/i.png\", w: 40, h: 30, pos: b, constraint: on }\nG@{ icon: \"fa:y\" }\nH@{ icon: \"fa:z\", form: rounded }\nI@{ icon: \"fa:z\", form: square }\nJ((j))\nK\nL{{l}}\nM[/m/]\nclick A \"https://x\" \"tip\" _blank",
    ),
    content=(
      #|gnode "A" label="a" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default clickable" dir=- link="https://x/" target="_blank" tooltip="tip" icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "B" label="b" lt=text shape="roundedRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "C" label="c" lt=text shape="diamond" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "D" label="D" lt=text shape="cyl" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "E" label="" lt=text shape="iconCircle" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon="fa:x" pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "F" label="" lt=text shape="imageSquare" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos="b" img="https://x/i.png" w=40 h=30 constraint="on" color=- metadata=-
      #|gnode "G" label="" lt=text shape="icon" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon="fa:y" pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "H" label="" lt=text shape="iconRounded" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon="fa:z" pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "I" label="" lt=text shape="iconSquare" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon="fa:z" pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "J" label="j" lt=text shape="circle" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "K" label="K" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "L" label="l" lt=text shape="hexagon" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "M" label="m" lt=text shape="lean_right" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
    ),
  )
}

///|
test "arrow types and strokes are resolved" {
  inspect(
    graph_of(
      "flowchart TD\nA-->B\nA---B\nA<-->B\nA--xB\nAx--xB\nAo--oB\nA--oB\nA~~~B\nA-.->B\nA==>B\nA x-- t -->B\nA-- \"q\" -->B\nA ~~~~~~ B",
    ),
    content=(
      #|gnode "A" label="A" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "B" label="B" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "Ax" label="Ax" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gnode "Ao" label="Ao" lt=text shape="squareRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- icon=- pos=- img=- w=- h=- constraint=- color=- metadata=-
      #|gedge "L_A_B_0" user=false "A" "B" type="arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
      #|gedge "L_A_B_2" user=false "A" "B" type="arrow_open" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,none compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
      #|gedge "L_A_B_3" user=false "A" "B" type="double_arrow_point" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=arrow_point,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
      #|gedge "L_A_B_4" user=false "A" "B" type="arrow_cross" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_cross compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
      #|gedge "L_Ax_B_0" user=false "Ax" "B" type="arrow_cross" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_cross compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
      #|gedge "L_Ao_B_0" user=false "Ao" "B" type="arrow_circle" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_circle compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
      #|gedge "L_A_B_5" user=false "A" "B" type="arrow_circle" label="" lt=text thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_circle compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
      #|gedge "L_A_B_6" user=false "A" "B" type="arrow_open" label="" lt=text thickness="invisible" pattern="invisible" minlen=1 arrows=none,none compiled=[] style=[] classes="" animate=- animation=- curve=-
      #|gedge "L_A_B_7" user=false "A" "B" type="arrow_point" label="" lt=text thickness="dotted" pattern="dotted" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
      #|gedge "L_A_B_8" user=false "A" "B" type="arrow_point" label="" lt=text thickness="thick" pattern="thick" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
      #|gedge "L_A_B_9" user=false "A" "B" type="INVALID" label="t" lt=text thickness="INVALID" pattern="INVALID" minlen=- arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
      #|gedge "L_A_B_10" user=false "A" "B" type="arrow_point" label="q" lt=string thickness="normal" pattern="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=-
      #|gedge "L_A_B_11" user=false "A" "B" type="arrow_open" label="" lt=text thickness="invisible" pattern="invisible" minlen=4 arrows=none,none compiled=[] style=[] classes="" animate=- animation=- curve=-
    ),
  )
}
