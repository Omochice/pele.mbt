///|
fn optional(value : String?) -> String {
  match value {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
fn node_line(node : @treeview.TreeNodeAst) -> String {
  let indent = match node.indent {
    Some(n) => n.to_string()
    None => "-"
  }
  "\{indent}|\{node.name.escape()}|\{optional(node.class_annotation)}|\{optional(node.icon_annotation)}|\{optional(node.desc_annotation)}"
}

///|
fn ast(source : String) -> String {
  let ast = @treeview.parse_treeview(source) catch {
    @errors.PeleError(failure) => return failure.message
  }
  let head = "title=\{optional(ast.title)} accTitle=\{optional(ast.acc_title)} accDescr=\{optional(ast.acc_descr)}"
  [head, ..ast.nodes.map(node_line)].join("\n")
}

///|
test "an empty tree view has no nodes" {
  inspect(ast("treeView-beta"), content="title=- accTitle=- accDescr=-")
}

///|
test "quoted names lose their quotes and keep their spaces" {
  inspect(
    ast("treeView-beta\n\"Root\"\n    'Child  1'\n        \"\""),
    content=(
      #|title=- accTitle=- accDescr=-
      #|-|"Root"|-|-|-
      #|4|"Child  1"|-|-|-
      #|8|""|-|-|-
    ),
  )
}

///|
test "bare names run to the end of the line or to an annotation" {
  inspect(
    ast(
      "treeView-beta\nsrc/\n    My Documents/ :::highlight\n    But  _  _ton.tsx\n    index.js  \n.dotfile",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|-|"src/"|-|-|-
      #|4|"My Documents/"|"highlight"|-|-
      #|4|"But  _  _ton.tsx"|-|-|-
      #|4|"index.js"|-|-|-
      #|-|".dotfile"|-|-|-
    ),
  )
}

///|
test "annotations are read in any order after a bare or quoted name" {
  inspect(
    ast(
      "treeView-beta\napp.ts icon(none) :::my-class ## entry point\n\"my app.tsx\" :::highlight icon(logos:react) ## main component\nx icon()\ny ##\nz icon(pack:name)",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|-|"app.ts"|"my-class"|"none"|"entry point"
      #|-|"my app.tsx"|"highlight"|"logos:react"|"main component"
      #|-|"x"|-|""|-
      #|-|"y"|-|-|""
      #|-|"z"|-|"pack:name"|-
    ),
  )
}

///|
test "a name may contain text that only looks like an annotation" {
  inspect(
    ast("treeView-beta\na:::b\nc ::: d\nf #g"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|-|"a:::b"|-|-|-
      #|-|"c"|"d"|-|-
      #|-|"f #g"|-|-|-
    ),
  )
}

///|
test "comments are skipped" {
  inspect(
    ast("treeView-beta\n%% this is a comment\nindex.js\nname %% not a comment"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|-|"index.js"|-|-|-
      #|-|"name %% not a comment"|-|-|-
    ),
  )
}

///|
test "a title and accessibility statements come before the nodes" {
  inspect(
    ast(
      "treeView-beta\ntitle My TreeView Diagram\naccTitle: Accessible Title\naccDescr: This is described\n\"Root\"\n  \"Child\"",
    ),
    content=(
      #|title="My TreeView Diagram" accTitle="Accessible Title" accDescr="This is described"
      #|-|"Root"|-|-|-
      #|2|"Child"|-|-|-
    ),
  )
  inspect(
    ast("treeView-beta\naccDescr {\n  line one\n  line two\n}\na"),
    content=(
      #|title=- accTitle=- accDescr="line one\nline two"
      #|-|"a"|-|-|-
    ),
  )
}

///|
test "text after the keyword on its line is not a tree view" {
  inspect(
    ast("treeView-beta title x\n a"),
    content=(
      #|Parse error on line 1:
      #|treeView-beta title x
      #|^
      #|Expecting token of type 'treeView-beta' but found `treeView-beta title x`.
    ),
  )
  inspect(
    ast("treeView-beta  \na"),
    content="Parse error on line 1:\ntreeView-beta  \n^\nExpecting token of type 'treeView-beta' but found `treeView-beta  `.",
  )
}

///|
test "an annotation that does not close is a lexical error" {
  inspect(
    ast("treeView-beta\na\ne icon(\nf"),
    content=(
      #|Lexical error on line 3. Unrecognized text.
      #|e icon(
      #|--^
    ),
  )
  inspect(
    ast("treeView-beta\nh icon(a:)"),
    content=(
      #|Lexical error on line 2. Unrecognized text.
      #|h icon(a:)
      #|--^
    ),
  )
}

///|
test "what is not a name is rejected" {
  inspect(
    ast("treeView-beta\n a\ntitle late"),
    content=(
      #|Parse error on line 3:
      #|title late
      #|^
      #|Expecting a name but found `title late`.
    ),
  )
  inspect(
    ast("treeView-beta\n  \n  a"),
    content=(
      #|Parse error on line 3:
      #|  a
      #|^
      #|Expecting a name but found `  `.
    ),
  )
  inspect(
    ast("treeView-beta\n :::x"),
    content=(
      #|Parse error on line 2:
      #| :::x
      #|^
      #|Expecting a name but found ` :::x`.
    ),
  )
  inspect(
    ast("treeView-beta\n\"open"),
    content=(
      #|Lexical error on line 2. Unrecognized text.
      #|"open
      #|^
    ),
  )
}
