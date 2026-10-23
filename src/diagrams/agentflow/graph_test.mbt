// The expectations were taken from pele's buildAgentGraph with the eight series colors pele draws with.

///|
/// The graph built from the source, with the diagnostics building it recorded.
fn graph_of(source : String) -> String {
  let db = @agentflow.AgentflowDb::new()
  @agentflow.parse_agentflow(source, db) catch {
    @errors.PeleError(failure) =>
      return "\{failure.code.to_string()} \{failure.message}"
  }
  dump_graph(db)
}

///|
test "every corpus input builds the graph pele builds" {
  inspect(mismatches(graph_cases, dump_graph), content="")
}

///|
test "building the graph again records each diagnostic once" {
  let db = @agentflow.AgentflowDb::new()
  @agentflow.parse_agentflow(
    "agentflow-beta TB\n  a((A))\n  b@{ shape: tri }", db,
  )
  ignore(@agentflow.build_agent_graph(db, 8))
  ignore(@agentflow.build_agent_graph(db, 8))
  inspect(
    db.diagnostics
    .map(d => "\{d.id} \{d.severity} \{d.node_id.unwrap_or("-")}")
    .join("\n"),
    content=(
      #|SHAPE_REMOVED error a
      #|SHAPE_UNSUPPORTED warning b
    ),
  )
}

///|
test "each kind of node takes its kind, and containers count in the order they were written" {
  inspect(
    graph_of(
      "agentflow-beta TB\n  flow one\n    flow two\n      t[\"T\"]@{ shape: tool }\n    end\n    d{D}\n  end\n  flow three@{ view: collapsed }\n    i@{ shape: input }\n  end\n  connector k\n  r@{ shape: refdoc }\n  a@{ shape: action }\n  plain",
    ),
    content=(
      #|gnode "three" label="" lt=text shape="collapsedGroup" group=false parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- color=7 kind=- metadata={"view":"collapsed","containerType":"flow"}
      #|gnode "one" label="" lt=text shape="flowGroup" group=true parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- color=7 kind=- metadata=-
      #|gnode "two" label="" lt=text shape="flowGroup" group=true parent="one" styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- color=7 kind=- metadata=-
      #|gnode "t" label="T" lt=string shape="subroutine" group=false parent="two" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="tool" metadata={"shape":"subroutine"}
      #|gnode "d" label="D" lt=text shape="diamond" group=false parent="one" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="decision" metadata=-
      #|gnode "k" label="k" lt=text shape="roundedRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="connector" metadata=-
      #|gnode "r" label="r" lt=text shape="lin-doc" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="refdoc" metadata={"shape":"lin-doc"}
      #|gnode "a" label="a" lt=text shape="hexagon" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="action" metadata={"shape":"hexagon"}
      #|gnode "plain" label="plain" lt=text shape="roundedRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata=-
    ),
  )
}

///|
test "a removed shape is an error and an unsupported one a warning, both drawn as the default" {
  inspect(
    graph_of(
      "agentflow-beta TB\n  a((A))\n  b[(B)]\n  c@{ shape: tri }\n  d@{ shape: cylinder }\n  e[[E]]\n  f{{F}}\n  g[/G/]",
    ),
    content=(
      #|gnode "a" label="A" lt=text shape="roundedRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata=-
      #|gnode "b" label="B" lt=text shape="roundedRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata=-
      #|gnode "c" label="c" lt=text shape="roundedRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata={"shape":"tri"}
      #|gnode "d" label="d" lt=text shape="roundedRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata={"shape":"cylinder"}
      #|gnode "e" label="E" lt=text shape="subroutine" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="tool" metadata=-
      #|gnode "f" label="F" lt=text shape="hexagon" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="action" metadata=-
      #|gnode "g" label="G" lt=text shape="roundedRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="input" metadata=-
      #|diagnostic SHAPE_REMOVED error "shape \"circle\" was removed in v0.8.1, using \"roundedRect\"" node="a" edge=- at=2:2-2:8
      #|diagnostic SHAPE_REMOVED error "shape \"cylinder\" was removed in v0.8.1, using \"roundedRect\"" node="b" edge=- at=3:2-3:8
      #|diagnostic SHAPE_UNSUPPORTED warning "shape \"tri\" is not supported, using \"roundedRect\"" node="c" edge=- at=4:2-4:17
      #|diagnostic SHAPE_REMOVED error "shape \"cylinder\" was removed in v0.8.1, using \"roundedRect\"" node="d" edge=- at=5:2-5:22
      #|diagnostic SHAPE_UNSUPPORTED warning "shape \"lean_right\" is not supported, using \"roundedRect\"" node="g" edge=- at=8:2-8:8
    ),
  )
}

///|
test "a collapsed flow stands for everything inside it" {
  inspect(
    graph_of(
      "agentflow-beta TB\n  flow p[\"P\"]@{ view: collapsed }\n    a --> b\n    flow q\n      c\n    end\n    b --> c\n  end\n  x --> a\n  c --> y\n  p --> x",
    ),
    content=(
      #|gnode "p" label="P" lt=string shape="collapsedGroup" group=false parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- color=7 kind=- metadata={"view":"collapsed","containerType":"flow"}
      #|gnode "x" label="x" lt=text shape="roundedRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata=-
      #|gnode "y" label="y" lt=text shape="roundedRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata=-
      #|gedge "L_x_a_0" user=false "x" "p" type="arrow_point" label="" lt=text thickness="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=- metadata=-
      #|gedge "L_c_y_0" user=false "p" "y" type="arrow_point" label="" lt=text thickness="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=- metadata=-
      #|gedge "L_p_x_0" user=false "p" "x" type="arrow_point" label="" lt=text thickness="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=- metadata=-
    ),
  )
}

///|
test "mutual containment drops the nesting that closes the loop" {
  inspect(
    graph_of(
      "agentflow-beta TB\n  flow A[\"Flow A\"]\n    a1[\"Task A1\"]\n    a1 --> B\n  end\n  flow B[\"Flow B\"]\n    b1[\"Task B1\"]\n    b1 --> A\n  end",
    ),
    content=(
      #|gnode "B" label="Flow B" lt=string shape="flowGroup" group=true parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- color=7 kind=- metadata=-
      #|gnode "A" label="Flow A" lt=string shape="flowGroup" group=true parent="B" styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- color=7 kind=- metadata=-
      #|gnode "a1" label="Task A1" lt=string shape="roundedRect" group=false parent="A" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata=-
      #|gnode "b1" label="Task B1" lt=string shape="roundedRect" group=false parent="B" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata=-
      #|gedge "L_a1_B_0" user=false "a1" "B" type="arrow_point" label="" lt=text thickness="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=- metadata=-
      #|gedge "L_b1_A_0" user=false "b1" "A" type="arrow_point" label="" lt=text thickness="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=- metadata=-
      #|diagnostic CONTAINMENT_VIOLATION warning "Container \"A\" cannot contain \"B\" because \"B\" already contains it. The nesting that would close the loop is dropped." node="B" edge=- at=4:11-4:12
    ),
  )
}

///|
test "mutual containment with a collapsed flow draws the collapsed flow at the top" {
  inspect(
    graph_of(
      "agentflow-beta TB\n  flow A[\"Flow A\"]@{ view: collapsed }\n    a1[\"Task A1\"]\n    a1 --> B\n  end\n  flow B[\"Flow B\"]\n    b1[\"Task B1\"]\n    b1 --> A\n  end",
    ),
    content=(
      #|gnode "A" label="Flow A" lt=string shape="collapsedGroup" group=false parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- color=7 kind=- metadata={"view":"collapsed","containerType":"flow"}
    ),
  )
}

///|
test "a three-flow cycle terminates" {
  inspect(
    graph_of(
      "agentflow-beta TB\n  flow A[\"A\"]@{ view: collapsed }\n    a1[\"a1\"]\n    a1 --> B\n  end\n  flow B[\"B\"]\n    b1[\"b1\"]\n    b1 --> C\n  end\n  flow C[\"C\"]\n    c1[\"c1\"]\n    c1 --> A\n  end",
    ),
    content=(
      #|gnode "A" label="A" lt=string shape="collapsedGroup" group=false parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- color=7 kind=- metadata={"view":"collapsed","containerType":"flow"}
    ),
  )
}

///|
test "classes, styles, links and tooltips reach the drawn nodes and edges" {
  inspect(
    graph_of(
      "agentflow-beta LR\n  classDef hot fill:#f00,color:#fff\n  a[\"A\"]:::hot --> b\n  style b stroke:#0f0\n  linkStyle default stroke:blue\n  linkStyle 0 interpolate step stroke:red\n  click a href \"https://example.com\" \"Go\" _blank\n  flow f\n    b\n  end\n  class f hot\n  style f fill:#eee",
    ),
    content=(
      #|gnode "f" label="" lt=text shape="flowGroup" group=true parent=- styles=["fill:#eee"] compiled=[] classes="" dir=- link=- target=- tooltip=- color=7 kind=- metadata=-
      #|gnode "a" label="A" lt=string shape="roundedRect" group=false parent=- styles=[] compiled=["fill:#f00","color:#fff","color:#fff"] classes="default hot clickable" dir=- link="https://example.com/" target="_blank" tooltip="Go" color=- kind="task" metadata=-
      #|gnode "b" label="b" lt=text shape="roundedRect" group=false parent="f" styles=["stroke:#0f0"] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata=-
      #|gedge "L_a_b_0" user=false "a" "b" type="arrow_point" label="" lt=text thickness="normal" minlen=1 arrows=none,arrow_point compiled=[] style=["stroke:blue","stroke:red","fill:none"] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve="step" metadata=-
    ),
  )
}

///|
test "an edge to a flow's own id leaves the flow out of itself" {
  inspect(
    graph_of("agentflow-beta TB\n  flow f[\"F\"]\n    a --> f\n  end"),
    content=(
      #|gnode "f" label="F" lt=string shape="flowGroup" group=true parent=- styles=[] compiled=[] classes="" dir=- link=- target=- tooltip=- color=7 kind=- metadata=-
      #|gnode "a" label="a" lt=text shape="roundedRect" group=false parent="f" styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata=-
      #|gedge "L_a_f_0" user=false "a" "f" type="arrow_point" label="" lt=text thickness="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=- metadata=-
    ),
  )
}

///|
test "edge ids, arrows and lengths reach the drawn edges" {
  inspect(
    graph_of(
      "agentflow-beta TB\n  a e1@---> b\n  a --x c\n  a -..- d\n  a -- \"label\" --> e\n  e1@{ curve: linear, animate: true }",
    ),
    content=(
      #|gnode "a" label="a" lt=text shape="roundedRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata=-
      #|gnode "b" label="b" lt=text shape="roundedRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata=-
      #|gnode "c" label="c" lt=text shape="roundedRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata=-
      #|gnode "d" label="d" lt=text shape="roundedRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata=-
      #|gnode "e" label="e" lt=text shape="roundedRect" group=false parent=- styles=[] compiled=[] classes="default " dir=- link=- target=- tooltip=- color=- kind="task" metadata=-
      #|gedge "e1" user=true "a" "b" type="arrow_point" label="" lt=text thickness="normal" minlen=2 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=true animation=- curve="linear" metadata={"curve":"linear","animate":true}
      #|gedge "L_a_c_0" user=false "a" "c" type="arrow_cross" label="" lt=text thickness="normal" minlen=1 arrows=none,arrow_cross compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=- metadata=-
      #|gedge "L_a_d_0" user=false "a" "d" type="arrow_open" label="" lt=text thickness="dotted" minlen=2 arrows=none,none compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=- metadata=-
      #|gedge "L_a_e_0" user=false "a" "e" type="arrow_point" label="label" lt=string thickness="normal" minlen=1 arrows=none,arrow_point compiled=[] style=[] classes="edge-thickness-normal edge-pattern-solid flowchart-link" animate=- animation=- curve=- metadata=-
    ),
  )
}

///|
test "containers wrap around the palette slots above the kinds, whatever the palette length" {
  let source = "agentflow-beta TB\n  flow g0\n    n0\n  end\n  flow g1\n    n1\n  end\n  flow g2\n    n2\n  end\n  flow g3\n    n3\n  end\n  flow g4\n    n4\n  end\n  flow g5\n    n5\n  end\n  flow g6\n    n6\n  end\n"
  let slots = [12, 3, 0].map(palette => {
    let db = @agentflow.AgentflowDb::new()
    @agentflow.parse_agentflow(source, db)
    @agentflow.build_agent_graph(db, palette).nodes
    .filter(n => n.is_group)
    .map(n => "\{n.id}:\{n.color_index.unwrap_or(-1)}")
    .join(" ")
  })
  inspect(
    slots.join("\n"),
    content=(
      #|g6:8 g5:7 g4:11 g3:10 g2:9 g1:8 g0:7
      #|g6:1 g5:1 g4:1 g3:1 g2:1 g1:1 g0:1
      #|g6:7 g5:7 g4:7 g3:7 g2:7 g1:7 g0:7
    ),
  )
}
