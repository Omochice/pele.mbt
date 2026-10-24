///|
fn describe_node(node : @treemap.TreemapNode) -> String {
  let out = StringBuilder()
  out.write_string(node.name)
  match node.children {
    Some(children) =>
      out.write_string("{\{children.map(describe_node).join(", ")}}")
    None => out.write_string("=\{node.value.unwrap_or(-1.0)}")
  }
  if node.class_selector is Some(name) {
    out.write_string(":::\{name}")
  }
  if node.css_compiled_styles is Some(styles) {
    out.write_string(" [\{styles.map(s => s.escape()).join("|")}]")
  }
  out.to_string()
}

///|
fn describe_nodes(nodes : Array[@treemap.TreemapNode]) -> String {
  nodes.map(describe_node).join(", ")
}

///|
fn item(
  level : Int32,
  name : String,
  leaf~ : Bool = false,
  value? : Double,
) -> @treemap.TreemapItem {
  { level, name, leaf, value, class_selector: None, css_compiled_styles: None, }
}

///|
fn built(source : String) -> String {
  let ast = @treemap.parse_treemap(source + "\n") catch {
    @errors.PeleError(failure) => return "error: \{failure.message}"
  }
  describe_nodes(@treemap.build_treemap(ast, None).roots)
}

///|
test "rows become a hierarchy by their indentation" {
  inspect(
    describe_nodes(
      @treemap.build_hierarchy([
        item(0, "Root"),
        item(4, "Branch 1"),
        item(8, "Leaf 1.1", leaf=true, value=10),
        item(8, "Leaf 1.2", leaf=true, value=15),
        item(4, "Branch 2"),
        item(8, "Leaf 2.1", leaf=true, value=20),
        item(8, "Leaf 2.2", leaf=true, value=25),
        item(8, "Leaf 2.3", leaf=true, value=30),
      ]),
    ),
    content="Root{Branch 1{Leaf 1.1=10, Leaf 1.2=15}, Branch 2{Leaf 2.1=20, Leaf 2.2=25, Leaf 2.3=30}}",
  )
}

///|
test "no rows make no nodes" {
  inspect(describe_nodes(@treemap.build_hierarchy([])), content="")
}

///|
test "rows at the same level are all roots, and a section with no rows under it is empty" {
  inspect(
    describe_nodes(
      @treemap.build_hierarchy([item(0, "Root 1"), item(0, "Root 2")]),
    ),
    content="Root 1{}, Root 2{}",
  )
}

///|
test "a row returns to the nearest section that is indented less" {
  inspect(
    describe_nodes(
      @treemap.build_hierarchy([
        item(0, "Root"),
        item(2, "Level 1"),
        item(4, "Level 2"),
        item(6, "Leaf 1", leaf=true, value=10),
        item(4, "Level 2 again"),
        item(6, "Leaf 2", leaf=true, value=20),
      ]),
    ),
    content="Root{Level 1{Level 2{Leaf 1=10}, Level 2 again{Leaf 2=20}}}",
  )
}

///|
test "indentation only has to be deeper, not deeper by a fixed step" {
  inspect(
    built(
      "treemap\n\"A\"\n  \"B\"\n    \"c\": 1\n  \"d\": 2\n\"E\"\n      \"f\": 3\n \"g\": 4",
    ),
    content="A{B{c=1}, d=2}, E{f=3, g=4}",
  )
}

///|
test "a leaf never has children, so the rows after it belong to its section" {
  inspect(built("treemap\n\"s\"\n \"a\": 1\n  \"b\": 2"), content="s{a=1, b=2}")
}
