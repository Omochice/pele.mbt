// Ported from pele v1.8.0 tests/requirement/stress.test.ts.
// pele also bounds each case to three seconds; here a case that rescans its text shows as a test run that does not finish.

///|
const HEAD : String = "requirementDiagram\n"

///|
const N : Int32 = 50000

///|
fn big(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
  Ok(@core.render([@requirement.requirement], source, options)) catch {
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
test "texts that make a naive lexer rescan are read in one pass" {
  let cases = [
    HEAD + "a - contains -> b ".repeat(N / 18) + "direction XX",
    HEAD + ": ".repeat(N / 2) + "direction LR",
    HEAD + ("direction" + "\n".repeat(40)).repeat(N / 50) + "TB",
    HEAD + "direction ".repeat(N / 10) + "TB",
    HEAD + "direction TB ".repeat(N / 13),
    HEAD + ("accTitle" + " ".repeat(100) + "\n").repeat(N / 110),
    HEAD + "accDescr" + " \n".repeat(N / 2),
    HEAD + "accDescr {" + " a\n".repeat(N / 3),
    HEAD + "title\n".repeat(N / 6),
    HEAD + "title #".repeat(N / 7),
    HEAD + "a" + " ".repeat(N) + "b",
    HEAD + "element \"" + "x".repeat(N),
    HEAD + "\"".repeat(N),
    HEAD + ("a" + " \n\t".repeat(30) + ":").repeat(N / 100),
    HEAD + "style a" + " ".repeat(N) + "fill:red\n",
  ]
  for source in cases {
    let tokens = @requirement.tokenize(source)
    inspect(tokens.types.length() > 0, content="true")
  }
}

///|
test "worst-case statements are read and drawn or refused" {
  let complete = StringBuilder()
  complete.write_string(HEAD + repeat_lines(40, i => "element e\{i} {\n}\n"))
  for i in 0..<40 {
    for j in (i + 1)..<40 {
      complete.write_string("e\{i} - derives -> e\{j}\n")
    }
  }
  let cases = [
    HEAD + "style a " + "f:#-;".repeat(N / 5) + "\n",
    HEAD + "requirement a {\n}\nclass a " + "c,".repeat(N / 2) + "c\n",
    HEAD +
    "requirement a {\n}\n" +
    "classDef c fill:red\nclass a c\n".repeat(1600),
    HEAD +
    "requirement a {\n}\nclassDef c " +
    "a:b,".repeat(6000) +
    "a:b\n" +
    "class a c\n".repeat(2500),
    HEAD +
    repeat_lines(1000, i => "element e\{i} {\n}\n") +
    "classDef c " +
    "a:b,".repeat(3000) +
    "a:b\n" +
    ("class " + Array::makei(1000, i => "e\{i}").join(",") + " c\n").repeat(3),
    HEAD +
    repeat_lines(2000, i => "element e\{i}:::c {\n}\n") +
    "classDef c a:b\n".repeat(600),
    HEAD + "requirement a {\n" + "id: 1\n".repeat(10000) + "}\n",
    HEAD + "requirement a {\n" + "text: x\n".repeat(6000),
    HEAD + "\n \n".repeat(N / 3) + "requirement a {\n}\n",
    HEAD + "# c\n% d\n".repeat(N / 8),
    HEAD +
    repeat_lines(2000, i => "requirement r\{i} {\nid: \{i}\nrisk: low\n}\n"),
    HEAD +
    repeat_lines(1500, i => "element e\{i} {\n}\n") +
    repeat_lines(1499, i => "e\{i} - traces -> e\{i + 1}\n"),
    HEAD +
    repeat_lines(1500, i => "element e\{i} {\n}\n") +
    repeat_lines(1499, i => "e0 - contains -> e\{i + 1}\n"),
    HEAD +
    "element a {\n}\nelement b {\n}\n" +
    "a - copies -> b\n".repeat(2500) +
    "a - contains -> a\n".repeat(500),
    HEAD +
    "element a {\n}\n" +
    repeat_lines(2500, i => "a - refines -> x\{i}\n"),
    complete.to_string(),
    HEAD + "requirement a {\ntext: \"" + "word ".repeat(N / 5) + "\"\n}\n",
    HEAD + "requirement a {\ntext: \"" + "*a _b **c ".repeat(N / 10) + "\"\n}\n",
    HEAD + "requirement " + "x".repeat(N) + " {\n}\n",
    HEAD +
    "requirement a {\ntext: \"" +
    "#35;&amp;<br>".repeat(N / 13) +
    "\"\n}\n",
  ]
  for source in cases {
    match big(source) {
      Ok(result) => inspect(result.svg.length() > 0, content="true")
      Err(failure) => inspect(failure.code is (Syntax | Limit), content="true")
    }
  }
}

///|
test "refuses source over the default limit" {
  let source = HEAD + "element a {\n}\n".repeat(5000)
  let message = try
    @core.render(
      [@requirement.requirement],
      source,
      @types.RenderOptions::default(),
    )
  catch {
    @errors.PeleError(failure) => failure.message
  } noraise {
    _ => "drawn"
  }
  inspect(message.contains("limit of 50000"), content="true")
}
