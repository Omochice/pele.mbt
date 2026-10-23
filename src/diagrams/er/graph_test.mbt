// The cluster specs follow Mermaid's erDb.spec.js getData tests; the expectations were taken from pele's buildErGraph.

///|
fn graph_dump(source : String) -> String raise @errors.PeleError {
  let db = @er.ErDb::new()
  @er.parse_er(source, db)
  let graph = @er.build_er_graph(db)
  let lines = []
  for n in graph.nodes {
    let parent = match n.parent_id {
      Some(id) => q(id)
      None => "-"
    }
    let dir = match n.dir {
      Some(dir) => q(dir)
      None => "-"
    }
    let kind = if n.is_group { "group" } else { "node" }
    lines.push(
      "\{kind} \{q(n.id)} label=\{q(n.label)} alias=\{q(n.alias_name)} parent=\{parent} attrs=\{n.attributes.length()} styles=\{quoted(n.css_styles)} compiled=\{quoted(n.css_compiled_styles)} classes=\{q(n.css_classes)} dir=\{dir}",
    )
  }
  for e in graph.edges {
    let pattern = if e.dashed { "dashed" } else { "solid" }
    lines.push(
      "edge \{q(e.id)} \{q(e.start)} -> \{q(e.end)} label=\{q(e.label)} \{e.arrow_type_start} \{e.arrow_type_end} \{pattern}",
    )
  }
  lines.join("\n")
}

///|
test "subgraphs come first, the last declared first, each with its parent" {
  inspect(
    graph_dump(
      "erDiagram\nsubgraph sub1 [Outer Group]\nsub1_1\nA\nend\nsubgraph sub1_1 [Inner Group]\nB\nend\nA\nB",
    ),
    content=(
      #|group "sub1_1" label="Inner Group" alias="" parent="sub1" attrs=0 styles=[] compiled=[] classes="" dir=-
      #|group "sub1" label="Outer Group" alias="" parent=- attrs=0 styles=[] compiled=[] classes="" dir=-
      #|node "entity-A-1" label="A" alias="" parent="sub1" attrs=0 styles=[] compiled=[] classes="default" dir=-
      #|node "entity-B-2" label="B" alias="" parent="sub1_1" attrs=0 styles=[] compiled=[] classes="default" dir=-
    ),
  )
}

///|
test "a relationship written before its subgraph follows the subgraph" {
  // The subgraph lists itself through the relationship inside it, so it is its own parent.
  inspect(
    graph_dump(
      "erDiagram\ng ||--o{ X : early\nsubgraph g\n  direction LR\n  A |o..|{ g : \"r\"\nend\nX }o--o| X : self\nX u--|| A : p",
    ),
    content=(
      #|group "g" label="g" alias="" parent="g" attrs=0 styles=[] compiled=[] classes="" dir="LR"
      #|node "entity-X-1" label="X" alias="" parent=- attrs=0 styles=[] compiled=[] classes="default" dir=-
      #|node "entity-A-2" label="A" alias="" parent="g" attrs=0 styles=[] compiled=[] classes="default" dir=-
      #|edge "id_entity-g-0_entity-X-1_0" "g" -> "entity-X-1" label="early" only_one zero_or_more solid
      #|edge "id_entity-A-2_entity-g-0_1" "entity-A-2" -> "g" label="r" zero_or_one one_or_more dashed
      #|edge "id_entity-X-1_entity-X-1_2" "entity-X-1" -> "entity-X-1" label="self" zero_or_more zero_or_one solid
      #|edge "id_entity-X-1_entity-A-2_3" "entity-X-1" -> "entity-A-2" label="p" md_parent only_one solid
    ),
  )
}

///|
test "class styles are compiled in class order, text styles after the rest" {
  inspect(
    graph_dump(
      "erDiagram\nA:::hot { int id }\nB\nclass B hot,cold\nclassDef hot fill:#f96, color:#fff\nclassDef default stroke-width:2px\nstyle A stroke:red\nsubgraph s\nB\nend\nclass s cold\nclassDef cold font-weight:bold\nstyle s fill:#eee\n",
    ),
    content=(
      #|group "s" label="s" alias="" parent=- attrs=0 styles=["fill:#eee"] compiled=["font-weight:bold"] classes="cold" dir=-
      #|node "entity-A-0" label="A" alias="" parent=- attrs=1 styles=["stroke:red"] compiled=["stroke-width:2px","fill:#f96","color:#fff","color:#fff"] classes="default hot" dir=-
      #|node "entity-B-1" label="B" alias="" parent="s" attrs=0 styles=[] compiled=["stroke-width:2px","fill:#f96","color:#fff","color:#fff","font-weight:bold"] classes="default hot cold" dir=-
    ),
  )
}
