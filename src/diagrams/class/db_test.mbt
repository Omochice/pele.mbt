// The expected models were taken from pele v1.8.0's ClassDb after the same calls.

///|
fn opt(value : String?) -> String {
  value.unwrap_or("-")
}

///|
fn member_dump(m : @class.ClassMember) -> String {
  "\{m.visibility}|\{m.id}|\{m.parameters}|\{m.classifier}|\{m.return_type}"
}

///|
fn end_dump(end : Int32?) -> String {
  match end {
    Some(kind) => kind.to_string()
    None => "none"
  }
}

///|
/// The model as one line per class, relation, note, namespace, interface and classDef.
fn db_dump(db : @class.ClassDb) -> String {
  let lines = [
    "direction=\{db.direction} title=\{opt(db.title)} accTitle=\{opt(db.acc_title)} accDescr=\{opt(db.acc_descr)}",
  ]
  for _, c in db.classes {
    lines.push(
      "class \{c.id} type=\{c.generic_type} label=\{c.label} css=\{c.css_classes} parent=\{opt(c.parent)} link=\{opt(c.link)} target=\{opt(c.link_target)} callback=\{c.have_callback} tooltip=\{opt(c.tooltip)} annotations=[\{c.annotations.join(",")}] styles=[\{c.styles.join(";")}] members=[\{c.members.map(member_dump).join(";")}] methods=[\{c.methods.map(member_dump).join(";")}]",
    )
  }
  for r in db.relations {
    lines.push(
      "rel \{r.id1} \{r.id2} t1=\{end_dump(r.relation.type1)} t2=\{end_dump(r.relation.type2)} line=\{r.relation.line_type} titles=\{r.relation_title1}/\{r.relation_title2} title=\{opt(r.title)}",
    )
  }
  for _, n in db.notes {
    lines.push(
      "note \{n.id} class=\{opt(n.class_id)} text=\{n.text} index=\{n.index} parent=\{opt(n.parent)}",
    )
  }
  for _, ns in db.namespaces {
    let classes = ns.classes.keys().collect().join(",")
    let notes = ns.notes.keys().collect().join(",")
    let children = ns.children.keys().collect().join(",")
    lines.push(
      "ns \{ns.id} label=\{ns.label} parent=\{opt(ns.parent)} explicit=\{ns.explicit} classes=[\{classes}] notes=[\{notes}] children=[\{children}]",
    )
  }
  for i in db.interfaces {
    lines.push("iface \{i.id} \{i.label} \{i.class_id}")
  }
  for _, s in db.style_classes {
    lines.push(
      "def \{s.id} styles=[\{s.styles.join(";")}] text=[\{s.text_styles.join(";")}]",
    )
  }
  lines.join("\n")
}

///|
fn relation(
  id1 : String,
  id2 : String,
  type1 : Int32?,
  type2 : Int32?,
  line_type : Int32,
  title1~ : String = "none",
  title2~ : String = "none",
  title? : String,
) -> @class.ClassRelation {
  {
    id1,
    id2,
    relation_title1: title1,
    relation_title2: title2,
    title,
    relation: { type1, type2, line_type, },
  }
}

///|
test "names a class by the part before its generic type" {
  let db = @class.ClassDb::new()
  db.add_class("List~T~")
  db.add_class("List~U~")
  db.add_class("Map~K~V~")
  db.add_class("~x")
  db.add_class("Open~T")
  db.set_class_label("List", "A list")
  db.set_class_label("New~Q~", "made")
  assert_eq(
    db_dump(db),
    "direction=TB title=- accTitle=- accDescr=-\nclass List type=T label=A list css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Map type=K label=Map css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass ~x type= label=~x css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Open type=T label=Open css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass New type=Q label=made css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
  )
}

///|
test "sorts members into attributes, methods and annotations" {
  let db = @class.ClassDb::new()
  db.add_class("A")
  db.add_member("A", "  +name : String  ")
  db.add_member("A", "+run() int")
  db.add_member("A", "<<interface>>")
  db.add_member("A", "x)")
  db.add_member("A", ")y")
  db.add_member("A", "   ")
  db.add_member("B~T~", "count$")
  db.add_members("A", ["first", "second()"])
  db.add_annotation("C", "service")
  assert_eq(
    db_dump(db),
    "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[interface] styles=[] members=[+|name : String|||;|x)|||;|)y|||;|first|||] methods=[+|run|||int;|second|||]\nclass B type=T label=B css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[|count||$|] methods=[]\nclass C type= label=C css=default parent=- link=- target=- callback=false tooltip=- annotations=[service] styles=[] members=[] methods=[]",
  )
}

///|
test "turns the lollipop end of a relation into an interface" {
  let db = @class.ClassDb::new()
  db.add_relation(relation("bar", "foo", Some(4), None, 0, title1=" 1 "))
  db.add_relation(relation("foo", "baz", None, Some(4), 1))
  db.add_relation(
    relation("A~T~", "B", Some(4), Some(4), 0, title2=" many", title="has"),
  )
  assert_eq(
    db_dump(db),
    "direction=TB title=- accTitle=- accDescr=-\nclass foo type= label=foo css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass A type=T label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass B type= label=B css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nrel interface0 foo t1=4 t2=none line=0 titles=1/none title=-\nrel foo interface1 t1=none t2=4 line=1 titles=none/none title=-\nrel A B t1=4 t2=4 line=0 titles=none/many title=has\niface interface0 bar foo\niface interface1 baz foo",
  )
}

///|
test "numbers notes in the order they are added" {
  let db = @class.ClassDb::new()
  db.add_class("A")
  inspect(db.add_note("general"), content="note0")
  inspect(db.add_note("about A", class_id="A"), content="note1")
  inspect(db.add_note("about nothing", class_id="Missing"), content="note2")
  assert_eq(
    db_dump(db),
    "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nnote note0 class=- text=general index=0 parent=-\nnote note1 class=A text=about A index=1 parent=-\nnote note2 class=Missing text=about nothing index=2 parent=-",
  )
}

///|
test "applies css classes and classDefs to whole class names, never to ids that start with a digit" {
  let db = @class.ClassDb::new()
  db.add_class("A")
  db.add_class("1B")
  db.add_class("C")
  db.set_css_class("A,1B,C~T~,Missing", "hot cold")
  db.define_class(["hot", "def", "default"], [
    "fill:#f00,color:#fff", "stroke:red",
  ])
  db.define_class(["cold"], ["color:blue"])
  db.add_class("D")
  db.define_class(["default"], ["fill:#0f0"])
  db.set_css_style("A", ["stroke:#000,stroke-width:2px"])
  db.set_css_style("Missing", ["x:y"])
  assert_eq(
    db_dump(db),
    "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default hot cold parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[fill:#f00;color:#fff;stroke:red;fill:#f00;color:#fff;stroke:red;color:blue;fill:#0f0;stroke:#000;stroke-width:2px] members=[] methods=[]\nclass 1B type= label=1B css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[fill:#f00;color:#fff;stroke:red;fill:#0f0] members=[] methods=[]\nclass C type= label=C css=default hot cold parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[fill:#f00;color:#fff;stroke:red;fill:#f00;color:#fff;stroke:red;color:blue;fill:#0f0] members=[] methods=[]\nclass D type= label=D css=default parent=- link=- target=- callback=false tooltip=- annotations=[] styles=[fill:#0f0] members=[] methods=[]\ndef hot styles=[fill:#f00,color:#fff;stroke:red] text=[bgFill:#f00,color:#fff]\ndef def styles=[fill:#f00,color:#fff;stroke:red] text=[bgFill:#f00,color:#fff]\ndef default styles=[fill:#f00,color:#fff;stroke:red;fill:#0f0] text=[bgFill:#f00,color:#fff]\ndef cold styles=[color:blue] text=[color:blue]",
  )
}

///|
test "sanitizes links and marks callbacks as clickable without keeping them" {
  let db = @class.ClassDb::new()
  db.add_class("A")
  db.add_class("B")
  db.add_class("1C")
  db.add_class("D")
  db.set_link("A", "javascript:alert(1)")
  db.set_link("B", " https://example.com/a b ", target="_self")
  db.set_link("1C", "https://x")
  db.set_link("D", "&#104;ttps://e.com", target="other")
  db.set_click_event("1C,A")
  db.set_tooltip("A,B~T~,Missing", Some("tip"))
  db.set_tooltip("D", None)
  db.set_link("B", "   ")
  assert_eq(
    db_dump(db),
    "direction=TB title=- accTitle=- accDescr=-\nclass A type= label=A css=default clickable clickable parent=- link=about:blank target=_blank callback=true tooltip=tip annotations=[] styles=[] members=[] methods=[]\nclass B type= label=B css=default clickable clickable parent=- link=- target=_blank callback=false tooltip=tip annotations=[] styles=[] members=[] methods=[]\nclass 1C type= label=1C css=default parent=- link=- target=- callback=true tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass D type= label=D css=default clickable parent=- link=https://e.com/ target=other callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]",
  )
}

///|
test "nests namespaces by block and by dotted name" {
  let db = @class.ClassDb::new()
  db.add_class("X")
  db.add_class("Y")
  ignore(db.add_note("n"))
  ignore(db.add_namespace("A.B"))
  db.add_classes_to_namespace("A.B", ["X~T~", "Missing"], ["note0", "note9"])
  db.pop_namespace()
  ignore(db.add_namespace("A"))
  inspect(db.add_namespace("C", label="See"), content="A.C")
  db.add_classes_to_namespace("A.C", ["Y"], [])
  db.pop_namespace()
  db.pop_namespace()
  ignore(db.add_namespace("A", label="Relabeled"))
  db.pop_namespace()
  ignore(db.add_namespace("P.Q.R", label="Leaf"))
  db.pop_namespace()
  ignore(db.add_namespace("P.Q"))
  db.pop_namespace()
  db.add_classes_to_namespace("Missing", ["X"], [])
  assert_eq(
    db_dump(db),
    "direction=TB title=- accTitle=- accDescr=-\nclass X type= label=X css=default parent=A.B link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nclass Y type= label=Y css=default parent=A.C link=- target=- callback=false tooltip=- annotations=[] styles=[] members=[] methods=[]\nnote note0 class=- text=n index=0 parent=A.B\nns A label=Relabeled parent=- explicit=true classes=[] notes=[] children=[A.B,A.C]\nns A.B label=B parent=A explicit=true classes=[X] notes=[note0] children=[]\nns A.C label=See parent=A explicit=true classes=[Y] notes=[] children=[]\nns P label=P parent=- explicit=false classes=[] notes=[] children=[P.Q]\nns P.Q label=Q parent=P explicit=true classes=[] notes=[] children=[P.Q.R]\nns P.Q.R label=Leaf parent=P.Q explicit=true classes=[] notes=[] children=[]",
  )
}

///|
test "keeps the direction and the accessibility text" {
  let db = @class.ClassDb::new(title="Shapes")
  db.set_direction("LR")
  db.set_acc_title("  \t The title ")
  db.set_acc_description("line one\n    line two\n\n  \tthree ")
  assert_eq(
    db_dump(db),
    "direction=LR title=Shapes accTitle=The title  accDescr=line one\nline two\nthree ",
  )
  inspect(db.cleanup_label(": text "), content="text")
  inspect(db.cleanup_label(" :text"), content=":text")
}
