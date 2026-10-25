// pele's class-security templates and payloads (tests/render/class-security.test.ts, tests/support/inert.ts), with a hash of what pele v1.8.0's render gives each template with every payload, as written and with its quotes as #quot;.

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
  "<script>alert(1)</script>", "\"><script>alert(1)</script>", "<img src=x onerror=alert(1)>",
  "<svg onload=alert(1)>", "<a href=\"javascript:alert(1)\">x</a>", "<foreignObject><iframe src=javascript:alert(1)></iframe></foreignObject>",
  "</text></g></svg><script>alert(1)</script>", "javascript:alert(1)", "JaVaScRiPt:alert(1)",
  " javascript:alert(1)", "jav&#x09;ascript:alert(1)", "data:text/html,<script>alert(1)</script>",
  "vbscript:msgbox(1)", "' onload='alert(1)", "\" onmouseover=\"alert(1)", "x\" onclick=\"alert(1)\" y=\"",
  "#60;script#62;alert(1)#60;/script#62;", "#106;avascript:alert(1)", "#34; onload=#34;alert(1)",
  "url#40;javascript:alert#40;1#41;#41;", "red#59;background:url#40;//evil.example/x#41;",
  "&lt;script&gt;alert(1)&lt;/script&gt;", "&#60;script&#62;", "url(javascript:alert(1))",
  "expression(alert(1))", "red;background:url(//evil.example/x)", "red\" onload=\"alert(1)",
  "]]><script>alert(1)</script>", "--><script>alert(1)</script>", "\u{0}\u{1}\u{8}\u{b}\u{1f}",
  "__proto__", "constructor", "toString", "hasOwnProperty", "{{7*7}}", "${alert(1)}",
  "%0ajavascript:alert(1)", "file:///etc/passwd", "//evil.example/share", "\\\\evil.example\\share",
  "smb://evil.example/share", "obsidian://open?vault=x", "\\\"><script>",
]

///|
/// The hash of the outcomes of each template with every payload.
let hostile_outcomes : Array[String] = [
  "43b7ac39", "630245e1", "b9cdec51", "1ccee52f", "12d4c507", "981e611f", "c27d454d",
  "b5ebd899", "e7f2ddf0", "d232d954", "752f15ba", "d870c79e", "7559bbbc", "8f60c1a5",
  "a572c8be", "59a0eb4f", "e23d98f5", "3b4dfedc", "9328db46", "023adbe1", "6fa6f64e",
  "c61c51e9", "a5ae0cb7", "92c97d5a", "888ab963", "47aeaab6", "e3835ccd", "95008e5f",
  "66eb1a1f", "6c775837", "c8c1ad87", "702f99b3", "949e93ce", "31f0d09f", "b72421c1",
  "60e87359", "19651c67", "06d65eff", "58c92ca5", "ea09a1ed", "f75b5035", "febea0f9",
  "8050909f", "2b326b97", "8ec861cc", "69d64e9d", "73050da3", "ab420e19", "21ecdaad",
]

///|
let hostile_option_outcomes : Array[String] = ["6263db63", "d1ac8a36"]

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
