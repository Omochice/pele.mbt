// The subgraph specs are ported from Mermaid's erDb.spec.js, as pele v1.8.0 runs them in tests/compat/er.
// The other expectations were taken from pele's ErDb.

///|
fn entity_dump(entity : @er.ErEntity) -> String {
  let attributes = entity.attributes.map(a => {
    "\{a.data_type} \{a.name} [\{a.keys.join(",")}] \{repr(a.comment)}"
  })
  "\{entity.id} label=\{repr(entity.label)} alias=\{repr(entity.alias_name)} classes=\{repr(entity.css_classes)} styles=[\{entity.css_styles.join(";")}] attributes=[\{attributes.join(" | ")}]"
}

///|
fn subgraph_dump(subgraph : @er.ErSubgraph) -> String {
  let dir = subgraph.dir.unwrap_or("-")
  "\{repr(subgraph.id)} title=\{repr(subgraph.title)} nodes=[\{subgraph.nodes.map(repr).join(",")}] classes=[\{subgraph.classes.join(",")}] styles=[\{subgraph.css_styles.join(";")}] dir=\{dir}"
}

///|
fn relationship_dump(relationship : @er.ErRelationship) -> String {
  let spec = relationship.rel_spec
  let rel_type = match spec.rel_type {
    Identifying => "IDENTIFYING"
    NonIdentifying => "NON_IDENTIFYING"
  }
  "\{relationship.entity_a} -\{repr(relationship.role_a)}- \{relationship.entity_b} \{spec.card_a.name()} \{rel_type} \{spec.card_b.name()}"
}

///|
fn repr(text : String) -> String {
  "\"" + text + "\""
}

///|
fn names(list : Array[String]) -> Array[@er.DocItem] {
  list.map(name => @er.DocItem::Name(name))
}

///|
test "add subgraph returns the id and keeps the title and nodes" {
  let db = @er.ErDb::new()
  let id = db.add_sub_graph("sub1", names(["A", "B"]), "Group One")
  inspect(id, content="sub1")
  inspect(
    db.subgraphs.map(subgraph_dump).join("\n"),
    content=(
      #|"sub1" title="Group One" nodes=["A","B"] classes=[] styles=[] dir=-
    ),
  )
}

///|
test "add subgraph keeps an empty title empty" {
  let db = @er.ErDb::new()
  ignore(db.add_sub_graph("sub1", names(["A"]), ""))
  inspect(db.subgraphs[0].title, content="")
}

///|
test "a node already in a subgraph is left out of later ones" {
  let db = @er.ErDb::new()
  ignore(db.add_sub_graph("sub1", names(["A", "B"]), "sub1"))
  ignore(db.add_sub_graph("sub2", names(["A", "C"]), "sub2"))
  ignore(db.add_sub_graph("sub3", names(["A"]), "sub3"))
  inspect(
    db.subgraphs.map(subgraph_dump).join("\n"),
    content=(
      #|"sub1" title="sub1" nodes=["A","B"] classes=[] styles=[] dir=-
      #|"sub2" title="sub2" nodes=["C"] classes=[] styles=[] dir=-
      #|"sub3" title="sub3" nodes=[] classes=[] styles=[] dir=-
    ),
  )
}

///|
test "a relationship to a subgraph keeps the subgraph id" {
  let db = @er.ErDb::new()
  ignore(db.add_sub_graph("sub1", names(["X"]), "sub1"))
  db.add_relationship("sub1", "roleA", "Y", {
    card_a: OnlyOne,
    rel_type: Identifying,
    card_b: ZeroOrOne,
  })
  inspect(
    db.relationships.map(relationship_dump).join("\n"),
    content=(
      #|sub1 -"roleA"- entity-Y-0 ONLY_ONE IDENTIFYING ZERO_OR_ONE
    ),
  )
}

///|
test "classes and styles apply to subgraphs" {
  let db = @er.ErDb::new()
  ignore(db.add_sub_graph("sub1", names(["A"]), "sub1"))
  db.set_class(["sub1"], ["B"])
  db.add_css_styles(["sub1"], ["fill:red"])
  inspect(
    subgraph_dump(db.subgraphs[0]),
    content=(
      #|"sub1" title="sub1" nodes=["A"] classes=[B] styles=[fill:red] dir=-
    ),
  )
}

///|
test "a subgraph trims its id and title, takes its last direction and skips blank and repeated names" {
  let db = @er.ErDb::new()
  let id = db.add_sub_graph(
    "  s  ",
    [
      Name(" A"),
      Name("A"),
      Name("B "),
      Dir("LR"),
      Name(""),
      Name("  "),
      Name("C"),
      Dir("RL"),
    ],
    "  T  ",
  )
  // A name is claimed as written, while repeats are spotted trimmed.
  let next = db.add_sub_graph("t", names(["A", " A", "B", "B "]), "")
  inspect("\{id} \{next}", content="s t")
  inspect(
    db.subgraphs.map(subgraph_dump).join("\n"),
    content=(
      #|"s" title="T" nodes=[" A","B ","C"] classes=[] styles=[] dir=RL
      #|"t" title="" nodes=["A","B"] classes=[] styles=[] dir=-
    ),
  )
}

///|
test "entities are numbered in order and keep their first alias" {
  let db = @er.ErDb::new()
  let x = db.add_entity("X")
  ignore(db.add_entity("X", alias_name="first"))
  ignore(db.add_entity("X", alias_name="second"))
  ignore(db.add_entity("Y", alias_name=""))
  db.add_attributes("Z", [
    { data_type: "int", name: "a", keys: [], comment: "", },
    { data_type: "string", name: "b", keys: ["PK", "FK"], comment: "c", },
  ])
  inspect(x.id, content="entity-X-0")
  inspect(
    db.entities.values().map(entity_dump).to_array().join("\n"),
    content=(
      #|entity-X-0 label="X" alias="first" classes="default" styles=[] attributes=[]
      #|entity-Y-1 label="Y" alias="" classes="default" styles=[] attributes=[]
      #|entity-Z-2 label="Z" alias="" classes="default" styles=[] attributes=[string b [PK,FK] "c" | int a [] ""]
    ),
  )
}

///|
test "classes and styles apply to entities and subgraphs of those ids" {
  let db = @er.ErDb::new()
  ignore(db.add_sub_graph("s", names(["A"]), "s"))
  ignore(db.add_entity("X"))
  db.set_class(["X", "s", "nothing"], ["k1", "k2"])
  db.add_css_styles(["X", "s"], ["fill:red", "stroke:blue"])
  inspect(
    entity_dump(db.entities.get("X").unwrap()),
    content=(
      #|entity-X-0 label="X" alias="" classes="default k1 k2" styles=[fill:red;stroke:blue] attributes=[]
    ),
  )
  inspect(
    subgraph_dump(db.subgraphs[0]),
    content=(
      #|"s" title="s" nodes=["A"] classes=[k1,k2] styles=[fill:red;stroke:blue] dir=-
    ),
  )
  inspect(db.entities.length(), content="1")
}

///|
test "a class definition keeps the styles that color text apart" {
  let db = @er.ErDb::new()
  db.add_class(["hot", "cold"], [
    "fill:#f96", "color:#fff", "fill-color:x;fill:y", "stroke:#333",
  ])
  db.add_class(["hot"], ["stroke-width:2px"])
  let dump = db.classes
    .values()
    .map(c => {
      "\{c.id} styles=[\{c.styles.join(" ")}] text=[\{c.text_styles.join(" ")}]"
    })
    .to_array()
  inspect(
    dump.join("\n"),
    content=(
      #|hot styles=[fill:#f96 color:#fff fill-color:x;fill:y stroke:#333 stroke-width:2px] text=[color:#fff bgFill-color:x;fill:y]
      #|cold styles=[fill:#f96 color:#fff fill-color:x;fill:y stroke:#333] text=[color:#fff bgFill-color:x;fill:y]
    ),
  )
}

///|
test "relationships name entities by id and add the ones they mention" {
  let db = @er.ErDb::new()
  ignore(db.add_entity("X"))
  db.add_relationship("X", "q", "X", {
    card_a: OnlyOne,
    rel_type: NonIdentifying,
    card_b: MdParent,
  })
  db.add_relationship("X", "r", "W", {
    card_a: ZeroOrMore,
    rel_type: Identifying,
    card_b: OneOrMore,
  })
  inspect(
    db.relationships.map(relationship_dump).join("\n"),
    content=(
      #|entity-X-0 -"q"- entity-X-0 ONLY_ONE NON_IDENTIFYING MD_PARENT
      #|entity-X-0 -"r"- entity-W-1 ZERO_OR_MORE IDENTIFYING ONE_OR_MORE
    ),
  )
}

///|
test "the accessible title loses its leading space and the description its indents" {
  let db = @er.ErDb::new()
  db.set_acc_title("  \n title  ")
  db.set_acc_description("a\n   b\n\n  c \n")
  db.set_direction("LR")
  inspect(repr(db.acc_title.unwrap_or("-")), content="\"title  \"")
  inspect(repr(db.acc_descr.unwrap_or("-")), content="\"a\nb\nc \n\"")
  inspect(db.direction, content="LR")
}
