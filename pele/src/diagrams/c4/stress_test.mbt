// Ported from pele v1.8.0, tests/c4/stress.test.ts.
// pele also bounds each worst case to three seconds; here each only has to finish.

///|
const N : Int32 = 50000

///|
const H : String = "C4Context\n"

///|
fn big(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
  Ok(@core.render([@c4.c4], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn big_parse(source : String) -> Result[Unit, @errors.Failure] {
  Ok(@c4.parse_c4(source, @c4.C4Db::new())) catch {
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
fn finishes(outcome : Result[@types.RenderResult, @errors.Failure]) -> Bool {
  match outcome {
    Ok(result) => result.svg.length() > 0
    Err(_) => true
  }
}

///|
test "inputs that make a naive lexer rescan the text are read in one pass" {
  let sources = [
    H + "Rel(a,b,\"x\")".repeat(N / 12) + " direction XX",
    H + "direction ".repeat(N / 10) + "\n" + "direction\n".repeat(N / 10),
    H + ("x direction" + "\n".repeat(50)).repeat(N / 60),
    H + "Person(" + " ".repeat(N),
    H + "Person(" + (" ".repeat(100) + "\"a\",").repeat(N / 104) + ")",
    H + "Person(a, \"" + "x".repeat(N),
    H + "Person(a, $" + "k".repeat(N),
    H + "Person(a, $k=" + " ".repeat(N) + "x",
    H + "accDescr {" + " x\n".repeat(N / 3),
    H + ("accTitle" + " ".repeat(100)).repeat(N / 108),
    H + "%% c" + "\r\n".repeat(N / 2) + "Person(a, \"b\")",
    H + " \n\t".repeat(N / 3) + "Person(a, \"b\")",
    H + "Person".repeat(N / 6),
  ]
  for source in sources {
    assert_true(@c4.tokenize(source).types.length() > 0)
  }
  // One optimized version of pele's lexer once repeated a whole-text search for every statement.
  for _ in 0..<30 {
    assert_true(
      @c4.tokenize(H + "System(a, \"A\", \"d\")\n".repeat(3000) + "\n").types.length() >
      0,
    )
  }
}

///|
test "long and repeated statements are parsed" {
  let sources = [
    H + "Person(" + ",".repeat(N) + ")",
    H + "title t\naccDescr: d\naccTitle: t\n".repeat(1000) + "System(a,\"A\")",
    H + "accDescr {" + "\n   ".repeat(N / 4) + "}\nSystem(a,\"A\")",
  ]
  for source in sources {
    match big_parse(source) {
      Ok(_) => ()
      Err(failure) => assert_true(failure.code is Syntax)
    }
  }
}

///|
test "large diagrams are drawn" {
  let complete = StringBuilder()
  complete.write_string(H + repeat_lines(50, i => "System(s\{i},\"S\")\n"))
  for i in 0..<50 {
    for j in 0..<50 {
      if i != j {
        complete.write_string("Rel(s\{i},s\{j},\"x\")\n")
      }
    }
  }
  let careful = StringBuilder()
  careful.write_string(H + repeat_lines(700, i => "System(s\{i},\"S\")\n"))
  for k in 0..<700 {
    careful.write_string(
      "Rel(s\{k},s\{(k * 37 + 11) % 700},\"a label to place \{k}\", \"tech\")\n",
    )
  }
  let boundaries = StringBuilder()
  boundaries.write_string(
    H +
    repeat_lines(600, i => {
      "Boundary(b\{i}, \"A heading \{i}\") {\nSystem(s\{i},\"S\")\n}\n"
    }),
  )
  for k in 0..<600 {
    boundaries.write_string("Rel(b\{k},s\{(k * 11 + 5) % 600},\"x\")\n")
  }
  let detours = StringBuilder()
  detours.write_string(
    H +
    "UpdateLayoutConfig(\"1000\", \"1\")\n" +
    repeat_lines(1000, i => "System(s\{i},\"S\")\n"),
  )
  for k in 0..<480 {
    detours.write_string("Rel(s0,s\{k + 2},\"x\")\n")
  }
  let sources = [
    H + "title " + "word ".repeat(N / 5) + "\nPerson(a, \"b\")",
    H + "Person(" + "a,".repeat(N / 2) + "\"z\")",
    H + "System(a, \"A\"" + repeat_lines(5000, i => ", $k\{i}=\"v\"") + ")",
    H +
    repeat_lines(2000, i => "Boundary(b\{i}, \"B\{i}\") {\n") +
    "System(s, \"S\")\n" +
    "}\n".repeat(2000),
    H +
    "Boundary(b, \"B\") {\n".repeat(3000) +
    "System(s, \"S\")\n" +
    "}\n".repeat(3000),
    H +
    repeat_lines(1200, i => {
      "Boundary(b\{i}, \"B\") {\nSystem(s\{i}, \"S\")\n}\n"
    }),
    H + repeat_lines(2500, i => "System(s\{i}, \"S\{i}\")\n"),
    H +
    "UpdateLayoutConfig(\"99999999\", \"1\")\n" +
    repeat_lines(2500, i => "System(s\{i}, \"S\{i}\")\n"),
    H + "System(a, \"A\", \"d\")\n".repeat(3000),
    complete.to_string(),
    careful.to_string(),
    boundaries.to_string(),
    detours.to_string(),
    H +
    "System(a,\"A\")\nSystem(b,\"B\")\n" +
    "Rel(a,a,\"x\")\nRel(a,b,\"y\")\nRel(b,a,\"z\")\n".repeat(700),
    H +
    "System(top, \"T\")\n" +
    repeat_lines(1000, i => "Node(n\{i}, \"N\") {\n") +
    "System(deep, \"D\")\n" +
    "}\n".repeat(1000) +
    "Rel(top, deep, \"x\")\nRel(n0, deep, \"y\")\nRel(deep, n999, \"z\")",
    H + "System(a, \"" + "word ".repeat(N / 5) + "\")",
    H + "System(a, \"" + "w".repeat(N) + "\")",
    H + "System(a, \"A\", \"" + "#35;&amp;<br>".repeat(N / 13) + "\")",
    H +
    "System(a,\"A\")\nSystem(b,\"B\")\nRel(a, b, \"" +
    "word ".repeat(N / 5) +
    "\", \"" +
    "tech ".repeat(100) +
    "\")",
    H + "Boundary(b, \"" + "word ".repeat(N / 5) + "\") {\nSystem(a,\"A\")\n}",
    H + "System(a, \"A\", $tags=\"" + "a,".repeat(N / 2) + "\")",
    H + "System(a, \"A\", $link=\"&" + "#38;".repeat(N / 4) + "x\")",
    H +
    "System(a, \"A\")\nUpdateElementStyle(a, \"" +
    "url( ".repeat(N / 5) +
    "\", \"" +
    "a".repeat(N) +
    "\")",
    H +
    "System(a,\"A\")\n" +
    repeat_lines(1500, i => {
      "UpdateElementStyle(x\{i},\"red\")\nUpdateRelStyle(a,x\{i},\"red\")\n"
    }),
  ]
  for source in sources {
    assert_true(finishes(big(source)))
  }
}

///|
test "renders what it can of the large cases" {
  let many = big(H + repeat_lines(2500, i => "System(s\{i}, \"S\{i}\")\n")).unwrap()
  let marker = "class=\"pele-node "
  let mut count = 0
  let mut at = @util.index_of(many.svg, marker)
  while at != -1 {
    count += 1
    at = @util.index_of(many.svg, marker, from=at + 1)
  }
  inspect(count, content="2500")
  let nested = big(
    H +
    repeat_lines(2000, i => "Boundary(b\{i}, \"B\{i}\") {\n") +
    "System(s, \"S\")\n" +
    "}\n".repeat(2000),
  ).unwrap()
  assert_true(nested.svg.contains("data-id=\"b1999\""))
  let refused = match drawn(H + "System(a, \"A\")\n".repeat(5000)) {
    Ok(_) => ""
    Err(failure) => failure.message
  }
  assert_true(refused.contains("limit of 50000"))
}
