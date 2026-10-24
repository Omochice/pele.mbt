///|
/// One line per node: its id, node id, level, type, section, class, icon and description.
fn dump(source : String) -> String {
  let model = @mindmap.parse_mindmap(source + "\n", None) catch {
    @errors.PeleError(failure) =>
      return "\{failure.code.to_string()}: \{failure.message}"
  }
  let lines = model.nodes.map(n => {
    let section = match n.section {
      Some(s) => s.to_string()
      None => "-"
    }
    "\{n.id} \{n.node_id} L\{n.level} T\{n.node_type} S\{section} C\{n.class_.unwrap_or("-")} I\{n.icon.unwrap_or("-")} \{n.descr.escape()}"
  })
  lines.join("\n")
}

///|
test "a simple root is the only node" {
  inspect(dump("mindmap\n    root"), content="0 root L0 T0 S- C- I- \"root\"")
  inspect(dump("mindmap\n    (root)"), content="0 root L0 T1 S- C- I- \"root\"")
}

///|
test "a root takes the level it is written at as its own" {
  inspect(
    dump("mindmap\n    root\n      child"),
    content=(
      #|0 root L0 T0 S- C- I- "root"
      #|1 child L2 T0 S0 C- I- "child"
    ),
  )
}

///|
test "children are collected under the nearest shallower node" {
  let model = @mindmap.parse_mindmap(
    "mindmap\n    root\n      child1\n        leaf1\n      child2\n",
    None,
  )
  let root = model.nodes[0]
  assert_eq(root.children.map(n => n.descr), ["child1", "child2"])
  assert_eq(root.children[0].children.map(n => n.descr), ["leaf1"])
  assert_true(root.is_root)
  assert_false(root.children[0].is_root)
}

///|
test "a mindmap with no node has no root" {
  inspect(dump("mindmap\n\n"), content="")
}

///|
test "a second root is rejected with Mermaid's message" {
  inspect(
    dump("mindmap\n    root\n    fakeRoot"),
    content="semantic: There can be only one root. No parent could be found for (\"fakeRoot\")",
  )
  inspect(
    dump("mindmap\n          root\n        fakeRoot\n    realRootWrongPlace"),
    content="semantic: There can be only one root. No parent could be found for (\"fakeRoot\")",
  )
  inspect(
    dump("mindmap\n    root\n  shallower"),
    content="semantic: There can be only one root. No parent could be found for (\"shallower\")",
  )
}

///|
test "the error of a second root names the mindmap diagram" {
  try @mindmap.parse_mindmap("mindmap\n  root\n  other\n", None) catch {
    @errors.PeleError(failure) => {
      assert_eq(failure.kind, Some("mindmap"))
      assert_eq(failure.code.to_string(), "semantic")
    }
  } noraise {
    _ => fail("expected an error")
  }
}

///|
test "each pair of delimiters gives its node type" {
  inspect(
    dump(
      "mindmap\n root\n  a[Square]\n  b(Rounded)\n  c((Circle))\n  d))Bang((\n  e)Cloud(\n  f{{Hexagon}}\n  Plain",
    ),
    content=(
      #|0 root L0 T0 S- C- I- "root"
      #|1 a L1 T2 S0 C- I- "Square"
      #|2 b L1 T1 S1 C- I- "Rounded"
      #|3 c L1 T3 S2 C- I- "Circle"
      #|4 d L1 T5 S3 C- I- "Bang"
      #|5 e L1 T4 S4 C- I- "Cloud"
      #|6 f L1 T6 S5 C- I- "Hexagon"
      #|7 Plain L1 T0 S6 C- I- "Plain"
    ),
  )
}

///|
test "a delimiter pairs with any closing one, as in Mermaid" {
  inspect(
    dump("mindmap\n  root\n    a[x)\n    b(x]\n    c(-x-)\n    -)x(-"),
    content=(
      #|0 root L0 T0 S- C- I- "root"
      #|1 a L2 T2 S0 C- I- "x"
      #|2 b L2 T4 S1 C- I- "x"
      #|3 c L2 T0 S2 C- I- "x-"
      #|4 x L2 T0 S3 C- I- "x"
    ),
  )
}

///|
test "an id comes with the shape and without it the text is the id" {
  inspect(
    dump("mindmap\n    root[The root]\n      theId(child1)"),
    content=(
      #|0 root L0 T2 S- C- I- "The root"
      #|1 theId L2 T1 S0 C- I- "child1"
    ),
  )
}

///|
test "string descriptions may hold the delimiters" {
  inspect(
    dump(
      "mindmap\n    root[\"String containing []\"]\n      child1[\"String containing ()\"]",
    ),
    content=(
      #|0 root L0 T2 S- C- I- "String containing []"
      #|1 child1 L2 T2 S0 C- I- "String containing ()"
    ),
  )
}

///|
test "an icon and classes decorate the node before them" {
  inspect(
    dump("mindmap\n    root[The root]\n    ::icon(bomb)\n    :::m-4 p-8\n"),
    content="0 root L0 T2 S- Cm-4 p-8 Ibomb \"The root\"",
  )
  inspect(
    dump("mindmap\n    root[The root]\n    :::m-4 p-8\n    ::icon(bomb)\n"),
    content="0 root L0 T2 S- Cm-4 p-8 Ibomb \"The root\"",
  )
  inspect(
    dump("mindmap\n    root[The root]\n    ::icon(bomb)\n"),
    content="0 root L0 T2 S- C- Ibomb \"The root\"",
  )
}

///|
test "a node can follow a decoration" {
  inspect(
    dump(
      "mindmap\n  root(Root)\n    Child(Child)\n    :::hot\n      a(a)\n      b[New Stuff]",
    ),
    content=(
      #|0 root L0 T1 S- C- I- "Root"
      #|1 Child L2 T1 S0 Chot I- "Child"
      #|2 a L4 T1 S0 C- I- "a"
      #|3 b L4 T2 S0 C- I- "New Stuff"
    ),
  )
}

///|
test "a decoration before any node is ignored" {
  inspect(
    dump("mindmap\n::icon(fa fa-book)\n:::big\nroot"),
    content="0 root L0 T0 S- C- I- \"root\"",
  )
}

///|
test "an empty decoration leaves the node as it was" {
  inspect(
    dump("mindmap\nroot\n::icon()\n:::\n"),
    content="0 root L0 T0 S- C- I- \"root\"",
  )
}

///|
test "empty rows, spaces and comments do not interfere" {
  let expected =
    #|0 root L0 T0 S- C- I- "root"
    #|1 A L1 T0 S0 C- I- "A"
    #|2 B L1 T0 S1 C- I- "B"
  inspect(dump("mindmap\nroot\n A\n \n\n B"), content=expected)
  inspect(dump("\n \nmindmap\nroot\n A\n \n\n B"), content=expected)
  inspect(dump("\n\n\nmindmap\nroot\n A\n \n\n B"), content=expected)
  inspect(dump("mindmap\nroot\n A\n %% comment\n B"), content=expected)
  inspect(dump("mindmap\nroot\n A\n\n B"), content=expected)
}

///|
test "a trailing comment stays out of a shaped node but not out of a bare one" {
  inspect(
    dump("mindmap\n  root(Root) %% note\n    a"),
    content=(
      #|0 root L0 T1 S- C- I- "Root"
      #|1 a L2 T0 S0 C- I- "a"
    ),
  )
  inspect(
    dump("mindmap\n  root %% note\n    a"),
    content=(
      #|0 root %% note L0 T0 S- C- I- "root %% note"
      #|1 a L2 T0 S0 C- I- "a"
    ),
  )
}

///|
test "unclear indentation follows Mermaid" {
  inspect(
    dump("mindmap\nRoot\n    A\n        B\n      C\n   D"),
    content=(
      #|0 Root L0 T0 S- C- I- "Root"
      #|1 A L4 T0 S0 C- I- "A"
      #|2 B L8 T0 S0 C- I- "B"
      #|3 C L6 T0 S0 C- I- "C"
      #|4 D L3 T0 S1 C- I- "D"
    ),
  )
  let model = @mindmap.parse_mindmap(
    "mindmap\nRoot\n    A\n        B\n      C\n   D\n",
    None,
  )
  assert_eq(model.nodes[1].children.map(n => n.node_id), ["B", "C"])
  assert_eq(model.nodes[0].children.map(n => n.node_id), ["A", "D"])
}

///|
test "sections count the first-level branches and wrap after eleven" {
  let source = StringBuilder()
  source.write_string("mindmap\n  root\n")
  for i in 0..<13 {
    source.write_string("    b\{i}\n      leaf\{i}\n")
  }
  let model = @mindmap.parse_mindmap(source.to_string(), None)
  let section = id => {
    model.nodes.iter().find_first(n => n.node_id == id).unwrap().section
  }
  assert_eq(section("b10"), Some(10))
  assert_eq(section("b11"), Some(0))
  assert_eq(section("leaf12"), Some(1))
  assert_eq(model.nodes[0].section, None)
}

///|
test "the title of the front matter is kept" {
  let model = @mindmap.parse_mindmap("mindmap\nroot\n", Some("Plans"))
  assert_eq(model.title, Some("Plans"))
}

///|
test "text the grammar rejects is a syntax error" {
  try @mindmap.parse_mindmap("mindmap\n  root\n  ::icon(", None) catch {
    @errors.PeleError(failure) => assert_eq(failure.code.to_string(), "syntax")
  } noraise {
    _ => fail("expected an error")
  }
}
