///|
fn statements_of(source : String) -> String {
  let db = @agentflow.AgentflowDb::new()
  @agentflow.parse_agentflow(source, db) catch {
    @errors.PeleError(failure) => return failure.message
  }
  dump_statements(db)
}

///|
test "every corpus input without metadata reads into the statements pele reads" {
  inspect(mismatches(statements_cases, db => dump_statements(db)), content="")
}

///|
test "reads two nodes and the edge between them" {
  inspect(
    statements_of("agentflow-beta TB\n  a[\"Alpha\"]\n  b[\"Beta\"]\n  a --> b"),
    content=(
      #|dir "TB"
      #|node "a" text="Alpha" lt=string type="square" styles=[] classes=[] dir=- props={} link=- target=- connector=false
      #|node "b" text="Beta" lt=string type="square" styles=[] classes=[] dir=- props={} link=- target=- connector=false
      #|edge "a" "b" id="L_a_b_0" user=false type="arrow_point" text="" lt=text stroke="normal" semantic="sequence" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}

///|
test "reads the three arrows as sequence, failure and reference" {
  inspect(
    statements_of(
      "agentflow-beta LR\n  a --> b\n  a --x c\n  a -.- d\n  a -- yes --> e",
    ),
    content=(
      #|dir "LR"
      #|node "a" text="a" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false
      #|node "b" text="b" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false
      #|node "c" text="c" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false
      #|node "d" text="d" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false
      #|node "e" text="e" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false
      #|edge "a" "b" id="L_a_b_0" user=false type="arrow_point" text="" lt=text stroke="normal" semantic="sequence" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "a" "c" id="L_a_c_0" user=false type="arrow_cross" text="" lt=text stroke="normal" semantic="failure" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "a" "d" id="L_a_d_0" user=false type="arrow_open" text="" lt=text stroke="dotted" semantic="reference" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "a" "e" id="L_a_e_0" user=false type="arrow_point" text="yes" lt=text stroke="normal" semantic="sequence" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}

///|
test "a flow holds the nodes inside it, and a global block takes them out of every flow" {
  inspect(
    statements_of(
      "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner\n      a --> b\n    end\n    c\n  end\n  global\n    b\n  end\n  connector k[\"K\"]",
    ),
    content=(
      #|dir "TB"
      #|node "a" text="a" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false
      #|node "b" text="b" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false
      #|node "c" text="c" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- connector=false
      #|node "k" text="K" lt=text type=- styles=[] classes=[] dir=- props=- link=- target=- connector=true
      #|edge "a" "b" id="L_a_b_0" user=false type="arrow_point" text="" lt=text stroke="normal" semantic="sequence" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|subgraph "inner" title="" lt=text dir=- nodes=["a"] classes=[]
      #|subgraph "outer" title="Outer" lt=string dir=- nodes=["inner","c"] classes=[]
      #|connector "k"
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}

///|
test "reports a flow left open as pele does" {
  inspect(
    statements_of("agentflow-beta TB\n  flow f\n    a\n"),
    content=(
      #|Parse error on line 3:
      #|    a
      #|-----^
      #|Expecting 'end', got '$end'
    ),
  )
}

///|
test "reports the end of input before trailing comments" {
  inspect(
    statements_of(
      "agentflow-beta TB\n  flow f[\"F\"]\n    a --> b\n\n%% trailing\n",
    ),
    content=(
      #|Parse error on line 3:
      #|    a --> b
      #|-----------^
      #|Expecting 'end', got '$end'
    ),
  )
}
