///|
fn dump_node(
  node : @treeview.TreeNode,
  depth : Int32,
  out : Array[String],
) -> Unit {
  let kind = match node.node_type {
    File => "file"
    Directory => "dir"
  }
  let extras = [
    node.css_class.map(c => "class=\{c}"),
    node.icon.map(i => "icon=\{i}"),
    node.description.map(d => "desc=\{d}"),
  ].filter_map(x => x)
  let suffix = if extras.is_empty() { "" } else { " " + extras.join(" ") }
  out.push(
    "\{"  ".repeat(depth)}#\{node.id} L\{node.level} \{kind} \{node.name}\{suffix}",
  )
  for child in node.children {
    dump_node(child, depth + 1, out)
  }
}

///|
fn dump(root : @treeview.TreeNode) -> String {
  let out = []
  dump_node(root, 0, out)
  out.join("\n")
}

///|
fn model(source : String, title? : String) -> String {
  let ast = @treeview.read_treeview(source) catch {
    @errors.PeleError(failure) => return failure.message
  }
  let built = @treeview.build_treeview(ast, title)
  [
    "title=\{built.title.unwrap_or("-")} accTitle=\{built.acc_title.unwrap_or("-").escape()} accDescr=\{built.acc_descr.unwrap_or("-").escape()} count=\{built.count}",
    dump(built.root),
  ].join("\n")
}

///|
test "a new database holds only the root" {
  let db = @treeview.TreeViewDb::new()
  inspect(db.count, content="1")
  inspect(dump(db.root), content="#0 L-1 dir /")
}

///|
test "entries nest below the nearest earlier entry that is indented less" {
  let db = @treeview.TreeViewDb::new()
  db.add_node(0, "src", Directory)
  db.add_node(4, "components", Directory)
  db.add_node(8, "Button.tsx", File)
  db.add_node(8, "Header.tsx", File)
  db.add_node(4, "utils", Directory)
  db.add_node(8, "helpers.ts", File)
  db.add_node(0, "README.md", File)
  db.add_node(2, "odd", File)
  inspect(db.count, content="9")
  inspect(
    dump(db.root),
    content=(
      #|#0 L-1 dir /
      #|  #1 L0 dir src
      #|    #2 L4 dir components
      #|      #3 L8 file Button.tsx
      #|      #4 L8 file Header.tsx
      #|    #5 L4 dir utils
      #|      #6 L8 file helpers.ts
      #|  #7 L0 file README.md
      #|    #8 L2 file odd
    ),
  )
}

///|
test "a class, an icon, and a description are stored" {
  let db = @treeview.TreeViewDb::new()
  db.add_node(
    0,
    "App.tsx",
    File,
    css_class="highlight",
    icon="logos:react",
    description="main component",
  )
  db.add_node(0, "a", File, icon="logos:mysql")
  inspect(
    dump(db.root),
    content=(
      #|#0 L-1 dir /
      #|  #1 L0 file App.tsx class=highlight icon=logos:react desc=main component
      #|  #2 L0 file a icon=logos:mysql
    ),
  )
}

///|
test "a trailing slash makes a directory and an empty icon hides the icon" {
  inspect(
    model(
      "treeView-beta\nsrc/\n    index.js icon()\n    \"my folder/\" icon(none) :::x ##\n    y :::\n",
    ),
    content=(
      #|title=- accTitle="-" accDescr="-" count=5
      #|#0 L-1 dir /
      #|  #1 L0 dir src
      #|    #2 L4 file index.js icon=none
      #|    #3 L4 dir my folder class=x icon=none
      #|    #4 L4 file y :::
    ),
  )
}

///|
test "the own title wins over the front matter title, and accessibility text is tidied" {
  inspect(
    model("treeView-beta\ntitle Own\n  a\n", title="Front"),
    content=(
      #|title=Own accTitle="-" accDescr="-" count=2
      #|#0 L-1 dir /
      #|  #1 L2 file a
    ),
  )
  inspect(
    model("treeView-beta\n  a\n", title="Front"),
    content=(
      #|title=Front accTitle="-" accDescr="-" count=2
      #|#0 L-1 dir /
      #|  #1 L2 file a
    ),
  )
  inspect(
    model("treeView-beta\naccTitle: Acc\naccDescr {\n  one\n    two\n}\na\n"),
    content=(
      #|title=- accTitle="Acc" accDescr="one\ntwo" count=2
      #|#0 L-1 dir /
      #|  #1 L0 file a
    ),
  )
}

///|
test "box-drawing input gives the same model as indented input" {
  inspect(
    model(
      "treeView-beta\n├── src/\n│   ├── index.ts\n│   └── utils.ts\n├── package.json\n└── README.md\n",
    ) ==
    model(
      "treeView-beta\n    src/\n        index.ts\n        utils.ts\n    package.json\n    README.md\n",
    ),
    content="true",
  )
}

///|
fn failure_of(source : String) -> @errors.Failure {
  try {
    @treeview.read_treeview(source) |> ignore
    abort("expected a failure")
  } catch {
    @errors.PeleError(failure) => failure
  }
}

///|
test "box-drawing errors name the lines of the original text" {
  let unclosed = failure_of(
    "treeView-beta\n│\n├── src/\n│\n│   └── \"a\n",
  )
  inspect("\{unclosed.line}:\{unclosed.column}", content="5:9")
  inspect(
    unclosed.message,
    content=(
      #|Lexical error on line 5. Unrecognized text.
      #|        "a
      #|--------^
    ),
  )
  inspect(
    failure_of("treeView-beta\n├── \n").message,
    content="Line 2: Empty node — expected a filename or directory name after the box-drawing prefix",
  )
  inspect(
    failure_of("treeView-beta\n├── a\n   b\n").message,
    content="Line 3: Unexpected indentation without box-drawing characters. In box-drawing format, use ├── or └── prefixes for indented nodes.",
  )
}
