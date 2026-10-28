// pele's class-security templates and payloads (tests/render/class-security.test.ts, tests/support/inert.ts), with a hash of what pele's render gives each template with every payload, as written and with its quotes as #quot;, taken from pele v1.12.0.

///|
/// Each template as the text around the places its payload goes.
let hostile_templates : Array[Array[String]] = [
  ["classDiagram\n  class ", ""],
  ["classDiagram\n  class `", "`"],
  ["classDiagram\n  class A[\"", "\"]"],
  ["classDiagram\n  class A~", "~"],
  ["classDiagram\n  class A:::", ""],
  ["classDiagram\n  class A <<", ">>"],
  ["classDiagram\n  <<", ">> A"],
  ["classDiagram\n  class A {\n    ", "\n  }"],
  [
    "classDiagram\n  class A {\n    +", "()\n    -", " x$\n    #f(", ") ", "*\n    <<",
    ">>\n  }",
  ],
  [
    "classDiagram\n  class A {\n    +List~", "~ x\n    +f(Map~", ", ", "~ m) List~",
    "~\n  }",
  ],
  ["classDiagram\n  A : ", ""],
  ["classDiagram\n  A : +", "()"],
  ["classDiagram\n  ", " <|-- B"],
  ["classDiagram\n  `", "` <|-- `", "2`"],
  ["classDiagram\n  A <|-- B : ", ""],
  ["classDiagram\n  A \"", "\" --> \"", "\" B : ", ""],
  ["classDiagram\n  A \"", "\" --> \"", "\" A : ", ""],
  ["classDiagram\n  ", " ()-- A"],
  ["classDiagram\n  A --() `", "`"],
  ["classDiagram\n  note \"", "\""],
  ["classDiagram\n  class A\n  note for A \"", "\""],
  ["classDiagram\n  note for `", "` \"x\""],
  ["classDiagram\n  namespace ", " {\n    class A\n  }"],
  ["classDiagram\n  namespace `", "` {\n    class A\n  }"],
  [
    "classDiagram\n  namespace N[\"", "\"] {\n    class A\n    note \"", "\"\n  }",
  ],
  ["classDiagram\n  class A\n  link A \"", "\""],
  ["classDiagram\n  class A\n  link A \"", "\" \"", "\" _blank"],
  ["classDiagram\n  class A\n  link A \"https://example.com\" ", ""],
  ["classDiagram\n  class A\n  click A href \"", "\" \"", "\""],
  ["classDiagram\n  class A\n  click A href \"x\" \"", "\" _top"],
  ["classDiagram\n  class A\n  click A call ", "()"],
  ["classDiagram\n  class A\n  click A call f(", ") \"", "\""],
  ["classDiagram\n  class A\n  callback A \"", "\" \"", "\""],
  ["classDiagram\n  class A\n  style A fill:", ""],
  ["classDiagram\n  class A\n  style A ", ":red"],
  [
    "classDiagram\n  class A\n  style A color:", ",stroke:", ",font-family:", ",font-size:",
    "",
  ],
  ["classDiagram\n  class A\n  style ", " fill:red"],
  ["classDiagram\n  class A:::c\n  classDef c fill:", ",color:", ""],
  [
    "classDiagram\n  class A {\n +x$\n}\n  classDef default color:", ",stroke:",
    "",
  ],
  ["classDiagram\n  class A\n  classDef ", " fill:red\n  cssClass \"A\" ", ""],
  ["classDiagram\n  class A\n  cssClass \"", "\" c"],
  ["classDiagram\n  class A\n  cssClass \"A\" ", ""],
  ["classDiagram\n  accTitle: ", "\n  accDescr: ", "\n  class A"],
  ["classDiagram\n  accDescr {\n ", "\n }\n  class A"],
  ["classDiagram\n  direction ", "\n  class A"],
  ["classDiagram\n  %% ", "\n  class A"],
  ["classDiagram ", "\n  class A"],
  [
    "---\ntitle: \"", "\"\nconfig:\n  class:\n    hideEmptyMembersBox: \"", "\"\n    nodeSpacing: \"",
    "\"\n    hierarchicalNamespaces: \"", "\"\n---\nclassDiagram\n  class A",
  ],
  [
    "%%{init: {\"class\": {\"rankSpacing\": \"", "\"}, \"themeVariables\": {\"fontFamily\": \"",
    "\"}}}%%\nclassDiagram\n  A --> B",
  ],
]

///|
let hostile_payloads : Array[String] = [
  "<script>alert(1)</script>",
  "\"><script>alert(1)</script>",
  "<img src=x onerror=alert(1)>",
  "<svg onload=alert(1)>",
  "<a href=\"javascript:alert(1)\">x</a>",
  "<foreignObject><iframe src=javascript:alert(1)></iframe></foreignObject>",
  "</text></g></svg><script>alert(1)</script>",
  "javascript:alert(1)",
  "JaVaScRiPt:alert(1)",
  " javascript:alert(1)",
  "jav&#x09;ascript:alert(1)",
  "data:text/html,<script>alert(1)</script>",
  "vbscript:msgbox(1)",
  "' onload='alert(1)",
  "\" onmouseover=\"alert(1)",
  "x\" onclick=\"alert(1)\" y=\"",
  "#60;script#62;alert(1)#60;/script#62;",
  "#106;avascript:alert(1)",
  "#34; onload=#34;alert(1)",
  "url#40;javascript:alert#40;1#41;#41;",
  "red#59;background:url#40;//evil.example/x#41;",
  "&lt;script&gt;alert(1)&lt;/script&gt;",
  "&#60;script&#62;",
  "url(javascript:alert(1))",
  "expression(alert(1))",
  "red;background:url(//evil.example/x)",
  "red\" onload=\"alert(1)",
  "]]><script>alert(1)</script>",
  "--><script>alert(1)</script>",
  "\u{0}\u{1}\u{8}\u{b}\u{1f}",
  "a￾b￿c" +
  String::from_array([(0xd800).unsafe_to_char()]) +
  "d" +
  String::from_array([(0xdc00).unsafe_to_char()]) +
  "e#65534;f",
  "u\u{1}rl(//evil.example/x)",
  "u￾RL(//evil.example/x)",
  "u" + String::from_array([(0xd800).unsafe_to_char()]) + "rl(//evil.example/x)",
  "java￾script:alert(1)",
  "java" + String::from_array([(0xdc00).unsafe_to_char()]) + "script:alert(1)",
  "file￿:///etc/passwd",
  "__proto__",
  "constructor",
  "toString",
  "hasOwnProperty",
  "{{7*7}}",
  "${alert(1)}",
  "%0ajavascript:alert(1)",
  "file:///etc/passwd",
  "//evil.example/share",
  "\\\\evil.example\\share",
  "#92;#92;nevil.example/share",
  "\u{9}/#92;nevil.example/share",
  "smb://evil.example/share",
  "obsidian://open?vault=x",
  "\\\"><script>",
]

///|
/// The hash of the outcomes of each template with every payload.
let hostile_outcomes : Array[String] = [
  "c7aab731", "86925e3b", "12f38479", "02e4ab1f", "7b1799e7", "905e1987", "0c3c2bbd",
  "49bdd2d9", "6e9d3414", "66aabfaa", "d2cfa80e", "d9e96208", "82301534", "13e96bc3",
  "85ef632a", "9305829b", "f9823667", "7bc8fb5c", "282af766", "008541d9", "591bacbe",
  "0b31b1e9", "1a92d9b1", "b67828da", "17276f89", "69f81bc6", "afe5520b", "2e70d6ee",
  "a5b5f2fd", "72baffcb", "f7f78d62", "dbdc3401", "7a1b79cc", "4ae5ea17", "41eb32c9",
  "e082c377", "0dae2f35", "fc7bad3b", "a3e51def", "b52ba16d", "f494737d", "147e622b",
  "005e847d", "43e33895", "cd882d2f", "6b8ee925", "6ab72087", "f97254d9", "a9b29165",
]

///|
let hostile_option_outcomes : Array[String] = ["3b7176fe", "d1ac8a36"]

///|
/// What rendering gives, written as the generator of `hostile_outcomes` writes pele's.
fn render_outcome(
  source : String,
  options~ : @types.RenderOptions = @types.RenderOptions::default(),
) -> String {
  let result = Ok(@core.render([@class.class], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
  match result {
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
  for t, pieces in hostile_templates {
    let all = StringBuilder()
    for payload in hostile_payloads {
      all.write_string(render_outcome(pieces.join(payload)) + "\n")
      let quoted = payload.replace_all(old="\"", new="#quot;")
      all.write_string(render_outcome(pieces.join(quoted)) + "\n")
    }
    if fnv1a(all.to_string()) != hostile_outcomes[t] {
      wrong.push("template \{t}")
    }
  }
  inspect(
    hostile_templates.length() == hostile_outcomes.length(),
    content="true",
  )
  inspect(wrong.join("\n"), content="")
}

///|
test "hostile options are drawn as pele draws them" {
  let all = StringBuilder()
  for payload in hostile_payloads {
    all.write_string(
      render_outcome("classDiagram\n  accTitle: t\n  A \"1\" --> \"2\" B : x", options={
        ..@types.RenderOptions::default(),
        id_prefix: Some(payload),
        font_family: Some(payload),
      }) +
      "\n",
    )
    all.write_string(
      render_outcome("classDiagram\n  A --> B", options={
        ..@types.RenderOptions::default(),
        config: Some({
          "class": {
            "nodeSpacing": Json::string(payload),
            "rankSpacing": Json::string(payload),
          },
        }),
      }) +
      "\n",
    )
  }
  inspect(fnv1a(all.to_string()), content=hostile_option_outcomes[0])
  let numbers = StringBuilder()
  for
    value in [
      @double.not_a_number, @double.infinity, @double.neg_infinity, -1.0, 1.0e308,
    ] {
    numbers.write_string(
      render_outcome("classDiagram\n  A \"1\" --> \"2\" B : x", options={
        ..@types.RenderOptions::default(),
        config: Some({
          "class": {
            "nodeSpacing": Json::number(value),
            "rankSpacing": Json::number(value),
          },
        }),
      }) +
      "\n",
    )
  }
  inspect(fnv1a(numbers.to_string()), content=hostile_option_outcomes[1])
}

///|
test "never emits a script URL as a link, nor anything from a callback" {
  for
    url in [
      "javascript:alert(1)", "JAVASCRIPT:alert(1)", " javascript:alert(1)", "java\tscript:alert(1)",
      "data:text/html,x", "vbscript:x", "&#106;avascript:alert(1)",
    ] {
    let result = drawn("classDiagram\n  class A\n  link A \"\{url}\"").unwrap()
    inspect(result.svg.contains("<a"), content="false")
    inspect(result.links.length(), content="0")
  }
  let result = drawn(
    "classDiagram\n  class A\n  click A call stealCookies(\"now\") \"tip\"\n  callback A \"stealCookies\"",
  ).unwrap()
  inspect(result.svg.contains("stealCookies"), content="false")
  inspect(result.svg.contains("<a"), content="false")
  inspect(result.links.length(), content="0")
}
