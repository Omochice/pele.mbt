// Ported from pele v1.8.0, tests/agentflow/stress.test.ts and tests/render/agentflow-security.test.ts.
// pele also bounds each worst case to three seconds; here each only has to finish.

///|
const N : Int32 = 50000

///|
const H : String = "agentflow-beta TB\n"

///|
fn drawn(
  source : String,
  limit? : Double,
) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), limit, }
  Ok(@core.render([@agentflow.agentflow], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn big(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  drawn(source, limit=1.0 / 0.0)
}

///|
fn parsed(source : String) -> Result[Unit, @errors.Failure] {
  Ok(@agentflow.parse_agentflow(source, @agentflow.AgentflowDb::new())) catch {
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
    Err(failure) => failure.code is (Syntax | Semantic | Limit)
  }
}

///|
test "inputs that make a naive lexer rescan the text are read in one pass" {
  let sources = [
    H + "A ".repeat(N / 2) + "direction XX",
    H + "direction ".repeat(N / 10),
    H + ("direction" + "\n".repeat(9)).repeat(N / 18) + "TB",
    H + "A direction B\n".repeat(N / 14),
    H + "direction" + " ".repeat(N) + "XX",
    H + " ".repeat(N) + "a",
    H + "a" + " ".repeat(N) + "-b",
    H + ("a" + " ".repeat(99) + "-b\n").repeat(N / 103),
    H + "a" + " ".repeat(N / 2) + "-" + ".".repeat(N / 2),
    H + "a" + " ".repeat(N / 2) + "-".repeat(N / 2) + "b",
    H + " ".repeat(N) + "%x",
    H + (" ".repeat(99) + "%%{\n").repeat(N / 103),
    H + "a -- " + " ".repeat(N) + "-b",
    H + "a -- " + " -".repeat(N / 2),
    H + "a -- x" + " ".repeat(N / 2) + "-".repeat(N / 2),
    H + "a -- " + "x ".repeat(N / 2) + "--> b",
    H + "a@".repeat(N / 2),
    H + "@".repeat(N) + "{",
    H + "a[\"" + "x%".repeat(N / 2),
    H + "a[\"`" + "x ".repeat(N / 2),
    H + "a[" + "x %% c\n".repeat(N / 7) + "]",
    H + "a(-" + "x %% c\n".repeat(N / 7) + "-)",
    H + "a[/" + "x %% c\n".repeat(N / 7) + "/]",
    H + "a" + "[(".repeat(N / 2),
    H + "a@{" + " k: \"v\",".repeat(N / 8),
    H + ("accTitle" + " ".repeat(40)).repeat(N / 48),
    H + "accDescr {" + " text\n".repeat(N / 6),
  ]
  for source in sources {
    let tokens = @agentflow.tokenize(source)
    assert_true(tokens.types.length() > 0)
  }
}

///|
test "long statements and deep nesting are parsed without overflowing" {
  let sources = [
    H + "  %% note\n".repeat(10000) + "a --> b\n",
    H + ("}" + " ".repeat(49)).repeat(N / 50),
    H + "A\nstyle A " + ":#".repeat(N / 2) + "\n",
    H +
    "class " +
    repeat_lines(10000, i => "e\{i},") +
    "z " +
    repeat_lines(10000, i => "c\{i},") +
    "z\n",
    H + "flow s\n".repeat(20000) + "A\n" + "end\n".repeat(20000),
    H + "flow s\n" + repeat_lines(10000, i => "n\{i}\n") + "end\n",
    H + "flow s\n".repeat(N / 7),
  ]
  for source in sources {
    match parsed(source) {
      Ok(_) => ()
      Err(failure) => assert_true(failure.code is (Syntax | Limit))
    }
  }
}

///|
test "large diagrams are drawn" {
  let sources = [
    H + "A\nstyle A " + repeat_lines(10000, i => "x\{i}:1,") + "fill:red\n",
    H + "A:::" + repeat_lines(20000, i => "c\{i},") + "z\n",
    H + "a --> b\nlinkStyle " + "0,".repeat(10000) + "0 stroke:red\n",
    H +
    repeat_lines(3000, i => "flow s\{i}\n") +
    "A --> B\n" +
    "end\n".repeat(3000),
    H +
    repeat_lines(3000, i => "flow s\{i}@{ view: collapsed }\n") +
    "A --> B\n" +
    "end\n".repeat(3000),
    H +
    repeat_lines(1500, i => "flow s\{i}\n") +
    "A\n" +
    "end\n".repeat(1500) +
    "A --> B\n".repeat(1000),
    H + repeat_lines(5000, i => "flow s\{i}\nn\{i}\nend\n"),
    H + "flow s\nA\nB\nC\nend\n".repeat(5000),
    H + repeat_lines(3000, i => "flow f\{i}\n a\{i} --> f\{i + 1}\nend\n"),
    H +
    repeat_lines(2000, i => {
      let other = if i == 0 { 1999 } else { i - 1 }
      "flow f\{i}\n a\{i} --> f\{other}\nend\n"
    }),
    H +
    "flow f\n" +
    repeat_lines(3000, i => "n\{i}\n") +
    "end\n" +
    repeat_lines(3000, i => "global\nn\{i}\nend\n"),
    H +
    repeat_lines(5000, i => "connector c\{i}[\"C\"]@{ protocol: \"mcp\" }\n"),
    H + "a\n" + repeat_lines(5000, i => "a@{ k\{i}: \{i} }\n"),
    H + "a e1@--> b\n" + repeat_lines(5000, i => "e1@{ k\{i}: \{i} }\n"),
    H + "a@{\n" + repeat_lines(5000, i => "  k\{i}: \"v\",\n") + "}\n",
    H + "a@{ k: " + "[".repeat(N / 2) + " }\n",
    H + "a@{\n" + "  k: 'a,\n".repeat(N / 9) + "}\n",
    H + repeat_lines(4000, i => "n\{i}((x))\n"),
    H + repeat_lines(3000, i => "n\{i}@{ shape: tri }\n"),
    H + "a[\"" + "word ".repeat(N / 5) + "\"]",
    H + "a[\"`" + "*a _b ".repeat(N / 6) + "`\"]",
    H + "a[\"" + "#35;&amp;<br>".repeat(N / 13) + "\"]",
    H + "a -- \"" + "word ".repeat(N / 5) + "\" --> b",
    H + "a".repeat(N) + " --> b",
    H + repeat_lines(5000, i => "n\{i}\n"),
    H + repeat_lines(5000, i => "n\{i} --> n\{i + 1}\n"),
    H + "n" + repeat_lines(5000, i => " --> n\{i}") + "\n",
    H + repeat_lines(5000, i => "c --> n\{i}\n"),
    H +
    repeat_lines(150, i => "a\{i} & ") +
    "a --> b" +
    repeat_lines(150, i => " & b\{i}") +
    "\n",
    H + "A --> B\n".repeat(2000) + "A --> A\n".repeat(2000),
    H + "flow f\n" + repeat_lines(1200, i => "n\{i} --> f\n") + "end\n",
    H + "flow f\na --> b\n" + "a --> f\nf --> b\n".repeat(2500) + "end\n",
    H + "flow a\nA\nend\nflow b\nB\nend\n" + "a --> b\nA -.- b\n".repeat(1000),
  ]
  for source in sources {
    assert_true(finishes(big(source)))
  }
}

///|
test "a complete graph of 50 is drawn" {
  let out = StringBuilder()
  out.write_string(H)
  for i in 0..<50 {
    for j in (i + 1)..<50 {
      out.write_string("n\{i} --> n\{j}\n")
    }
  }
  assert_true(finishes(big(out.to_string())))
}

///|
test "refuses source over the default limit" {
  match drawn(H + "A --> B\n".repeat(7000)) {
    Ok(_) => fail("drew source over the limit")
    Err(failure) => assert_true(failure.message.contains("limit of 50000"))
  }
}

///|
/// FNV-1a over UTF-16 code units, the hash under which `hostile_outcomes` were taken from pele.
fn hash(text : String) -> String {
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
      let actual = hash(render_outcome(source))
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
  let svg = drawn(
      H +
      "  a[\"<img src=x onerror=alert(1)>\"] -- \"</text><script>alert(1)</script>\" --> b[\"a&b\"]\n  flow f[\"<svg onload=alert(1)>\"]\n   c\n  end",
    ).unwrap().svg
  inspect(svg.contains("<img"), content="false")
  inspect(svg.contains("<script"), content="false")
  inspect(svg.contains("<svg onload"), content="false")
  inspect(svg.contains("a&amp;b"), content="true")
}

///|
test "escapes ids in attributes" {
  let svg = drawn(H + "  flow q&r\n  a\n  end\n  connector 'x&y'").unwrap().svg
  inspect(svg.contains("data-id=\"q&amp;r\""), content="true")
  inspect(svg.contains("data-id=\"'x&amp;y'\""), content="true")
}

///|
test "never links to a script" {
  for
    url in [
      "javascript:alert(1)", " JaVaScRiPt:alert(1)", "data:text/html,<script>alert(1)</script>",
      "vbscript:x",
    ] {
    let result = drawn(H + "  a\n  click a href \"\{url}\"").unwrap()
    let svg = result.svg.to_lower()
    assert_false(svg.contains("href=\"javascript"))
    assert_false(svg.contains("href=\" javascript"))
    assert_false(svg.contains("href=\"data"))
    assert_false(svg.contains("href=\"vbscript"))
    for link in result.links {
      let href = @util.trim(link.href).to_lower()
      assert_false(
        href.has_prefix("javascript:") ||
        href.has_prefix("data:") ||
        href.has_prefix("vbscript:"),
      )
    }
  }
}

///|
test "never gives an unsafe href to an internal link" {
  let result = drawn(H + "  a[\"javascript:alert(1)\"]:::internal-link").unwrap()
  inspect(
    result.svg.contains(
      "<a class=\"internal-link\" data-href=\"javascript:alert(1)\">",
    ),
    content="true",
  )
  inspect(
    result.links.map(l => "\{l.id}|\{l.href}|\{l.internal}").join(";"),
    content="a|javascript:alert(1)|true",
  )
}

///|
test "never gives an href to an internal link that sanitizing alone would let through" {
  let options = {
    ..@types.RenderOptions::default(),
    link_schemes: Some(["about"]),
  }
  let svg = @core.render(
      [@agentflow.agentflow],
      H + "  a[\"javascript:alert(1)\"]:::internal-link",
      options,
    ).svg
  assert_false(svg.contains(" href="))
}

///|
test "names that are object keys in pele are plain names" {
  let sources = [
    H +
    "  __proto__ --> constructor --> toString\n  flow __proto__[constructor]\n  hasOwnProperty\n  end\n  connector prototype[\"__proto__\"]",
    H +
    "  a\n  classDef __proto__ fill:red\n  class a __proto__\n  class __proto__ constructor\n  style __proto__ fill:red\n  a:::__proto__",
    H +
    "  a@{ __proto__: 1, constructor: 2, prototype: 3 }\n  a@{\n    __proto__:\n      polluted: true\n    constructor:\n      prototype:\n        polluted: true\n  }",
    H +
    "  a[|__proto__:polluted|x]\n  global\n  __proto__\n  end\n  flow f@{ __proto__: 1 }\n  __proto__\n  end",
  ]
  for source in sources {
    assert_true(drawn(source) is Ok(_))
  }
  let db = @agentflow.parse_model(
    H + "  a@{ shape: constructor }",
    {},
    None,
    0,
    { max_edges: 5000, },
  )
  ignore(@agentflow.agent_graph(db, {}))
  inspect(db.diagnostics.map(d => d.id).join(","), content="SHAPE_UNSUPPORTED")
}

///|
test "more edges than maxEdges is a limit error that names the limit" {
  let options = { ..@types.RenderOptions::default(), max_edges: Some(2.0), }
  let message = try {
    @core.render(
      [@agentflow.agentflow],
      "agentflow-beta TB\n  a --> b\n  b --> c\n  c --> d",
      options,
    )
    |> ignore
    ""
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()} \{failure.message}"
  }
  inspect(message, content="limit Edge limit exceeded. The limit is 2.")
}
