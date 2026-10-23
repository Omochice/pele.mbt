// Behaviour of pele's C4Db (src/diagrams/c4/db.ts), driven through the calls its parser makes.

///|
fn t(text : String) -> @c4.C4Attr {
  Text(text)
}

///|
fn kv(key : String, value : String) -> @c4.C4Attr {
  Named({ key, value, })
}

///|
fn opt(parts : Array[String], name : String, value : String?) -> Unit {
  if value is Some(v) {
    parts.push("\{name}=\{v}")
  }
}

///|
/// The fields an element has, in a fixed order, leaving out those that are unset.
fn show_element(el : @c4.C4Element) -> String {
  let parts = ["alias=\{el.alias_}", "label=\{el.label}"]
  if el.alias_attr is Some(a) {
    parts.push("aliasAttr=\{a.key}:\{a.value}")
  }
  if el.label_attr is Some(a) {
    parts.push("labelAttr=\{a.key}:\{a.value}")
  }
  if el.kind != "" {
    parts.push("kind=\{el.kind}")
  }
  opt(parts, "parent", el.parent.map(p => p.alias_))
  opt(parts, "type", el.type_)
  opt(parts, "descr", el.descr)
  opt(parts, "techn", el.techn)
  opt(parts, "sprite", el.sprite)
  opt(parts, "tags", el.tags)
  opt(parts, "link", el.link)
  opt(parts, "bgColor", el.bg_color)
  opt(parts, "fontColor", el.font_color)
  opt(parts, "borderColor", el.border_color)
  opt(parts, "shadowing", el.shadowing)
  opt(parts, "shape", el.shape)
  opt(parts, "legendText", el.legend_text)
  opt(parts, "legendSprite", el.legend_sprite)
  opt(parts, "nodeType", el.node_type)
  if el.extra is Some(extra) {
    let pairs = []
    for key, value in extra {
      pairs.push("\{key}:\{value}")
    }
    parts.push("extra={\{pairs.join(",")}}")
  }
  parts.join(" ")
}

///|
fn show_rel(rel : @c4.C4Rel) -> String {
  let parts = [
    "type=\{rel.type_}",
    "from=\{rel.from}",
    "to=\{rel.to}",
    "label=\{rel.label}",
  ]
  if rel.from_attr is Some(a) {
    parts.push("fromAttr=\{a.key}:\{a.value}")
  }
  if rel.to_attr is Some(a) {
    parts.push("toAttr=\{a.key}:\{a.value}")
  }
  if rel.label_attr is Some(a) {
    parts.push("labelAttr=\{a.key}:\{a.value}")
  }
  opt(parts, "techn", rel.techn)
  opt(parts, "descr", rel.descr)
  opt(parts, "sprite", rel.sprite)
  opt(parts, "tags", rel.tags)
  opt(parts, "link", rel.link)
  opt(parts, "textColor", rel.text_color)
  opt(parts, "lineColor", rel.line_color)
  opt(parts, "offsetX", rel.offset_x.map(x => x.to_string()))
  opt(parts, "offsetY", rel.offset_y.map(y => y.to_string()))
  if rel.extra is Some(extra) {
    let pairs = []
    for key, value in extra {
      pairs.push("\{key}:\{value}")
    }
    parts.push("extra={\{pairs.join(",")}}")
  }
  parts.join(" ")
}

///|
fn unset(value : String?) -> String {
  value.unwrap_or("<unset>")
}

///|
fn rows(db : @c4.C4Db) -> String {
  "\{db.shape_in_row} \{db.boundary_in_row}"
}

///|
fn shapes_of(db : @c4.C4Db) -> String {
  db.shapes.map(show_element).join("\n")
}

///|
test "starts with the unnamed top-level boundary and Mermaid's row sizes" {
  let db = @c4.C4Db::new()
  inspect(
    db.boundaries.map(show_element).join("\n"),
    content="alias=global label=global type=global",
  )
  inspect(rows(db), content="4 2")
  inspect(unset(db.title), content="<unset>")
  inspect(
    unset(@c4.C4Db::new(title="From front matter").title),
    content="From front matter",
  )
  inspect(unset(@c4.C4Db::new(title="").title), content="<unset>")
}

///|
test "sets the header, the title and the description" {
  let db = @c4.C4Db::new(title="Front")
  db.set_c4_type("C4Dynamic")
  db.set_title("Own")
  db.set_acc_description("two\n   lines\n\n\t and\nmore")
  inspect(unset(db.c4_type), content="C4Dynamic")
  inspect(unset(db.title), content="Own")
  inspect(unset(db.acc_descr), content="two\nlines\nand\nmore")
}

///|
test "fills a person or system from its positional arguments" {
  let db = @c4.C4Db::new()
  db.add_person_or_system("person", [
    t("a"),
    t("A"),
    t("d"),
    t("s"),
    t("tags"),
    t("l"),
  ])
  db.add_person_or_system("external_system", [t("b")])
  inspect(
    shapes_of(db),
    content=(
      #|alias=a label=A kind=person parent=global descr=d sprite=s tags=tags link=l
      #|alias=b label= kind=external_system parent=global descr=
    ),
  )
}

///|
test "fills a container's technology before its description" {
  let db = @c4.C4Db::new()
  db.add_container("container", [t("c"), t("C"), t("Go"), t("d"), t("s")])
  db.add_component("component_db", [t("k"), t("K")])
  db.add_container("container", [t("n"), t("N"), kv("descr", "named")])
  db.add_container("container", [t("m"), t("M"), kv("techn", "Java")])
  inspect(
    shapes_of(db),
    content=(
      #|alias=c label=C kind=container parent=global descr=d techn=Go sprite=s
      #|alias=k label=K kind=component_db parent=global descr= techn=
      #|alias=n label=N kind=container parent=global descr=named
      #|alias=m label=M kind=container parent=global descr= techn=Java
    ),
  )
}

///|
test "applies a named argument to the field it names, whichever slot it is in" {
  let db = @c4.C4Db::new()
  db.add_person_or_system("person", [t("a"), kv("sprite", "users")])
  db.add_person_or_system("system", [kv("tags", "t"), t("Anonymous")])
  db.add_person_or_system("system", [kv("label", "x"), t("Second anonymous")])
  db.add_person_or_system("system", [
    t("b"),
    kv("label", "Named label"),
    kv("unknown", "kept"),
    kv("__proto__", "safe"),
    kv("unknown", "again"),
  ])
  inspect(
    shapes_of(db),
    content=(
      #|alias=a label= labelAttr=sprite:users kind=person parent=global descr= sprite=users
      #|alias= label=Anonymous aliasAttr=tags:t kind=system parent=global descr= tags=t
      #|alias= label=Second anonymous aliasAttr=label:x kind=system parent=global descr=
      #|alias=b label=Named label labelAttr=label:Named label kind=system parent=global extra={unknown:again,__proto__:safe}
    ),
  )
}

///|
test "merges a repeated alias and keeps its first position" {
  let db = @c4.C4Db::new()
  db.add_person_or_system("system", [t("a"), t("First"), t("d1")])
  db.add_person_or_system("system", [t("b"), t("B")])
  db.add_person_or_system_boundary([t("x"), t("X")])
  db.add_person_or_system("person", [t("a"), t("Second")])
  db.pop_boundary_parse_stack()
  inspect(
    shapes_of(db),
    content=(
      #|alias=a label=Second kind=person parent=x descr=d1
      #|alias=b label=B kind=system parent=global descr=
    ),
  )
}

///|
test "opens boundaries of each kind and nests them" {
  let db = @c4.C4Db::new()
  db.add_person_or_system_boundary([t("e"), t("E"), t("ENTERPRISE")])
  db.add_person_or_system_boundary([
    t("s"),
    t("S"),
    t("custom"),
    t("tg"),
    t("lk"),
  ])
  db.add_container_boundary([t("c"), t("C")])
  db.pop_boundary_parse_stack()
  db.add_container_boundary([t("c2"), kv("type", "named")])
  db.pop_boundary_parse_stack()
  db.pop_boundary_parse_stack()
  db.add_deployment_node("nodeL", [
    t("n"),
    t("N"),
    t("Linux"),
    t("A machine"),
    t("sp"),
    t("tg"),
    t("lk"),
  ])
  db.add_deployment_node("node", [t("m"), t("M")])
  db.add_person_or_system("container", [t("app"), t("App")])
  db.pop_boundary_parse_stack()
  db.pop_boundary_parse_stack()
  db.pop_boundary_parse_stack()
  db.pop_boundary_parse_stack()
  db.add_person_or_system("system", [t("top"), t("Top")])
  inspect(
    db.boundaries.map(show_element).join("\n"),
    content=(
      #|alias=global label=global type=global
      #|alias=e label=E parent=global type=ENTERPRISE
      #|alias=s label=S parent=e type=custom tags=tg link=lk
      #|alias=c label=C parent=s type=container
      #|alias=c2 label= labelAttr=type:named parent=s type=container
      #|alias=n label=N parent=e type=Linux descr=A machine sprite=sp tags=tg link=lk nodeType=nodeL
      #|alias=m label=M parent=n type=node descr= nodeType=node
    ),
  )
  inspect(
    shapes_of(db),
    content=(
      #|alias=app label=App kind=container parent=m descr=
      #|alias=top label=Top kind=system parent=global descr=
    ),
  )
}

///|
test "moves a boundary opened again inside itself" {
  let db = @c4.C4Db::new()
  db.add_person_or_system_boundary([t("a"), t("A")])
  db.add_person_or_system_boundary([t("b"), t("B")])
  db.add_person_or_system_boundary([t("a"), t("A again")])
  db.add_person_or_system("system", [t("lost"), t("Lost")])
  inspect(
    db.boundaries.map(show_element).join("\n"),
    content=(
      #|alias=global label=global type=global
      #|alias=a label=A again parent=b type=system
      #|alias=b label=B parent=a type=system
    ),
  )
}

///|
test "finds shapes before boundaries by alias" {
  let db = @c4.C4Db::new()
  db.add_person_or_system_boundary([t("b1"), t("Bank")])
  db.add_person_or_system("system", [t("s"), t("S")])
  db.pop_boundary_parse_stack()
  inspect(
    unset(db.get_c4_shape("b1").map(show_element)),
    content="alias=b1 label=Bank parent=global type=system",
  )
  inspect(unset(db.get_c4_shape("s").map(e => e.kind)), content="system")
  inspect(
    unset(db.get_c4_shape("missing").map(show_element)),
    content="<unset>",
  )
  inspect(unset(db.get_c4_shape("global").map(show_element)), content="<unset>")
}

///|
test "adds relations, merging one between the same ends" {
  let db = @c4.C4Db::new()
  db.add_rel("rel", [t("a"), t("b"), t("one"), t("t")])
  db.add_rel("birel", [t("a"), t("b"), t("two")])
  db.add_rel("rel", [t("b"), t("a")])
  db.add_rel("rel_u", [kv("x", "y"), t("a"), t("named end")])
  db.add_rel("rel_u", [kv("x", "y"), t("a"), t("named end")])
  db.add_rel("rel", [
    t("a"),
    t("c"),
    kv("techn", "HTTP"),
    t("d"),
    t("s"),
    t("tg"),
    t("lk"),
    kv("offsetX", "12px"),
  ])
  db.add_rel("rel", [
    t("c"),
    t("a"),
    t("x"),
    kv("offsetY", "-3"),
    kv("other", "v"),
  ])
  inspect(
    db.rels.map(show_rel).join("\n"),
    content=(
      #|type=birel from=a to=b label=two techn=t descr=
      #|type=rel_u from= to=a label=named end fromAttr=x:y techn= descr=
      #|type=rel_u from= to=a label=named end fromAttr=x:y techn= descr=
      #|type=rel from=a to=c label= labelAttr=techn:HTTP techn=d descr=s sprite=tg tags=lk offsetX=12
      #|type=rel from=c to=a label=x offsetY=-3 extra={other:v}
    ),
  )
}

///|
test "styles shapes and boundaries by alias" {
  let db = @c4.C4Db::new()
  db.add_person_or_system("person", [t("a"), t("A")])
  db.add_person_or_system_boundary([t("b"), t("B")])
  db.pop_boundary_parse_stack()
  db.update_el_style([
    t("a"),
    kv("fontColor", "red"),
    kv("bgColor", "grey"),
    kv("borderColor", "blue"),
    kv("legendText", "L"),
    kv("legendSprite", "S"),
    kv("shadowing", "true"),
  ])
  db.update_el_style([
    t("b"),
    t("#eee"),
    t("green"),
    t("orange"),
    t("false"),
    t("Person"),
    t("sp"),
    t("tc"),
    t("lt"),
    t("ls"),
  ])
  db.update_el_style([t("nobody"), t("red")])
  db.update_el_style([kv("a", "b"), t("red")])
  inspect(
    shapes_of(db),
    content="alias=a label=A kind=person parent=global descr= bgColor=grey fontColor=red borderColor=blue shadowing=true legendText=L legendSprite=S",
  )
  inspect(
    show_element(db.boundaries[1]),
    content="alias=b label=B parent=global type=system techn=tc sprite=sp bgColor=#eee fontColor=green borderColor=orange shadowing=false shape=Person legendText=lt legendSprite=ls",
  )
}

///|
test "styles relations and reads offsets as parseInt does" {
  let db = @c4.C4Db::new()
  db.add_rel("rel", [t("a"), t("b"), t("x")])
  db.add_rel("rel", [t("c"), t("d"), t("y")])
  db.add_rel("rel", [t("e"), t("f"), t("z")])
  db.update_rel_style([t("a"), t("b"), t("red"), t("blue"), t("30"), t("-10")])
  db.update_rel_style([
    t("c"),
    t("d"),
    kv("offsetX", " 0x1A"),
    kv("offsetY", "-7.9e3"),
    kv("lineColor", "blue"),
    kv("textColor", "red"),
  ])
  db.update_rel_style([t("e"), t("f"), t(""), t(""), t("abc"), t("+5")])
  db.update_rel_style([t("a"), t("missing"), t("green")])
  inspect(
    db.rels.map(show_rel).join("\n"),
    content=(
      #|type=rel from=a to=b label=x techn= descr= textColor=red lineColor=blue offsetX=30 offsetY=-10
      #|type=rel from=c to=d label=y techn= descr= textColor=red lineColor=blue offsetX=26 offsetY=-7
      #|type=rel from=e to=f label=z techn= descr= textColor= lineColor= offsetX=NaN offsetY=5
    ),
  )
}

///|
test "sets row sizes from their slots, ignoring values below one" {
  let db = @c4.C4Db::new()
  db.update_layout_config([t("0"), t("-3")])
  inspect(rows(db), content="4 2")
  db.update_layout_config([kv("c4BoundaryInRow", "3")])
  inspect(rows(db), content="3 2")
  db.update_layout_config([t("x"), t("5 shapes")])
  inspect(rows(db), content="3 5")
  db.update_layout_config([t("99999999999")])
  inspect(rows(db), content="99999999999 5")
}
