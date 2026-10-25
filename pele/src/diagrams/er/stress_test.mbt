// Ported from pele v1.8.0, tests/er/stress.test.ts and tests/render/er-security.test.ts.
// pele also bounds each worst case to three seconds; here each only has to finish.

///|
const N : Int32 = 50000

///|
fn big(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
  Ok(@core.render([@er.er], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn parsed(source : String) -> Result[Unit, @errors.Failure] {
  Ok(@er.parse_er(source, @er.ErDb::new())) catch {
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
    Err(failure) => failure.code is (Syntax | Limit)
  }
}

///|
test "inputs that make a naive lexer rescan the text are read in one pass" {
  let sources = [
    "erDiagram\n" + "A ".repeat(N / 2) + "direction XX",
    "erDiagram\n" + "direction ".repeat(N / 10),
    "erDiagram\n" + ("direction" + "\n".repeat(9)).repeat(N / 18) + "TB",
    "erDiagram\n" + "A direction B\n".repeat(N / 14),
    "erDiagram\ndirection" + " ".repeat(N) + "XX",
    "erDiagram\n" + ("accTitle" + " ".repeat(40)).repeat(N / 48),
    "erDiagram\n" + ("1" + " ".repeat(99)).repeat(N / 100) + "!",
    "erDiagram\n" + "|o}o}|o{|{||--..".repeat(N / 16),
    "erDiagram\n" + "\"a%".repeat(N / 3),
    "erDiagram\nA {\n" + "! ".repeat(N / 4) + "~" + " !".repeat(N / 4),
    "erDiagram\nA {\n" + "!".repeat(N) + "~~",
    "erDiagram\nA {\n" + "a~ b\n".repeat(N / 5) + "}",
    "erDiagram\nA {\n" + "~a~ ".repeat(N / 4) + "}",
    "erDiagram\nA {\n" + "`" + "a ".repeat(N / 2),
    "erDiagram\nA {\n" + "`a``b` ".repeat(N / 7) + "}",
    "erDiagram\nA {\n" + "a b \"".repeat(N / 5),
    "erDiagram\naccDescr {" + " text\n".repeat(N / 6),
  ]
  for source in sources {
    inspect(@er.tokenize(source).types.length() > 0, content="true")
  }
}

///|
test "long statements and deep nesting are parsed without overflowing" {
  let sources = [
    "erDiagram\nA\nstyle A " + ":#".repeat(N / 2) + "\n",
    "erDiagram\nstyle " + repeat_lines(10000, i => "e\{i},") + "z fill:red\n",
    "erDiagram\nclass " +
    repeat_lines(10000, i => "e\{i},") +
    "z " +
    repeat_lines(10000, i => "c\{i},") +
    "z\n",
    "erDiagram\n" + "subgraph s\n".repeat(20000) + "A\n" + "end\n".repeat(20000),
    "erDiagram\nsubgraph s\n" + repeat_lines(10000, i => "n\{i}\n") + "end\n",
    "erDiagram\n" + "subgraph s\n".repeat(N / 11),
  ]
  for source in sources {
    match parsed(source) {
      Ok(_) => ()
      Err(failure) => inspect(failure.code is Syntax, content="true")
    }
  }
}

///|
test "large diagrams are drawn" {
  let complete = StringBuilder()
  complete.write_string("erDiagram\n")
  for i in 0..<50 {
    for j in (i + 1)..<50 {
      complete.write_string("n\{i} }o--o{ n\{j} : r\n")
    }
  }
  let sources = [
    "erDiagram\nA\nstyle A " +
    repeat_lines(10000, i => "x\{i}:1,") +
    "fill:red\n",
    "erDiagram\nA:::" + repeat_lines(20000, i => "c\{i},") + "z\n",
    "erDiagram\n" +
    repeat_lines(3000, i => "subgraph s\{i}\n") +
    "A ||--|| B : x\n" +
    "end\n".repeat(3000),
    "erDiagram\n" + repeat_lines(5000, i => "subgraph s\{i}\nn\{i}\nend\n"),
    "erDiagram\n" + repeat_lines(5000, _ => "subgraph s\nA\nB\nC\nend\n"),
    "erDiagram\nA {\n" + repeat_lines(5000, i => "t\{i} n\{i}\n") + "}",
    "erDiagram\nA {\n string id " + "PK,".repeat(10000) + "FK\n}",
    "erDiagram\n" + repeat_lines(5000, i => "A { t n\{i} }\n"),
    "erDiagram\nA {\n string id \"" + "word ".repeat(N / 5) + "\"\n}",
    "erDiagram\nA {\n string " + "a".repeat(N) + "\n}",
    "erDiagram\nA {\n " + "~".repeat(N) + " name\n}",
    "erDiagram\nA {\n " + "a~b,".repeat(N / 4) + " name\n}",
    "erDiagram\nA {\n string id \"" + "*a _b ".repeat(N / 6) + "\"\n}",
    "erDiagram\n\"" + "#35;&amp;<br>".repeat(N / 13) + "\"",
    "erDiagram\nA ||--o{ B : \"" + "word ".repeat(N / 5) + "\"",
    "erDiagram\n" + repeat_lines(5000, i => "n\{i}\n"),
    "erDiagram\n" + repeat_lines(5000, i => "n\{i} ||--o{ n\{i + 1} : r\n"),
    "erDiagram\n" + repeat_lines(5000, i => "c ||--o{ n\{i} : r\n"),
    "erDiagram\n" +
    "A ||--o{ B : r\n".repeat(2000) +
    "A ||--|| A : s\n".repeat(2000),
    complete.to_string(),
    "erDiagram\nsubgraph a\nA\nend\nsubgraph b\nB\nend\n" +
    "a ||--|| b : r\nA ||--|| b : s\n".repeat(1000),
    "erDiagram\n" + "a[\"Some Alias\"]\n".repeat(10000),
  ]
  for source in sources {
    inspect(finishes(big(source)), content="true")
  }
}

///|
test "generic types of nested tildes are read in one pass" {
  let text = "a~".repeat(N / 2) + ",".repeat(1000) + "~b".repeat(N / 2)
  inspect(@common.parse_generic_types(text).length() > 0, content="true")
}

///|
test "refuses source over the default limit" {
  let outcome = try {
    ignore(
      @core.render(
        [@er.er],
        "erDiagram\n" + "A ||--o{ B : r\n".repeat(5000),
        @types.RenderOptions::default(),
      ),
    )
    ""
  } catch {
    @errors.PeleError(failure) => failure.message
  }
  inspect(outcome.contains("limit of 50000"), content="true")
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
  match drawn(source) {
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
      let source = pieces.join(payload)
      let actual = fnv1a(render_outcome(source))
      if actual != hostile_outcomes[k] {
        wrong.push("template \{t} payload \{p}")
      }
      k += 1
    }
  }
  inspect(k == hostile_outcomes.length(), content="true")
  inspect(wrong.join("\n"), content="")
}

///|
test "escapes what it shows" {
  let svg = svg_of(
    "erDiagram\n  \"<img src=x onerror=alert(1)>\" {\n    `<script>` `a&b` PK \"</text><script>alert(1)</script>\"\n  }",
  )
  inspect(svg.contains("<img"), content="false")
  inspect(svg.contains("<script"), content="false")
  inspect(svg.contains("a&amp;b"), content="true")
  inspect(
    svg.contains("data-id=\"&lt;img src=x onerror=alert(1)&gt;\""),
    content="true",
  )
}

///|
test "never gives an unsafe href to an internal link" {
  let result = drawn("erDiagram\n  \"javascript:alert(1)\":::internal-link").unwrap()
  inspect(
    result.svg.contains(
      "<a class=\"internal-link\" data-href=\"javascript:alert(1)\">",
    ),
    content="true",
  )
  inspect(
    result.links.map(l => "\{l.id} \{l.href} \{l.internal}").join("\n"),
    content="javascript:alert(1) javascript:alert(1) true",
  )
}

///|
test "never gives an href to an internal link that sanitizing alone would let through" {
  let options = {
    ..@types.RenderOptions::default(),
    link_schemes: Some(["about"]),
  }
  let svg = @core.render(
      [@er.er],
      "erDiagram\n  \"javascript:alert(1)\":::internal-link",
      options,
    ).svg
  assert_false(svg.contains(" href="))
}

///|
test "names that are object keys in pele are plain names" {
  let sources = [
    "erDiagram\n  __proto__ ||--o{ constructor : toString\n  __proto__ {\n    __proto__ __proto__ PK \"__proto__\"\n  }",
    "erDiagram\n  A\n  classDef __proto__ fill:red\n  class A __proto__\n  class __proto__ constructor\n  style __proto__ fill:red\n",
    "erDiagram\n  subgraph __proto__ [constructor]\n  hasOwnProperty\n  end\n  __proto__ ||--|| prototype : x",
  ]
  for source in sources {
    let svg = svg_of(source)
    inspect(svg.has_prefix("<svg"), content="true")
    inspect(svg.contains("[object"), content="false")
  }
}
