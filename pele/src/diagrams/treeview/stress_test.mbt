///|
const HEAD : String = "treeView-beta\n"

///|
fn big(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
  Ok(@core.render([@treeview.treeview], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn repeat_lines(count : Int32, line : (Int32) -> String) -> String {
  let out = StringBuilder()
  for i in 0..<count {
    out.write_string(line(i))
  }
  out.to_string()
}

///|
test "inputs that make a naive lexer rescan the text are read in one pass" {
  let n = 50000
  let cases = [
    HEAD + "a\n".repeat(n / 2),
    HEAD + repeat_lines(300, i => " ".repeat(i) + "d/\n"),
    HEAD + "a".repeat(n),
    HEAD + "a" + " ".repeat(n) + "b",
    HEAD + ("a" + " ".repeat(99)).repeat(n / 100) + "b",
    HEAD + ("a :::" + " ".repeat(95)).repeat(n / 100) + "1",
    HEAD + "a" + " ::: 1 icon[ #".repeat(n / 14),
    HEAD + (" ".repeat(98) + ":\n").repeat(n / 100),
    HEAD + "accDescr {\n".repeat(n / 11),
    HEAD + "a\n" + " accDescr {\n".repeat(n / 12),
    HEAD + "\"a\n".repeat(n / 3),
    HEAD + "a" + " :::highlight".repeat(n / 13),
    HEAD + "%% c\n".repeat(n / 5),
    HEAD + "a ## " + "word ".repeat(n / 5),
    HEAD + "\u{251c}\u{2500}\u{2500} a\n".repeat(n / 6),
    HEAD + repeat_lines(300, i => "\u{2502}".repeat(i) + "\u{251c}\u{2500} x\n"),
    HEAD + "\u{2502}   \u{2502}   \u{2502}\n".repeat(n / 10),
    HEAD + "a \u{2500} b\n".repeat(n / 6),
  ]
  for source in cases {
    match big(source) {
      Ok(result) => inspect(result.svg.length() > 0, content="true")
      Err(failure) => inspect(failure.code is Syntax, content="true")
    }
  }
}

///|
test "options outside their range are ignored" {
  let source = "---\nconfig:\n  treeView:\n    rowIndent: x\n    paddingX: 1e999\n    paddingY: -5\n    lineThickness: .nan\n---\ntreeView-beta\n  a\n    b\n"
  let plain = "treeView-beta\n  a\n    b\n"
  inspect(big(source).unwrap().svg == big(plain).unwrap().svg, content="true")
}

///|
test "names that are object keys in pele are plain names" {
  let out = big(
      "---\nconfig:\n  treeView:\n    showIcons: true\n    defaultIconPack: p\n---\ntreeView-beta\n  __proto__\n  x.constructor\n  y icon(toString)\n",
    ).unwrap().svg
  inspect(out.contains("data-icon=\"p:toString\""), content="true")
  inspect(out.contains("[object"), content="false")
  inspect(out.contains("function"), content="false")
}

///|
test "hostile text is escaped in every position" {
  let payload = "<script>alert(1)</script>\"'&"
  let sources = [
    "treeView-beta\n  \{payload}",
    "treeView-beta\n  \"<script>alert(1)</script>\" ## x",
    "treeView-beta\n  a ## \{payload}",
    "treeView-beta\n  a :::\{payload}",
    "treeView-beta\n  a icon(x:\{payload})",
    "treeView-beta\ntitle \{payload}\n  a",
    "treeView-beta\naccTitle: \{payload}\naccDescr: \{payload}\n  a",
  ]
  for source in sources {
    match big(source) {
      Ok(result) => inspect(result.svg.contains("<script>"), content="false")
      Err(failure) => inspect(failure.code is Syntax, content="true")
    }
  }
}
