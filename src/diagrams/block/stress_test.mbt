// Ported from pele v1.8.0, tests/block/stress.test.ts and tests/render/block-security.test.ts.
// pele also bounds each worst case to three seconds; here each only has to finish.

///|
const N : Int32 = 50000

///|
fn big(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
  Ok(@core.render([@block.block], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn parsed_big(source : String) -> Result[Unit, @errors.Failure] {
  Ok(@block.parse_block(source, @block.BlockDb::new())) catch {
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
fn finished(outcome : Result[@types.RenderResult, @errors.Failure]) -> Bool {
  match outcome {
    Ok(result) => result.svg.length() > 0
    Err(_) => true
  }
}

///|
fn parse_finished(outcome : Result[Unit, @errors.Failure]) -> Bool {
  outcome is (Ok(_) | Err(_))
}

///|
test "draws large grids, rows, columns and nestings" {
  let sources = [
    "block\n" + repeat_lines(16000, i => "b\{i} "),
    "block\ncolumns 1\n" + repeat_lines(10000, i => "b\{i}\n"),
    "block\ncolumns 100\n" + repeat_lines(8000, i => "b\{i}[\"x\"] "),
    "block\n" + "block\n".repeat(8000) + "a\n" + "end\n".repeat(8000),
    "block\n" +
    repeat_lines(5000, i => "block:g\{i}\n") +
    "a\n" +
    "end\n".repeat(5000),
    "block\ncolumns 50\n" + repeat_lines(5000, i => "block\nn\{i}\nend\n"),
  ]
  for source in sources {
    assert_true(finished(big(source)), msg=@util.slice(source, 0, end=40))
  }
}

///|
test "draws many edges, parallel edges, self loops and labelled edges" {
  let complete = StringBuilder()
  complete.write_string("block\ncolumns 9\n")
  for i in 0..<70 {
    for j in (i + 1)..<70 {
      complete.write_string("n\{i}-->n\{j}\n")
    }
  }
  let sources = [
    "block\na0" + repeat_lines(8000, i => "-->a\{i + 1}"),
    "block\ncolumns 20\n" +
    repeat_lines(400, i => "n\{i} ") +
    "\n" +
    repeat_lines(4000, i => "n\{i % 400} --> n\{(i * 37 + 11) % 400}\n"),
    complete.to_string(),
    "block\nA space B\n" + "A-->B\n".repeat(4000) + "A-->A\n".repeat(4000),
    "block\nA space:3 B\n" + "A -- \"label text\" --> B\n".repeat(2500),
  ]
  for source in sources {
    assert_true(finished(big(source)), msg=@util.slice(source, 0, end=40))
  }
}

///|
test "copes with huge counts and widths" {
  let sources = [
    "block\n" + "space:99999 ".repeat(4000),
    "block\na space:" + "9".repeat(400) + " b",
    "block\na space:99999 b",
    "block\ncolumns 3\na:" + "9".repeat(400) + " b c",
    "block\ncolumns " + "9".repeat(400) + "\na b",
    "block\n" + repeat_lines(5000, i => "b\{i}:999 "),
  ]
  for source in sources {
    assert_true(finished(big(source)), msg=@util.slice(source, 0, end=40))
  }
}

///|
test "copes with long labels, lists and styles" {
  let sources = [
    "block\nA[\"" + "word ".repeat(N / 5) + "\"]",
    "block\nA[\"" + "#35;&amp;<br>".repeat(N / 13) + "\"]",
    "block\nA<[\"x\"]>(" + "up, down , x,y ".repeat(2500) + ")",
    "block\nA\nclass " + "A,".repeat(25000) + "A hot\nclassDef hot fill:#f96",
    "block\nA\nstyle A " + ",".repeat(N),
    "block\nA\nstyle A " + "fill:red;".repeat(N / 9),
    "block\nA\nclassDef c " + "x".repeat(N) + "\nclass A c",
    "block\nA\nclassDef c " + "fill:red,".repeat(10000) + "x\nclass A c",
    "block\nA\n" +
    repeat_lines(2500, i => "classDef c\{i} fill:red\nclass A c\{i}\n"),
    "block\n" + "a".repeat(N),
    "block\n__proto__ constructor toString\nclassDef __proto__ fill:red\nclass constructor,toString __proto__\nstyle __proto__ fill:blue\n__proto__ --> constructor",
  ]
  for source in sources {
    assert_true(finished(big(source)), msg=@util.slice(source, 0, end=40))
  }
}

///|
test "reads unclosed and runaway input in one pass" {
  let sources = [
    "block\n" + "block\n".repeat(12000) + "a",
    "block\na\n" + "end\n".repeat(12000),
    "block\nA[\"" + "x".repeat(N),
    "block\nA[\"`" + "x`".repeat(N / 2),
    "block\nA<[\"" + "x".repeat(N) + "\"]>",
    "block\nA<[\"x\"]>(" + " ".repeat(N) + "sideways)",
    "block\nA<[\"x\"]>" + " ".repeat(N) + "x",
    "block\nA\nclass A" + ("," + " ".repeat(40)).repeat(1200) + " x",
    "block\nclassDef " + "a".repeat(N / 2) + " ".repeat(N / 2),
    "block\nA\naccDescr {" + " a\n".repeat(15000),
    "block\n" + "--> ".repeat(N / 4),
    "block " + "a;".repeat(N / 2),
  ]
  for source in sources {
    assert_true(
      parse_finished(parsed_big(source)),
      msg=@util.slice(source, 0, end=40),
    )
  }
  let tokens = [
    "block\n" + ("columns" + " ".repeat(40) + "x ").repeat(1000),
    "block\n" + ("accTitle" + " ".repeat(40) + "x ").repeat(1000),
    "block\nA" + "-".repeat(N) + ".".repeat(N) + "=".repeat(N),
    "block\nA -" + ".".repeat(N) + "x",
    "block\nA -- \"x\"" + " ".repeat(N) + "y",
    "block\n" + "(([[{{".repeat(N / 6),
  ]
  for source in tokens {
    assert_true(@block.tokenize(source).types.length() > 0)
  }
}

///|
test "refuses space counts past the limit and keeps the ones within it" {
  match parsed_big("block\na space:100001 b") {
    Err(failure) =>
      assert_true(failure.message.contains("at most 100000 space blocks"))
    Ok(_) => fail("accepted")
  }
  assert_true(parsed_big("block\n" + "space:60000 ".repeat(2)) is Err(_))
  let db = @block.BlockDb::new()
  @block.parse_block("block\na space:5 b", db)
  assert_eq(db.blocks.length(), 7)
}

///|
test "keeps every number in the output finite" {
  for
    source in [
      "block\ncolumns 3\na:" + "9".repeat(400) + " b c",
      "block\na:" + "9".repeat(400) + " b c",
      "block\na:0 b:00 c",
      "block\ncolumns 99999999999999999999\na b",
      "block\nblock:g:99999999\na\nend\nb",
    ] {
    guard big(source) is Ok(result) else { fail(source) }
    assert_false(result.width.is_nan() || result.width.is_inf(), msg=source)
    assert_false(result.height.is_nan() || result.height.is_inf(), msg=source)
    assert_false(result.svg.contains("NaN"), msg=source)
    assert_false(result.svg.contains("Infinity"), msg=source)
  }
}

///|
/// FNV-1a over UTF-16 code units, the hash under which `hostile_outcomes` were taken from pele.
fn fnv1a(text : String) -> String {
  let mut h : UInt32 = 0x811c9dc5U
  for i in 0..<text.length() {
    h = (h ^ text.unsafe_get(i).to_int().reinterpret_as_uint()) * 0x01000193U
  }
  let digits = "0123456789abcdef"
  let out = StringBuilder()
  for shift in [28, 24, 20, 16, 12, 8, 4, 0] {
    let d = ((h >> shift) & 0xfU).reinterpret_as_int()
    out.write_char(digits.get_char(d).unwrap())
  }
  out.to_string()
}

///|
/// What rendering gives, written as the generator of `hostile_outcomes` writes pele's.
fn render_outcome(source : String) -> String {
  match block_render(source) {
    Ok(r) => {
      let links = r.links.map(l => "\{l.id}|\{l.href}|\{l.internal}").join(";")
      "ok \{r.width} \{r.height} \{links}\n\{r.svg}"
    }
    Err(failure) => "error \{failure.code.to_string()}\n\{failure.message}"
  }
}

///|
test "hostile text in every position is drawn as pele draws it" {
  let wrong = []
  let mut k = 0
  for t, pieces in hostile_templates {
    for p, payload in hostile_payloads {
      let actual = fnv1a(render_outcome(pieces.join(payload)))
      if actual != hostile_outcomes[k] {
        wrong.push("template \{t} payload \{p}")
      }
      k += 1
    }
  }
  assert_eq(k, hostile_outcomes.length())
  assert_eq(wrong.join("\n"), "")
}

///|
test "keeps hostile text out of markup" {
  let svg = block_svg(
    "block\n  a[\"</text><script>alert(1)</script>\"]\n  classDef x fill:url(javascript:alert(1)),stroke:red\n  class a x",
  )
  assert_false(svg.contains("<script"))
  assert_false(svg.contains("url("))
  assert_true(svg.contains("stroke:red"))
}

///|
test "keeps coordinates finite when blocks have no size" {
  let zero = "---\nconfig:\n  block:\n    padding: 0\n---\n"
  for
    body in [
      "block\n  columns 1\n  block:g\n    classDef x fill:red\n  end\n  a\n  g --> a\n  a --> g\n  g --> g",
      "block\n  block:g\n    space\n  end\n  block:h\n    space\n  end\n  g --> h\n  h -- \"x\" --> g",
      "block\n  columns 1\n  block:g\n    classDef x fill:red\n  end\n  block:h\n    classDef x fill:red\n  end\n  g --> h",
      "block\n  space\n  block:g\n    space:0\n  end\n  g --> g",
    ] {
    for source in [zero + body, body] {
      guard block_render(source) is Ok(result) else { fail(source) }
      assert_false(result.svg.contains("NaN"), msg=source)
      assert_false(result.svg.contains("Infinity"), msg=source)
    }
  }
}
