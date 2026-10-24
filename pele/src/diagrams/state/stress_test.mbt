// Ported from pele v1.8.0, tests/state/stress.test.ts and tests/render/state-security.test.ts.
// pele also bounds each worst case to three seconds; here each only has to finish.

///|
const N : Int32 = 50000

///|
fn big(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
  Ok(@core.render([@state.state], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn parse_only(source : String) -> Result[Unit, @errors.Failure] {
  ignore(@state.parse_state(source, @state.StateDb::new())) catch {
    @errors.PeleError(failure) => return Err(failure)
  }
  Ok(())
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
    Err(failure) => failure.code is (Syntax | Semantic | Limit)
  }
}

///|
let head : String = "stateDiagram-v2\n"

///|
test "inputs that make a naive lexer rescan the text are read in one pass" {
  let sources = [
    head + "a direction XX ".repeat(N / 15),
    head + "direction TB direction lr ".repeat(N / 26),
    head + ("direction" + "\n".repeat(24)).repeat(N / 33),
    head + "a b ".repeat(N / 4) + "direction TB",
    head + "a ".repeat(N / 2) + "\"" + "b ".repeat(N / 2),
    head + "state " + "<<fork> [[join] ".repeat(N / 16),
    head + "state " + "x <<choice>> ".repeat(N / 13),
    head + "state ".repeat(N / 6),
    head + "state a" + " ".repeat(N) + "b",
    head + "state " + "w ".repeat(N / 2),
    head +
    repeat_lines(2000, _ => "state a\n") +
    "state " +
    "w".repeat(N / 2) +
    " x {",
    head + "a%%{".repeat(N / 4),
    head + "state \"x\" as " + "%%{".repeat(N / 3),
    head + "note right of a\n" + "\n ".repeat(N / 2),
    head + "note right of a\n" + " end not\n".repeat(N / 9),
    head + "note left of" + " ".repeat(N) + ": x",
    head + "note \"" + " ".repeat(N) + "x\" as n",
    head + "class a" + ", ".repeat(N / 2),
    head + "a " + ":x".repeat(N / 2),
    head + "-".repeat(N / 2) + ":".repeat(N / 2),
    head + "accTitle" + " ".repeat(N) + "x",
    head + "scale 1" + " ".repeat(N) + "x",
  ]
  for source in sources {
    inspect(@state.tokenize(source).types.length() > 0, content="true")
  }
}

///|
test "long statements and deep nesting are parsed without overflowing" {
  let sources = [
    head + "accDescr {" + "x ".repeat(N / 2),
    head + "state s{\n".repeat(6000) + "}\n".repeat(6000),
  ]
  for source in sources {
    match parse_only(source) {
      Ok(_) => ()
      Err(failure) => inspect(failure.code is Syntax, content="true")
    }
  }
}

///|
test "large diagrams are drawn" {
  let complete = StringBuilder()
  complete.write_string(head)
  for i in 0..<60 {
    for j in (i + 1)..<60 {
      complete.write_string("n\{i}-->n\{j}\n")
    }
  }
  let sources = [
    head +
    "classDef hot fill:#f00,color:white,font-weight:bold,stroke-width:2px,stroke:yellow\n" +
    "A --> B\nB --> A\nclass A hot\n".repeat(1500),
    head +
    repeat_lines(3000, i => "state s\{i}{\n") +
    "a-->b\n" +
    "}\n".repeat(3000),
    head +
    repeat_lines(2500, i => "state s\{i}{\nx\{i}\n--\n") +
    "a\n" +
    "}\n".repeat(2500),
    head + repeat_lines(5000, i => "state s\{i}{\n}\n"),
    head + "state s{\n" + repeat_lines(8000, i => "a\{i}\n--\n") + "z\n}\n",
    head + repeat_lines(5000, i => "n\{i}-->n\{i + 1}\n"),
    head + repeat_lines(5000, i => "c-->n\{i}\n"),
    head + "state f <<fork>>\n" + repeat_lines(5000, i => "f-->n\{i}\n"),
    complete.to_string(),
    head + "a-->b\n".repeat(3000) + "a-->a\n".repeat(3000),
    head + "[*]-->[*]\n".repeat(N / 12),
    head +
    repeat_lines(2500, i => {
      let side = if i % 2 == 1 { "left" } else { "right" }
      "note \{side} of a:n\n"
    }),
    head + repeat_lines(2000, i => "note right of s\{i}:n\n"),
    head + "a:x\n".repeat(N / 4),
    head + "a : " + "word ".repeat(N / 5),
    head + "note right of a\n" + "word *b _c\n".repeat(N / 11) + "end note\n",
    head + "a --> b : " + "#35;<br>x ".repeat(N / 10),
    head + "state \"" + "w ".repeat(N / 2) + "\" as s {\na\n}\n",
    head + "a\n" + repeat_lines(5000, i => "class a c\{i}\n"),
    head + "class " + repeat_lines(8000, i => "s\{i},") + "z c\n",
    head + "a\nclassDef c " + "fill:red,".repeat(N / 9) + "x\nclass a c\n",
    head + "a-->b\n" + "style a,b fill:red\n".repeat(3000),
    head + "a-->b\n" + "click a \"u\" \"t\"\n".repeat(3000),
    head + "a\nclick a \"&" + "#38;".repeat(N / 4) + "x\" \"t\"\n",
    head +
    repeat_lines(1500, i => "state s\{i}{\n") +
    "z\n" +
    "}\n".repeat(1500) +
    repeat_lines(1500, i => "s\{i}-->z\n"),
    head +
    repeat_lines(1500, i => "state s\{i}{\n") +
    "z\n" +
    "}\n".repeat(1500) +
    repeat_lines(3000, i => "o\{i}-->z\n"),
    head +
    repeat_lines(2000, i => "state a\{i}{\nstate a\{(i + 1) % 2000}{\n}\n}\n"),
    head +
    repeat_lines(1200, i => {
      "state a\{i}{\nstate a\{(i + 1) % 1200}{\nz\{i}\n}\n}\n"
    }) +
    repeat_lines(3000, i => "o\{i}-->z\{i % 1200}\n"),
    head + "state root {\n a --> b\n}\nroot --> root\n",
  ]
  for source in sources {
    inspect(finishes(big(source)), content="true")
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
fn render_outcome(
  source : String,
  options~ : @types.RenderOptions = @types.RenderOptions::default(),
) -> String {
  let outcome = Ok(@core.render([@state.state], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
  match outcome {
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
test "hostile option values are drawn as pele draws them" {
  let wrong = []
  for p, payload in hostile_payloads {
    let options = {
      ..@types.RenderOptions::default(),
      id_prefix: Some(payload),
      font_family: Some(payload),
    }
    let actual = fnv1a(
      render_outcome("stateDiagram-v2\n  accTitle: t\n  a --> b", options~),
    )
    if actual != hostile_option_outcomes[p] {
      wrong.push("payload \{p}")
    }
  }
  inspect(wrong.join("\n"), content="")
}

///|
test "never emits a script-capable link" {
  // The last two spell characters as Mermaid entity codes, which are resolved before the check.
  for
    url in [
      "javascript:alert(1)", " JaVaScRiPt:alert(1)", "data:text/html,x", "vbscript:x",
      "jav#9;ascript:alert(1)", "#106;avascript#colon;alert(1)",
    ] {
    let result = @core.render(
      [@state.state],
      "stateDiagram-v2\n  a --> b\n  click a \"\{url}\" \"t\"\n",
      @types.RenderOptions::default(),
    )
    inspect(result.svg.contains("<a "), content="false")
    inspect(result.links.length(), content="0")
  }
}

///|
test "names that are object keys in pele are plain names" {
  let sources = [
    "stateDiagram-v2\n  __proto__ --> constructor\n  constructor --> toString\n  class __proto__ constructor\n  classDef constructor fill:red",
    "stateDiagram-v2\n  state __proto__ {\n  hasOwnProperty --> valueOf\n  }\n  note right of __proto__ : x\n  style __proto__ fill:red",
    "stateDiagram-v2\n  state \"x\" as __proto__:polluted\n  click __proto__ \"x\" \"y\"\n",
  ]
  for source in sources {
    let outcome = render_outcome(source)
    inspect(outcome.has_prefix("ok "), content="true")
    inspect(outcome.contains("[object"), content="false")
  }
}
