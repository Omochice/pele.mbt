// Ported from pele v1.8.0, tests/class/stress.test.ts.
// pele also bounds each worst case to three seconds; here each only has to finish, with a drawing or a PeleError.

///|
const N : Int32 = 50000

///|
fn big(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
  Ok(@core.render([@class.class], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn parsed(source : String) -> Result[Unit, @errors.Failure] {
  Ok(@class.parse_class(source, @class.ClassDb::new())) catch {
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
fn diagram(body : String) -> String {
  "classDiagram\n" + body
}

///|
fn finishes(outcome : Result[@types.RenderResult, @errors.Failure]) -> Bool {
  match outcome {
    Ok(result) => result.svg.length() > 0
    Err(failure) => failure.code is (Syntax | Limit)
  }
}

///|
test "inputs that make a naive lexer rescan the text are read in one pass" {
  let sources = [
    diagram("A --> B " + "A ".repeat(N / 2) + "direction XX"),
    diagram("direction\n".repeat(N / 10)),
    diagram("direction" + "\n ".repeat(N / 2) + "XX\nclass A"),
    diagram("direction X ".repeat(N / 12)),
    diagram("a ".repeat(N / 2)),
    diagram("class A" + " ".repeat(N) + "x"),
    diagram("accTitle ".repeat(N / 9)),
    diagram("accDescr" + " ".repeat(N)),
    diagram("click A call" + " ".repeat(N) + "f()"),
    diagram("click A call f(" + " ".repeat(N) + "x)"),
    diagram("A " + ":".repeat(N)),
    diagram("A " + ":;".repeat(N / 2)),
    diagram("A " + "-".repeat(N / 2) + ".".repeat(N / 2) + " B"),
    diagram("A " + "<|".repeat(N / 4) + "()".repeat(N / 4)),
  ]
  for source in sources {
    inspect(@class.tokenize(source).types.length() > 0, content="true")
  }
}

///|
test "long statements, unclosed text and deep nesting are parsed without overflowing" {
  let sources = [
    diagram(repeat_lines(2000, i => "class C\{i}" + "\n \t".repeat(8) + "\n")),
    diagram("accDescr {" + "x\n".repeat(N / 2)),
    diagram("click A call f(" + "a,".repeat(N / 2)),
    diagram("note \"" + "x".repeat(N)),
    diagram("class A~" + "T".repeat(N)),
    diagram("class `" + "a".repeat(N)),
    diagram("class " + "A.".repeat(N / 2) + "B"),
    diagram("A ".repeat(N / 2) + "--> B"),
    diagram("namespace " + "a.".repeat(12000) + "b {\nclass X\n}"),
    diagram("namespace n {\n".repeat(4000) + "class X\n" + "}\n".repeat(4000)),
    diagram("namespace n {\n".repeat(4000) + "class X\n"),
    diagram("namespace n {\nclass X\n" + "}".repeat(N)),
    diagram("namespace ".repeat(N / 10) + "x {\nclass X\n}"),
  ]
  for source in sources {
    match parsed(source) {
      Ok(_) => ()
      Err(failure) => inspect(failure.code is Syntax, content="true")
    }
  }
}

///|
test "members and generic types of worst-case text are read in one pass" {
  let parsed_member = @class.ClassMember::new(
    "(\r".repeat(N / 2) + "a(b)",
    Method,
  )
  inspect(parsed_member.member_type is Method, content="true")
  inspect(
    @common.parse_generic_types("~" + ",".repeat(N) + "~").length() > 0,
    content="true",
  )
}

///|
test "large diagrams are drawn" {
  let complete = StringBuilder()
  for i in 0..<50 {
    for j in (i + 1)..<50 {
      complete.write_string("C\{i} --> C\{j}\n")
    }
  }
  let sources = [
    diagram("namespace " + "a.".repeat(3000) + "b {\nclass X\n}"),
    diagram(
      repeat_lines(2000, i => "namespace n\{i} {\n") +
      "class X\n" +
      "}\n".repeat(2000),
    ),
    diagram(repeat_lines(5000, i => "namespace n\{i} {\nclass C\{i}\n}\n")),
    diagram("class A {\n" + repeat_lines(10000, i => "+m\{i}()\n") + "}\n"),
    diagram("class A {\n+a)" + "(".repeat(N) + "\n}\n"),
    diagram("class A {\n" + "(a)".repeat(N / 3) + "\n}\n"),
    diagram("class A {\n+x " + "~".repeat(N) + "\n}\n"),
    diagram("class A {\n+x(" + "~a,".repeat(N / 3) + ")\n}\n"),
    diagram("class A {\n+" + "word ".repeat(N / 5) + "\n}\n"),
    diagram("note \"" + "word ".repeat(N / 5) + "\"\n"),
    diagram("note \"" + "*a _b <br>".repeat(N / 10) + "\"\n"),
    diagram("class A[\"" + "#35;&amp;".repeat(N / 9) + "\"]\n"),
    diagram(repeat_lines(5000, i => "class C\{i}\n")),
    diagram(repeat_lines(4000, i => "C\{i} <|-- C\{i + 1}\n")),
    diagram(repeat_lines(4000, i => "Hub \"1\" --> \"\{i}\" C\{i}\n")),
    diagram(
      "A \"1\" --> \"2\" B : x\n".repeat(2000) +
      "A \"1\" --> \"2\" A : y\n".repeat(2000),
    ),
    diagram(complete.to_string()),
    diagram(repeat_lines(3000, i => "i\{i} ()-- A\n")),
    diagram("class A\n" + repeat_lines(3000, i => "note for A \"n\{i}\"\n")),
    diagram("class A\nstyle A fill:#fff" + ",stroke:#000".repeat(4000) + "\n"),
    diagram(
      repeat_lines(100, i => "class C\{i}:::k\n") +
      "classDef k fill:#fff\n".repeat(3000),
    ),
    diagram(
      repeat_lines(1600, i => "class C\{i}:::k\n") +
      "classDef k fill:#fff\n".repeat(1600),
    ),
    diagram(
      repeat_lines(800, i => "class C\{i}:::k\nstyle C\{i} x:\{i}\n") +
      "classDef k x:y" +
      repeat_lines(5000, i => ",a\{i}:b") +
      "\n",
    ),
    diagram("class A\ncssClass \"" + "A,".repeat(12000) + "A\" k\n"),
    diagram("class A\nlink A \"&" + "#38;".repeat(N / 4) + "x\"\n"),
    diagram(repeat_lines(4000, _ => "<<a>> A\n")),
  ]
  for source in sources {
    inspect(finishes(big(source)), content="true")
  }
}

///|
test "refuses source over the default limit" {
  let outcome = try {
    ignore(
      @core.render(
        [@class.class],
        diagram("class A\n".repeat(10000)),
        @types.RenderOptions::default(),
      ),
    )
    ""
  } catch {
    @errors.PeleError(failure) => failure.message
  }
  inspect(outcome.contains("limit of 50000"), content="true")
}
