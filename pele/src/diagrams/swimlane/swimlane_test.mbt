///|
let order : String =
  #|swimlane-beta LR
  #|  subgraph Customer
  #|    browse[Browse] --> pay[Pay]
  #|  end
  #|  subgraph Warehouse
  #|    pick[Pick] --> ship[Ship]
  #|  end
  #|  pay -- paid --> pick

///|
fn read(source : String) -> @flowchart.FlowDb raise {
  @swimlane.parse_swimlane(source + "\n", {}, None, { max_edges: 5000, })
}

///|
fn outcome(source : String) -> String {
  let result = @core.render(
    [@swimlane.swimlane],
    source,
    @types.RenderOptions::default(),
  ) catch {
    @errors.PeleError(failure) => return "error \{failure.code.to_string()}"
  }
  "ok \{result.kind}"
}

///|
test "is detected and drawn as a swimlane diagram" {
  inspect(outcome(order), content="ok swimlane")
  inspect(
    outcome("swimlane-betax\n a --> b"),
    content="error unsupported-diagram",
  )
}

///|
test "reads the same model as a flowchart with the same body" {
  let lane = read(order)
  let flow = @flowchart.parse_model(
    order.replace(old="swimlane-beta", new="flowchart") + "\n",
    {},
    None,
    { max_edges: 5000, },
  )
  assert_eq(lane.nodes.keys().collect(), flow.nodes.keys().collect())
  let ends = (db : @flowchart.FlowDb) => {
    db.edges.map(e => (e.start, e.end, e.text))
  }
  assert_eq(ends(lane), ends(flow))
  let groups = (db : @flowchart.FlowDb) => {
    db.subgraphs.map(s => (s.id, s.nodes))
  }
  assert_eq(groups(lane), groups(flow))
  assert_eq(lane.direction, Some("LR"))
}

///|
test "rejects what the flowchart grammar rejects" {
  inspect(outcome("swimlane-beta LR\n  a --> "), content="error syntax")
  inspect(
    outcome("swimlane-beta LR\n  subgraph x\n  a"),
    content="error syntax",
  )
}
