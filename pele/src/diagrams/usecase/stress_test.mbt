// Ported from pele v1.8.0, tests/usecase/stress.test.ts and tests/render/usecase-security.test.ts.
// pele also bounds each worst case to three seconds; here each only has to finish.
// The security test's corpus and mutation fuzzing need pele's corpus loader and are not ported.

///|
const N : Int32 = 50000

///|
const U : String = "usecase-beta\n"

///|
fn drawn(
  source : String,
  limit? : Double,
) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), limit, }
  Ok(@core.render([@usecase.usecase], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn big(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  drawn(source, limit=1.0 / 0.0)
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
/// Whether a worst case came to an end: a drawing, or a `PeleError` rather than a trap.
fn finishes(outcome : Result[@types.RenderResult, @errors.Failure]) -> Bool {
  match outcome {
    Ok(result) => result.svg.length() > 0
    Err(failure) => failure.code is (Syntax | Semantic | Limit)
  }
}

///|
fn lexes(source : String) -> Bool {
  try @usecase.tokenize(source).types.length() > 0 catch {
    @errors.PeleError(failure) => failure.code is Syntax
  }
}

///|
fn parses(source : String) -> Bool {
  try {
    @usecase.parse_usecase(source) |> ignore
    true
  } catch {
    @errors.PeleError(failure) => failure.code is (Syntax | Semantic)
  }
}

///|
test "inputs that make a naive lexer rescan the text are read in one pass" {
  let sources = [
    U + "A " + "-".repeat(N) + " B",
    U + "-- ".repeat(N / 3),
    U + "A <<x\n".repeat(N / 6),
    U + "A " + "<<".repeat(N / 2),
    U + "A <<x\n".repeat(N / 6) + ">>",
    U + "accDescr {\n".repeat(N / 11),
    U + "accDescr {\n".repeat(N / 11) + "}",
    U + ("accTitle" + " ".repeat(40) + "\n").repeat(N / 49),
    U + "\"`x".repeat(N / 3),
    U + "A \"x".repeat(N / 4),
    U + "json P@" + "{".repeat(N),
    U + "json P@{ \"a\": \n".repeat(N / 15),
    U + ("A" + " ".repeat(40) + "%%\n").repeat(N / 44),
    U + (" ".repeat(100) + "%".repeat(100) + "\n").repeat(N / 201),
    U + "endx forx notex truex classDefx jsonx ".repeat(N / 38),
    U + "é日".repeat(N / 2),
  ]
  for source in sources {
    inspect(lexes(source), content="true")
  }
}

///|
test "long statements and deep nesting are parsed without overflowing" {
  let sources = [
    U + "A(" + "word ".repeat(20000) + ")",
    U + "A -- " + "word ".repeat(N / 5),
    U + repeat_lines(10000, i => "A\{i} -- x y z\n"),
    U + "actor A\nA@{\n" + "business: true,\n".repeat(10000) + "}",
    U + "A@{" + "\n".repeat(N) + "}\nA",
    U +
    repeat_lines(2500, i => "e\{i}\n") +
    "class " +
    repeat_lines(2500, i => "e\{i},") +
    "e0 " +
    repeat_lines(4000, i => "c\{i},") +
    "z\n",
    U + "A\nstyle A fill:" + ":#".repeat(N / 2),
    U + "systemBoundary S\n" + repeat_lines(10000, i => "u\{i}\n") + "end",
    U + "actor A\n" + "A@{ type: hollow }\n".repeat(5000),
    U + "json P@{\"a\":\"" + "x".repeat(N) + "\",}",
  ]
  for source in sources {
    inspect(parses(source), content="true")
  }
}

///|
test "large and hostile diagrams are drawn" {
  let complete = StringBuilder()
  complete.write_string(U)
  for i in 0..<40 {
    for j in (i + 1)..<40 {
      complete.write_string("n\{i} --o n\{j}\n")
    }
  }
  let sources = [
    U + "'\"".repeat(N / 2),
    U + "A:::" + repeat_lines(8000, i => "c\{i},") + "z\n",
    U +
    "A\nclassDef " +
    repeat_lines(8000, i => "c\{i},") +
    "z " +
    repeat_lines(8000, i => "x\{i}:1,") +
    "fill:red\nclass A z\n",
    U + "A(A) <<S>>:::c\n".repeat(10000),
    U + repeat_lines(3000, i => "systemBoundary s\{i}\n u\{i}\nend\n"),
    U + "A\n" + "note for A \"n\"\n".repeat(5000),
    U + "json P@" + "{\"a\":".repeat(12000) + "1" + "}".repeat(12000),
    U + "json P@{\"a\":" + "[".repeat(20000) + "]".repeat(20000) + "}",
    U + "json P@{" + repeat_lines(8000, i => "\"k\{i}\":\{i},") + "\"z\":0}",
    U + "json P@{" + "\"k\":{\"a\":{}},".repeat(8000) + "\"z\":0}",
    U +
    "json P@{" +
    repeat_lines(5000, i => "\"k\{i}\":{},") +
    "\"d\":1,".repeat(5000) +
    "\"z\":0}",
    U + "json P@{\"a\":[" + "1,".repeat(20000) + "1]}",
    U + "A(\"" + "word ".repeat(N / 5) + "\")",
    U + "actor A(\"" + "a".repeat(N) + "\")",
    U + "A(\"" + "#35;&amp;<br>".repeat(N / 13) + "\")",
    U + "A(\"`" + "*a _b ".repeat(N / 6) + "`\")",
    U + "A -- \"" + "word ".repeat(N / 5) + "\" --> B",
    U + repeat_lines(3000, i => "actor a\{i}\n"),
    U + repeat_lines(3000, i => "n\{i} --> n\{i + 1}\n"),
    U + repeat_lines(3000, i => "actor a\{i}\na\{i} --> hub\n"),
    U + "A --> B\n".repeat(2000) + "A -- l --> A\n".repeat(1000),
    complete.to_string(),
    U + "A " + "-".repeat(10000) + "> B",
    U +
    "systemBoundary S\n U\n V\nend\n" +
    repeat_lines(1000, i => "actor a\{i}\na\{i} --> U\nV --> a\{i}\n"),
  ]
  for source in sources {
    inspect(finishes(big(source)), content="true")
  }
}

///|
test "refuses source over the default limit" {
  let outcome = match drawn(U + "A --> B\n".repeat(8000)) {
    Ok(_) => ""
    Err(failure) => failure.message
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
      if fnv1a(render_outcome(source)) != hostile_outcomes[k] {
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
    U +
    "actor \"<img src=x onerror=alert(1)>\" <<</text><script>alert(1)</script >>\n'<script>a&b</script>'\njson P@{\"<b>\": \"</text><script>alert(1)</script>\"}\nnote for P2 \"<svg onload=alert(1)>\"\nP2",
  )
  inspect(svg.contains("<img"), content="false")
  inspect(svg.contains("<script"), content="false")
  inspect(svg.contains("<svg onload"), content="false")
  inspect(svg.contains("&lt;script&gt;a&amp;b&lt;/script&gt;"), content="true")
  inspect(
    svg.contains("data-id=\"_img_src_x_onerror_alert_1__\""),
    content="true",
  )
  inspect(svg.contains(">&lt;b&gt;</text>"), content="true")
  inspect(
    svg.contains("«&lt;/text&gt;&lt;script&gt;alert(1)&lt;/script»"),
    content="true",
  )
}

///|
test "never emits the icon name as markup" {
  let svg = svg_of(U + "actor A@{ icon: '\"><script>alert(1)</script>' }")
  inspect(
    svg.contains(
      "data-icon=\"&quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt;\"",
    ),
    content="true",
  )
  inspect(svg.contains("<script"), content="false")
}

///|
test "names that are object keys in pele are plain names" {
  let sources = [
    U +
    "actor __proto__\n__proto__ constructor@--> toString\nconstructor@{ animate: true }\nnote for toString \"__proto__\"",
    U +
    "A\nclassDef __proto__ fill:red\nclass A __proto__\nstyle A fill:red\nA@{ business: true }",
    U +
    "systemBoundary __proto__[constructor]\n  hasOwnProperty\n  actor valueOf\nend\n__proto__@{ type: package }",
    U +
    "json __proto__@{\"__proto__\": {\"polluted\": true}, \"constructor\": {\"prototype\": {\"polluted\": true}}}\nA --> __proto__",
  ]
  for source in sources {
    let svg = svg_of(source)
    inspect(svg.has_prefix("<svg"), content="true")
    inspect(svg.contains("[object"), content="false")
  }
  let svg = svg_of(U + "json P@{\"__proto__\": {\"x\": 1}, \"constructor\": 2}")
  inspect(svg.contains(">__proto__.x</text>"), content="true")
  inspect(svg.contains(">constructor</text>"), content="true")
}
