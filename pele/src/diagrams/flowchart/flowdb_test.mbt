// Ported from the database-level specs of Mermaid's flowDb.spec.ts, as pele v1.8.0 runs them in tests/compat/flowchart; the specs that parse text are covered through the golden sources.

///|
fn subgraph_of(nodes : Array[String]) -> @flowchart.FlowSubgraph {
  {
    id: "",
    nodes,
    title: "",
    classes: [],
    dir: None,
    label_type: Text,
    metadata: None,
  }
}

///|
let spec_subgraphs : Array[@flowchart.FlowSubgraph] = [
  subgraph_of(["a", "b", "c", "e"]),
  subgraph_of(["f", "g", "h"]),
  subgraph_of(["i", "j"]),
  subgraph_of(["k"]),
]

///|
test "exists tells whether a subgraph holds the id" {
  let db = @flowchart.FlowDb::new()
  let found = ["a", "h", "j", "k", "a2", "l"].map(id => {
    db.exists(spec_subgraphs, id)
  })
  inspect(
    found.map(f => f.to_string()).join(" "),
    content="true true true true false false",
  )
}

///|
test "makeUniq leaves out ids that another subgraph already holds" {
  let db = @flowchart.FlowDb::new()
  let uniq = (nodes : Array[String]) => {
    db.make_uniq(subgraph_of(nodes), spec_subgraphs).join(",")
  }
  inspect(uniq(["i", "j"]), content="")
  inspect(uniq(["i", "j", "o"]), content="o")
  inspect(uniq(["q", "r", "s"]), content="q,r,s")
}

///|
test "addClass defines each class it names" {
  let db = @flowchart.FlowDb::new()
  db.add_class("a,b", ["stroke-width: 8px"])
  db.add_class("c", ["stroke-width: 8px"])
  let styles = (id : String) => {
    match db.classes.get(id) {
      Some(def) => def.styles.join(";")
      None => "-"
    }
  }
  inspect(
    "\{styles("a")} | \{styles("b")} | \{styles("c")}",
    content="stroke-width: 8px | stroke-width: 8px | stroke-width: 8px",
  )
}

///|
fn spec_vertex(
  db : @flowchart.FlowDb,
  id : String,
) -> Unit raise @errors.PeleError {
  db.add_vertex(id, text={ text: id, kind: Text, }, style=[], classes=[])
}

///|
fn spec_link(
  db : @flowchart.FlowDb,
  start : String,
  end : String,
  id? : String,
) -> Unit raise @errors.PeleError {
  let link = db.destruct_link("-->")
  link.id = id
  db.add_link([start], [end], Some(link))
}

///|
fn curves(db : @flowchart.FlowDb) -> String {
  @flowchart.build_flow_graph(db).edges.map(e => json(e.curve)).join(" ")
}

///|
test "edges without a curve of their own take linkStyle default's" {
  let db = @flowchart.FlowDb::new()
  spec_vertex(db, "A")
  spec_vertex(db, "B")
  spec_link(db, "A", "B")
  db.update_link_interpolate(["default"], "stepBefore")
  inspect(curves(db), content="\"stepBefore\"")
  db.update_link_interpolate(["0"], "basis")
  inspect(curves(db), content="\"basis\"")
}

///|
test "node data on an edge id sets that edge's curve" {
  let db = @flowchart.FlowDb::new()
  for id in ["A", "B", "C", "D"] {
    spec_vertex(db, id)
  }
  spec_link(db, "A", "B")
  spec_link(db, "A", "C", id="e2")
  spec_link(db, "B", "D", id="e3")
  spec_link(db, "C", "D")
  db.update_link_interpolate(["default"], "stepBefore")
  db.update_link_interpolate(["0"], "basis")
  db.add_vertex(
    "e2",
    text={ text: "Shouldnt be used", kind: Text, },
    metadata=" curve: monotoneX ",
  )
  db.add_vertex(
    "e3",
    text={ text: "Shouldnt be used", kind: Text, },
    metadata=" curve: catmullRom ",
  )
  inspect(
    curves(db),
    content="\"basis\" \"monotoneX\" \"catmullRom\" \"stepBefore\"",
  )
}

///|
fn spec_subgraph(
  db : @flowchart.FlowDb,
  id : String,
  members : Array[String],
  title : String,
) -> Unit {
  ignore(
    db.add_subgraph(
      Some({ text: id, kind: Text, }),
      members.map(m => @flowchart.DocItem::Id(m)),
      Some({ text: title, kind: Text, }),
    ),
  )
}

///|
fn node_ids(db : @flowchart.FlowDb) -> String {
  @flowchart.build_flow_graph(db).nodes.map(n => "\{n.id}:\{n.shape}").join(" ")
}

///|
fn edge_ends(db : @flowchart.FlowDb) -> String {
  @flowchart.build_flow_graph(db).edges
  .map(e => "\{e.start}>\{e.end}")
  .join(" ")
}

///|
test "a subgraph without collapse metadata is a group" {
  let db = @flowchart.FlowDb::new()
  for id in ["A", "B", "C"] {
    spec_vertex(db, id)
  }
  spec_link(db, "A", "B")
  spec_link(db, "C", "A")
  spec_subgraph(db, "sub1", ["A", "B"], "My Group")
  inspect(
    node_ids(db),
    content="sub1:rect A:squareRect B:squareRect C:squareRect",
  )
  inspect(edge_ends(db), content="A>B C>A")
}

///|
test "subgraph metadata reaches the group node" {
  let db = @flowchart.FlowDb::new()
  spec_vertex(db, "A")
  spec_vertex(db, "B")
  spec_subgraph(db, "sub1", ["A", "B"], "My Group")
  db.add_vertex("sub1", metadata=" algorithm: elk.box ")
  let group = @flowchart.build_flow_graph(db).nodes[0]
  inspect(
    "\{group.is_group} \{metadata(group.metadata)}",
    content="true {\"algorithm\":\"elk.box\"}",
  )
}

///|
test "a collapsed subgraph is one node that takes its members' edges" {
  let db = @flowchart.FlowDb::new()
  for id in ["A", "B", "C"] {
    spec_vertex(db, id)
  }
  spec_link(db, "A", "B")
  spec_link(db, "C", "A")
  spec_subgraph(db, "sub1", ["A", "B"], "My Group")
  db.add_vertex("sub1", metadata=" view: collapsed ")
  let group = @flowchart.build_flow_graph(db).nodes[0]
  inspect(
    "\{group.label.unwrap_or("-")} \{group.is_group}",
    content="My Group false",
  )
  inspect(node_ids(db), content="sub1:collapsedGroup C:squareRect")
  inspect(edge_ends(db), content="C>sub1")
}

///|
test "edges go to the outermost of nested collapsed subgraphs" {
  let db = @flowchart.FlowDb::new()
  for id in ["A", "B", "C"] {
    spec_vertex(db, id)
  }
  spec_link(db, "C", "A")
  spec_subgraph(db, "inner", ["A", "B"], "Inner")
  spec_subgraph(db, "outer", ["inner"], "Outer")
  db.add_vertex("inner", metadata=" view: collapsed ")
  db.add_vertex("outer", metadata=" view: collapsed ")
  inspect(node_ids(db), content="outer:collapsedGroup C:squareRect")
  inspect(edge_ends(db), content="C>outer")
}

///|
fn slots(db : @flowchart.FlowDb) -> String {
  let graph = @flowchart.build_flow_graph(db)
  graph.nodes
  .map(n => {
    let slot = match n.color_index {
      Some(i) => i.to_string()
      None => "-"
    }
    "\{n.id}=\{slot}"
  })
  .join(" ")
}

///|
test "subgraphs get colour slots in source order, parents before children" {
  let db = @flowchart.FlowDb::new()
  for id in ["A", "B", "C", "D"] {
    spec_vertex(db, id)
  }
  spec_subgraph(db, "InnerOne", ["A"], "InnerOne")
  spec_subgraph(db, "InnerTwo", ["B"], "InnerTwo")
  spec_subgraph(db, "Outer", ["InnerOne", "InnerTwo"], "Outer")
  spec_subgraph(db, "Sibling", ["D"], "Sibling")
  inspect(
    slots(db),
    content="Sibling=3 Outer=0 InnerTwo=2 InnerOne=1 A=- B=- C=- D=-",
  )
}

///|
test "a collapsed subgraph keeps its colour slot" {
  let db = @flowchart.FlowDb::new()
  for id in ["A", "B", "C"] {
    spec_vertex(db, id)
  }
  spec_subgraph(db, "first", ["A"], "First")
  spec_subgraph(db, "second", ["B"], "Second")
  spec_subgraph(db, "third", ["C"], "Third")
  db.add_vertex("second", metadata=" view: collapsed ")
  inspect(slots(db), content="third=2 second=1 first=0 A=- C=-")
}

///|
test "a TD direction is stored as TB, with or without leading spaces" {
  let db = @flowchart.FlowDb::new()
  db.set_direction("TD")
  inspect(db.direction.unwrap_or("-"), content="TB")
  db.set_direction(" TD")
  inspect(db.direction.unwrap_or("-"), content="TB")
}
