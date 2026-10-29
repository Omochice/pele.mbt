// Ported from pele v1.8.0 tests/render/requirement-security.test.ts, with the reduced inert check of the mindmap port.

///|
/// Pele's output is inserted into pages as markup, so it must be inert whatever the diagram says:
/// only drawing elements, only presentation attributes, and nothing that loads or runs anything.
/// This is a reduced form of the check pele's tests apply, with the same allowed names.
let allowed_elements : Array[String] = [
  "svg", "g", "rect", "circle", "ellipse", "polygon", "path", "text", "tspan", "a",
  "title", "desc", "image",
]

///|
let allowed_attributes : Array[String] = [
  "xmlns", "class", "viewBox", "width", "height", "style", "font-family", "font-size",
  "font-weight", "font-style", "fill", "fill-opacity", "opacity", "stroke", "stroke-width",
  "stroke-dasharray", "stroke-linecap", "stroke-linejoin", "role", "aria-roledescription",
  "aria-labelledby", "aria-describedby", "id", "data-id", "data-icon", "data-href",
  "transform", "x", "y", "rx", "ry", "r", "cx", "cy", "d", "points", "text-anchor",
  "xml:space", "href", "target", "rel", "preserveAspectRatio", "pointer-events",
]

///|
let numeric_attributes : Array[String] = [
  "x", "y", "width", "height", "r", "cx", "cy", "rx", "ry",
]

///|
fn is_name_char(c : Int32) -> Bool {
  (c >= 'a'.to_int() && c <= 'z'.to_int()) ||
  (c >= 'A'.to_int() && c <= 'Z'.to_int()) ||
  (c >= '0'.to_int() && c <= '9'.to_int()) ||
  c == '-'.to_int() ||
  c == ':'.to_int() ||
  c == '_'.to_int()
}

///|
fn is_number(value : String) -> Bool {
  value == "100%" ||
  (
    value != "" &&
    value.iter().all(c => c.is_ascii_digit() || c is ('-' | '.' | 'e' | '+'))
  )
}

///|
fn unsafe_value(name : String, value : String) -> Bool {
  match name {
    "style" =>
      value.contains("url") ||
      value.contains("expression") ||
      value.contains("@import") ||
      value.contains("javascript:") ||
      value.iter().any(c => c is ('<' | '>' | '{' | '}' | '\\'))
    "fill" | "stroke" | "font-family" | "rx" =>
      value.contains("url") || value.contains("javascript:")
    _ => false
  }
}

///|
/// The first thing about the markup that is not inert, or `None` when there is none.
fn inert_problem(svg : String) -> String? {
  if @svg.has_invalid_xml(svg) {
    return Some("a character XML does not allow")
  }
  let n = svg.length()
  let mut i = 0
  while i < n {
    if @util.code_at(svg, i) != '<'.to_int() {
      i += 1
      continue
    }
    i += 1
    if @util.code_at(svg, i) == '/'.to_int() {
      i += 1
    }
    let start = i
    while i < n && is_name_char(@util.code_at(svg, i)) {
      i += 1
    }
    let element = @util.slice(svg, start, end=i)
    if !allowed_elements.contains(element) {
      return Some("element <\{element}>")
    }
    while true {
      while @util.is_space(@util.code_at(svg, i)) {
        i += 1
      }
      let c = @util.code_at(svg, i)
      if c == '>'.to_int() {
        i += 1
        break
      }
      if c == '/'.to_int() && @util.code_at(svg, i + 1) == '>'.to_int() {
        i += 2
        break
      }
      let name_start = i
      while i < n && is_name_char(@util.code_at(svg, i)) {
        i += 1
      }
      let name = @util.slice(svg, name_start, end=i)
      if !allowed_attributes.contains(name) {
        return Some("attribute \{name} on <\{element}>")
      }
      if @util.code_at(svg, i) != '='.to_int() ||
        @util.code_at(svg, i + 1) != '"'.to_int() {
        return Some("attribute \{name} has no quoted value")
      }
      let close = @util.index_of(svg, "\"", from=i + 2)
      if close == -1 {
        return Some("attribute \{name} is not closed")
      }
      let value = @util.slice(svg, i + 2, end=close)
      if value.contains("<") {
        return Some("\{name}=\"\{value}\" holds a tag")
      }
      if numeric_attributes.contains(name) && !is_number(value) {
        return Some("\{name}=\"\{value}\" is not a number")
      }
      if unsafe_value(name, value) {
        return Some("\{name}=\"\{value}\"")
      }
      i = close + 1
    }
  }
  None
}

///|
/// Text an attacker might put anywhere a diagram accepts a string.
let payloads : Array[String] = [
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
const BODY : String = "requirement a {\nid: 1\n}\nelement b {\ntype: t\n}\n"

///|
let templates : Array[(String) -> String] = [
  p => "requirementDiagram\nrequirement \{p} {\nid: 1\n}\n",
  p => "requirementDiagram\nrequirement \"\{p}\" {\nid: 1\n}\n",
  p => "requirementDiagram\nelement \{p} {\ntype: t\n}\n",
  p => {
    "requirementDiagram\nelement \"\{p}\" {\ntype: t\n}\n\"\{p}\" - contains -> \"\{p}\"\n"
  },
  p => "requirementDiagram\nrequirement a {\nid: \{p}\ntext: \{p}\n}\n",
  p => "requirementDiagram\nrequirement a {\nid: \"\{p}\"\ntext: \"\{p}\"\n}\n",
  p => {
    "requirementDiagram\nrequirement a {\nrisk: \{p}\nverifymethod: \{p}\n}\n"
  },
  p => "requirementDiagram\nelement b {\ntype: \{p}\ndocref: \{p}\n}\n",
  p => "requirementDiagram\nelement b {\ntype: \"\{p}\"\ndocRef: \"\{p}\"\n}\n",
  p => "requirementDiagram\n\{BODY}a - \{p} -> b\n",
  p => "requirementDiagram\n\{BODY}a - contains -> \{p}\n",
  p => "requirementDiagram\n\{BODY}\"\{p}\" <- traces - a\n",
  p => "requirementDiagram\nrequirement a:::\{p} {\nid: 1\n}\n",
  p => {
    "requirementDiagram\nrequirement a:::\"\{p}\" {\nid: 1\n}\nelement b:::\"\{p}\",\"\{p}\" {\n}\n"
  },
  p => "requirementDiagram\n\{BODY}a:::\{p}\n",
  p => "requirementDiagram\n\{BODY}a:::\"\{p}\"\n",
  p => "requirementDiagram\n\{BODY}class a \{p}\n",
  p => "requirementDiagram\n\{BODY}class a,b \"\{p}\"\n",
  p => "requirementDiagram\n\{BODY}class \"\{p}\" c\n",
  p => "requirementDiagram\n\{BODY}classDef \{p} fill:red\nclass a \{p}\n",
  p => {
    "requirementDiagram\n\{BODY}classDef \"\{p}\" fill:red\nclass a \"\{p}\"\n"
  },
  p => "requirementDiagram\n\{BODY}classDef c fill:\{p}\nclass a c\n",
  p => "requirementDiagram\n\{BODY}classDef c \{p}:red\nclass a c\n",
  p => "requirementDiagram\n\{BODY}style a fill:\{p}\n",
  p => "requirementDiagram\n\{BODY}style a \{p}\n",
  p => {
    "requirementDiagram\n\{BODY}style a color:\{p},stroke:\{p},font-family:\{p}\n"
  },
  p => "requirementDiagram\n\{BODY}style \"\{p}\" fill:red\n",
  p => "requirementDiagram\naccTitle: \{p}\naccDescr: \{p}\n\{BODY}",
  p => "accTitle: \{p}\nrequirementDiagram\n\{BODY}",
  p => "requirementDiagram\naccDescr {\n \{p}\n }\n\{BODY}",
  p => "requirementDiagram\ndirection \{p}\n\{BODY}",
  p => "requirementDiagram\n\{p} direction LR\n\{BODY}",
  p => "requirementDiagram\n# \{p}\n\{BODY}",
  p => "requirementDiagram\n%% \{p}\n\{BODY}",
  p => "requirementDiagram \{p}\n\{BODY}",
  p => {
    "---\ntitle: \"\{p}\"\nconfig:\n  requirement:\n    fontSize: \"\{p}\"\n  theme: \"\{p}\"\n---\nrequirementDiagram\n\{BODY}"
  },
  p => {
    "%%{init: {\"requirement\": {\"rect_fill\": \"\{p}\"}, \"themeVariables\": {\"fontFamily\": \"\{p}\"}}}%%\nrequirementDiagram\n\{BODY}"
  },
]

///|
/// Renders `source`, saying whether pele drew it and the first thing in the drawing that is not inert.
fn check(source : String, options : @types.RenderOptions) -> (Bool, String?) {
  let result = @core.render([@requirement.requirement], source, options) catch {
    @errors.PeleError(_) => return (false, None)
  }
  (true, inert_problem(result.svg))
}

///|
test "the output is inert with hostile text in every position" {
  let mut rendered = 0
  for template in templates {
    for payload in payloads {
      let source = template(payload)
      let (drawn, problem) = check(source, @types.RenderOptions::default())
      if drawn {
        rendered += 1
      }
      if problem is Some(problem) {
        fail("\{problem} for \{source.escape()}")
      }
    }
  }
  // pele v1.12.0 draws exactly this many of these texts and rejects the rest.
  inspect(rendered, content="966")
}

///|
test "text is escaped where it is shown" {
  let result = @core.render(
    [@requirement.requirement],
    "requirementDiagram\nrequirement \"<script>alert(1)</script>\" {\ntext: \"<img src=x onerror=alert(1)>\"\n}\n",
    @types.RenderOptions::default(),
  )
  assert_false(result.svg.contains("<script"))
  assert_false(result.svg.contains("<img"))
  assert_true(
    result.svg.contains("data-id=\"&lt;script&gt;alert(1)&lt;/script&gt;\""),
  )
}

///|
test "hostile option values stay inert" {
  for payload in payloads {
    let options = {
      ..@types.RenderOptions::default(),
      id_prefix: Some(payload),
      font_family: Some(payload),
    }
    let (drawn, problem) = check(
      "requirementDiagram\naccTitle: t\n\{BODY}a - contains -> b\n",
      options,
    )
    assert_true(drawn)
    assert_eq(problem, None, msg=payload.escape())
  }
}

///|
test "a model filled in directly, which the grammar would not allow, stays inert" {
  for payload in payloads {
    let db = @requirement.RequirementDb::new()
    db.title = Some(payload)
    db.set_acc_title(payload)
    db.set_acc_description(payload)
    db.set_direction(payload)
    db.set_new_req_id(payload)
    db.set_new_req_text(payload)
    db.set_new_req_risk(payload)
    db.set_new_req_verify_method(payload)
    db.add_requirement(payload, payload)
    db.set_new_element_type(payload)
    db.set_new_element_doc_ref(payload)
    db.add_element("e")
    db.add_relationship(payload, payload, "e")
    db.add_relationship(payload, "e", "e")
    db.define_class([payload], [
      payload,
      "fill:\{payload}",
      "stroke:\{payload}",
      "color:\{payload}",
      "font-family:\{payload}",
    ])
    db.set_class([payload, "e"], [payload])
    db.set_css_style(["e"], [
      "fill:\{payload},stroke-dasharray:\{payload}",
      "font-size:\{payload}",
      "\{payload}:red",
    ])
    let out = @requirement.render_requirement(
        db,
        {},
        @types.RenderOptions::default(),
      ).svg
    assert_eq(inert_problem(out), None, msg=payload.escape())
  }
}

///|
test "names that are special to JavaScript are ordinary names" {
  let result = @core.render(
    [@requirement.requirement],
    "requirementDiagram\nrequirement __proto__ {\nid: constructor\n}\nelement constructor {\ntype: toString\n}\n__proto__ - contains -> constructor\nclassDef __proto__ fill:red\nclass __proto__,constructor __proto__,toString\n__proto__:::constructor\nstyle __proto__ fill:red\n",
    @types.RenderOptions::default(),
  )
  assert_true(result.svg.contains("data-id=\"__proto__\""))
  assert_true(result.svg.contains("data-id=\"constructor\""))
  assert_true(result.svg.contains("data-id=\"__proto__-constructor-0\""))
}
