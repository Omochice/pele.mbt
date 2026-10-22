///|
fn converted(lines : Array[String]) -> String {
  let result = @treeview.preprocess_box_drawing(lines.join("\n")) catch {
    @errors.PeleError(failure) => return failure.message
  }
  result.text
}

///|
fn line_map(lines : Array[String]) -> String {
  let result = @treeview.preprocess_box_drawing(lines.join("\n")) catch {
    @errors.PeleError(failure) => return failure.message
  }
  result.line_map.iter().map(pair => "\{pair.0}:\{pair.1}").collect().join(",")
}

///|
test "box-drawing characters are told from plain text" {
  inspect(
    [
      ["├── file.txt", "└── other.txt"],
      ["┣━━ file.txt", "┗━━ other.txt"],
      ["│   └── file.txt"],
      ["    file.txt", "        nested.txt"],
      ["", "   "],
      ["root/", "file.txt"],
    ].map(lines => @treeview.is_box_drawing_format(lines)),
    content="[true, true, true, false, false, false]",
  )
}

///|
test "indented text and text without the keyword pass through" {
  let indented = "treeView-beta\nroot/\n    src/\n        index.js"
  let result = @treeview.preprocess_box_drawing(indented)
  inspect(result.text == indented && result.line_map.is_empty(), content="true")
  let plain = "not-a-keyword\n\u{251c}\u{2500}\u{2500} some text"
  let kept = @treeview.preprocess_box_drawing(plain)
  inspect(kept.text == plain && kept.line_map.is_empty(), content="true")
}

///|
test "a tree command output becomes indentation" {
  inspect(
    converted([
      "treeView-beta", "my-project/", "├── src/", "│   ├── components/",
      "│   │   └── MyComponent.js", "│   ├── index.css", "│   └── index.js",
      "├── package.json", "└── README.md",
    ]),
    content=(
      #|treeView-beta
      #|my-project/
      #|    src/
      #|        components/
      #|            MyComponent.js
      #|        index.css
      #|        index.js
      #|    package.json
      #|    README.md
    ),
  )
  inspect(
    converted([
      "treeView-beta", "root/", "├── a/", "│   └── b.txt", "└── c/",
      "    └── d.txt",
    ]),
    content=(
      #|treeView-beta
      #|root/
      #|    a/
      #|        b.txt
      #|    c/
      #|        d.txt
    ),
  )
}

///|
test "the width of a segment is inferred from the first branch that is not at the start" {
  inspect(
    converted([
      "treeView-beta", "root/", "  ├── a/", "  │   └── b", "  └── c",
    ]),
    content=(
      #|treeView-beta
      #|root/
      #|        a/
      #|            b
      #|        c
    ),
  )
}

///|
test "dashes and the space after a branch are optional" {
  inspect(
    converted([
      "treeView-beta", "├─── a", "├──b", "├───── c", "└─ d",
      "┣━━━ e",
    ]),
    content=(
      #|treeView-beta
      #|    a
      #|    b
      #|    c
      #|    d
      #|    e
    ),
  )
}

///|
test "annotations, comments, blank lines and metadata are kept" {
  inspect(
    converted([
      "treeView-beta", "title My Tree", "accTitle: Accessible", "accDescr: Described",
      "%% a comment", "", "├── App.tsx :::highlight icon(react) ## main component",
    ]),
    content=(
      #|treeView-beta
      #|title My Tree
      #|accTitle: Accessible
      #|accDescr: Described
      #|%% a comment
      #|
      #|    App.tsx :::highlight icon(react) ## main component
    ),
  )
}

///|
test "decoration lines are dropped and the line map follows" {
  inspect(
    converted(["treeView-beta", "├── a.txt", "│", "└── b.txt"]),
    content=(
      #|treeView-beta
      #|    a.txt
      #|    b.txt
    ),
  )
  inspect(
    line_map(["treeView-beta", "├── a.txt", "│", "└── b.txt"]),
    content="1:1,2:2,3:4",
  )
}

///|
test "tabs count as four spaces" {
  inspect(
    converted(["treeView-beta", "├──\tfile.txt", "\t└── nested"]),
    content=(
      #|treeView-beta
      #|    file.txt
      #|        nested
    ),
  )
}

///|
test "a name that contains a box character is a root entry" {
  inspect(
    converted(["treeView-beta", "Section \u{2500} A.txt", "├── b"]),
    content=(
      #|treeView-beta
      #|Section ─ A.txt
      #|    b
    ),
  )
}

///|
test "an empty node and stray indentation name the original line" {
  inspect(
    converted(["treeView-beta", "root/", "├── src/", "│   └── "]),
    content="Line 4: Empty node — expected a filename or directory name after the box-drawing prefix",
  )
  inspect(
    converted([
      "treeView-beta", "├── src/", "    index.js", "└── README.md",
    ]),
    content="Line 3: Unexpected indentation without box-drawing characters. In box-drawing format, use ├── or └── prefixes for indented nodes.",
  )
}

///|
test "line numbers in a message are remapped" {
  let map = { 1: 1, 2: 3, 3: 5 }
  inspect(
    @treeview.remap_error_lines("Error at line 2: bad syntax", map),
    content="Error at line 3: bad syntax",
  )
  inspect(
    @treeview.remap_error_lines("Error at line 99: bad syntax", map),
    content="Error at line 99: bad syntax",
  )
  inspect(
    @treeview.remap_error_lines("Errors at line 2 and line 3", map),
    content="Errors at line 3 and line 5",
  )
  inspect(
    @treeview.remap_error_lines("Error at Line 3: bad, outline 2, line 2x", map),
    content="Error at line 5: bad, outline 2, line 2x",
  )
}
