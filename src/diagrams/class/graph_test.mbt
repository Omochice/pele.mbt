// The expected graphs were taken from pele v1.8.0's buildClassGraph.
// The colour slot tests are ported from Mermaid's classDiagram-colorIndex.spec.ts, as pele runs them in tests/compat/class.

///|
fn graph_dump(graph : @class.ClassGraph) -> String {
  let lines = []
  for n in graph.nodes {
    let color = match n.color_index {
      Some(index) => index.to_string()
      None => "-"
    }
    let owner = match n.class_node {
      Some(c) => c.id
      None => "-"
    }
    lines.push(
      "node \{n.id} label=\{n.label} group=\{n.is_group} shape=\{n.shape.name()} parentId=\{opt(n.parent_id)} parent=\{n.parent} class=\{owner} color=\{color}",
    )
  }
  for e in graph.edges {
    lines.push(
      "edge \{e.id} \{e.start}->\{e.end} \{e.source}->\{e.target} label=\{opt(e.label)} \{e.arrow_type_start}/\{e.arrow_type_end} right=\{e.start_label_right} left=\{e.end_label_left} \{e.pattern} \{e.classes}",
    )
  }
  lines.join("\n")
}

///|
test "resolves the model into the nodes and edges that are drawn" {
  let cases = [
    (
      "classDiagram\nclass interface0\nclass note0\nbar ()-- interface0\nnote for note0 \"n\"\nnamespace note0 {\n class X\n}",
      true, "node note0 label=note0 group=true shape=rect parentId=- parent=-1 class=- color=-\nnode interface0 label=interface0 group=false shape=classBox parentId=- parent=-1 class=interface0 color=0\nnode note0 label=note0 group=false shape=classBox parentId=- parent=-1 class=note0 color=1\nnode X label=X group=false shape=classBox parentId=note0 parent=0 class=X color=2\nnode note0 label=n group=false shape=note parentId=- parent=-1 class=- color=-\nnode interface0 label=bar group=false shape=interface parentId=- parent=-1 class=- color=-\nedge edgeNote0 note0->note0 4->2 label=- none/none right= left= dotted relation\nedge id_interface0_interface0_1 interface0->interface0 5->1 label=- lollipop/none right= left= solid relation",
    ),
    (
      "classDiagram\nnamespace Company.Engineering {\n  class Dev\n}\nnote for Dev \"n\"\nnote \"free\"",
      true, "node Company label=Company group=true shape=rect parentId=- parent=-1 class=- color=-\nnode Company.Engineering label=Engineering group=true shape=rect parentId=Company parent=0 class=- color=-\nnode Dev label=Dev group=false shape=classBox parentId=Company.Engineering parent=1 class=Dev color=0\nnode note0 label=n group=false shape=note parentId=- parent=-1 class=- color=-\nnode note1 label=free group=false shape=note parentId=- parent=-1 class=- color=-\nedge edgeNote0 note0->Dev 3->2 label=- none/none right= left= dotted relation",
    ),
    (
      "classDiagram\nnamespace Company.Engineering {\n  class Dev\n}\nnote for Dev \"n\"\nnote \"free\"",
      false, "node Company.Engineering label=Company.Engineering group=true shape=rect parentId=- parent=-1 class=- color=-\nnode Dev label=Dev group=false shape=classBox parentId=Company.Engineering parent=0 class=Dev color=0\nnode note0 label=n group=false shape=note parentId=- parent=-1 class=- color=-\nnode note1 label=free group=false shape=note parentId=- parent=-1 class=- color=-\nedge edgeNote0 note0->Dev 2->1 label=- none/none right= left= dotted relation",
    ),
    (
      "classDiagram\nnamespace A.B.C {\n class X\n}\nnamespace A {\n class Y\n namespace D {\n  class Z\n  note \"z\"\n }\n}",
      false, "node A label=A group=true shape=rect parentId=- parent=-1 class=- color=-\nnode A.B.C label=A.B.C group=true shape=rect parentId=- parent=-1 class=- color=-\nnode A.D label=A.D group=true shape=rect parentId=- parent=-1 class=- color=-\nnode X label=X group=false shape=classBox parentId=A.B.C parent=1 class=X color=0\nnode Y label=Y group=false shape=classBox parentId=A parent=0 class=Y color=1\nnode Z label=Z group=false shape=classBox parentId=A.D parent=2 class=Z color=2\nnode note0 label=z group=false shape=note parentId=A.D parent=2 class=- color=-",
    ),
    (
      "classDiagram\nnamespace N {\n  class A\n}\nbar ()-- A\nA --() baz\nA ()--() B\nA \"1\" --> \"many\" B : uses\nA ..|> A\nnote for Missing \"x\"",
      true, "node N label=N group=true shape=rect parentId=- parent=-1 class=- color=-\nnode A label=A group=false shape=classBox parentId=N parent=0 class=A color=0\nnode B label=B group=false shape=classBox parentId=- parent=-1 class=B color=1\nnode note0 label=x group=false shape=note parentId=- parent=-1 class=- color=-\nnode interface0 label=bar group=false shape=interface parentId=- parent=0 class=- color=-\nnode interface1 label=baz group=false shape=interface parentId=- parent=0 class=- color=-\nedge id_interface0_A_1 interface0->A 4->1 label=- lollipop/none right= left= solid relation\nedge id_A_interface1_2 A->interface1 1->5 label=- none/lollipop right= left= solid relation\nedge id_A_B_3 A->B 1->2 label=- lollipop/lollipop right= left= solid relation\nedge id_A_B_4 A->B 1->2 label=uses none/dependency right=1 left=many solid relation\nedge id_A_A_5 A->A 1->1 label=- none/extension right= left= dashed relation",
    ),
    (
      "classDiagram\nA <|-- B\nC *-- D\nE o-- F\nG <-- H\nI .. J\nK --o L", true,
      "node A label=A group=false shape=classBox parentId=- parent=-1 class=A color=0\nnode B label=B group=false shape=classBox parentId=- parent=-1 class=B color=1\nnode C label=C group=false shape=classBox parentId=- parent=-1 class=C color=2\nnode D label=D group=false shape=classBox parentId=- parent=-1 class=D color=3\nnode E label=E group=false shape=classBox parentId=- parent=-1 class=E color=4\nnode F label=F group=false shape=classBox parentId=- parent=-1 class=F color=5\nnode G label=G group=false shape=classBox parentId=- parent=-1 class=G color=6\nnode H label=H group=false shape=classBox parentId=- parent=-1 class=H color=7\nnode I label=I group=false shape=classBox parentId=- parent=-1 class=I color=8\nnode J label=J group=false shape=classBox parentId=- parent=-1 class=J color=9\nnode K label=K group=false shape=classBox parentId=- parent=-1 class=K color=10\nnode L label=L group=false shape=classBox parentId=- parent=-1 class=L color=11\nedge id_A_B_1 A->B 0->1 label=- extension/none right= left= solid relation\nedge id_C_D_2 C->D 2->3 label=- composition/none right= left= solid relation\nedge id_E_F_3 E->F 4->5 label=- aggregation/none right= left= solid relation\nedge id_G_H_4 G->H 6->7 label=- dependency/none right= left= solid relation\nedge id_I_J_5 I->J 8->9 label=- none/none right= left= dashed relation\nedge id_K_L_6 K->L 10->11 label=- none/aggregation right= left= solid relation",
    ),
  ]
  for case in cases {
    let (source, hierarchical, expected) = case
    let db = @class.ClassDb::new()
    @class.parse_class(source, db)
    assert_eq(
      graph_dump(@class.build_class_graph(db, hierarchical~)),
      expected,
      msg=source,
    )
  }
}

///|
fn color_index_by_id(db : @class.ClassDb) -> Map[String, String] {
  let slots = Map([])
  for node in @class.build_class_graph(db).nodes {
    slots.set(
      node.id,
      match node.color_index {
        Some(index) => index.to_string()
        None => "none"
      },
    )
  }
  slots
}

///|
test "gives each class its own slot in declaration order" {
  let db = @class.ClassDb::new()
  db.add_class("Order")
  db.add_class("Customer")
  db.add_class("Payment")
  let slots = color_index_by_id(db)
  inspect(slots.get("Order").unwrap(), content="0")
  inspect(slots.get("Customer").unwrap(), content="1")
  inspect(slots.get("Payment").unwrap(), content="2")
}

///|
test "does not spend a slot on a namespace container" {
  let db = @class.ClassDb::new()
  ignore(db.add_namespace("shop"))
  db.add_class("Order")
  db.add_classes_to_namespace("shop", ["Order"], [])
  db.add_class("Customer")
  let slots = color_index_by_id(db)
  inspect(slots.get("shop").unwrap(), content="none")
  inspect(slots.get("Order").unwrap(), content="0")
  inspect(slots.get("Customer").unwrap(), content="1")
}

///|
test "does not spend a slot on a note" {
  let db = @class.ClassDb::new()
  db.add_class("Order")
  ignore(db.add_note("a note", class_id="Order"))
  db.add_class("Customer")
  let slots = color_index_by_id(db)
  inspect(slots.get("note0").unwrap(), content="none")
  inspect(slots.get("Order").unwrap(), content="0")
  inspect(slots.get("Customer").unwrap(), content="1")
}
