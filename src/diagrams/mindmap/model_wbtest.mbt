///|
fn add(
  db : MindmapDb,
  level : Int32,
  id : String,
  descr : String,
  node_type : Int32,
) -> Unit raise @errors.PeleError {
  @common.OutlineDb::add_node(db, level, id, descr, node_type, None)
}

///|
fn decorate(db : MindmapDb, decoration : @common.Decoration) -> Unit {
  @common.OutlineDb::decorate_node(db, decoration)
}

///|
/// The links of a database as `parent->child` by node id, in the order the nodes were added.
fn links(db : MindmapDb) -> Array[String] {
  let links = []
  for node in db.nodes {
    for child in node.children {
      links.push("\{node.id}->\{child.id}")
    }
  }
  links
}

///|
test "nodes added by level form a tree" {
  let db = MindmapDb::new()
  add(db, 0, "root", "Root Node", 0)
  add(db, 1, "child1", "Child 1", 0)
  add(db, 2, "grandchild1", "Grandchild 1", 0)
  add(db, 2, "grandchild2", "Grandchild 2", 0)
  add(db, 1, "child2", "Child 2", 0)
  assert_eq(db.nodes.map(n => n.level), [0, 1, 2, 2, 1])
  assert_eq(links(db), ["0->1", "0->4", "1->2", "1->3"])
}

///|
test "the root takes any level as its own" {
  let db = MindmapDb::new()
  add(db, 4, "root", "Root", 0)
  add(db, 6, "a", "A", 0)
  add(db, 5, "b", "B", 0)
  assert_eq(db.nodes.map(n => n.level), [0, 2, 1])
  assert_eq(links(db), ["0->1", "0->2"])
}

///|
test "a node shallower than the root has no parent" {
  let db = MindmapDb::new()
  add(db, 4, "root", "Root", 0)
  try add(db, 2, "x", "X", 0) catch {
    @errors.PeleError(failure) =>
      assert_eq(
        failure.message,
        "There can be only one root. No parent could be found for (\"X\")",
      )
  } noraise {
    _ => fail("expected an error")
  }
  assert_eq(db.nodes.length(), 1)
}

///|
test "decorations apply to the node added last" {
  let db = MindmapDb::new()
  decorate(db, Icon("ignored"))
  add(db, 0, "root", "Root", 2)
  add(db, 1, "a", "A", 0)
  decorate(db, Icon("star"))
  decorate(db, Class("custom-class"))
  decorate(db, Class(""))
  assert_eq(db.nodes[0].icon, None)
  assert_eq(db.nodes[1].icon, Some("star"))
  assert_eq(db.nodes[1].class_, Some("custom-class"))
}

///|
test "a later decoration of the same kind replaces the earlier" {
  let db = MindmapDb::new()
  add(db, 0, "root", "Root", 0)
  decorate(db, Class("first"))
  decorate(db, Class("second"))
  assert_eq(db.nodes[0].class_, Some("second"))
}
