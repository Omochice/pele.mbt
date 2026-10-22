///|
const TREE : String = "treeView-beta\n    my-project/\n        src/\n            index.js\n        package.json\n    README.md\n"

///|
fn drawn(
  source : String,
  max_width? : Double,
) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), max_width, }
  Ok(@core.render([@treeview.treeview], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn svg(source : String, max_width? : Double) -> String {
  match drawn(source, max_width?) {
    Ok(result) => result.svg
    Err(failure) => failure.message
  }
}

///|
fn count(text : String, needle : String) -> Int32 {
  let mut n = 0
  let mut at = @util.index_of(text, needle)
  while at != -1 {
    n += 1
    at = @util.index_of(text, needle, from=at + needle.length())
  }
  n
}

///|
fn numbers_after(text : String, prefix : String) -> Array[String] {
  let found = []
  let mut at = @util.index_of(text, prefix)
  while at != -1 {
    let start = at + prefix.length()
    let end = @util.index_of(text, "\"", from=start)
    found.push(@util.slice(text, start, end~))
    at = @util.index_of(text, prefix, from=end)
  }
  found
}

///|
test "a row per entry, directories in bold, and a guide per parent" {
  let out = svg(TREE)
  inspect(count(out, "class=\"pele-node pele-tree-"), content="5")
  inspect(count(out, "class=\"pele-node pele-tree-dir\""), content="2")
  inspect(
    out.contains(
      "font-weight=\"var(--_hw)\" xml:space=\"preserve\">my-project</text>",
    ),
    content="true",
  )
  inspect(
    out.contains("xml:space=\"preserve\">index.js</text>"),
    content="true",
  )
  inspect(count(out, "<path d=\"M"), content="2")
  inspect(out.contains(">/<"), content="false")
}

///|
test "a small tree with a highlighted entry and a description" {
  inspect(
    svg("treeView-beta\n    src/\n        a\n        b :::highlight ## note\n"),
    content="<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-treeView\" viewBox=\"0 0 101 100\" width=\"101\" height=\"100\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"treeView\"><g class=\"pele-tree-guides\" fill=\"none\" stroke=\"var(--_b)\" stroke-width=\"1\"><path d=\"M19,34V74Q19,78 23,78H27M19,50H27\"/></g><g class=\"pele-node pele-tree-dir\" data-id=\"src\"><text class=\"pele-label\" x=\"12\" y=\"27.6\" font-weight=\"var(--_hw)\" xml:space=\"preserve\">src</text></g><g class=\"pele-node pele-tree-file\" data-id=\"a\"><text class=\"pele-label\" x=\"32\" y=\"55.6\" xml:space=\"preserve\">a</text></g><g class=\"pele-node pele-tree-file highlight\" data-id=\"b\"><rect class=\"pele-tree-highlight\" x=\"28\" y=\"65\" width=\"65\" height=\"26\" fill=\"var(--_c)\" fill-opacity=\"0.14\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"32\" y=\"83.6\" xml:space=\"preserve\">b</text><text class=\"pele-tree-description\" x=\"56.9\" y=\"83.6\" font-style=\"italic\" fill=\"var(--_m)\" xml:space=\"preserve\">note</text></g></svg>",
  )
}

///|
test "box-drawing input draws the same as indented input" {
  inspect(
    svg(
      "treeView-beta\n├── src/\n│   ├── index.ts\n│   └── utils.ts\n├── package.json\n└── README.md\n",
    ) ==
    svg(
      "treeView-beta\n    src/\n        index.ts\n        utils.ts\n    package.json\n    README.md\n",
    ),
    content="true",
  )
}

///|
test "box-drawing errors name the original lines" {
  match
    drawn("treeView-beta\n│\n├── src/\n│\n│   └── \"a\n") {
    Err(failure) => {
      inspect(failure.line, content="5")
      inspect(failure.message.contains("line 5"), content="true")
    }
    Ok(_) => fail("expected an error")
  }
  inspect(
    svg("treeView-beta\n├── \n"),
    content="Line 2: Empty node — expected a filename or directory name after the box-drawing prefix",
  )
}

///|
test "highlights, descriptions in one column, and extra classes" {
  let out = svg(
    "treeView-beta\n    src/\n        App.tsx :::highlight ## main\n        index.js :::mine ## entry point\n",
  )
  inspect(count(out, "class=\"pele-tree-highlight\""), content="1")
  inspect(
    out.contains("class=\"pele-node pele-tree-file highlight\""),
    content="true",
  )
  inspect(
    out.contains("class=\"pele-node pele-tree-file mine\""),
    content="true",
  )
  let xs = numbers_after(out, "class=\"pele-tree-description\" x=\"")
  inspect(xs.length(), content="2")
  inspect(xs[0] == xs[1], content="true")
}

///|
test "icons appear only when asked" {
  inspect(svg(TREE).contains("pele-icon"), content="false")
  let shown = svg(
    "---\nconfig:\n  treeView:\n    showIcons: true\n---\n" + TREE,
  )
  inspect(count(shown, "class=\"pele-icon\""), content="5")
  inspect(
    shown.contains("data-icon=\"mermaid-treeview:folder\""),
    content="true",
  )
  inspect(shown.contains("data-icon=\"mermaid-treeview:file\""), content="true")
}

///|
test "an annotated icon is drawn and an empty one hides the icon" {
  let out = svg(
    "treeView-beta\n  App.tsx icon(logos:react)\n  index.js\n  x.rs icon(rust)\n  y icon()\n",
  )
  inspect(out.contains("data-icon=\"logos:react\""), content="true")
  inspect(out.contains("data-icon=\"mermaid-treeview:rust\""), content="true")
  inspect(count(out, "class=\"pele-icon\""), content="2")
}

///|
test "file names and extensions map to icons from the config" {
  let out = svg(
    "---\nconfig:\n  treeView:\n    showIcons: true\n    defaultIconPack: material\n    filenameIcons:\n      Dockerfile: docker\n    extensionIcons:\n      .ts: typescript\n      txt: none\n---\ntreeView-beta\n  a.ts\n  Dockerfile\n  notes.txt\n  constructor\n  dir.ts/\n",
  )
  inspect(out.contains("data-icon=\"material:typescript\""), content="true")
  inspect(out.contains("data-icon=\"material:docker\""), content="true")
  inspect(count(out, "data-icon=\"mermaid-treeview:file\""), content="1")
  inspect(count(out, "data-icon=\"mermaid-treeview:folder\""), content="1")
  inspect(count(out, "class=\"pele-icon\""), content="4")
}

///|
test "names are kept as written" {
  let out = svg(
    "treeView-beta\n  \"a  b   c\"\n  <T>.ts ## x <br> y\n  #35;hash\n",
  )
  inspect(out.contains(">a  b   c</text>"), content="true")
  inspect(out.contains(">&lt;T&gt;.ts</text>"), content="true")
  inspect(out.contains(">x &lt;br&gt; y</text>"), content="true")
  inspect(out.contains(">#hash</text>"), content="true")
}

///|
test "titles and accessible names" {
  let out = svg(
    "---\ntitle: Front\n---\ntreeView-beta\naccTitle: Acc\naccDescr: Described\n  a\n",
  )
  inspect(out.contains(">Front<"), content="true")
  inspect(out.contains("<title id=\"pele-title\">Acc</title>"), content="true")
  inspect(
    out.contains("<desc id=\"pele-desc\">Described</desc>"),
    content="true",
  )
  inspect(
    svg("---\ntitle: Front\n---\ntreeView-beta\ntitle Own\n  a\n").contains(
      ">Own<",
    ),
    content="true",
  )
}

///|
test "the layout options are honoured" {
  let base = drawn(TREE).unwrap()
  let wide = drawn(
    "---\nconfig:\n  treeView:\n    rowIndent: 80\n    paddingY: 10\n    lineThickness: 3\n---\n" +
    TREE,
  ).unwrap()
  inspect(wide.width > base.width, content="true")
  inspect(wide.height > base.height, content="true")
  inspect(wide.svg.contains("stroke-width=\"3\""), content="true")
}

///|
test "an empty tree is drawn and the drawing is deterministic" {
  inspect(svg("treeView-beta").contains("<svg"), content="true")
  inspect(svg(TREE) == svg(TREE), content="true")
}

///|
test "what Mermaid rejects is rejected" {
  for
    source in [
      "treeView-beta title x\n a", "treeView-beta\n a\ntitle late", "treeView-beta\n  \n  a",
      "treeView-beta\n :::x",
    ] {
    inspect(drawn(source) is Err(_), content="true")
  }
}

///|
test "a narrow width wraps names and tightens the indentation" {
  let source = "treeView-beta\n    a-very-long-directory-name-that-does-not-fit/\n        another-quite-long-file-name-that-wraps.txt ## and a description that is long too\n"
  let loose = drawn(source).unwrap()
  let tight = drawn(source, max_width=240).unwrap()
  inspect(tight.width < loose.width, content="true")
  inspect(tight.height > loose.height, content="true")
}
