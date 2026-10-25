///|
const N : Int32 = 50000

///|
fn count(text : String, needle : String) -> Int32 {
  let mut total = 0
  let mut at = @util.index_of(text, needle)
  while at != -1 {
    total += 1
    at = @util.index_of(text, needle, from=at + needle.length())
  }
  total
}

///|
/// Draws `source` without a source length or output limit and tells what came out.
/// Any outcome but a trap is fine: pele only promises that hostile input ends in a `PeleError`.
fn outcome(source : String) -> String {
  let options = {
    ..@types.RenderOptions::default(),
    limit: Some(@double.infinity),
    output_limit: Some(@double.infinity),
  }
  let result = @core.render([@mindmap.mindmap], source, options) catch {
    @errors.PeleError(failure) => return "error \{failure.code.to_string()}"
  }
  "drawn nodes=\{count(result.svg, "class=\"pele-node")} edges=\{count(result.svg, "class=\"pele-edge\"")} \{result.width}x\{result.height}"
}

///|
fn chain(count : Int32, line : (Int32) -> String) -> String {
  let out = StringBuilder()
  for i in 0..<count {
    out.write_string(line(i))
  }
  out.to_string()
}

///|
test "16,000 nodes on one level are drawn with a link each" {
  inspect(
    outcome("mindmap\nroot\n" + " a\n".repeat(16000)),
    content="drawn nodes=16001 edges=16000 242x415988",
  )
}

///|
test "a chain as deep as indentation allows" {
  inspect(
    outcome("mindmap\n" + chain(310, i => " ".repeat(i) + "n\n")),
    content="drawn nodes=310 edges=309 21370x64",
  )
}

///|
test "3,000 levels of nesting" {
  inspect(
    outcome("mindmap\n" + chain(3000, i => " ".repeat(i) + "n\n")),
    content="drawn nodes=3000 edges=2999 206701x64",
  )
}

///|
test "indentation that rises and falls" {
  inspect(
    outcome(
      "mindmap\nroot\n" + chain(2400, i => " ".repeat(1 + i % 40) + "n\n"),
    ),
    content="drawn nodes=2401 edges=2400 5616x1728",
  )
}

///|
test "deep branches each followed by a shallow one" {
  inspect(
    outcome(
      "mindmap\nroot\n" +
      chain(160, _ => chain(24, i => " ".repeat(1 + i) + "n\n")),
    ),
    content="drawn nodes=3841 edges=3840 3411x4628",
  )
}

///|
test "5,000 branches with two leaves each" {
  inspect(
    outcome("mindmap\nroot\n" + " b\n  l\n  l\n".repeat(5000)),
    content="drawn nodes=15001 edges=15000 369x209988",
  )
}

///|
test "1,400 shaped nodes with icons and classes" {
  inspect(
    outcome(
      "mindmap\nroot\n" + " a((b))\n ::icon(fa fa-x)\n :::c d\n".repeat(1400),
    ),
    content="drawn nodes=1401 edges=1400 288x50388",
  )
}

///|
test "a 50,000 character label and a 50,000 character word" {
  inspect(
    outcome("mindmap\nroot[" + "word ".repeat(N / 5) + "]"),
    content=(
      #|drawn nodes=1 edges=0 244x42040
    ),
  )
  inspect(
    outcome("mindmap\nroot[" + "w".repeat(N) + "]"),
    content="drawn nodes=1 edges=0 577652x64",
  )
}

///|
test "labels of markers, line breaks and entities" {
  inspect(
    outcome("mindmap\nroot[\"`" + "*a _b ".repeat(N / 6) + "`\"]"),
    content=(
      #|drawn nodes=1 edges=0 251x38932
    ),
  )
  inspect(
    outcome("mindmap\nroot[" + "#35;&amp;<br>".repeat(N / 13) + "]"),
    content=(
      #|drawn nodes=1 edges=0 72x80827
    ),
  )
}

///|
test "a class list and an icon name of 50,000 characters" {
  inspect(
    outcome("mindmap\nroot\n:::" + "a ".repeat(N / 2)),
    content="drawn nodes=1 edges=0 96x64",
  )
  inspect(
    outcome("mindmap\nroot\n::icon(" + "fa ".repeat(N / 3) + ")"),
    content="drawn nodes=1 edges=0 96x64",
  )
}

///|
test "a second root after 16,000 nodes is rejected" {
  inspect(
    outcome("mindmap\n root\n" + "  a\n".repeat(16000) + " b\n"),
    content="error semantic",
  )
}

///|
test "text that cannot be read ends in a syntax error" {
  inspect(outcome("mindmap\n" + "(a) ".repeat(N / 4)), content="error syntax")
  inspect(
    outcome("mindmap\n" + "a(b)" + " ".repeat(N) + "x"),
    content="error syntax",
  )
  inspect(
    outcome("mindmap\nroot[" + "}\n".repeat(N / 2) + "]"),
    content="error syntax",
  )
  inspect(outcome("mindmap\nroot[\"" + "a".repeat(N)), content="error syntax")
  inspect(
    outcome("mindmap\nroot[\"`" + "a\n".repeat(N / 2)),
    content="error syntax",
  )
  inspect(outcome("mindmap\n" + "-)(-".repeat(N / 4)), content="error syntax")
}
