// The expectations were taken from pele's agentflow model.

///|
/// The model read from the source, or the error with its code and position.
fn model_of(source : String, line_offset~ : Int32 = 0) -> String {
  let db = @agentflow.AgentflowDb::new(line_offset~)
  @agentflow.parse_agentflow(source, db) catch {
    @errors.PeleError(failure) =>
      return "\{failure.code.to_string()} \{failure.line}:\{failure.column} \{failure.message}"
  }
  dump_model(db)
}

///|
test "every corpus input reads into the model pele reads, or fails as pele fails" {
  inspect(mismatches(model_cases, dump_model), content="")
}

///|
test "metadata sets a node's shape and label and keeps the rest" {
  inspect(
    model_of(
      "agentflow-beta TB\n  a[\"A\"]@{ shape: tool, label: \"Fetch\", description: \"calls the API\" }\n  b@{ shape: decision }",
    ),
    content=(
      #|dir "TB"
      #|node "a" text="Fetch" lt=markdown type="subroutine" styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata={"shape":"subroutine","label":"Fetch","description":"calls the API"}
      #|node "b" text="b" lt=text type="diamond" styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata={"shape":"diamond"}
      #|defaultStyle=- defaultInterpolate=-
      #|mapping "a" vertex 2:2-2:69
      #|mapping "b" attachment 3:2-3:22
      #|semantic dir="TB"
      #|sv "a" label="Fetch" shape="subroutine" kind="tool" metadata={"label":"Fetch","description":"calls the API"}
      #|sv "b" label="b" shape="diamond" kind="decision" metadata=-
    ),
  )
}

///|
test "a metadata block may end its lines with commas" {
  inspect(
    model_of(
      "agentflow-beta TB\n  a@{\n    description: \"one, two\",\n    retries: 3,\n  }",
    ),
    content=(
      #|dir "TB"
      #|node "a" text="a" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata={"description":"one, two","retries":3}
      #|defaultStyle=- defaultInterpolate=-
      #|mapping "a" attachment 2:2-5:2
      #|semantic dir="TB"
      #|sv "a" label="a" shape=- kind="task" metadata={"description":"one, two","retries":3}
    ),
  )
}

///|
test "metadata never keeps a prototype key" {
  inspect(
    model_of(
      "agentflow-beta TB\n  a@{\n    __proto__: 1\n    constructor: x\n    prototype: y\n    nested:\n      __proto__: 1\n      ok: 2\n    list:\n      - prototype: 3\n        keep: 4\n  }",
    ),
    content=(
      #|dir "TB"
      #|node "a" text="a" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata={"nested":{"ok":2},"list":[{"keep":4}]}
      #|defaultStyle=- defaultInterpolate=-
      #|mapping "a" attachment 2:2-12:2
      #|semantic dir="TB"
      #|sv "a" label="a" shape=- kind="task" metadata={"nested":{"ok":2},"list":[{"keep":4}]}
    ),
  )
}

///|
test "metadata on a flow, a connector or an edge id goes to that element" {
  inspect(
    model_of(
      "agentflow-beta TB\n  flow f[\"F\"]@{ view: collapsed }\n    a e1@--> b\n  end\n  connector k[\"K\"]@{ protocol: mcp }\n  e1@{ curve: basis, animate: true, owner: me }\n  k@{ more: 1 }",
    ),
    content=(
      #|dir "TB"
      #|node "a" text="a" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata=-
      #|node "b" text="b" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata=-
      #|node "k" text="K" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=true metadata={"protocol":"mcp","more":1}
      #|edge "a" "b" id="e1" user=true type="arrow_point" text="" lt=text stroke="normal" semantic="sequence" length=1 style=- classes=[] interpolate="basis" animate=true animation=- metadata={"curve":"basis","animate":true,"owner":"me"}
      #|subgraph "f" title="F" lt=string dir=- nodes=["b","a"] classes=[] metadata={"view":"collapsed"}
      #|connector "k"
      #|defaultStyle=- defaultInterpolate=-
      #|mapping "a" vertex 3:4-3:5
      #|mapping "b" vertex 3:13-3:14
      #|mapping "b" edge 3:4-3:14
      #|mapping "f" subgraph 2:2-4:5
      #|mapping "k" connector 5:2-6:0
      #|mapping "e1" attachment 6:2-6:46
      #|mapping "k" attachment 7:2-7:14
      #|semantic dir="TB"
      #|sv "a" label="a" shape=- kind="task" metadata=-
      #|sv "b" label="b" shape=- kind="task" metadata=-
      #|se "a" "b" id="e1" label=- type="arrow_point" stroke="normal" semantic="sequence" length=1 metadata={"curve":"basis","animate":true,"owner":"me"}
      #|ss "f" title="F" nodes=["b","a"] direction=- metadata=-
      #|sc "k" title="K" metadata={"protocol":"mcp","more":1}
    ),
  )
}

///|
test "a list or a string of metadata adds its indexes as keys" {
  inspect(
    model_of("agentflow-beta TB\n  a@{\n- x\n- y\n}\n  b@{\n:\n}"),
    content=(
      #|dir "TB"
      #|node "a" text="a" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata={"0":"x","1":"y"}
      #|node "b" text="b" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata={"0":":"}
      #|defaultStyle=- defaultInterpolate=-
      #|mapping "a" attachment 2:2-5:0
      #|mapping "b" attachment 6:2-8:0
      #|semantic dir="TB"
      #|sv "a" label="a" shape=- kind="task" metadata={"0":"x","1":"y"}
      #|sv "b" label="b" shape=- kind="task" metadata={"0":":"}
    ),
  )
}

///|
test "reports invalid YAML at the metadata block, past the front matter" {
  inspect(
    model_of(
      "agentflow-beta TB\n  a --> b\n  c@{\n    k: 1\n\tbad: 2\n  }",
      line_offset=3,
    ),
    content=(
      #|syntax 6:4 Metadata of "c" is not valid YAML. YAML: tabs are not allowed for indentation (6:4)
    ),
  )
}

///|
test "rejects a shape name with capitals" {
  inspect(
    model_of("agentflow-beta TB\n  a@{ shape: Rounded }"),
    content="semantic 2:4 No such shape: Rounded. Shape names should be lowercase.",
  )
}

///|
test "rejects a shape that is not a name" {
  inspect(
    model_of("agentflow-beta TB\n  a@{ shape: 123 }", line_offset=2),
    content="semantic 4:4 No such shape: 123.",
  )
}

///|
test "rejects an unknown shape" {
  inspect(
    model_of("agentflow-beta TB\n  a@{ shape: nope }"),
    content="semantic 2:4 No such shape: nope.",
  )
}

///|
test "maps every statement to where it sits" {
  inspect(
    model_of(
      "agentflow-beta TB\n  a[\"A\"] --> b\n  a@{ k: 1 }\n  flow f\n    c\n  end\n  connector k\n  e@{\n    x: 1\n  }",
    ),
    content=(
      #|dir "TB"
      #|node "a" text="A" lt=string type="square" styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata={"k":1}
      #|node "b" text="b" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata=-
      #|node "c" text="c" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata=-
      #|node "k" text="k" lt=text type=- styles=[] classes=[] dir=- props=- link=- target=- connector=true metadata=-
      #|node "e" text="e" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata={"x":1}
      #|edge "a" "b" id="L_a_b_0" user=false type="arrow_point" text="" lt=text stroke="normal" semantic="sequence" length=1 style=- classes=[] interpolate=- animate=- animation=- metadata=-
      #|subgraph "f" title="" lt=text dir=- nodes=["c"] classes=[] metadata=-
      #|connector "k"
      #|defaultStyle=- defaultInterpolate=-
      #|mapping "a" vertex 2:2-2:8
      #|mapping "b" vertex 2:13-2:14
      #|mapping "b" edge 2:2-2:14
      #|mapping "a" attachment 3:2-3:11
      #|mapping "c" vertex 5:4-5:5
      #|mapping "f" subgraph 4:2-6:5
      #|mapping "k" connector 7:2-8:0
      #|mapping "e" attachment 8:2-10:2
      #|semantic dir="TB"
      #|sv "a" label="A" shape="square" kind="task" metadata={"k":1}
      #|sv "b" label="b" shape=- kind="task" metadata=-
      #|sv "c" label="c" shape=- kind="task" metadata=-
      #|sv "e" label="e" shape=- kind="task" metadata={"x":1}
      #|se "a" "b" id="L_a_b_0" label=- type="arrow_point" stroke="normal" semantic="sequence" length=1 metadata=-
      #|ss "f" title="" nodes=["c"] direction=- metadata=-
      #|sc "k" title=- metadata=-
    ),
  )
}

///|
test "widens a node's span over the metadata that follows it" {
  inspect(
    model_of(
      "agentflow-beta TB\n  a[\"A\"]@{ k: 1 } & b@{ j: 2 } --> c",
      line_offset=1,
    ),
    content=(
      #|dir "TB"
      #|node "a" text="A" lt=string type="square" styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata={"k":1}
      #|node "b" text="b" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata={"j":2}
      #|node "c" text="c" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata=-
      #|edge "a" "c" id="L_a_c_0" user=false type="arrow_point" text="" lt=text stroke="normal" semantic="sequence" length=1 style=- classes=[] interpolate=- animate=- animation=- metadata=-
      #|edge "b" "c" id="L_b_c_0" user=false type="arrow_point" text="" lt=text stroke="normal" semantic="sequence" length=1 style=- classes=[] interpolate=- animate=- animation=- metadata=-
      #|defaultStyle=- defaultInterpolate=-
      #|mapping "a" vertex 3:2-3:16
      #|mapping "b" attachment 3:20-3:29
      #|mapping "c" vertex 3:35-3:36
      #|mapping "c" edge 3:2-3:36
      #|semantic dir="TB"
      #|sv "a" label="A" shape="square" kind="task" metadata={"k":1}
      #|sv "b" label="b" shape=- kind="task" metadata={"j":2}
      #|sv "c" label="c" shape=- kind="task" metadata=-
      #|se "a" "c" id="L_a_c_0" label=- type="arrow_point" stroke="normal" semantic="sequence" length=1 metadata=-
      #|se "b" "c" id="L_b_c_0" label=- type="arrow_point" stroke="normal" semantic="sequence" length=1 metadata=-
    ),
  )
}

///|
test "the semantic model leaves presentation keys out" {
  inspect(
    model_of(
      "agentflow-beta LR\n  a[\"A\"]@{ shape: tool, icon: x, img: y, form: z, pos: t, w: 1, h: 2, class: c, style: s, labelType: text, view: v, description: kept }\n  flow f@{ view: collapsed, owner: me }\n    a\n  end\n  connector k[\"K\"]@{ icon: x }\n  a -- go --> k",
    ),
    content=(
      #|dir "LR"
      #|node "a" text="A" lt=string type="subroutine" styles=[] classes=[] dir=- props={} link=- target=- connector=false metadata={"shape":"subroutine","icon":"x","img":"y","form":"z","pos":"t","w":1,"h":2,"class":"c","style":"s","labelType":"text","view":"v","description":"kept"}
      #|node "k" text="K" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=true metadata={"icon":"x"}
      #|edge "a" "k" id="L_a_k_0" user=false type="arrow_point" text="go" lt=text stroke="normal" semantic="sequence" length=1 style=- classes=[] interpolate=- animate=- animation=- metadata=-
      #|subgraph "f" title="" lt=text dir=- nodes=["a"] classes=[] metadata={"view":"collapsed","owner":"me"}
      #|connector "k"
      #|defaultStyle=- defaultInterpolate=-
      #|mapping "a" vertex 2:2-2:134
      #|mapping "a" vertex 4:4-4:5
      #|mapping "f" subgraph 3:2-5:5
      #|mapping "k" connector 6:2-7:0
      #|mapping "a" vertex 7:2-7:3
      #|mapping "k" vertex 7:14-7:15
      #|mapping "k" edge 7:2-7:15
      #|semantic dir="LR"
      #|sv "a" label="A" shape="subroutine" kind="tool" metadata={"description":"kept"}
      #|se "a" "k" id="L_a_k_0" label="go" type="arrow_point" stroke="normal" semantic="sequence" length=1 metadata=-
      #|ss "f" title="" nodes=["a"] direction=- metadata={"owner":"me"}
      #|sc "k" title="K" metadata=-
    ),
  )
}
